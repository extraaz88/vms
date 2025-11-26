import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';
import '../../models/location_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/location_validation_service.dart';
import '../../services/background_timer_service.dart';
import '../../utils/auth_helper.dart';
import 'visit_provider.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final Battery _battery = Battery();

  Position? _currentPosition;
  Position? _lastLoggedPosition;
  List<LocationLog> _locationLogs = [];
  bool _isTracking = false;
  bool _hasPermission = false;
  String? _error;
  int _batteryLevel = 0;
  VisitProvider? _visitProvider;
  bool _autoCheckoutEnabled = true;
  Timer? _locationLogTimer;
  bool _isLoggingLocation = false;
  User? _currentUser;
  Timer? _autoCheckoutTimer;
  DateTime? _autoCheckoutDeadline;
  bool _isOutsideOfficeRadius = false;
  bool _isAutoCheckoutInProgress = false;
  VoidCallback? _visitProviderListener;
  StreamSubscription<Position>? _backgroundPositionStream;

  // Minimum distance in meters to trigger a new location log
  static const double _minDistanceForLogging = 10.0;

  static const Duration _autoCheckoutGracePeriod = Duration(minutes: 30);

  // Getters
  Position? get currentPosition => _currentPosition;
  List<LocationLog> get locationLogs => _locationLogs;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  String? get error => _error;
  int get batteryLevel => _batteryLevel;
  bool get autoCheckoutEnabled => _autoCheckoutEnabled;
  bool get isLoggingLocation => _isLoggingLocation;
  bool get isOutsideOfficeRadius => _isOutsideOfficeRadius;
  bool get isAutoCheckoutTimerActive => _autoCheckoutDeadline != null;
  DateTime? get autoCheckoutDeadline => _autoCheckoutDeadline;
  Duration? get autoCheckoutRemaining {
    if (_autoCheckoutDeadline == null) return null;
    final remaining = _autoCheckoutDeadline!.difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  // Initialize location services
  Future<void> initializeLocation() async {
    await _checkLocationPermission();

    // IMPORTANT: Restore timer state FIRST before getting location
    // This prevents _evaluateAutoCheckoutState from creating a new timer
    await _restoreTimerState();

    if (_hasPermission) {
      // If timer was restored, just get location without evaluating
      // Otherwise, normal location evaluation
      if (_autoCheckoutDeadline != null) {
        // Timer was restored, just update position
        try {
          _currentPosition = await _locationService.getCurrentPosition();
          notifyListeners();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not get location on init: $e');
          }
        }
      } else {
        // No timer restored, normal location evaluation
        await _getCurrentLocation();
      }
      await _updateBatteryLevel();
    }
  }

  // Restore timer state from persistent storage
  Future<void> _restoreTimerState() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) {
      await BackgroundTimerService.clearTimerState();
      return;
    }

    // Don't restore timer for sales people - they're expected to be outside office
    if (_currentUser?.isSalesPerson == true) {
      await BackgroundTimerService.clearTimerState();
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      return;
    }

    final savedDeadline = await BackgroundTimerService.loadTimerDeadline();
    final isOutside = await BackgroundTimerService.loadOutsideOfficeState();
    final savedVisitId = await BackgroundTimerService.loadActiveVisitId();

    // Check if we have an active visit that matches saved visit ID
    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit == null || savedVisitId != activeVisit.id) {
      // Visit doesn't match or no active visit, clear timer state
      await BackgroundTimerService.clearTimerState();
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      notifyListeners();
      return;
    }

    // If timer was active and we're still outside office
    if (savedDeadline != null && isOutside) {
      // Check if timer expired while app was closed
      final now = DateTime.now();
      if (now.isAfter(savedDeadline)) {
        // Timer expired, trigger auto checkout
        if (kDebugMode) {
          final expiredBy = now.difference(savedDeadline);
          print(
            '⏰ Timer expired while app was closed. Expired by: ${expiredBy.inSeconds} seconds. Triggering auto-checkout...',
          );
        }
        await BackgroundTimerService.clearTimerState();
        await _triggerAutoCheckout();
      } else {
        // Timer still active, restore it
        // Set the deadline FIRST before calling _startAutoCheckoutTimer
        // This prevents _startAutoCheckoutTimer from creating a new deadline
        _autoCheckoutDeadline = savedDeadline;
        _isOutsideOfficeRadius = true;
        _startAutoCheckoutTimer();
        if (kDebugMode) {
          final remaining = _autoCheckoutDeadline!.difference(now);
          print(
            '⏰ ✅ Restored background timer. Deadline: $_autoCheckoutDeadline, Remaining: ${remaining.inSeconds} seconds (${(remaining.inSeconds / 60).toStringAsFixed(1)} minutes)',
          );
        }
        notifyListeners();
      }
    } else {
      // No active timer, clear state
      if (kDebugMode) {
        if (savedDeadline != null) {
          print(
            '⏰ No active timer to restore (isOutside=$isOutside, savedDeadline=$savedDeadline)',
          );
        }
      }
      await BackgroundTimerService.clearTimerState();
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
    }
  }

  // Set current user for role-based functionality
  void setCurrentUser(User? user) {
    _currentUser = user;

    // If user becomes Flutter Developer, stop location logging
    if (user?.isFlutterDeveloper == true && _isLoggingLocation) {
      stopPeriodicLocationLogging();
      if (kDebugMode) {
        print('📍 Location logging stopped for Flutter Developer role');
      }
    }
  }

  // Start periodic location logging (every 30 seconds)
  void startPeriodicLocationLogging() {
    if (_isLoggingLocation) return;

    // Don't start location logging for Flutter Developer
    if (_currentUser?.isFlutterDeveloper == true) {
      if (kDebugMode) {
        print('📍 Location logging disabled for Flutter Developer role');
      }
      return;
    }

    _isLoggingLocation = true;
    notifyListeners();

    if (kDebugMode) {
      print('📍 Starting periodic location logging (every 30 seconds)...');
    }

    // Update battery level immediately before starting
    _updateBatteryLevel();

    // Start the timer to log location every 30 seconds
    _locationLogTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      await _logLocationToApi();
    });
  }

  // Stop periodic location logging
  void stopPeriodicLocationLogging() {
    _locationLogTimer?.cancel();
    _locationLogTimer = null;
    _isLoggingLocation = false;
    notifyListeners();

    if (kDebugMode) {
      print('📍 Stopped periodic location logging');
    }
  }

  // Update battery level
  Future<void> _updateBatteryLevel() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      _batteryLevel = batteryLevel;

      if (kDebugMode) {
        print('🔋 Battery Level Retrieved: $_batteryLevel%');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting battery level: $e');
        print('Setting default battery level to 50%');
      }
      // Set a default value if battery level can't be retrieved
      _batteryLevel = 50;
      notifyListeners();
    }
  }

  // Log location to API
  Future<void> _logLocationToApi() async {
    try {
      // Get current position
      Position? position = _currentPosition;

      // If we don't have a current position, try to get one
      if (position == null) {
        position = await _getCurrentLocation();
        if (position == null) return;
      }

      // Check if location has changed significantly since last log
      if (_lastLoggedPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastLoggedPosition!.latitude,
          _lastLoggedPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Skip logging if location hasn't changed significantly
        if (distance < _minDistanceForLogging) {
          if (kDebugMode) {
            print(
              '📍 Location unchanged (${distance.toStringAsFixed(1)}m < ${_minDistanceForLogging}m), skipping log',
            );
          }
          return;
        }
      }

      // Update battery level
      await _updateBatteryLevel();

      // Get user ID
      final userId = await getCurrentUserId();
      final userIdInt = int.tryParse(userId) ?? 3;

      // Format timestamp: "2025-10-03 09:30"
      final now = DateTime.now();
      final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(now);

      // Log location to API
      await _apiService.logLocationToLiveApi(
        userId: userIdInt,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        batteryPercent: _batteryLevel,
        loggedAt: formattedTime,
      );

      // Update last logged position
      _lastLoggedPosition = position;

      if (kDebugMode) {
        print(
          '📍 Location logged: (${position.latitude}, ${position.longitude}), Battery: $_batteryLevel%',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging location: $e');
      }
      // Don't stop logging on error, just continue
    }
  }

  // Set visit provider for auto checkout
  void setVisitProvider(VisitProvider visitProvider) {
    if (_visitProvider != null && _visitProviderListener != null) {
      _visitProvider!.removeListener(_visitProviderListener!);
    }

    _visitProvider = visitProvider;
    _visitProviderListener = () {
      if (!visitProvider.hasActiveVisit) {
        final bool wasOutside = _isOutsideOfficeRadius;
        final bool timerWasActive =
            _autoCheckoutTimer != null || _autoCheckoutDeadline != null;
        _isOutsideOfficeRadius = false;
        _cancelAutoCheckoutTimer();
        if (wasOutside || timerWasActive) {
          notifyListeners();
        }
      } else if (_currentPosition != null) {
        _evaluateAutoCheckoutState(_currentPosition!);
      }
    };

    _visitProvider!.addListener(_visitProviderListener!);
  }

  // Enable/disable auto checkout
  void setAutoCheckoutEnabled(bool enabled) {
    _autoCheckoutEnabled = enabled;
    if (!enabled) {
      final bool stateChanged =
          _isOutsideOfficeRadius || _autoCheckoutDeadline != null;
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      if (stateChanged) {
        notifyListeners();
        return;
      }
    } else if (_currentPosition != null) {
      _evaluateAutoCheckoutState(_currentPosition!);
    }
    notifyListeners();
  }

  // Check location permission
  Future<bool> _checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;

      if (permission.isGranted) {
        _hasPermission = true;
        notifyListeners();
        return true;
      }

      if (permission.isDenied) {
        final result = await Permission.location.request();
        _hasPermission = result.isGranted;
        notifyListeners();
        return _hasPermission;
      }

      if (permission.isPermanentlyDenied) {
        _hasPermission = false;
        _setError(
          'Location permission is permanently denied. Please enable it in settings.',
        );
        _handleLocationPermissionLost();
        notifyListeners();
        return false;
      }

      return false;
    } catch (e) {
      _setError('Permission check failed: ${e.toString()}');
      return false;
    }
  }

  // Get current location (private method)
  Future<Position?> _getCurrentLocation() async {
    try {
      _currentPosition = await _locationService.getCurrentPosition();
      if (_currentPosition != null) {
        _evaluateAutoCheckoutState(_currentPosition!);
      }
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _setError('Failed to get location: ${e.toString()}');
      // Check if location service is disabled
      if (e.toString().contains('Location services are disabled')) {
        _handleLocationServiceDisabled();
      }
      return null;
    }
  }

  // Get current location (public method)
  Future<Position?> getCurrentLocation() async {
    if (!_hasPermission) {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return null;
    }

    return await _getCurrentLocation();
  }

  // Start location tracking
  Future<void> startTracking() async {
    if (!_hasPermission) {
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) return;
    }

    _isTracking = true;
    _clearError();

    // Start location stream with periodic updates
    _locationService.startLocationStream(
      onLocationUpdate: _onLocationUpdate,
      onError: _setError,
    );

    // Start background location tracking for timer
    await _startBackgroundLocationTracking();

    // Start periodic location updates
    _startPeriodicLocationUpdates();

    // Start monitoring location permission changes
    startLocationPermissionMonitoring();

    notifyListeners();
  }

  // Start background location tracking for timer
  Future<void> _startBackgroundLocationTracking() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;

    // Don't start background tracking for sales people
    if (_currentUser?.isSalesPerson == true) return;

    try {
      // Request background location permission
      final backgroundPermission = await Permission.locationAlways.request();
      if (!backgroundPermission.isGranted) {
        if (kDebugMode) {
          print('⚠️ Background location permission not granted');
        }
        return;
      }

      // Start background position stream for timer checking
      // This will run even when app is in background
      _startBackgroundPositionStream();

      if (kDebugMode) {
        print('✅ Background location tracking started for timer');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting background location tracking: $e');
      }
    }
  }

  // Start background position stream
  void _startBackgroundPositionStream() {
    _backgroundPositionStream?.cancel();

    // Configure location settings for background execution
    // The position stream will continue even when app is in background
    // For true background execution when app is killed, we need proper native configuration
    _backgroundPositionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
            timeLimit: Duration(
              seconds: 30, // Check every 30 seconds for 1-hour timer
            ),
          ),
        ).listen(
          (Position position) async {
            // This callback runs even in background (when app is minimized)
            // For app completely killed, we rely on resume check
            await _checkTimerInBackground(position);
          },
          onError: (error) {
            if (kDebugMode) {
              print('❌ Background position stream error: $error');
            }
          },
        );

    // Also start a periodic background timer check
    // This runs independently to check timer even if location updates are delayed
    _startPeriodicBackgroundTimerCheck();

    if (kDebugMode) {
      print('✅ Background position stream started with 15-second checks');
    }
  }

  // Periodic background timer check (runs every 10 seconds)
  Timer? _backgroundTimerCheckTimer;
  void _startPeriodicBackgroundTimerCheck() {
    _backgroundTimerCheckTimer?.cancel();

    _backgroundTimerCheckTimer = Timer.periodic(const Duration(seconds: 10), (
      Timer timer,
    ) async {
      // Check timer state even without location update
      await _checkTimerStateInBackground();
    });
  }

  // Check timer state in background (without location update)
  Future<void> _checkTimerStateInBackground() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;
    if (_currentUser?.isSalesPerson == true) return;

    final deadline = await BackgroundTimerService.loadTimerDeadline();
    final isOutside = await BackgroundTimerService.loadOutsideOfficeState();
    final visitId = await BackgroundTimerService.loadActiveVisitId();

    if (deadline == null || !isOutside || visitId == null) {
      return;
    }

    final now = DateTime.now();

    // Check if timer expired
    if (now.isAfter(deadline)) {
      // Timer expired - get current location and trigger auto checkout
      if (kDebugMode) {
        final expiredBy = now.difference(deadline);
        print(
          '🚨 Timer expired in background check! Expired by: ${expiredBy.inSeconds} seconds. Getting location and triggering auto-checkout...',
        );
      }

      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not get location for background checkout: $e');
        }
      }

      await _triggerAutoCheckoutFromBackground(visitId, position);
    }
  }

  // Check timer in background
  Future<void> _checkTimerInBackground(Position position) async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;

    // Don't check timer for sales people
    if (_currentUser?.isSalesPerson == true) return;

    final deadline = await BackgroundTimerService.loadTimerDeadline();
    final isOutside = await BackgroundTimerService.loadOutsideOfficeState();
    final visitId = await BackgroundTimerService.loadActiveVisitId();

    if (deadline == null || !isOutside || visitId == null) {
      return;
    }

    final now = DateTime.now();

    // Check if timer expired
    if (now.isAfter(deadline)) {
      // Timer expired - trigger auto checkout immediately
      if (kDebugMode) {
        final expiredBy = now.difference(deadline);
        print(
          '🚨 Timer expired in background! Expired by: ${expiredBy.inSeconds} seconds. Triggering auto-checkout...',
        );
      }
      await _triggerAutoCheckoutFromBackground(visitId, position);
      return;
    }

    // Check if user returned to office
    final isInOffice = LocationValidationService.isUserInOffice(position);
    if (isInOffice) {
      // User returned, clear timer
      await BackgroundTimerService.clearTimerState();
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      _backgroundPositionStream?.cancel();
      if (kDebugMode) {
        print('✅ User returned to office (background check)');
      }
    } else {
      // Still outside, update saved state and log remaining time
      await BackgroundTimerService.saveOutsideOfficeState(true);
      if (kDebugMode) {
        final remaining = deadline.difference(now);
        if (remaining.inSeconds % 15 == 0) {
          // Log every 15 seconds to avoid spam
          print(
            '⏰ Background timer active. Remaining: ${remaining.inSeconds} seconds',
          );
        }
      }
    }
  }

  // Trigger auto checkout from background
  Future<void> _triggerAutoCheckoutFromBackground(
    String visitId,
    Position? position,
  ) async {
    if (_isAutoCheckoutInProgress || _visitProvider == null) return;

    _isAutoCheckoutInProgress = true;

    try {
      final userId = await getCurrentUserId();

      // Call the checkout API
      final success = await _visitProvider!.checkOut(
        visitId: visitId,
        userId: int.tryParse(userId),
        outLatitude: position?.latitude ?? 0.0,
        outLongitude: position?.longitude ?? 0.0,
        checkOutTime: DateTime.now().toString().substring(0, 19),
        outAccuracy: position?.accuracy ?? 0.0,
        outBatteryPercent: _batteryLevel.toDouble(),
        outNotes:
            'Auto checkout: Away from office for more than 1 hour (Background)',
      );

      if (success) {
        // Checkout successful - clear all state
        await BackgroundTimerService.clearTimerState();
        _isOutsideOfficeRadius = false;
        _cancelAutoCheckoutTimer();
        _stopBackgroundLocationTracking();

        if (kDebugMode) {
          print('✅ Background auto-checkout completed successfully');
        }
      } else {
        // Checkout failed - log error but still clear timer state
        if (kDebugMode) {
          print(
            '❌ Background auto-checkout failed: ${_visitProvider!.error ?? "Unknown error"}',
          );
        }
        await BackgroundTimerService.clearTimerState();
        _isOutsideOfficeRadius = false;
        _cancelAutoCheckoutTimer();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in background auto-checkout: $e');
      }
      // Even on exception, clear the timer state
      await BackgroundTimerService.clearTimerState();
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
    } finally {
      _isAutoCheckoutInProgress = false;
    }
  }

  // Stop background location tracking
  Future<void> _stopBackgroundLocationTracking() async {
    try {
      _backgroundPositionStream?.cancel();
      _backgroundPositionStream = null;
      if (kDebugMode) {
        print('🛑 Background location tracking stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error stopping background location tracking: $e');
      }
    }
  }

  // Start periodic location updates (alternative to workmanager)
  void _startPeriodicLocationUpdates() {
    Future.delayed(const Duration(minutes: 1), () async {
      if (_isTracking) {
        await _getCurrentLocation();
        _startPeriodicLocationUpdates();
      }
    });
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    _isTracking = false;
    await _locationService.stopLocationStream();
    await _stopBackgroundLocationTracking();
    notifyListeners();
  }

  // Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    _currentPosition = position;
    _evaluateAutoCheckoutState(position);

    // Get current user ID
    final userId = await getCurrentUserId();

    // Create location log
    final locationLog = LocationLog.create(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      battery: _batteryLevel.toDouble(),
      userId: userId,
    );

    // Add to logs
    _locationLogs.add(locationLog);

    // Send to API
    await _sendLocationToApi(locationLog);

    notifyListeners();
  }

  // Send location to API
  Future<void> _sendLocationToApi(LocationLog locationLog) async {
    try {
      await _apiService.logLocation(
        locationLog.latitude,
        locationLog.longitude,
        locationLog.accuracy,
        locationLog.battery,
      );
    } catch (e) {
      // Store locally if API fails
      await _locationService.storeLocationLocally(locationLog);
    }
  }

  // Get journey data
  Future<List<LocationLog>> getJourneyData(DateTime date) async {
    try {
      final response = await _apiService.getJourneyData(date);
      _locationLogs = response;
      notifyListeners();
      return _locationLogs;
    } catch (e) {
      _setError('Failed to fetch journey data: ${e.toString()}');
      return [];
    }
  }

  // Get live tracking data
  Future<List<Map<String, dynamic>>> getLiveTrackingData() async {
    try {
      return await _apiService.getLiveTrackingData();
    } catch (e) {
      _setError('Failed to fetch live tracking data: ${e.toString()}');
      return [];
    }
  }

  // Update battery level manually
  void updateBatteryLevel(int level) {
    _batteryLevel = level;
    notifyListeners();
  }

  // Clear location logs
  void clearLocationLogs() {
    _locationLogs.clear();
    notifyListeners();
  }

  // Helper methods
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Get current user ID (for location logging)
  Future<String> getCurrentUserId() async {
    // Use AuthHelper to get authenticated user ID
    final userId = await AuthHelper.getAuthenticatedUserId();

    if (kDebugMode) {
      print('📍 LocationProvider: Using authenticated user ID: $userId');
    }

    return userId;
  }

  // Handle location permission lost - trigger auto checkout
  Future<void> _handleLocationPermissionLost() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;

    _isOutsideOfficeRadius = false;
    _cancelAutoCheckoutTimer();

    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit != null) {
      try {
        await _visitProvider!.checkOut(
          visitId: activeVisit.id,
          notes: 'Auto checkout: Location permission denied',
        );

        // Show notification about auto checkout
        _showAutoCheckoutNotification(
          'Location permission denied. Auto checkout completed.',
        );
      } catch (e) {
        debugPrint('Auto checkout failed: $e');
      }
    }
  }

  // Handle location service disabled - trigger auto checkout
  Future<void> _handleLocationServiceDisabled() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;

    _isOutsideOfficeRadius = false;
    _cancelAutoCheckoutTimer();

    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit != null) {
      try {
        await _visitProvider!.checkOut(
          visitId: activeVisit.id,
          notes: 'Auto checkout: Location service disabled',
        );

        // Show notification about auto checkout
        _showAutoCheckoutNotification(
          'Location service disabled. Auto checkout completed.',
        );
      } catch (e) {
        debugPrint('Auto checkout failed: $e');
      }
    }
  }

  // Show auto checkout notification
  void _showAutoCheckoutNotification(String message) {
    // This will be handled by the UI layer
    debugPrint('Auto Checkout: $message');
  }

  void _evaluateAutoCheckoutState(Position position) {
    if (!_autoCheckoutEnabled || _visitProvider == null) {
      final bool stateChanged =
          _isOutsideOfficeRadius || _autoCheckoutDeadline != null;
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      if (stateChanged) {
        notifyListeners();
      }
      return;
    }

    // Auto-checkout timer only applies to developers, not sales people
    // Sales people are expected to work outside the office
    if (_currentUser?.isSalesPerson == true) {
      // Sales person - don't start timer, clear any existing timer
      final bool stateChanged =
          _isOutsideOfficeRadius || _autoCheckoutDeadline != null;
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      BackgroundTimerService.clearTimerState();
      _stopBackgroundLocationTracking();
      if (stateChanged) {
        notifyListeners();
      }
      return;
    }

    if (!_visitProvider!.hasActiveVisit) {
      final bool stateChanged =
          _isOutsideOfficeRadius || _autoCheckoutDeadline != null;
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      _stopBackgroundLocationTracking();
      BackgroundTimerService.clearTimerState();
      if (stateChanged) {
        notifyListeners();
      }
      return;
    }

    final bool isInOffice = LocationValidationService.isUserInOffice(position);
    final distance = LocationValidationService.getDistanceFromOffice(position);

    if (kDebugMode) {
      print(
        '📍 Location evaluation: isInOffice=$isInOffice, distance=${distance?.toStringAsFixed(0) ?? "unknown"}m, hasActiveVisit=${_visitProvider!.hasActiveVisit}',
      );
    }

    if (isInOffice) {
      final bool stateChanged =
          _isOutsideOfficeRadius || _autoCheckoutDeadline != null;
      if (stateChanged && kDebugMode) {
        print('✅ Developer returned to office, canceling auto-checkout timer');
      }
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      // Clear saved state when back in office
      BackgroundTimerService.clearTimerState();
      // Stop background tracking when back in office
      _stopBackgroundLocationTracking();
      if (stateChanged) {
        notifyListeners();
      }
      return;
    }

    if (!_isOutsideOfficeRadius) {
      // Only start a new timer if one doesn't already exist (not restoring)
      if (_autoCheckoutDeadline == null) {
        _isOutsideOfficeRadius = true;
        if (kDebugMode) {
          final distance = LocationValidationService.getDistanceFromOffice(
            position,
          );
          print(
            '🚨 Developer went outside office. Distance: ${distance?.toStringAsFixed(0) ?? "unknown"}m',
          );
          print('⏰ Starting 1-hour auto-checkout timer...');
        }
        _startAutoCheckoutTimer();
        // Save state immediately when going outside
        _saveTimerState();
        // Start background tracking when going outside
        _startBackgroundLocationTracking();
        notifyListeners();
      } else {
        // Timer already exists (being restored), just mark as outside
        _isOutsideOfficeRadius = true;
        if (kDebugMode) {
          print('🔄 Timer already exists, not creating new one');
        }
      }
    } else if (_autoCheckoutDeadline != null) {
      // Already outside, just update saved state
      _saveTimerState();
    }
  }

  void _startAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();

    // If deadline is already set (from restore), use it, otherwise create new one
    if (_autoCheckoutDeadline == null) {
      _autoCheckoutDeadline = DateTime.now().add(_autoCheckoutGracePeriod);
      if (kDebugMode) {
        print(
          '⏰ Created NEW timer deadline: $_autoCheckoutDeadline (${_autoCheckoutGracePeriod.inSeconds} seconds from now)',
        );
      }
    } else {
      if (kDebugMode) {
        final remaining = _autoCheckoutDeadline!.difference(DateTime.now());
        print(
          '⏰ Using EXISTING timer deadline: $_autoCheckoutDeadline (${remaining.inSeconds} seconds remaining)',
        );
      }
    }

    // Save timer state to persistent storage for background tracking
    _saveTimerState();

    _autoCheckoutTimer = Timer.periodic(const Duration(seconds: 1), (
      Timer timer,
    ) async {
      if (_autoCheckoutDeadline == null) {
        timer.cancel();
        return;
      }

      // Check if there's still an active visit before triggering checkout
      if (_visitProvider == null || !_visitProvider!.hasActiveVisit) {
        timer.cancel();
        _autoCheckoutDeadline = null;
        _isOutsideOfficeRadius = false;
        await BackgroundTimerService.clearTimerState();
        notifyListeners();
        return;
      }

      final remaining = _autoCheckoutDeadline!.difference(DateTime.now());
      if (remaining.isNegative || remaining.inSeconds == 0) {
        timer.cancel();
        await BackgroundTimerService.clearTimerState();
        await _triggerAutoCheckout();
      } else {
        // Update saved state periodically (every 10 seconds to reduce writes)
        if (remaining.inSeconds % 10 == 0) {
          _saveTimerState();
        }
        notifyListeners();
      }
    });

    if (kDebugMode) {
      print('⏰ Auto-checkout timer started. Deadline: $_autoCheckoutDeadline');
    }
  }

  // Save timer state to persistent storage
  Future<void> _saveTimerState() async {
    if (_autoCheckoutDeadline != null && _visitProvider?.activeVisit != null) {
      await BackgroundTimerService.saveTimerDeadline(_autoCheckoutDeadline);
      await BackgroundTimerService.saveTimerStartTime(
        _autoCheckoutDeadline!.subtract(_autoCheckoutGracePeriod),
      );
      await BackgroundTimerService.saveOutsideOfficeState(
        _isOutsideOfficeRadius,
      );
      await BackgroundTimerService.saveActiveVisitId(
        _visitProvider!.activeVisit!.id,
      );
    }
  }

  void _cancelAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;
    _autoCheckoutDeadline = null;
    // Clear saved timer state
    BackgroundTimerService.clearTimerState();
  }

  Future<void> _triggerAutoCheckout() async {
    if (_isAutoCheckoutInProgress || _visitProvider == null) return;

    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit == null) {
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      _stopBackgroundLocationTracking();
      await BackgroundTimerService.clearTimerState();
      notifyListeners();
      return;
    }

    _isAutoCheckoutInProgress = true;

    try {
      final userId = await getCurrentUserId();
      final position = _currentPosition;

      // Call the checkout API
      final success = await _visitProvider!.checkOut(
        visitId: activeVisit.id,
        userId: int.tryParse(userId),
        outLatitude: position?.latitude,
        outLongitude: position?.longitude,
        checkOutTime: DateTime.now().toString().substring(0, 19),
        outAccuracy: position?.accuracy,
        outBatteryPercent: _batteryLevel.toDouble(),
        outNotes: 'Auto checkout: Away from office for more than 1 hour',
      );

      if (success) {
        // Checkout successful - clear all state
        _isOutsideOfficeRadius = false;
        _cancelAutoCheckoutTimer();
        _stopBackgroundLocationTracking();
        await BackgroundTimerService.clearTimerState();

        _showAutoCheckoutNotification(
          'You were outside the office for over 1 hour. Auto check-out completed.',
        );

        if (kDebugMode) {
          print('✅ Auto checkout completed successfully');
        }
      } else {
        // Checkout failed - log error but still clear timer state to prevent retry loops
        debugPrint(
          '❌ Auto checkout failed: ${_visitProvider!.error ?? "Unknown error"}',
        );
        _isOutsideOfficeRadius = false;
        _cancelAutoCheckoutTimer();
        await BackgroundTimerService.clearTimerState();
      }
    } catch (e) {
      debugPrint('❌ Auto checkout exception: $e');
      // Even on exception, clear the timer state to prevent retry loops
      _isOutsideOfficeRadius = false;
      _cancelAutoCheckoutTimer();
      await BackgroundTimerService.clearTimerState();
    } finally {
      _isAutoCheckoutInProgress = false;
      notifyListeners();
    }
  }

  // Check timer state when app resumes (called by AppLifecycleObserver)
  Future<void> checkTimerOnResume() async {
    if (kDebugMode) {
      print('📱 App resumed, checking timer state...');
    }

    // IMPORTANT: Restore timer state FIRST before getting location
    // This prevents _evaluateAutoCheckoutState from creating a new timer
    final hadActiveTimer = _autoCheckoutDeadline != null;
    await _restoreTimerState();
    final timerWasRestored = _autoCheckoutDeadline != null && !hadActiveTimer;

    // Get current location to update position
    if (_hasPermission) {
      if (timerWasRestored) {
        // Timer was restored, just update current position without re-evaluating
        // (to avoid creating a new timer)
        try {
          _currentPosition = await _locationService.getCurrentPosition();
          notifyListeners();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not get location on resume: $e');
          }
        }
      } else {
        // No timer was restored, normal location evaluation
        await _getCurrentLocation();
      }
    }
  }

  // Start monitoring location permission changes
  void startLocationPermissionMonitoring() {
    // Check permission status every 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      if (_isTracking) {
        final currentPermission = await Permission.location.status;
        if (!currentPermission.isGranted && _hasPermission) {
          // Permission was revoked
          _hasPermission = false;
          _handleLocationPermissionLost();
          notifyListeners();
        }
        startLocationPermissionMonitoring(); // Continue monitoring
      }
    });
  }

  @override
  void dispose() {
    _locationLogTimer?.cancel();
    _autoCheckoutTimer?.cancel();
    _backgroundPositionStream?.cancel();
    _backgroundTimerCheckTimer?.cancel();
    if (_visitProvider != null && _visitProviderListener != null) {
      _visitProvider!.removeListener(_visitProviderListener!);
    }
    super.dispose();
  }
}
