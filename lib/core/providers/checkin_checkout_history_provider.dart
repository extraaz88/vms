import 'package:flutter/foundation.dart';
import '../../models/checkin_checkout_history_model.dart';
import '../../services/api_service.dart';

class CheckInCheckOutHistoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<UserCheckInCheckOutHistory> _historyList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserCheckInCheckOutHistory> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all check-in/check-out details from all users
  List<CheckInCheckOutHistory> get allCheckInCheckOutDetails {
    final List<CheckInCheckOutHistory> allDetails = [];
    for (final userHistory in _historyList) {
      allDetails.addAll(userHistory.userCheckInCheckOutDetails);
    }
    // Sort by check-in time (most recent first)
    allDetails.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return allDetails;
  }

  // Get check-in/check-out details for current month
  List<CheckInCheckOutHistory> get currentMonthDetails {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    return allCheckInCheckOutDetails.where((detail) {
      return detail.checkInTime.isAfter(currentMonth) &&
          detail.checkInTime.isBefore(nextMonth);
    }).toList();
  }

  // Get statistics for current month
  Map<String, dynamic> get currentMonthStatistics {
    final details = currentMonthDetails;
    final completed = details.where((d) => d.isCompleted).length;
    final totalHours = details
        .where((d) => d.isCompleted)
        .fold(0.0, (sum, d) => sum + d.duration.inMinutes / 60.0);

    return {
      'totalSessions': details.length,
      'completedSessions': completed,
      'activeSessions': details.length - completed,
      'totalHours': totalHours,
      'averageHoursPerSession': details.isNotEmpty
          ? totalHours / details.length
          : 0.0,
    };
  }

  // Load check-in/check-out history for a specific user
  Future<void> loadCheckInCheckOutHistory(int userId) async {
    _setLoading(true);
    _error = null;

    try {
      final history = await _apiService.getCheckInCheckOutHistory(userId);
      _historyList = history;

      if (kDebugMode) {
        print(
          '📊 Loaded ${history.length} user(s) with check-in/check-out history',
        );
        for (final user in history) {
          print(
            '  - ${user.name}: ${user.userCheckInCheckOutDetails.length} sessions',
          );
        }
      }
    } catch (e) {
      _error = 'Failed to load attendance history: ${e.toString()}';
      if (kDebugMode) {
        print('❌ Error loading check-in/check-out history: $e');
        print('Error type: ${e.runtimeType}');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load check-in/check-out history for multiple users
  Future<void> loadCheckInCheckOutHistoryForUsers(List<int> userIds) async {
    _setLoading(true);
    _error = null;
    _historyList.clear();

    try {
      for (final userId in userIds) {
        try {
          final history = await _apiService.getCheckInCheckOutHistory(userId);
          _historyList.addAll(history);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Failed to load history for user $userId: $e');
          }
          // Continue with other users even if one fails
        }
      }

      if (kDebugMode) {
        print(
          '📊 Loaded check-in/check-out history for ${userIds.length} users',
        );
        print('  Total users with history: ${_historyList.length}');
        print('  Total sessions: ${allCheckInCheckOutDetails.length}');
      }
    } catch (e) {
      _error = 'Failed to load attendance history: ${e.toString()}';
      if (kDebugMode) {
        print('❌ Error loading check-in/check-out history: $e');
        print('Error type: ${e.runtimeType}');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Refresh data
  Future<void> refresh(int userId) async {
    await loadCheckInCheckOutHistory(userId);
  }

  // Clear data
  void clearData() {
    _historyList.clear();
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get check-in/check-out details for a specific date range
  List<CheckInCheckOutHistory> getDetailsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return allCheckInCheckOutDetails.where((detail) {
      return detail.checkInTime.isAfter(startDate) &&
          detail.checkInTime.isBefore(endDate);
    }).toList();
  }

  // Get check-in/check-out details for a specific user
  List<CheckInCheckOutHistory> getDetailsForUser(int userId) {
    final userHistory = _historyList.where((h) => h.id == userId).firstOrNull;
    return userHistory?.userCheckInCheckOutDetails ?? [];
  }

  // Get check-in/check-out details for a specific user and date range
  List<CheckInCheckOutHistory> getDetailsForUserAndDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final userDetails = getDetailsForUser(userId);
    return userDetails.where((detail) {
      return detail.checkInTime.isAfter(startDate) &&
          detail.checkInTime.isBefore(endDate);
    }).toList();
  }
}
