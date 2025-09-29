import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../../models/location_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/mock_data_service.dart';
import 'visit_provider.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  
  Position? _currentPosition;
  List<LocationLog> _locationLogs = [];
  bool _isTracking = false;
  bool _hasPermission = false;
  String? _error;
  double _batteryLevel = 0.0;
  VisitProvider? _visitProvider;
  bool _autoCheckoutEnabled = true;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  List<LocationLog> get locationLogs => _locationLogs;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  String? get error => _error;
  double get batteryLevel => _batteryLevel;
  bool get autoCheckoutEnabled => _autoCheckoutEnabled;
  
  // Initialize location services
  Future<void> initializeLocation() async {
    await _checkLocationPermission();
    if (_hasPermission) {
      await _getCurrentLocation();
    }
  }

  // Set visit provider for auto checkout
  void setVisitProvider(VisitProvider visitProvider) {
    _visitProvider = visitProvider;
  }

  // Enable/disable auto checkout
  void setAutoCheckoutEnabled(bool enabled) {
    _autoCheckoutEnabled = enabled;
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
        _setError('Location permission is permanently denied. Please enable it in settings.');
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
    
    // Start periodic location updates
    _startPeriodicLocationUpdates();
    
    // Start monitoring location permission changes
    startLocationPermissionMonitoring();
    
    notifyListeners();
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
    notifyListeners();
  }
  
  // Handle location updates
  Future<void> _onLocationUpdate(Position position) async {
    _currentPosition = position;
    
    // Get current user ID
    final userId = await getCurrentUserId();
    
    // Create location log
    final locationLog = LocationLog.create(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      battery: _batteryLevel,
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
  
  // Update battery level
  void updateBatteryLevel(double level) {
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
    try {
      final user = await MockDataService.getCurrentUser();
      return user?.id ?? '1'; // Default to user ID 1 if no user found
    } catch (e) {
      return '1'; // Default user ID for mock data
    }
  }

  // Handle location permission lost - trigger auto checkout
  Future<void> _handleLocationPermissionLost() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;
    
    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit != null) {
      try {
        await _visitProvider!.checkOut(
          visitId: activeVisit.id,
          notes: 'Auto checkout: Location permission denied',
        );
        
        // Show notification about auto checkout
        _showAutoCheckoutNotification('Location permission denied. Auto checkout completed.');
      } catch (e) {
        debugPrint('Auto checkout failed: $e');
      }
    }
  }

  // Handle location service disabled - trigger auto checkout
  Future<void> _handleLocationServiceDisabled() async {
    if (!_autoCheckoutEnabled || _visitProvider == null) return;
    
    final activeVisit = _visitProvider!.activeVisit;
    if (activeVisit != null) {
      try {
        await _visitProvider!.checkOut(
          visitId: activeVisit.id,
          notes: 'Auto checkout: Location service disabled',
        );
        
        // Show notification about auto checkout
        _showAutoCheckoutNotification('Location service disabled. Auto checkout completed.');
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
}
