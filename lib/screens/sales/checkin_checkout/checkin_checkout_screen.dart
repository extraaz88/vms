import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms/core/providers/auth_provider.dart';
import 'package:vms/core/providers/checkin_checkout_history_provider.dart';
import 'package:vms/core/providers/location_provider.dart';
import 'package:vms/core/providers/notification_provider.dart';
import 'package:vms/core/providers/visit_provider.dart';
import 'package:vms/core/theme/app_theme.dart';
import 'package:vms/screens/developer/attendance/attendance_screen.dart';
import 'dart:convert';

import 'package:vms/services/api_service.dart';
import 'package:vms/services/checkin_reminder_service.dart';
import 'package:vms/services/geocoding_service.dart';
import 'package:vms/services/location_validation_service.dart';
import 'package:vms/utils/auth_helper.dart';
import 'package:vms/utils/responsive_utils.dart';
import 'package:vms/utils/validation_utils.dart';
import 'package:vms/widgets/custom_bottom_navigation.dart';

class CheckinCheckoutScreen extends StatefulWidget {
  const CheckinCheckoutScreen({super.key});

  @override
  State<CheckinCheckoutScreen> createState() => _CheckinCheckoutScreenState();
}

class _CheckinCheckoutScreenState extends State<CheckinCheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  String _areaName = 'Loading...';
  bool _isLoadingArea = true;
  bool _isCheckingStatus = true;
  bool _shouldShowCheckOut = false;
  bool _isTodayCompleted =
      false; // Track if today's checkin/checkout is completed
  String?
  _todayAttendanceStatus; // Track today's attendance status (full_day, half_day, etc.)
  String? _activeCheckInId; // Store check-in ID from API
  DateTime? _checkInTime; // Store check-in time for duration calculation
  DateTime? _checkOutTime; // Store check-out time for final duration display

  // Notes controller for check-in/check-out
  final TextEditingController _notesController = TextEditingController();
  // Tasks controller for developers
  final TextEditingController _tasksController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _notesController.dispose();
    _tasksController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();

    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
    ]);

    // Load check-in/check-out times from API (with local storage fallback)
    await _loadTimesFromAPI();

    await _loadAreaName();
    await _checkUserCheckInStatus();
  }

  // Load check-in/check-out times from API (same as attendance screen)
  Future<void> _loadTimesFromAPI() async {
    try {
      final userId = await AuthHelper.getAuthenticatedUserId();
      final userIdInt = int.tryParse(userId) ?? 3;

      // Use the same API as attendance screen
      final historyProvider = context.read<CheckInCheckOutHistoryProvider>();
      await historyProvider.loadCheckInCheckOutHistory(userIdInt);

      // Get today's record from the history
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all details and find today's record
      final allDetails = historyProvider.allCheckInCheckOutDetails;
      final todayRecord = allDetails.firstWhere(
        (detail) =>
            detail.checkInTime.isAfter(todayStart) &&
            detail.checkInTime.isBefore(todayEnd),
        orElse: () => throw StateError('No record found for today'),
      );

      // Extract check-in and check-out times from today's record
      bool shouldUpdate = false;

      // Check-in time is always present in the record
      if (_checkInTime != todayRecord.checkInTime) {
        _checkInTime = todayRecord.checkInTime;
        shouldUpdate = true;
        print('📅 Loaded check-in time from history API: $_checkInTime');
      }

      // Check-out time can be null (same as attendance screen)
      if (todayRecord.checkOutTime != null) {
        if (_checkOutTime != todayRecord.checkOutTime) {
          _checkOutTime = todayRecord.checkOutTime;
          shouldUpdate = true;
          print('📅 Loaded check-out time from history API: $_checkOutTime');
        }
      } else {
        // Explicitly set to null if not checked out (same as attendance screen)
        if (_checkOutTime != null) {
          _checkOutTime = null;
          shouldUpdate = true;
          print('📅 Check-out time is null (not checked out yet)');
        }
      }

      if (shouldUpdate && mounted) {
        setState(() {
          // State variables already updated above
        });
      }
    } catch (e) {
      // No record found for today or error loading
      print('⚠️ Error loading times from history API: $e');
      // Reset times if no record found
      if (mounted) {
        setState(() {
          _checkInTime = null;
          _checkOutTime = null;
        });
      }
    }
  }

  Future<void> _checkUserCheckInStatus() async {
    try {
      if (mounted) {
        setState(() {
          _isCheckingStatus = true;
        });
      }

      final authProvider = context.read<AuthProvider>();
      final visitProvider = context.read<VisitProvider>();
      final isFlutterDeveloper = authProvider.user?.isFlutterDeveloper ?? false;
      final prefs = await SharedPreferences.getInstance();

      // For Flutter developers, check API first, then local storage for today's completion
      if (isFlutterDeveloper) {
        // First try to get times from API
        final userId = await AuthHelper.getAuthenticatedUserId();
        final userIdInt = int.tryParse(userId) ?? 3;
        final todayStatusCheck = await _apiService.getTodayCheckInStatus(
          userIdInt,
        );
        final Map<String, dynamic>? todayDataCheck =
            todayStatusCheck['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(todayStatusCheck['data'])
            : null;

        final bool hasCheckedOutTodayCheck =
            _parseBool(todayStatusCheck['hasCheckedOutToday']) ??
            _parseBool(todayDataCheck?['has_checked_out_today']) ??
            false;

        if (hasCheckedOutTodayCheck) {
          final todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final attendanceStatus =
              todayDataCheck?['attendance_status'] ?? 'completed';

          // Extract times from API
          final checkInTimeFromAPI = _parseFlexibleDateTime(
            todayStatusCheck['todayCheckInTime'] ??
                todayDataCheck?['today_checkin_time'] ??
                todayDataCheck?['check_in_time'],
          );
          final checkOutTimeFromAPI = _parseFlexibleDateTime(
            todayStatusCheck['todayCheckOutTime'] ??
                todayDataCheck?['today_checkout_time'] ??
                todayDataCheck?['check_out_time'],
          );

          if (checkInTimeFromAPI != null) {
            final today = DateTime.now();
            if (checkInTimeFromAPI.year == today.year &&
                checkInTimeFromAPI.month == today.month &&
                checkInTimeFromAPI.day == today.day) {
              _checkInTime = checkInTimeFromAPI;
            }
          }
          if (checkOutTimeFromAPI != null) {
            final today = DateTime.now();
            if (checkOutTimeFromAPI.year == today.year &&
                checkOutTimeFromAPI.month == today.month &&
                checkOutTimeFromAPI.day == today.day) {
              _checkOutTime = checkOutTimeFromAPI;
            }
          }

          await prefs.setString('flutter_dev_completed_date', todayDateKey);
          await prefs.setString(
            'flutter_dev_attendance_status',
            attendanceStatus,
          );

          visitProvider.clearRemoteActiveVisit();
          setState(() {
            _isCheckingStatus = false;
            _isTodayCompleted = true;
            _todayAttendanceStatus = attendanceStatus;
            _shouldShowCheckOut = false;
          });
          print(
            '✅ Flutter Developer: Today ($todayDateKey) is already completed (from API)',
          );
          return;
        }

        // No fallback to local storage - API is the source of truth
      }

      // Get user ID
      final userId = await AuthHelper.getAuthenticatedUserId();
      final userIdInt = int.tryParse(userId) ?? 3;

      print('🔍 Checking check-in status for user ID: $userIdInt');

      final todayStatus = await _apiService.getTodayCheckInStatus(userIdInt);
      final Map<String, dynamic>? todayData =
          todayStatus['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(todayStatus['data'])
          : null;
      final bool hasCheckedOutToday =
          _parseBool(todayStatus['hasCheckedOutToday']) ??
          _parseBool(todayData?['has_checked_out_today']) ??
          false;
      final bool hasCheckedInToday =
          _parseBool(todayStatus['hasCheckedInToday']) ??
          _parseBool(todayData?['has_checked_in_today']) ??
          false;

      // Get times from history API (same source as attendance screen)
      // This ensures consistency between attendance screen and check-in/check-out screen
      try {
        final historyProvider = context.read<CheckInCheckOutHistoryProvider>();
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final allDetails = historyProvider.allCheckInCheckOutDetails;
        final todayRecord = allDetails.firstWhere(
          (detail) =>
              detail.checkInTime.isAfter(todayStart) &&
              detail.checkInTime.isBefore(todayEnd),
          orElse: () => throw StateError('No record found for today'),
        );

        // Update times from history API (same as attendance screen)
        bool timesUpdated = false;
        if (_checkInTime != todayRecord.checkInTime) {
          _checkInTime = todayRecord.checkInTime;
          timesUpdated = true;
          print('📅 Updated check-in time from history API: $_checkInTime');
        }

        // Check-out time can be null (same as attendance screen)
        if (todayRecord.checkOutTime != null) {
          if (_checkOutTime != todayRecord.checkOutTime) {
            _checkOutTime = todayRecord.checkOutTime;
            timesUpdated = true;
            print('📅 Updated check-out time from history API: $_checkOutTime');
          }
        } else {
          // Explicitly set to null if not checked out (same as attendance screen)
          if (_checkOutTime != null) {
            _checkOutTime = null;
            timesUpdated = true;
            print('📅 Check-out time is null (not checked out yet)');
          }
        }

        // Update UI if times were changed
        if (timesUpdated && mounted) {
          setState(() {
            // Times already updated above
          });
        }
      } catch (e) {
        // No record found for today - times will remain as loaded from _loadTimesFromAPI
        print('⚠️ No today record in history API during status check: $e');
      }

      if (hasCheckedOutToday) {
        final todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final attendanceStatus = todayData?['attendance_status'] ?? 'completed';

        if (isFlutterDeveloper) {
          await prefs.setString('flutter_dev_completed_date', todayDateKey);
          await prefs.setString(
            'flutter_dev_attendance_status',
            attendanceStatus,
          );
        }

        visitProvider.clearRemoteActiveVisit();
        setState(() {
          _isCheckingStatus = false;
          _isTodayCompleted = true;
          _todayAttendanceStatus = attendanceStatus;
          _shouldShowCheckOut = false;
        });
        return;
      }

      bool isCurrentlyCheckedIn = false;
      String? detectedCheckInId;
      DateTime? detectedCheckInTime;
      Map<String, dynamic>? checkInDataToPersist = todayData;

      if (hasCheckedInToday && !hasCheckedOutToday) {
        isCurrentlyCheckedIn = true;
        detectedCheckInId =
            todayStatus['todayCheckInId']?.toString() ??
            todayData?['today_checkin_id']?.toString() ??
            (todayData != null ? _extractCheckInId(todayData) : null);
        // Use check-in time from state (loaded from history API) or try to parse from data
        detectedCheckInTime =
            _checkInTime ??
            _parseFlexibleDateTime(todayData?['check_in_time']) ??
            _parseFlexibleDateTime(todayData?['in_time']);
      }

      final response = await _apiService.getCheckInStatus(userIdInt);
      print('═══════════════════════════════════════');
      print('📥 CHECK-IN API RESPONSE:');
      print('═══════════════════════════════════════');
      print('Full Response: $response');
      print('');
      print('Status: ${response['status']}');
      print('Is Checked In: ${response['isCheckedIn']}');
      print('');

      final dynamic responseDataRaw = response['data'];
      final Map<String, dynamic>? responseData =
          responseDataRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(responseDataRaw)
          : null;

      final bool apiIsCheckedIn =
          _parseBool(response['isCheckedIn']) ??
          _parseBool(responseData?['is_checked_in']) ??
          false;

      if (apiIsCheckedIn && responseData != null) {
        isCurrentlyCheckedIn = true;
        final Map<String, dynamic> extractedMap = _extractCheckInMap(
          responseData,
        );
        checkInDataToPersist = extractedMap;
        final extractedId = _extractCheckInId(extractedMap);
        if (extractedId != null) {
          detectedCheckInId = extractedId;
        }
        final responseCheckInTime =
            _parseFlexibleDateTime(extractedMap['check_in_time']) ??
            _parseFlexibleDateTime(extractedMap['created_at']) ??
            _parseFlexibleDateTime(extractedMap['in_time']);
        if (responseCheckInTime != null) {
          detectedCheckInTime = responseCheckInTime;
        }

        print('📋 Check-In Data Details:');
        extractedMap.forEach((key, value) {
          print('   $key: $value');
        });
      } else if (apiIsCheckedIn) {
        // Handle non-Map responses where API returns just the ID (e.g., 32 or "32")
        final dynamic checkInIdRaw =
            response['checkInId'] ?? responseDataRaw; // prefer normalized field
        if (checkInIdRaw != null && checkInIdRaw.toString().isNotEmpty) {
          detectedCheckInId = checkInIdRaw.toString();
          isCurrentlyCheckedIn = true;
          // No timestamp available; use now for UI
          detectedCheckInTime = DateTime.now();
          print(
            '🆔 Detected Check-In ID from numeric response: $detectedCheckInId',
          );
        } else if (!isCurrentlyCheckedIn) {
          detectedCheckInId = null;
          detectedCheckInTime = null;
          checkInDataToPersist = null;
          print('❌ No active check-in data returned from API');
        }
      } else if (!isCurrentlyCheckedIn) {
        detectedCheckInId = null;
        detectedCheckInTime = null;
        checkInDataToPersist = null;
        print('❌ No active check-in data returned from API');
      }
      print('═══════════════════════════════════════');

      final bool finalShouldShowCheckOut =
          isCurrentlyCheckedIn && (detectedCheckInId ?? '').isNotEmpty;
      final String? finalActiveCheckInId = finalShouldShowCheckOut
          ? detectedCheckInId
          : null;
      final DateTime? finalCheckInTime = finalShouldShowCheckOut
          ? (detectedCheckInTime ?? DateTime.now())
          : null;

      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _shouldShowCheckOut = finalShouldShowCheckOut;
          _activeCheckInId = finalActiveCheckInId;
          // Preserve times already loaded from API in _loadTimesFromAPI()
          // Only update if we have a new time from this API call and current time is null
          if (finalShouldShowCheckOut &&
              finalCheckInTime != null &&
              _checkInTime == null) {
            _checkInTime = finalCheckInTime;
          }
          // Don't clear check-in time if user has checked out today (we want to show it)
          // Only clear if there's truly no check-in today
          if (!finalShouldShowCheckOut &&
              !_isTodayCompleted &&
              _checkInTime != null) {
            // Check if the time is from today - if not, clear it
            final today = DateTime.now();
            if (_checkInTime!.year != today.year ||
                _checkInTime!.month != today.month ||
                _checkInTime!.day != today.day) {
              _checkInTime = null;
            }
          }
        });
      }

      if (finalShouldShowCheckOut && finalActiveCheckInId != null) {
        final DateTime timeToPersist = finalCheckInTime ?? DateTime.now();
        final Map<String, dynamic> dataToStore = {
          if (checkInDataToPersist != null) ...checkInDataToPersist,
          'id': finalActiveCheckInId,
          'check_in_time': timeToPersist.toIso8601String(),
        };
        await prefs.setString('active_checkin_id', finalActiveCheckInId);
        await prefs.setString('active_checkin_data', json.encode(dataToStore));
        visitProvider.setRemoteActiveVisit(
          visitId: finalActiveCheckInId,
          checkInTime: timeToPersist,
          rawData: checkInDataToPersist,
        );
        print(
          '💾 Check-in state saved from status check: ID = $finalActiveCheckInId, Time = $timeToPersist',
        );
        print('✅ SHOWING CHECK-OUT SLIDER');
      } else {
        await prefs.remove('active_checkin_id');
        await prefs.remove('active_checkin_data');
        visitProvider.clearRemoteActiveVisit();
        print('📍 SHOWING CHECK-IN SLIDER');
      }
      print('');
    } catch (e) {
      print('❌ Error checking check-in status: $e');
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
          _shouldShowCheckOut = false;
          _activeCheckInId = null;
        });
      }
      context.read<VisitProvider>().clearRemoteActiveVisit();
    }
  }

  Future<void> _loadAreaName() async {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.currentPosition != null) {
      try {
        final areaName = await GeocodingService.getAreaName(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        if (mounted) {
          setState(() {
            _areaName = areaName;
            _isLoadingArea = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _areaName = 'Location not available';
            _isLoadingArea = false;
          });
        }
      }
    } else {
      setState(() {
        _areaName = 'Location not available';
        _isLoadingArea = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Check-In & Out',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(
        //     Icons.arrow_back_ios,
        //     color: Colors.white,
        //     size: ResponsiveUtils.getResponsiveIconSize(context, 20),
        //   ),
        //   onPressed: () => context.pop(),
        // ),
        actions: [
          // Attendance drawer button - hide for telecaller users
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final isTelecaller = authProvider.user?.isTelecaller ?? false;
              if (!isTelecaller) {
                return IconButton(
                  icon: Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                  ),
                  onPressed: () => _showAttendanceDrawer(),
                  tooltip: 'View Attendance',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
            onPressed: _initializeData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          final activeVisit = visitProvider.activeVisit;
          final hasLocation =
              context.watch<LocationProvider>().currentPosition != null;

          return RefreshIndicator(
            onRefresh: _initializeData,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.getResponsiveSpacing(context),
                ResponsiveUtils.getResponsiveSpacing(context),
                ResponsiveUtils.getResponsiveSpacing(context),
                ResponsiveUtils.getResponsiveSpacing(context) * 5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Status Section
                  _buildTodaysStatus(activeVisit)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                  ),

                  // Date and Time
                  _buildDateTime()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 2.5,
                  ),

                  // Compact Timer above slider (shows when checked in)
                  if (_checkInTime != null)
                    _buildCompactTimer(activeVisit)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 350.ms)
                        .slideY(begin: 0.2, end: 0),

                  if (_checkInTime != null)
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                    ),

                  // Slide to Check-In/Out Button
                  _buildSlideButton(activeVisit, hasLocation)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                  ),

                  // Conditionally show Notes or Tasks based on user role
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final isFlutterDeveloper =
                          authProvider.user?.isFlutterDeveloper ?? false;
                      final isSalesPerson =
                          authProvider.user?.isSalesPerson ?? false;

                      // For developers: show today's tasks
                      if (isFlutterDeveloper) {
                        return _buildTodayTasksSection()
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideY(begin: 0.2, end: 0);
                      }
                      // For sales people: show notes only during check-out
                      else if (isSalesPerson && activeVisit != null) {
                        return _buildNotesSection()
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideY(begin: 0.2, end: 0);
                      }
                      // For others: show notes always
                      else {
                        return _buildNotesSection()
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideY(begin: 0.2, end: 0);
                      }
                    },
                  ),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                  ),

                  // Current Location
                  _buildCurrentLocation()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                  ),

                  // Attendance Details (if there's an active visit)
                  if (activeVisit != null)
                    _buildAttendanceDetails(activeVisit)
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 800.ms)
                        .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer2<VisitProvider, AuthProvider>(
        builder: (context, visitProvider, authProvider, child) {
          final user = authProvider.user;
          final isTelecaller = user?.isTelecaller ?? false;
          final isFlutterDeveloper =
              authProvider.user?.isFlutterDeveloper ?? false;
          
          // Telecaller users ke liye telecalling bottom navigation
          if (isTelecaller) {
            return BottomNavigationBar(
              currentIndex: 2, // Check-in tab selected
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Dashboard
                    context.go('/telecalling-dashboard');
                    break;
                  case 1:
                    // Reports
                    context.go('/telecalling-reports');
                    break;
                  case 2:
                    // Already on Check-in
                    break;
                  case 3:
                    // Records
                    context.go('/telecalling-records');
                    break;
                  case 4:
                    // Profile
                    context.go('/profile');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.login_outlined),
                  activeIcon: Icon(Icons.login),
                  label: 'Check-in',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_outlined),
                  activeIcon: Icon(Icons.folder),
                  label: 'Records',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          }
          
          // Developer aur Sales users ke liye original bottom navigation
          final checkInIndex = isFlutterDeveloper ? 2 : 3;
          return CustomBottomNavigation(
            currentIndex: checkInIndex,
            isCheckedIn: visitProvider.hasActiveVisit,
          );
        },
      ),
    );
  }

  // Helper method to get check-in time from state or activeVisit
  DateTime? _getCheckInTime(activeVisit) {
    // Priority: State variable > activeVisit > saved check-in time
    if (_checkInTime != null) {
      return _checkInTime;
    }
    if (activeVisit?.checkInTime != null) {
      return activeVisit.checkInTime;
    }
    return null;
  }

  // Helper method to get check-out time from state or activeVisit
  DateTime? _getCheckOutTime(activeVisit) {
    // Priority: State variable > activeVisit
    if (_checkOutTime != null) {
      return _checkOutTime;
    }
    if (activeVisit?.checkOutTime != null) {
      return activeVisit.checkOutTime;
    }
    return null;
  }

  Widget _buildTodaysStatus(activeVisit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Status',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
        Container(
          height: 2,
          width: ResponsiveUtils.getResponsiveIconSize(context, 60),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            ),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Text(
                      _getCheckInTime(activeVisit) != null
                          ? DateFormat(
                              'h:mm a',
                            ).format(_getCheckInTime(activeVisit)!)
                          : '--:--',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check Out',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withOpacity(0.5),
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Text(
                      _getCheckOutTime(activeVisit) != null
                          ? DateFormat(
                              'h:mm a',
                            ).format(_getCheckOutTime(activeVisit)!)
                          : '--:--',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTime() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('d MMMM yyyy').format(now),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 24),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
        StreamBuilder<DateTime>(
          stream: Stream.periodic(
            const Duration(seconds: 1),
            (_) => DateTime.now(),
          ),
          builder: (context, snapshot) {
            final currentTime = snapshot.data ?? now;
            return Text(
              DateFormat('h:mm:ss a').format(currentTime),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSlideButton(activeVisit, hasLocation) {
    // Check if user is Flutter developer or Sales person
    final authProvider = context.read<AuthProvider>();
    final isFlutterDeveloper = authProvider.user?.isFlutterDeveloper ?? false;
    final isSalesPerson = authProvider.user?.isSalesPerson ?? false;

    // Show loading if still checking status
    if (_isCheckingStatus) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Checking status...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // For Flutter developers, show "Today is Done" if completed and hide slider
    // But duration timer will still show the final duration (handled separately)
    if (_isTodayCompleted && isFlutterDeveloper) {
      return _buildTodayDoneAnimation();
    }

    // For non-Flutter developers, if today is completed but they should still see the slider
    // (existing behavior is maintained)
    if (_isTodayCompleted && !isFlutterDeveloper) {
      // You can uncomment this if you want to show "Today is Done" for non-developers too
      // return _buildTodayDoneAnimation();
    }

    // Check if user is in office for check-in (only for developers)
    final locationProvider = context.read<LocationProvider>();
    final hasLocation = locationProvider.currentPosition != null;
    final isInOffice = hasLocation
        ? LocationValidationService.isUserInOffice(
            locationProvider.currentPosition!,
          )
        : false;

    // Use API check-in status instead of just activeVisit
    final isActive = _shouldShowCheckOut || activeVisit != null;

    // For check-in: Developers must be in office, Sales people can check-in from anywhere (just need location)
    // For check-out: location doesn't matter for anyone
    final canPerformAction =
        isActive || (isSalesPerson ? hasLocation : isInOffice);

    String buttonText;
    Color buttonColor;

    if (isActive) {
      buttonText = 'Slide to Check Out';
      buttonColor = AppTheme.errorColor;
    } else if (!hasLocation) {
      buttonText = 'Location Unavailable';
      buttonColor = Colors.grey;
    } else if (!isInOffice) {
      buttonText = 'You are not in office';
      buttonColor = Colors.orange;
    } else {
      buttonText = 'Slide to Check In';
      buttonColor = AppTheme.successColor;
    }

    return GestureDetector(
      onPanUpdate: (details) {
        if (!hasLocation || !canPerformAction) return;

        // Calculate slide progress based on horizontal movement
        final screenWidth = MediaQuery.of(context).size.width;
        final slideWidth = screenWidth - 80; // Account for padding
        final progress = (details.localPosition.dx / slideWidth).clamp(
          0.0,
          1.0,
        );

        _slideController.value = progress;
      },
      onPanEnd: (details) {
        if (!hasLocation || !canPerformAction) return;

        if (_slideAnimation.value > 0.7) {
          // Complete the action
          _handleSlideComplete(isActive, activeVisit);
        } else {
          // Reset the slide
          _slideController.reverse();
        }
      },
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: buttonColor.withOpacity(0.3), width: 2),
        ),
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                color: buttonColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(35),
              ),
            ),

            // Slide indicator
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                final containerWidth =
                    MediaQuery.of(context).size.width -
                    40; // Account for padding
                final maxSlideDistance =
                    containerWidth - 70; // Account for button width

                return Positioned(
                  left: 4 + (_slideAnimation.value * maxSlideDistance),
                  top: 4,
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(31),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isActive ? Icons.logout_rounded : Icons.login_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                );
              },
            ),

            // Text
            Center(
              child: Text(
                buttonText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: buttonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSlideComplete(bool isActive, activeVisit) async {
    if (isActive && (activeVisit != null || _activeCheckInId != null)) {
      // Handle check-out
      await _performCheckOut(activeVisit);
    } else {
      // Handle check-in
      await _performCheckIn();
    }
  }

  Future<void> _performCheckIn() async {
    try {
      // Check if user is Flutter developer and today is already completed
      final authProvider = context.read<AuthProvider>();
      final isFlutterDeveloper = authProvider.user?.isFlutterDeveloper ?? false;
      final isSalesPerson = authProvider.user?.isSalesPerson ?? false;

      if (isFlutterDeveloper) {
        final prefs = await SharedPreferences.getInstance();
        final todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final completedDate = prefs.getString('flutter_dev_completed_date');

        if (completedDate == todayDateKey) {
          _showErrorSnackBar(
            'Today\'s check-in/check-out is already completed. You can check in again tomorrow.',
          );
          // Reset slider to starting position
          _slideController.reset();
          return;
        }
      }

      final visitProvider = context.read<VisitProvider>();
      final locationProvider = context.read<LocationProvider>();

      if (locationProvider.currentPosition == null) {
        _showErrorSnackBar(
          'Location not available. Please enable location services.',
        );
        // Reset slider to starting position
        _slideController.reset();
        return;
      }

      // Office validation only for developers, not for sales people
      // Sales people can check in from anywhere
      if (!isSalesPerson &&
          !LocationValidationService.isUserInOffice(
            locationProvider.currentPosition!,
          )) {
        final distance = LocationValidationService.getDistanceFromOffice(
          locationProvider.currentPosition!,
        );
        final formattedDistance = distance != null
            ? LocationValidationService.formatDistance(distance)
            : 'unknown';

        _showErrorSnackBar(
          'You are not in office. Distance from office: $formattedDistance. Please come within 50 meters of the office to check in.',
        );
        // Reset slider to starting position
        _slideController.reset();
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Load saved visit form data
      final formData = await _loadVisitFormData();

      // Get authenticated user ID
      final userId = await AuthHelper.getAuthenticatedUserId();

      debugPrint('🔑 CheckIn - Authenticated User ID: $userId');

      final success = await visitProvider.checkIn(
        // New API format parameters
        userId: int.tryParse(userId) ?? 1,
        userName: authProvider.user?.name ?? 'User',
        inLatitude: locationProvider.currentPosition!.latitude,
        inLongitude: locationProvider.currentPosition!.longitude,
        checkInTime: DateTime.now().toString().substring(0, 19),
        inAccuracy: 5.0, // Default accuracy
        inBatteryPercent: 85.0, // Default battery percentage
        inNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : '${formData['visitingPerson']} - ${formData['visitingReason']}',
      );

      if (!success) {
        throw Exception(visitProvider.error ?? 'Check-in failed');
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Save check-in state to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final checkInId =
          visitProvider.currentVisit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final checkInData = {
        'id': checkInId,
        'user_id': userId,
        'check_in_time': DateTime.now().toIso8601String(),
        'notes': _notesController.text.trim(),
      };

      // Save check-in ID for session persistence (not the time - that comes from API)
      await prefs.setString('active_checkin_id', checkInId);
      await prefs.setString('active_checkin_data', json.encode(checkInData));

      // Refresh times from history API after check-in (same source as attendance screen)
      await _loadTimesFromAPI();

      print('💾 Check-in ID saved: $checkInId (times loaded from API)');

      // Update UI state - times are loaded from API above
      setState(() {
        _shouldShowCheckOut = true;
        _activeCheckInId = checkInId;
        // _checkInTime and _checkOutTime are set by _loadTimesFromAPI() above
        _isTodayCompleted = false; // Reset completion status for new check-in
      });

      // Show success message
      _showSuccessSnackBar('Check-in successful!');

      // Add notification for check-in
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Check-in Successful',
          message: 'You have successfully checked in',
          type: NotificationType.checkin,
        );
      }

      // Cancel check-in reminder since user has checked in
      await CheckInReminderService().onCheckInCompleted();

      // Reset slider
      _slideController.reset();

      // Clear notes and tasks fields
      _notesController.clear();
      _tasksController.clear();

      // No need to refresh - the state is already updated by check-in
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      final errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('already checked in')) {
        await _checkUserCheckInStatus();
      } else {
        _showErrorSnackBar('Check-in failed: $errorMessage');
      }
      // Reset slider to starting position on error
      _slideController.reset();
    }
  }

  Future<void> _performCheckOut(activeVisit) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final isFlutterDeveloper = authProvider.user?.isFlutterDeveloper ?? false;
      final visitProvider = context.read<VisitProvider>();
      final String? visitId = activeVisit?.id ?? _activeCheckInId;
      if (visitId == null) {
        _showErrorSnackBar(
          'Unable to determine active check-in. Please refresh and try again.',
        );
        _slideController.reset();
        return;
      }

      // Show loading with visit details saving message
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildVisitDetailsSavingDialog(),
      );

      // Simulate 2-second loading process for visit details saving
      await Future.delayed(const Duration(seconds: 2));

      // Complete the visit with new API format
      final locationProvider = context.read<LocationProvider>();

      // Get authenticated user ID
      final userId = await AuthHelper.getAuthenticatedUserId();
      debugPrint('🔑 CheckOut - Authenticated User ID: $userId');

      final success = await visitProvider.checkOut(
        visitId: visitId,
        userId: int.tryParse(userId) ?? 1,
        outLatitude: locationProvider.currentPosition?.latitude ?? 0.0,
        outLongitude: locationProvider.currentPosition?.longitude ?? 0.0,
        checkOutTime: DateTime.now().toString().substring(0, 19),
        outAccuracy: 5.0, // Default accuracy
        outBatteryPercent: 85.0, // Default battery percentage
        outNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : 'Check-out from mobile app',
      );

      if (!success) {
        throw Exception(visitProvider.error ?? 'Check-out failed');
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Clear check-in state from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_checkin_id');
      await prefs.remove('active_checkin_data');
      visitProvider.clearRemoteActiveVisit(visitId: visitId);

      print('🧹 Check-in state cleared');

      // Get attendance status from the response
      String attendanceStatus = 'completed';

      // Try to get working hours data from SharedPreferences or API response
      final workingHoursDataStr = prefs.getString('working_hours_data');
      if (workingHoursDataStr != null) {
        try {
          final workingHoursData = json.decode(workingHoursDataStr);
          attendanceStatus =
              workingHoursData['attendance_status'] ?? 'completed';
          print('📊 Retrieved attendance status: $attendanceStatus');
        } catch (e) {
          print('⚠️ Error parsing working hours data: $e');
        }
      }

      // Save check-out time and calculate final duration
      // Times will be fetched from history API on next load, not saved to local storage
      final checkOutTime = DateTime.now();
      _checkOutTime = checkOutTime;

      // Don't save to local storage - history API is the source of truth (same as attendance screen)
      // Refresh times from history API after check-out
      await _loadTimesFromAPI();

      // For Flutter developers, save completion status to local storage with today's date
      if (isFlutterDeveloper) {
        final todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await prefs.setString('flutter_dev_completed_date', todayDateKey);
        await prefs.setString(
          'flutter_dev_attendance_status',
          attendanceStatus,
        );
        print(
          '💾 Flutter Developer: Saved completion status for today ($todayDateKey)',
        );
      }

      // Update UI state - Keep check-in time for final duration display
      setState(() {
        _shouldShowCheckOut = false;
        _activeCheckInId = null;
        _isTodayCompleted = true;
        _todayAttendanceStatus = attendanceStatus;
        _checkOutTime = checkOutTime;
        // Keep _checkInTime so final duration can be displayed
      });

      // Show success message with attendance status
      String statusMessage = 'Attendance Done! Check-out successful.';
      if (attendanceStatus == 'half_day') {
        statusMessage = 'Half Day Completed! Check-out successful.';
      } else if (attendanceStatus == 'full_day') {
        statusMessage = 'Full Day Completed! Check-out successful.';
      }
      _showSuccessSnackBar(statusMessage);

      // Add notification for check-out
      if (mounted) {
        context.read<NotificationProvider>().addNotification(
          title: 'Check-out Successful',
          message: 'You have successfully checked out',
          type: NotificationType.checkout,
        );
      }

      // Reset slider
      _slideController.reset();

      // Clear notes field
      _notesController.clear();

      // No need to refresh - the state is already updated by check-out
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Check-out failed: ${e.toString()}');
      // Reset slider to starting position on error
      _slideController.reset();
    }
  }

  String? _extractCheckInId(Map<String, dynamic> data) {
    final candidates = [
      data['id'],
      data['visit_id'],
      data['checkin_id'],
      data['check_in_id'],
      data['today_checkin_id'],
      data['todayCheckinId'],
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.toString();
      if (value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  Map<String, dynamic> _extractCheckInMap(Map<String, dynamic> data) {
    final List<String> candidateKeys = [
      'data',
      'visit',
      'checkin',
      'check_in',
      'active_visit',
      'active_checkin',
    ];

    for (final key in candidateKeys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return data;
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is double) return value != 0.0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower.isEmpty) return null;
      if (lower == 'true' || lower == 'yes' || lower == '1' || lower == 'y') {
        return true;
      }
      if (lower == 'false' || lower == 'no' || lower == '0' || lower == 'n') {
        return false;
      }
    }
    return null;
  }

  DateTime? _parseFlexibleDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is int) {
      try {
        return value > 100000000000
            ? DateTime.fromMillisecondsSinceEpoch(value)
            : DateTime.fromMillisecondsSinceEpoch(value * 1000);
      } catch (_) {
        return null;
      }
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      final int? numeric = int.tryParse(trimmed);
      if (numeric != null) {
        return _parseFlexibleDateTime(numeric);
      }

      try {
        return DateTime.parse(trimmed);
      } catch (_) {
        try {
          return DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).parse(trimmed, true).toLocal();
        } catch (_) {
          try {
            return DateFormat(
              'yyyy/MM/dd HH:mm:ss',
            ).parse(trimmed, true).toLocal();
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }

  Widget _buildVisitDetailsSavingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.save_rounded,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Saving Visit Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              'Please wait while we save your visit information...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),

            // Progress Text
            Text(
              'Processing visit data...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAttendanceDrawer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AttendanceScreen()),
    );
  }

  Widget _buildCurrentLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Location:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isLoadingArea
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Loading location...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      )
                    : Text(
                        _areaName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceDetails(activeVisit) {
    return FutureBuilder<String>(
      future: _getAreaNameForVisit(activeVisit),
      builder: (context, snapshot) {
        final areaName = snapshot.data ?? 'Loading location...';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Check-in Details
                  _buildAttendanceRow(
                    icon: Icons.login_rounded,
                    title: 'Check-in Time',
                    value: DateFormat(
                      'dd MMM yyyy, h:mm a',
                    ).format(activeVisit.checkInTime),
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(height: 16),
                  _buildAttendanceRow(
                    icon: Icons.location_on_rounded,
                    title: 'Check-in Location',
                    value: areaName,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildAttendanceRow(
                    icon: Icons.person_rounded,
                    title: 'User',
                    value: context.read<AuthProvider>().user?.name ?? 'User',
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  // Working Duration
                  _buildWorkingDuration(activeVisit),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, String?>> _loadVisitFormData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final formDataJson = prefs.getString('visit_form_data');

      if (formDataJson != null) {
        final formData = json.decode(formDataJson);
        return {
          'visitingPlace': formData['visitingPlace'] ?? '',
          'visitingPerson': formData['visitingPerson'] ?? '',
          'visitingReason': formData['visitingReason'] ?? '',
          'visitingArea': formData['visitingArea'] ?? '',
          'photoPath': formData['photoPath'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error loading visit form data: $e');
    }

    // Return empty data if no form data found
    return {
      'visitingPlace': '',
      'visitingPerson': '',
      'visitingReason': '',
      'visitingArea': '',
      'photoPath': '',
    };
  }

  Future<String> _getAreaNameForVisit(activeVisit) async {
    try {
      final areaName = await GeocodingService.getAreaName(
        activeVisit.latitude,
        activeVisit.longitude,
      );
      return areaName;
    } catch (e) {
      return 'Location not available';
    }
  }

  Widget _buildAttendanceRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Compact timer widget to show above slider
  Widget _buildCompactTimer(activeVisit) {
    final checkInTime = _checkInTime ?? activeVisit?.checkInTime;

    if (checkInTime == null) {
      return const SizedBox.shrink();
    }

    // If check-out is completed, show final duration
    if (_checkOutTime != null && _isTodayCompleted) {
      final finalDuration = _checkOutTime!.difference(checkInTime);
      final hours = finalDuration.inHours;
      final minutes = finalDuration.inMinutes.remainder(60);
      final seconds = finalDuration.inSeconds.remainder(60);

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
          vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
        ),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 12),
          ),
          border: Border.all(
            color: AppTheme.successColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off_rounded,
              color: AppTheme.successColor,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Duration: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              ),
            ),
          ],
        ),
      );
    }

    // If checked in, show running timer
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return DateTime.now().difference(checkInTime);
      }),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
            vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 12),
            ),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_rounded,
                color: AppTheme.primaryColor,
                size: ResponsiveUtils.getResponsiveIconSize(context, 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Duration: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkingDuration(activeVisit) {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) {
        return DateTime.now().difference(activeVisit.checkInTime);
      }),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_rounded, color: AppTheme.successColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Working Duration',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayDoneAnimation() {
    return Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.successColor,
                AppTheme.successColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: AppTheme.successColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(5, (index) {
                return Positioned(
                  left: (index * 20.0) % MediaQuery.of(context).size.width,
                  top: 10 + (index * 5.0),
                  child:
                      Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 1000.ms, delay: (index * 200).ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                );
              }),

              // Main content
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success icon with animation
                    Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: AppTheme.successColor,
                            size: 24,
                          ),
                        )
                        .animate()
                        .scale(duration: 500.ms)
                        .then()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),

                    const SizedBox(width: 16),

                    // Text with animation
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                              'Today is Done!',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 300.ms)
                            .slideX(begin: 0.3, end: 0),

                        const SizedBox(height: 2),

                        Text(
                              _getAttendanceStatusText(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 500.ms)
                            .slideX(begin: 0.2, end: 0),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 1000.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
  }

  String _getAttendanceStatusText() {
    switch (_todayAttendanceStatus) {
      case 'half_day':
        return 'Half Day Completed';
      case 'full_day':
        return 'Full Day Completed';
      case 'partial':
        return 'Partial Day Completed';
      default:
        return 'Attendance Completed';
    }
  }

  Widget _buildNotesSection() {
    final authProvider = context.read<AuthProvider>();
    final isFlutterDeveloper = authProvider.user?.isFlutterDeveloper ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              ),
            ),
            if (isFlutterDeveloper) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 12),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add notes for this check-in/check-out...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
            validator: ValidationUtils.validateNotes,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row(
        //   children: [
        //     Text(
        //       'Today\'s Tasks',
        //       style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //         fontWeight: FontWeight.bold,
        //         color: AppTheme.textPrimaryColor,
        //         fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
        //       ),
        //     ),
        //     const SizedBox(width: 4),
        //     Text(
        //       '*',
        //       style: Theme.of(context).textTheme.titleMedium?.copyWith(
        //         fontWeight: FontWeight.bold,
        //         color: Colors.red,
        //         fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
        // Container(
        //   padding: ResponsiveUtils.getResponsivePadding(context),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     borderRadius: BorderRadius.circular(
        //       ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        //     ),
        //     border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.black.withOpacity(0.05),
        //         blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
        //         offset: const Offset(0, 4),
        //       ),
        //     ],
        //   ),
        //   // child: TextFormField(
        //   //   controller: _tasksController,
        //   //   maxLines: 4,
        //   //   maxLength: 500,
        //   //   decoration: InputDecoration(
        //   //     hintText: 'Enter today\'s tasks...',
        //   //     hintStyle: TextStyle(
        //   //       color: Colors.grey[500],
        //   //       fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        //   //     ),
        //   //     border: InputBorder.none,
        //   //     counterText: '',
        //   //   ),
        //   //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        //   //     color: AppTheme.textPrimaryColor,
        //   //     fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
        //   //   ),
        //   // ),
        // ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
        // Notes field (optional)
        Row(
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 12),
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: ResponsiveUtils.getResponsiveElevation(context, 10),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Add notes for this check-in/check-out...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              ),
              border: InputBorder.none,
              counterText: '',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
            validator: ValidationUtils.validateNotes,
          ),
        ),
      ],
    );
  }
}
