import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Helper class for authentication-related utilities
/// Provides consistent access to authenticated user information
class AuthHelper {
  /// Get the currently authenticated user's ID
  /// Returns the user ID from SharedPreferences (stored during login)
  /// Returns '1' as fallback if no user is logged in
  static Future<String> getAuthenticatedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        final user = json.decode(userJson);
        final userId = user['id']?.toString();

        if (userId != null && userId.isNotEmpty) {
          if (kDebugMode) {
            print('✅ AuthHelper: Retrieved user ID: $userId');
          }
          return userId;
        }
      }

      if (kDebugMode) {
        print('⚠️ AuthHelper: No user data found, using fallback ID: 1');
      }
      return '1'; // Fallback to default user ID
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthHelper: Error getting user ID: $e');
        print('Using fallback ID: 1');
      }
      return '1'; // Fallback on error
    }
  }

  /// Get the currently authenticated user's complete data
  /// Returns null if no user is logged in
  static Future<Map<String, dynamic>?> getAuthenticatedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');

      if (userJson != null) {
        final user = json.decode(userJson);
        if (kDebugMode) {
          print(
            '✅ AuthHelper: Retrieved user data: ${user['name']} (${user['email']})',
          );
        }
        return user;
      }

      if (kDebugMode) {
        print('⚠️ AuthHelper: No user data found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthHelper: Error getting user data: $e');
      }
      return null;
    }
  }

  /// Get the authentication token
  /// Returns null if no token exists
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null) {
        if (kDebugMode) {
          print(
            '✅ AuthHelper: Retrieved auth token: ${token.substring(0, 10)}...',
          );
        }
        return token;
      }

      if (kDebugMode) {
        print('⚠️ AuthHelper: No auth token found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthHelper: Error getting auth token: $e');
      }
      return null;
    }
  }

  /// Check if user is logged in
  /// Returns true if both user data and token exist
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      final token = prefs.getString('auth_token');

      final loggedIn = userJson != null && token != null;

      if (kDebugMode) {
        print('AuthHelper: User logged in status: $loggedIn');
      }

      return loggedIn;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthHelper: Error checking login status: $e');
      }
      return false;
    }
  }

  /// Log current user ID for debugging purposes
  /// Useful to verify which user ID is being used in API calls
  static Future<void> logCurrentUserId(String context) async {
    final userId = await getAuthenticatedUserId();
    if (kDebugMode) {
      print('🔑 [$context] Using User ID: $userId');
    }
  }
}
