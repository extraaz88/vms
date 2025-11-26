import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../models/location_model.dart';

class MockDataService {
  static const String _usersKey = 'mock_users';
  static const String _visitsKey = 'mock_visits';
  static const String _activeVisitsKey = 'mock_active_visits';
  static const String _locationsKey = 'mock_locations';
  static const String _currentUserKey = 'current_user';

  // Initialize mock data
  static Future<void> initializeMockData() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if mock data already exists
    if (prefs.getString(_usersKey) == null) {
      await _createMockUsers();
    }
  }

  // Create mock users
  static Future<void> _createMockUsers() async {
    final prefs = await SharedPreferences.getInstance();

    final mockUsers = [
      {
        'id': '1',
        'name': 'Saurabh Vishwakarma',
        'email': 'saurabhvish@gmail.com',
        'password': '123456',
        'role': 'field_executive',
        'phone': '+91 98765 43210',
        'avatar': null,
        'is_active': true,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Priya Patel',
        'email': 'priya@example.com',
        'password': '123456',
        'role': 'manager',
        'phone': '+91 98765 43211',
        'avatar': null,
        'is_active': true,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 25))
            .toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Rahul Singh',
        'email': 'rahul@example.com',
        'password': '123456',
        'role': 'field_executive',
        'phone': '+91 98765 43212',
        'avatar': null,
        'is_active': true,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 20))
            .toIso8601String(),
      },
    ];

    await prefs.setString(_usersKey, json.encode(mockUsers));
  }

  // Simple Mock Login - Any email and password works
  static Future<Map<String, dynamic>> mockLogin(
    String email,
    String password,
  ) async {
    // Accept any email and password - no validation
    if (email.isNotEmpty) {
      // Generate simple token
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      // Create user data with provided email
      final user = {
        'id': '1',
        'name': 'Saurabh Vishwakarma',
        'email': email,
        'role': 'field_executive',
        'phone': '+91 98765 43210',
        'avatar': null,
        'is_active': true,
        'created_at': DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      };

      // Store current user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user));

      return {
        'success': true,
        'token': token,
        'user': {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
          'phone': user['phone'],
          'avatar': user['avatar'],
          'is_active': user['is_active'],
        },
      };
    }

    return {'success': false, 'message': 'Email cannot be empty'};
  }

  // Mock Create Visit (direct creation without check-in/check-out)
  static Future<Map<String, dynamic>> mockCreateVisit({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);

      // Use provided clientName or default
      String visitClientName = clientName ?? 'Field Visit';

      final visit = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'client_name': visitClientName,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_out_time': DateTime.now()
            .toIso8601String(), // Set same time for direct creation
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'check_out_notes': null,
        'visiting_reason': visitingReason,
        'visiting_area': visitingArea,
        'photo_path': photoPath,
        'user_id': currentUser['id'],
        'status': 'completed', // Direct creation is always completed
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add directly to visits history
      final visitsJson = prefs.getString(_visitsKey);
      List<dynamic> visits = visitsJson != null ? json.decode(visitsJson) : [];
      visits.insert(0, visit);
      await prefs.setString(_visitsKey, json.encode(visits));

      return {'success': true, 'visit': visit};
    }

    return {'success': false, 'message': 'User not found'};
  }

  // Mock Create Visit Details with Lead Information
  static Future<Map<String, dynamic>> mockCreateVisitDetails({
    required String visitingPlace,
    required String visitingPerson,
    required String visitingReason,
    String? visitingArea,
    String? photoPath,
    String? leadId,
    String? leadName,
    String? leadEmail,
    String? leadPhone,
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);

      final visit = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'client_name': visitingPerson,
        'visiting_place': visitingPlace,
        'visiting_person': visitingPerson,
        'visiting_reason': visitingReason,
        'visiting_area': visitingArea,
        'photo_path': photoPath,
        'lead_id': leadId,
        'lead_name': leadName,
        'lead_email': leadEmail,
        'lead_phone': leadPhone,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_out_time': DateTime.now().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'notes': visitingReason,
        'check_out_notes': null,
        'user_id': currentUser['id'],
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add to visits history
      final visitsJson = prefs.getString(_visitsKey);
      List<dynamic> visits = visitsJson != null ? json.decode(visitsJson) : [];
      visits.insert(0, visit);
      await prefs.setString(_visitsKey, json.encode(visits));

      return {
        'success': true,
        'message': 'Visit details created successfully',
        'visit': visit,
      };
    }

    return {'success': false, 'message': 'User not found'};
  }

  // Mock Check-in
  static Future<Map<String, dynamic>> mockCheckIn({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);

      // Use provided clientName or default
      String visitClientName = clientName ?? 'Field Visit';

      final visit = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'client_name': visitClientName,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_out_time': null,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'check_out_notes': null,
        'visiting_reason': visitingReason,
        'visiting_area': visitingArea,
        'photo_path': photoPath,
        'user_id': currentUser['id'],
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Store active visit separately (not in history yet)
      await prefs.setString(_activeVisitsKey, json.encode(visit));

      return {'success': true, 'visit': visit};
    }

    return {'success': false, 'message': 'User not found'};
  }

  // Mock Check-out
  static Future<Map<String, dynamic>> mockCheckOut({
    required String visitId,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();

    // Get active visit
    final activeVisitJson = prefs.getString(_activeVisitsKey);
    if (activeVisitJson != null) {
      final activeVisit = json.decode(activeVisitJson);

      if (activeVisit['id'] == visitId) {
        // Update visit with check-out details
        activeVisit['check_out_time'] = DateTime.now().toIso8601String();
        activeVisit['check_out_notes'] = notes;
        activeVisit['status'] = 'completed';
        activeVisit['updated_at'] = DateTime.now().toIso8601String();

        // Remove from active visits
        await prefs.remove(_activeVisitsKey);

        // Add to completed visits history
        final visitsJson = prefs.getString(_visitsKey);
        List<dynamic> visits = visitsJson != null
            ? json.decode(visitsJson)
            : [];
        visits.insert(0, activeVisit);
        await prefs.setString(_visitsKey, json.encode(visits));

        return {'success': true, 'visit': activeVisit};
      }
    }

    return {'success': false, 'message': 'Active visit not found'};
  }

  // Mock Get Visits
  static Future<List<Visit>> mockGetVisits() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final visitsJson = prefs.getString(_visitsKey);

    if (visitsJson != null) {
      List<dynamic> visits = json.decode(visitsJson);
      return visits.map((visit) => Visit.fromJson(visit)).toList();
    }

    return [];
  }

  // Mock Get Current Active Visit
  static Future<Visit?> mockGetCurrentActiveVisit() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    final activeVisitJson = prefs.getString(_activeVisitsKey);

    if (activeVisitJson != null) {
      final activeVisit = json.decode(activeVisitJson);
      return Visit.fromJson(activeVisit);
    }

    return null;
  }

  // Mock Log Location
  static Future<Map<String, dynamic>> mockLogLocation(
    double latitude,
    double longitude,
    double accuracy,
    double battery,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);

      final locationLog = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'battery': battery,
        'logged_at': DateTime.now().toIso8601String(),
        'user_id': currentUser['id'],
      };

      // Store location log
      final locationsJson = prefs.getString(_locationsKey);
      List<dynamic> locations = locationsJson != null
          ? json.decode(locationsJson)
          : [];
      locations.add(locationLog);

      // Keep only last 1000 location logs
      if (locations.length > 1000) {
        locations = locations.sublist(locations.length - 1000);
      }

      await prefs.setString(_locationsKey, json.encode(locations));

      return {'success': true, 'log': locationLog};
    }

    return {'success': false, 'message': 'User not found'};
  }

  // Mock Get Journey Data
  static Future<List<LocationLog>> mockGetJourneyData(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_locationsKey);

    if (locationsJson != null) {
      List<dynamic> locations = json.decode(locationsJson);

      // Filter by date
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final filteredLocations = locations.where((loc) {
        final logDate = DateTime.parse(
          loc['logged_at'],
        ).toIso8601String().split('T')[0];
        return logDate == dateString;
      }).toList();

      return filteredLocations.map((loc) => LocationLog.fromJson(loc)).toList();
    }

    return [];
  }

  // Mock Get Live Tracking Data
  static Future<List<Map<String, dynamic>>> mockGetLiveTrackingData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final locationsJson = prefs.getString(_locationsKey);

    if (usersJson != null && locationsJson != null) {
      List<dynamic> users = json.decode(usersJson);
      List<dynamic> locations = json.decode(locationsJson);

      List<Map<String, dynamic>> liveData = [];

      for (var user in users) {
        // Find latest location for each user
        final userLocations = locations
            .where((loc) => loc['user_id'] == user['id'])
            .toList();

        if (userLocations.isNotEmpty) {
          // Sort by timestamp and get latest
          userLocations.sort(
            (a, b) => DateTime.parse(
              b['logged_at'],
            ).compareTo(DateTime.parse(a['logged_at'])),
          );
          final latestLocation = userLocations.first;

          liveData.add({
            'user': {'id': user['id'], 'name': user['name']},
            'latitude': latestLocation['latitude'],
            'longitude': latestLocation['longitude'],
            'logged_at': latestLocation['logged_at'],
          });
        }
      }

      return liveData;
    }

    return [];
  }

  // Get Current User
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);
      return User.fromJson(currentUser);
    }

    return null;
  }

  // Clear All Mock Data
  static Future<void> clearAllMockData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_visitsKey);
    await prefs.remove(_locationsKey);
    await prefs.remove(_currentUserKey);
  }

  // Clear only visits and locations (keep user data)
  static Future<void> clearVisitsAndLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_visitsKey);
    await prefs.remove(_locationsKey);
  }

  // Ensure a user is logged in for visit creation
  static Future<void> ensureUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    // If no user is logged in, log in a default user
    if (currentUserJson == null) {
      await mockLogin('saurabhvish@gmail.com', '123456');
    }
  }
}
