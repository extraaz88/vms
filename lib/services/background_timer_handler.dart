import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'background_timer_service.dart';
import 'location_validation_service.dart';
import '../utils/auth_helper.dart';
import '../services/api_service.dart';

/// Background callback function that runs even when app is closed
/// This is registered with geolocator for background location updates
@pragma('vm:entry-point')
void backgroundTimerCallback(LocationSettings locationSettings) async {
  if (kDebugMode) {
    print('🔄 Background timer callback triggered');
  }

  try {
    // Check if timer is active
    final deadline = await BackgroundTimerService.loadTimerDeadline();
    final isOutside = await BackgroundTimerService.loadOutsideOfficeState();
    final visitId = await BackgroundTimerService.loadActiveVisitId();

    if (deadline == null || !isOutside || visitId == null) {
      // No active timer
      return;
    }

    // Check if timer has expired
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      // Timer expired - trigger auto checkout
      await _triggerBackgroundAutoCheckout(visitId);
      return;
    }

    // Get current location to verify still outside office
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final isInOffice = LocationValidationService.isUserInOffice(position);

      if (isInOffice) {
        // User returned to office, clear timer
        await BackgroundTimerService.clearTimerState();
        if (kDebugMode) {
          print('✅ User returned to office, timer cleared');
        }
      } else {
        // Still outside, update saved state
        await BackgroundTimerService.saveOutsideOfficeState(true);
        if (kDebugMode) {
          final remaining = deadline.difference(now);
          print(
            '⏰ Background timer active. Remaining: ${remaining.inMinutes} minutes',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location in background: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background timer callback: $e');
    }
  }
}

/// Trigger auto checkout from background
Future<void> _triggerBackgroundAutoCheckout(String visitId) async {
  try {
    if (kDebugMode) {
      print('🚨 Background auto-checkout triggered for visit: $visitId');
    }

    // Get user ID
    final userId = await AuthHelper.getAuthenticatedUserId();
    final userIdInt = int.tryParse(userId) ?? 0;

    // Get current location
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get location for checkout: $e');
      }
    }

    // Get battery level
    int batteryLevel = 50; // Default
    try {
      // Note: battery_plus doesn't work in background, use default
    } catch (e) {
      // Ignore
    }

    // Call checkout API
    final apiService = ApiService();
    final now = DateTime.now();
    final checkOutTime = now.toString().substring(0, 19);

    // Use default values if position is null
    final outLatitude = position?.latitude ?? 0.0;
    final outLongitude = position?.longitude ?? 0.0;
    final outAccuracy = position?.accuracy ?? 0.0;

    await apiService.checkOut(
      visitId: visitId,
      userId: userIdInt,
      outLatitude: outLatitude,
      outLongitude: outLongitude,
      checkOutTime: checkOutTime,
      outAccuracy: outAccuracy,
      outBatteryPercent: batteryLevel.toDouble(),
      outNotes:
          'Auto checkout: Away from office for more than 1 hour (Background)',
    );

    // Clear timer state
    await BackgroundTimerService.clearTimerState();

    if (kDebugMode) {
      print('✅ Background auto-checkout completed');
    }

    // Show notification (will be handled by local notification service)
    // Note: You may want to trigger a local notification here
  } catch (e) {
    if (kDebugMode) {
      print('❌ Error in background auto-checkout: $e');
    }
  }
}
