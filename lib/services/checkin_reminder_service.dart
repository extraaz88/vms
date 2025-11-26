import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_notification_service.dart';
import 'api_service.dart';
import '../utils/auth_helper.dart';

class CheckInReminderService {
  static final CheckInReminderService _instance =
      CheckInReminderService._internal();
  factory CheckInReminderService() => _instance;
  CheckInReminderService._internal();

  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final ApiService _apiService = ApiService();

  /// Initialize and schedule daily check-in reminder
  Future<void> initialize() async {
    // Schedule daily reminder at 10:00 PM
    await _scheduleDailyReminder();

    // Check if we need to show reminder right now
    await _checkAndShowReminderIfNeeded();
  }

  /// Schedule daily check-in reminder at 10:00 PM
  Future<void> _scheduleDailyReminder() async {
    try {
      await _notificationService.scheduleDailyCheckInReminder();
      if (kDebugMode) {
        print('✅ Daily check-in reminder scheduled for 10:00 PM');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling daily reminder: $e');
      }
    }
  }

  /// Check if user has checked in today (using API)
  Future<bool> _hasCheckedInToday() async {
    try {
      // Get user ID
      final userId = await AuthHelper.getAuthenticatedUserId();
      final userIdInt = int.tryParse(userId) ?? 0;

      if (userIdInt == 0) {
        return false;
      }

      // Check API for today's check-in status
      final todayStatus = await _apiService.getTodayCheckInStatus(userIdInt);
      final bool hasCheckedInToday = todayStatus['hasCheckedInToday'] ?? false;

      if (kDebugMode) {
        print(
          '🔍 Check-in reminder: User has checked in today: $hasCheckedInToday',
        );
      }

      return hasCheckedInToday;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking check-in status from API: $e');
      }
      // Fallback: check active check-in ID from local storage (session persistence only)
      try {
        final prefs = await SharedPreferences.getInstance();
        final activeCheckInId = prefs.getString('active_checkin_id');
        return activeCheckInId != null && activeCheckInId.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// Check current time and show reminder if needed
  Future<void> _checkAndShowReminderIfNeeded() async {
    try {
      final now = DateTime.now();
      final reminderTime = DateTime(now.year, now.month, now.day, 12, 52);

      // If current time is after 10:00 PM and before 1:00 PM
      // and user hasn't checked in, show reminder
      if (now.isAfter(reminderTime) && now.hour == 12 && now.minute < 60) {
        final hasCheckedIn = await _hasCheckedInToday();

        if (!hasCheckedIn) {
          // Check if we already showed reminder today
          final prefs = await SharedPreferences.getInstance();
          final todayKey =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final reminderShownKey = 'checkin_reminder_shown_$todayKey';
          final reminderShown = prefs.getBool(reminderShownKey) ?? false;

          if (!reminderShown) {
            await _showReminderNow();
            await prefs.setBool(reminderShownKey, true);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking reminder: $e');
      }
    }
  }

  /// Show reminder notification immediately
  Future<void> _showReminderNow() async {
    await _notificationService.showNotification(
      id: 1002, // Different ID for immediate reminder
      title: '⏰ Check-In Reminder',
      body:
          'Your working hours are about to start! Please check in soon, or a half-day will be marked.',
      payload: 'checkin_reminder_immediate',
    );

    if (kDebugMode) {
      print('🔔 Check-in reminder shown immediately');
    }
  }

  /// Check and show reminder if user hasn't checked in (called from app lifecycle)
  Future<void> checkAndShowReminder() async {
    await _checkAndShowReminderIfNeeded();
  }

  /// Cancel reminder if user has checked in
  Future<void> onCheckInCompleted() async {
    try {
      // Cancel scheduled reminder for today
      await _notificationService.cancelDailyCheckInReminder();

      // Reschedule for tomorrow
      await _scheduleDailyReminder();

      if (kDebugMode) {
        print('✅ Check-in reminder cancelled (user checked in)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling check-in completion: $e');
      }
    }
  }

  /// Reschedule reminder (call this daily or on app start)
  Future<void> rescheduleReminder() async {
    await _scheduleDailyReminder();
  }

  /// Cancel reminder (used on logout to avoid stale schedules)
  Future<void> cancelReminder() async {
    await _notificationService.cancelDailyCheckInReminder();
    if (kDebugMode) {
      print('🛑 Check-in reminder cancelled (logout)');
    }
  }
}
