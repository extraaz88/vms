import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/sales/assigned_leads_service.dart';
import '../../services/sales/lead_dropdown_service.dart';
import 'location_provider.dart';
import '../../services/checkin_reminder_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final ApiService _apiService = ApiService();
  LocationProvider? _locationProvider;

  AuthProvider(this._prefs);

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Set location provider for user updates
  void setLocationProvider(LocationProvider locationProvider) {
    _locationProvider = locationProvider;
  }

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  // Initialize auth state from stored data
  Future<void> initializeAuth() async {
    _token = _prefs.getString('auth_token');
    final userJson = _prefs.getString('user_data');

    if (_token != null && userJson != null) {
      try {
        _user = User.fromJson(json.decode(userJson));
        _apiService.setAuthToken(_token!);
        
        // Set developer status in API service to control logging
        _apiService.setDeveloperStatus(_user?.isFlutterDeveloper ?? false);
        
        // Update location provider with user info
        _locationProvider?.setCurrentUser(_user);
      } catch (e) {
        await logout();
      }
    }
    notifyListeners();
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(email, password);

      // Check if login was successful (real API response format)
      if (response['message'] != null &&
          response['token'] != null &&
          response['user'] != null) {
        _token = response['token'];
        _user = User.fromJson(response['user']);

        // Store in SharedPreferences
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('user_data', json.encode(_user!.toJson()));

        // Set token in API service
        _apiService.setAuthToken(_token!);
        
        // Set developer status in API service to control logging
        _apiService.setDeveloperStatus(_user?.isFlutterDeveloper ?? false);

        // Update location provider with new user info
        _locationProvider?.setCurrentUser(_user);

        // Ensure check-in reminder is scheduled for the logged-in user
        await CheckInReminderService().rescheduleReminder();
        await CheckInReminderService().checkAndShowReminder();

        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;

    // Clear stored data
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    
    // Clear check-in state
    await _prefs.remove('active_checkin_id');
    await _prefs.remove('active_checkin_data');

    // Clear API service token
    _apiService.clearAuthToken();

    // Clear all service caches
    AssignedLeadsService.clearCache();
    LeadDropdownService.clearCache();

    // Clear user from location provider
    _locationProvider?.setCurrentUser(null);

    // Cancel reminder so next user can get a fresh schedule
    await CheckInReminderService().cancelReminder();

    notifyListeners();
  }

  // Update user profile
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateProfile(userData);

      if (response['success'] == true) {
        _user = User.fromJson(response['user']);
        await _prefs.setString('user_data', json.encode(_user!.toJson()));
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
}
