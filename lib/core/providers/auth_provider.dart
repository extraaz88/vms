import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final ApiService _apiService = ApiService();
  
  AuthProvider(this._prefs);
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  
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
      
      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user']);
        
        // Store in SharedPreferences
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('user_data', json.encode(_user!.toJson()));
        
        // Set token in API service
        _apiService.setAuthToken(_token!);
        
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
    
    // Clear API service token
    _apiService.clearAuthToken();
    
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
