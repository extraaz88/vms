import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Demo class to show API usage with comprehensive logging
class ApiDemo {
  static final ApiService _apiService = ApiService();

  /// Demonstrate the check-in API call with logging
  static Future<Map<String, dynamic>> demonstrateCheckIn() async {
    if (kDebugMode) {
      print('\n🚀 API DEMO: Check-in Endpoint');
      print('═══════════════════════════════════════');
      print('Testing: https://rpsales.extraaaz.com/api/visits/checkin');
      print('Method: POST');
      print('═══════════════════════════════════════\n');
    }

    try {
      // Set auth token (you would get this from login)
      _apiService.setAuthToken(
        '13|Z5bVkQcrhpN4DAqFGhMYzR9wjPpnI3afRuSUocqab67f1940',
      );

      // Make the check-in API call
      final response = await _apiService.checkIn(
        userId: 3,
        userName: "Shubham",
        inLatitude: 18.5204,
        inLongitude: 73.8567,
        checkInTime: "2025-10-03 09:30",
        inAccuracy: 2,
        inBatteryPercent: 15,
        inNotes: "Demo meeting scheduled",
      );

      if (kDebugMode) {
        print('\n✅ API CALL SUCCESSFUL!');
        print('Response Status: ${response['status']}');
        print('Response Message: ${response['message']}');
        print('Visit ID: ${response['visit']['id']}');
        print('Visit Created At: ${response['visit']['created_at']}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('\n❌ API CALL FAILED!');
        print('Error: $e');
      }
      rethrow;
    }
  }

  /// Demonstrate check-out API call with real server
  static Future<Map<String, dynamic>> demonstrateCheckOut() async {
    if (kDebugMode) {
      print('\n🚀 API DEMO: Check-out Endpoint');
      print('═══════════════════════════════════════');
      print('Testing: https://rpsales.extraaaz.com/api/visits/checkout/{id}');
      print('Method: POST');
      print('═══════════════════════════════════════\n');
    }

    try {
      // Set auth token first
      _apiService.setAuthToken(
        '13|Z5bVkQcrhpN4DAqFGhMYzR9wjPpnI3afRuSUocqab67f1940',
      );

      // Make the check-out API call
      final response = await _apiService.checkOut(
        visitId: '1', // Use existing visit ID
        userId: 3,
        outLatitude: 19.5204,
        outLongitude: 74.8567,
        checkOutTime: "2025-10-03 06:30",
        outAccuracy: 9,
        outBatteryPercent: 25,
        outNotes: "Task Completed dfdf - Demo from API Demo",
      );

      if (kDebugMode) {
        print('\n✅ CHECK-OUT API CALL SUCCESSFUL!');
        print('Response Status: ${response['status']}');
        print('Response Message: ${response['message']}');
        print('Visit ID: ${response['visit']['id']}');
        print('Check-out Time: ${response['visit']['check_out_time']}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('\n❌ CHECK-OUT API CALL FAILED!');
        print('Error: $e');
      }
      rethrow;
    }
  }

  /// Demonstrate login API call with real server
  static Future<Map<String, dynamic>> demonstrateLogin() async {
    if (kDebugMode) {
      print('\n🚀 API DEMO: Sign-in Endpoint');
      print('═══════════════════════════════════════');
      print('Testing: https://rpsales.extraaaz.com/api/sign-in');
      print('Method: POST');
      print('═══════════════════════════════════════\n');
    }

    try {
      final response = await _apiService.login(
        'info@extraaazpos.com',
        'Admin@2025',
      );

      if (kDebugMode) {
        print('\n✅ SIGN-IN SUCCESSFUL!');
        print('Response Message: ${response['message']}');
        print('User ID: ${response['user']['id']}');
        print('User Name: ${response['user']['name']}');
        print('User Email: ${response['user']['email']}');
        print('User Type: ${response['user']['type']}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('\n❌ SIGN-IN FAILED!');
        print('Error: $e');
      }
      rethrow;
    }
  }
}
