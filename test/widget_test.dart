import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:vms/main.dart';
import 'package:vms/services/config_service.dart';
import 'package:vms/core/providers/auth_provider.dart';

void main() {
  group('Base URL Configuration Tests', () {
    testWidgets('Splash screen shows base URL config dialog', (WidgetTester tester) async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Build our app and trigger a frame.
      await tester.pumpWidget(const VMSApp(prefs: null));
      
      // Wait for splash screen to load
      await tester.pumpAndSettle();
      
      // Verify that the base URL config dialog appears
      expect(find.text('Configure Base URL'), findsOneWidget);
      expect(find.text('Set the API endpoint for the app'), findsOneWidget);
    });

    test('ConfigService saves and retrieves base URL correctly', () async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Initialize config service
      await ConfigService.initialize();
      
      // Test setting a custom base URL
      const testUrl = 'https://test-api.example.com/api';
      final success = await ConfigService.setBaseUrl(testUrl);
      
      expect(success, true);
      expect(ConfigService.baseUrl, testUrl);
    });

    test('ConfigService uses default URL when none is set', () async {
      // Mock SharedPreferences with empty values
      SharedPreferences.setMockInitialValues({});
      
      // Initialize config service
      await ConfigService.initialize();
      
      // Should use default URL
      expect(ConfigService.baseUrl, ConfigService.defaultBaseUrl);
    });
  });
}
