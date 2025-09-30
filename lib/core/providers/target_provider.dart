import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TargetProvider extends ChangeNotifier {
  static const String _submissionCountKey = 'form_submission_count';
  static const int _dailyTarget = 10;
  
  int _currentSubmissions = 0;
  int _dailyTargets = _dailyTarget;
  
  int get currentSubmissions => _currentSubmissions;
  int get dailyTargets => _dailyTargets;
  int get remainingTargets => _dailyTargets - _currentSubmissions;
  double get progressPercentage => _dailyTargets > 0 ? (_currentSubmissions / _dailyTargets) : 0.0;
  bool get isTargetCompleted => _currentSubmissions >= _dailyTargets;
  
  Future<void> initializeTargets() async {
    await _loadTargetData();
  }
  
  Future<void> incrementSubmission() async {
    _currentSubmissions++;
    await _saveTargetData();
    notifyListeners();
  }
  
  Future<void> resetDailyTargets() async {
    _currentSubmissions = 0;
    await _saveTargetData();
    notifyListeners();
  }
  
  Future<void> _loadTargetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final lastResetDate = prefs.getString('last_reset_date');
      
      // Reset if it's a new day
      if (lastResetDate != today) {
        _currentSubmissions = 0;
        await prefs.setString('last_reset_date', today);
      } else {
        _currentSubmissions = prefs.getInt(_submissionCountKey) ?? 0;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading target data: $e');
    }
  }
  
  Future<void> _saveTargetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_submissionCountKey, _currentSubmissions);
    } catch (e) {
      debugPrint('Error saving target data: $e');
    }
  }
}
