import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist and manage background timer state
/// This allows the timer to continue tracking even when the app is closed
class BackgroundTimerService {
  static const String _keyTimerDeadline = 'auto_checkout_timer_deadline';
  static const String _keyTimerStartTime = 'auto_checkout_timer_start_time';
  static const String _keyIsOutsideOffice = 'is_outside_office_radius';
  static const String _keyActiveVisitId = 'active_visit_id_for_timer';

  /// Save timer deadline to persistent storage
  static Future<void> saveTimerDeadline(DateTime? deadline) async {
    final prefs = await SharedPreferences.getInstance();
    if (deadline == null) {
      await prefs.remove(_keyTimerDeadline);
    } else {
      await prefs.setString(_keyTimerDeadline, deadline.toIso8601String());
    }
  }

  /// Load timer deadline from persistent storage
  static Future<DateTime?> loadTimerDeadline() async {
    final prefs = await SharedPreferences.getInstance();
    final deadlineString = prefs.getString(_keyTimerDeadline);
    if (deadlineString == null) return null;
    try {
      return DateTime.parse(deadlineString);
    } catch (e) {
      return null;
    }
  }

  /// Save timer start time
  static Future<void> saveTimerStartTime(DateTime? startTime) async {
    final prefs = await SharedPreferences.getInstance();
    if (startTime == null) {
      await prefs.remove(_keyTimerStartTime);
    } else {
      await prefs.setString(_keyTimerStartTime, startTime.toIso8601String());
    }
  }

  /// Load timer start time
  static Future<DateTime?> loadTimerStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeString = prefs.getString(_keyTimerStartTime);
    if (startTimeString == null) return null;
    try {
      return DateTime.parse(startTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Save outside office state
  static Future<void> saveOutsideOfficeState(bool isOutside) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOutsideOffice, isOutside);
  }

  /// Load outside office state
  static Future<bool> loadOutsideOfficeState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsOutsideOffice) ?? false;
  }

  /// Save active visit ID for timer
  static Future<void> saveActiveVisitId(String? visitId) async {
    final prefs = await SharedPreferences.getInstance();
    if (visitId == null) {
      await prefs.remove(_keyActiveVisitId);
    } else {
      await prefs.setString(_keyActiveVisitId, visitId);
    }
  }

  /// Load active visit ID
  static Future<String?> loadActiveVisitId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveVisitId);
  }

  /// Clear all timer state
  static Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTimerDeadline);
    await prefs.remove(_keyTimerStartTime);
    await prefs.remove(_keyIsOutsideOffice);
    await prefs.remove(_keyActiveVisitId);
  }

  /// Check if timer has expired (for background checking)
  static Future<bool> hasTimerExpired() async {
    final deadline = await loadTimerDeadline();
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  /// Get remaining time until deadline
  static Future<Duration?> getRemainingTime() async {
    final deadline = await loadTimerDeadline();
    if (deadline == null) return null;
    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }
}
