import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/visit_model.dart';
import '../models/location_model.dart';

class MockDataService {
  static const String _usersKey = 'mock_users';
  static const String _visitsKey = 'mock_visits';
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
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
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
        'created_at': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
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
        'created_at': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
    ];

    await prefs.setString(_usersKey, json.encode(mockUsers));
  }

  // Simple Mock Login - Any email and password works
  static Future<Map<String, dynamic>> mockLogin(String email, String password) async {
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
        'created_at': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
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
        }
      };
    }
    
    return {
      'success': false,
      'message': 'Email cannot be empty'
    };
  }

  // Mock Check-in
  static Future<Map<String, dynamic>> mockCheckIn({
    required String clientName,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);
    
    if (currentUserJson != null) {
      final currentUser = json.decode(currentUserJson);
      
      final visit = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'client_name': clientName,
        'check_in_time': DateTime.now().toIso8601String(),
        'check_out_time': null,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'check_out_notes': null,
        'user_id': currentUser['id'],
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Store visit
      final visitsJson = prefs.getString(_visitsKey);
      List<dynamic> visits = visitsJson != null ? json.decode(visitsJson) : [];
      visits.insert(0, visit);
      await prefs.setString(_visitsKey, json.encode(visits));
      
      return {
        'success': true,
        'visit': visit,
      };
    }
    
    return {
      'success': false,
      'message': 'User not found'
    };
  }

  // Mock Check-out
  static Future<Map<String, dynamic>> mockCheckOut({
    required String visitId,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final visitsJson = prefs.getString(_visitsKey);
    
    if (visitsJson != null) {
      List<dynamic> visits = json.decode(visitsJson);
      final visitIndex = visits.indexWhere((v) => v['id'] == visitId);
      
      if (visitIndex != -1) {
        visits[visitIndex]['check_out_time'] = DateTime.now().toIso8601String();
        visits[visitIndex]['check_out_notes'] = notes;
        visits[visitIndex]['status'] = 'completed';
        visits[visitIndex]['updated_at'] = DateTime.now().toIso8601String();
        
        await prefs.setString(_visitsKey, json.encode(visits));
        
        return {
          'success': true,
          'visit': visits[visitIndex],
        };
      }
    }
    
    return {
      'success': false,
      'message': 'Visit not found'
    };
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
      List<dynamic> locations = locationsJson != null ? json.decode(locationsJson) : [];
      locations.add(locationLog);
      
      // Keep only last 1000 location logs
      if (locations.length > 1000) {
        locations = locations.sublist(locations.length - 1000);
      }
      
      await prefs.setString(_locationsKey, json.encode(locations));
      
      return {
        'success': true,
        'log': locationLog,
      };
    }
    
    return {
      'success': false,
      'message': 'User not found'
    };
  }

  // Mock Get Journey Data
  static Future<List<LocationLog>> mockGetJourneyData(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString(_locationsKey);
    
    if (locationsJson != null) {
      List<dynamic> locations = json.decode(locationsJson);
      
      // Filter by date
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final filteredLocations = locations.where((loc) {
        final logDate = DateTime.parse(loc['logged_at']).toIso8601String().split('T')[0];
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
        final userLocations = locations.where((loc) => loc['user_id'] == user['id']).toList();
        
        if (userLocations.isNotEmpty) {
          // Sort by timestamp and get latest
          userLocations.sort((a, b) => DateTime.parse(b['logged_at']).compareTo(DateTime.parse(a['logged_at'])));
          final latestLocation = userLocations.first;
          
          liveData.add({
            'user': {
              'id': user['id'],
              'name': user['name'],
            },
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

  // Add Sample Data for Testing
  static Future<void> addSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add sample visits
    final sampleVisits = [
      {
        'id': '1',
        'client_name': 'ABC Retail Store',
        'check_in_time': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'check_out_time': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'latitude': 28.6139,
        'longitude': 77.2090,
        'notes': 'Product demo completed',
        'check_out_notes': 'Order confirmed for next month',
        'user_id': '1',
        'status': 'completed',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '2',
        'client_name': 'XYZ Corporation',
        'check_in_time': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'check_out_time': null,
        'latitude': 28.6140,
        'longitude': 77.2091,
        'notes': 'Meeting in progress',
        'check_out_notes': null,
        'user_id': '1',
        'status': 'active',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        'updated_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      },
    ];
    
    await prefs.setString(_visitsKey, json.encode(sampleVisits));
    
    // Add sample location logs
    final sampleLocations = [
      {
        'id': '1',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'accuracy': 5.0,
        'battery': 85.0,
        'logged_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'user_id': '1',
      },
      {
        'id': '2',
        'latitude': 28.6140,
        'longitude': 77.2091,
        'accuracy': 8.0,
        'battery': 82.0,
        'logged_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
        'user_id': '1',
      },
      {
        'id': '3',
        'latitude': 28.6141,
        'longitude': 77.2092,
        'accuracy': 6.0,
        'battery': 80.0,
        'logged_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'user_id': '1',
      },
    ];
    
    await prefs.setString(_locationsKey, json.encode(sampleLocations));
  }
}
