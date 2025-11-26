import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/visit_model.dart';
import '../../services/api_service.dart';
import '../../utils/auth_helper.dart';

class VisitProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Visit> _visits = [];
  Visit? _currentVisit;
  Visit? _remoteActiveVisit;
  bool _isLoading = false;
  String? _error;
  String? _activeCheckInId; // Store check-in ID from API
  
  // Callback for when visits are completed
  Function(int)? onVisitCompleted;

  // Getters
  List<Visit> get visits => _visits;
  Visit? get currentVisit => _currentVisit;
  Visit? get activeVisit {
    if (_currentVisit != null && _currentVisit!.checkOutTime == null) {
      return _currentVisit;
    }
    return _remoteActiveVisit;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveVisit =>
      (_currentVisit != null && _currentVisit!.checkOutTime == null) ||
      _remoteActiveVisit != null ||
      (_activeCheckInId != null && _activeCheckInId!.isNotEmpty);
  
  String? get activeCheckInId => _activeCheckInId;

  // Initialize visits
  Future<void> initializeVisits() async {
    await Future.wait([loadVisits(), loadCurrentActiveVisit(), checkCheckInStatus()]);
  }
  
  // Check check-in status from API
  Future<void> checkCheckInStatus() async {
    try {
      // Get authenticated user ID
      final userId = await AuthHelper.getAuthenticatedUserId();
      final userIdInt = int.tryParse(userId) ?? 0;
      
      if (userIdInt == 0) {
        if (kDebugMode) {
          print('⚠️ No user ID available for check-in status check');
        }
        return;
      }
      
      if (kDebugMode) {
        print('🔍 Checking check-in status for user ID: $userIdInt');
      }
      
      final response = await _apiService.getCheckInStatus(userIdInt);
      
      if (response['status'] == 'success') {
        final checkInId = response['checkInId']?.toString();
        final isCheckedIn = response['isCheckedIn'] == true;
        
        if (kDebugMode) {
          print('📥 Check-in Status API Response:');
          print('  - Check-In ID: $checkInId');
          print('  - Is Checked In: $isCheckedIn');
        }
        
        if (isCheckedIn && checkInId != null && checkInId.isNotEmpty) {
          // User is checked in, store the ID
          _activeCheckInId = checkInId;
          
          // Create a remote active visit if we don't have one
          if (_remoteActiveVisit == null && _currentVisit == null) {
            setRemoteActiveVisit(
              visitId: checkInId,
              checkInTime: DateTime.now(),
              rawData: {'id': checkInId},
            );
          }
          
          if (kDebugMode) {
            print('✅ User is checked in with ID: $checkInId');
          }
        } else {
          // User is not checked in
          _activeCheckInId = null;
          if (kDebugMode) {
            print('📍 User is not checked in');
          }
        }
        
        notifyListeners();
      } else {
        if (kDebugMode) {
          print('⚠️ Check-in status check failed: ${response['error'] ?? 'Unknown error'}');
        }
        _activeCheckInId = null;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking check-in status: $e');
      }
      _activeCheckInId = null;
      notifyListeners();
    }
  }
  
  // Clear active check-in ID (called after checkout)
  void clearActiveCheckInId() {
    _activeCheckInId = null;
    notifyListeners();
  }
  
  // Set active check-in ID (called after check-in)
  void setActiveCheckInId(String checkInId) {
    _activeCheckInId = checkInId;
    notifyListeners();
  }

  void setRemoteActiveVisit({
    required String visitId,
    required DateTime checkInTime,
    Map<String, dynamic>? rawData,
  }) {
    final Visit visit = _buildVisitFromRawData(
      visitId: visitId,
      checkInTime: checkInTime,
      rawData: rawData,
    );

    if (_remoteActiveVisit == null ||
        _remoteActiveVisit!.id != visit.id ||
        _remoteActiveVisit!.checkInTime != visit.checkInTime) {
      _remoteActiveVisit = visit;
      notifyListeners();
    }
  }

  void clearRemoteActiveVisit({String? visitId}) {
    if (_remoteActiveVisit == null) return;
    if (visitId == null || _remoteActiveVisit!.id == visitId) {
      _remoteActiveVisit = null;
      notifyListeners();
    }
  }

  Visit _buildVisitFromRawData({
    required String visitId,
    required DateTime checkInTime,
    Map<String, dynamic>? rawData,
  }) {
    final data = rawData ?? <String, dynamic>{};
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          try {
            return DateFormat('yyyy-MM-dd HH:mm:ss').parse(value, true).toLocal();
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }

    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String && value.isNotEmpty) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    final DateTime createdAt =
        _parseDate(data['created_at']) ?? checkInTime;
    final DateTime updatedAt =
        _parseDate(data['updated_at']) ?? DateTime.now();

    return Visit(
      id: visitId,
      clientName: data['client_name'] ??
          data['user_name'] ??
          data['person_name'] ??
          data['visiting_person'] ??
          'Active Visit',
      checkInTime: checkInTime,
      checkOutTime: null,
      latitude: _parseDouble(
        data['latitude'] ?? data['in_latitude'],
      ),
      longitude: _parseDouble(
        data['longitude'] ?? data['in_longitude'],
      ),
      notes: data['in_notes'] ?? data['notes'],
      checkOutNotes: null,
      visitingReason: data['visiting_reason'] ?? data['reason'],
      visitingArea: data['visiting_area'] ?? data['area_name'],
      photoPath: data['photo_path'] ?? data['photo'],
      userId: (data['user_id'] ?? data['user']?['id'] ?? '').toString(),
      status: 'active',
      createdAt: createdAt,
      updatedAt: updatedAt,
      visitingPlace: data['visiting_place'],
      visitingPerson: data['visiting_person'] ?? data['user_name'],
      leadId: data['lead_id']?.toString(),
      leadName: data['lead_name'] ?? data['get_lead']?['name'],
      leadEmail: data['lead_email'] ?? data['get_lead']?['email'],
      leadPhone: data['lead_phone'] ?? data['get_lead']?['phone'],
    );
  }

  // Load current active visit
  Future<void> loadCurrentActiveVisit() async {
    try {
      final activeVisit = await _apiService.getCurrentActiveVisit();
      _currentVisit = activeVisit;
      if (activeVisit != null) {
        _remoteActiveVisit = null;
      }
      notifyListeners();
    } catch (e) {
      // No active visit found, which is normal
      _currentVisit = null;
    }
  }

  // Load visits history from API
  Future<void> loadVisits() async {
    _setLoading(true);
    _clearError();

    try {
      // Get authenticated user ID
      final userId = await AuthHelper.getAuthenticatedUserId();
      final userIdInt = int.tryParse(userId) ?? 3;

      if (kDebugMode) {
        print('📋 Loading visit history for user ID: $userIdInt');
      }

      // Fetch visit details history from API
      final response = await _apiService.getVisitDetailsHistory(userIdInt);
      _visits = response;

      if (kDebugMode) {
        print('✅ Loaded ${_visits.length} visits from history');
        print('═══════════════════════════════════════');
        print('VISIT HISTORY DATA:');
        for (var i = 0; i < _visits.length; i++) {
          final visit = _visits[i];
          print('Visit ${i + 1}:');
          print('  - ID: ${visit.id}');
          print('  - Client: ${visit.clientName}');
          print('  - Date: ${visit.checkInTime}');
          print('  - Status: ${visit.isActive ? 'Active' : 'Completed'}');
          print('  - Location: ${visit.latitude}, ${visit.longitude}');
          if (visit.visitingPlace != null) {
            print('  - Visiting Place: ${visit.visitingPlace}');
          }
          if (visit.visitingPerson != null) {
            print('  - Visiting Person: ${visit.visitingPerson}');
          }
          if (visit.visitingArea != null) {
            print('  - Visiting Area: ${visit.visitingArea}');
          }
          print('---');
        }
        print('═══════════════════════════════════════');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load visits: $e');
      }
      _setError('Failed to load visits: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Create a visit directly (without check-in/check-out)
  Future<bool> createVisit({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createVisit(
        latitude: latitude,
        longitude: longitude,
        clientName: clientName,
        notes: notes,
        visitingReason: visitingReason,
        visitingArea: visitingArea,
        photoPath: photoPath,
      );

      if (response['success'] == true) {
        final newVisit = Visit.fromJson(response['visit']);
        // Add directly to visits list
        _visits.insert(0, newVisit);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Visit creation failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check-in to a visit (supports both old and new API format)
  Future<bool> checkIn({
    // New API format parameters
    int? userId,
    String? userName,
    double? inLatitude,
    double? inLongitude,
    String? checkInTime,
    double? inAccuracy,
    double? inBatteryPercent,
    String? inNotes,

    // Old API format parameters (for backward compatibility)
    double? latitude,
    double? longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    // Check if user has already checked in today (only one checkin per day)
    if (userId != null) {
      try {
        final todayStatus = await _apiService.getTodayCheckInStatus(userId);
        if (todayStatus['hasCheckedInToday'] == true) {
          _setError('You have already checked in today. Only one check-in per day is allowed.');
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not verify today\'s check-in status: $e');
        }
        // Continue with check-in if verification fails
      }
    }

    if (hasActiveVisit) {
      _setError('You already have an active visit. Please check out first.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      Map<String, dynamic> response;

      // Check if new API format is being used
      if (userId != null &&
          userName != null &&
          inLatitude != null &&
          inLongitude != null) {
        // Use new API format
        response = await _apiService.checkIn(
          userId: userId,
          userName: userName,
          inLatitude: inLatitude,
          inLongitude: inLongitude,
          checkInTime:
              checkInTime ?? DateTime.now().toString().substring(0, 19),
          inAccuracy: inAccuracy ?? 0,
          inBatteryPercent: inBatteryPercent ?? 85,
          inNotes: inNotes,
        );
      } else {
        // Use old API format (mock data)
        response = await _apiService.createVisit(
          latitude: latitude ?? 0,
          longitude: longitude ?? 0,
          clientName: clientName,
          notes: notes,
          visitingReason: visitingReason,
          visitingArea: visitingArea,
          photoPath: photoPath,
        );
      }

      // Handle response based on format
      bool isSuccess;
      String? checkInIdFromResponse;
      
      if (response['status'] == 'success') {
        // New API format
        final visitData = response['visit'];
        if (visitData != null) {
          _currentVisit = Visit.fromJson(visitData);
          checkInIdFromResponse = _currentVisit!.id;
          _remoteActiveVisit = null;
        }
        isSuccess = true;
      } else if (response['success'] == true) {
        // Old API format
        final visitData = response['visit'];
        if (visitData != null) {
          _currentVisit = Visit.fromJson(visitData);
          checkInIdFromResponse = _currentVisit!.id;
          _remoteActiveVisit = null;
        }
        isSuccess = true;
      } else {
        _setError(response['message'] ?? 'Check-in failed');
        isSuccess = false;
      }

      if (isSuccess) {
        // Store check-in ID from response
        if (checkInIdFromResponse != null && checkInIdFromResponse.isNotEmpty) {
          _activeCheckInId = checkInIdFromResponse;
          if (kDebugMode) {
            print('✅ Check-in successful, stored ID: $_activeCheckInId');
          }
        } else if (_currentVisit != null) {
          _activeCheckInId = _currentVisit!.id;
          if (kDebugMode) {
            print('✅ Check-in successful, using visit ID: $_activeCheckInId');
          }
        }
        
        // Don't add to visits list yet - only add when checked out
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check-out from current visit (supports both old and new API format)
  Future<bool> checkOut({
    required String visitId,
    String? notes,

    // New API format parameters (optional)
    int? userId,
    double? outLatitude,
    double? outLongitude,
    String? checkOutTime,
    double? outAccuracy,
    double? outBatteryPercent,
    String? outNotes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      Map<String, dynamic> response;

      // Check if new API format is being used
      if (userId != null && outLatitude != null && outLongitude != null) {
        // Get check-in time from current visit for working hours calculation
        DateTime? checkInTime;
        if (_currentVisit != null) {
          checkInTime = _currentVisit!.checkInTime;
          if (kDebugMode) {
            print('📅 Using check-in time for working hours calculation: $checkInTime');
          }
        }

        // Use new API format with working hours validation
        response = await _apiService.checkOut(
          visitId: visitId,
          userId: userId,
          outLatitude: outLatitude,
          outLongitude: outLongitude,
          checkOutTime:
              checkOutTime ?? DateTime.now().toString().substring(0, 19),
          outAccuracy: outAccuracy ?? 0,
          outBatteryPercent: outBatteryPercent ?? 85,
          outNotes: outNotes,
          checkInTime: checkInTime, // Pass check-in time for working hours calculation
        );
      } else {
        // Use old API format (mock data)
        response = await _apiService.checkOutOld(
          visitId: visitId,
          notes: notes,
        );
      }

      // Handle response based on format
      bool isSuccess;
      Map<String, dynamic>? visitData;

      if (response['status'] == 'success') {
        // New API format
        visitData = response['visit'];
        isSuccess = true;
      } else if (response['success'] == true) {
        // Old API format
        visitData = response['visit'];
        isSuccess = true;
      } else {
        _setError(response['message'] ?? 'Check-out failed');
        isSuccess = false;
      }

      if (isSuccess && visitData != null) {
        final updatedVisit = Visit.fromJson(visitData);

        // Clear current visit
        if (_currentVisit?.id == visitId) {
          _currentVisit = null;
        }
        clearRemoteActiveVisit(visitId: visitId);
        
        // Clear active check-in ID after successful checkout
        if (_activeCheckInId == visitId || _activeCheckInId != null) {
          _activeCheckInId = null;
          if (kDebugMode) {
            print('🧹 Cleared active check-in ID after checkout');
          }
        }

        // Add completed visit to history (since it wasn't added during check-in)
        _visits.insert(0, updatedVisit);
        
        // Recheck check-in status to sync with server
        // This ensures the UI reflects the latest server state
        checkCheckInStatus();

        // Notify target provider about visit completion
        if (onVisitCompleted != null) {
          final todayVisitsCount = _getTodayVisitsCount();
          onVisitCompleted!(todayVisitsCount);
          
          if (kDebugMode) {
            print('🎯 VISIT COMPLETED - Target Update Triggered:');
            print('  - Today Visits Count: $todayVisitsCount');
            print('  - Target Provider will be updated');
          }
        }

        // Store working hours information if available
        Map<String, dynamic>? workingHoursData;
        if (response['working_hours_data'] != null) {
          workingHoursData = response['working_hours_data'];
          if (kDebugMode) {
            print('⏰ WORKING HOURS SUMMARY:');
            print('  - Total Hours: ${workingHoursData?['working_hours']?.toStringAsFixed(2) ?? 'N/A'}');
            print('  - Attendance Status: ${workingHoursData?['attendance_status'] ?? 'N/A'}');
            print('  - Is Full Day: ${workingHoursData?['is_full_day'] ?? false}');
            print('  - Is Half Day: ${workingHoursData?['is_half_day'] ?? false}');
          }
          
          // Store working hours data in SharedPreferences for UI access
          if (workingHoursData?['attendance_status'] != null) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('working_hours_data', json.encode(workingHoursData));
              if (kDebugMode) {
                print('💾 Stored working hours data in SharedPreferences');
                print('📊 ATTENDANCE STATUS: ${workingHoursData?['attendance_status']}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error storing working hours data: $e');
              }
            }
          }
        }

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update visit notes
  Future<bool> updateVisitNotes(String visitId, String notes) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateVisitNotes(visitId, notes);

      if (response['success'] == true) {
        final updatedVisit = Visit.fromJson(response['visit']);

        // Update in visits list
        final index = _visits.indexWhere((v) => v.id == updatedVisit.id);
        if (index != -1) {
          _visits[index] = updatedVisit;
        }

        // Update current visit if it's the same
        if (_currentVisit?.id == updatedVisit.id) {
          _currentVisit = updatedVisit;
        }

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Update failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get visits by date range
  Future<List<Visit>> getVisitsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _apiService.getVisitsByDateRange(startDate, endDate);
    } catch (e) {
      _setError('Failed to fetch visits: ${e.toString()}');
      return [];
    }
  }

  // Get visit statistics
  Future<Map<String, dynamic>> getVisitStatistics() async {
    try {
      return await _apiService.getVisitStatistics();
    } catch (e) {
      _setError('Failed to fetch statistics: ${e.toString()}');
      return {};
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

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
  
  // Helper method to count today's visits
  int _getTodayVisitsCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _visits.where((visit) {
      final visitDate = DateTime(
        visit.visitTime.year,
        visit.visitTime.month,
        visit.visitTime.day,
      );
      return visitDate.isAtSameMomentAs(today);
    }).length;
  }
}
