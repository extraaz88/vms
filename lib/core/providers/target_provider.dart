import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class TargetProvider extends ChangeNotifier {
  static const String _submissionCountKey = 'form_submission_count';
  static const int _fallbackDailyTarget = 10; // Fallback if API fails
  
  int _currentSubmissions = 0;
  int _dailyTargets = _fallbackDailyTarget;
  bool _isLoading = false;
  String? _error;
  
  int get currentSubmissions => _currentSubmissions;
  int get dailyTargets => _dailyTargets;
  int get remainingTargets => _dailyTargets - _currentSubmissions;
  double get progressPercentage => _dailyTargets > 0 ? (_currentSubmissions / _dailyTargets) : 0.0;
  bool get isTargetCompleted => _currentSubmissions >= _dailyTargets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> initializeTargets() async {
    await _loadTargetData();
  }
  
  Future<void> fetchLeadCountFromAPI(String userId) async {
    debugPrint('\n🔄 FETCHING LEAD COUNT FROM API:');
    debugPrint('═══════════════════════════════════════');
    debugPrint('👤 User ID: $userId');
    debugPrint('⏳ Loading...');
    debugPrint('═══════════════════════════════════════');
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final apiService = ApiService();
      final response = await apiService.getLeadCount(userId);
      
      debugPrint('\n📥 TARGET PROVIDER RECEIVED RESPONSE:');
      debugPrint('═══════════════════════════════════════');
      debugPrint('📊 Full Response: $response');
      debugPrint('📊 Status: ${response['status']}');
      debugPrint('═══════════════════════════════════════');
      
      if (response['status'] == 'success') {
        // Use total_lead as the target (as requested by user)
        _dailyTargets = response['totalLead'] ?? _fallbackDailyTarget;
        
        debugPrint('\n✅ LEAD COUNT PROCESSED SUCCESSFULLY:');
        debugPrint('═══════════════════════════════════════');
        debugPrint('🎯 New Daily Target: $_dailyTargets');
        debugPrint('📈 Total Lead: ${response['totalLead']}');
        debugPrint('📈 Today Total Lead: ${response['todayTotalLead']}');
        debugPrint('📈 Today Visit Lead: ${response['todayVisitLead']}');
        debugPrint('📈 Visit Lead: ${response['visitLead']}');
        debugPrint('═══════════════════════════════════════');
        
        if (kDebugMode) {
          debugPrint('✅ Lead count fetched successfully:');
          debugPrint('Total Lead: ${response['totalLead']}');
          debugPrint('Today Total Lead: ${response['todayTotalLead']}');
          debugPrint('Today Visit Lead: ${response['todayVisitLead']}');
          debugPrint('Visit Lead: ${response['visitLead']}');
        }
      } else {
        _error = response['error'] ?? 'Failed to fetch lead count';
        _dailyTargets = _fallbackDailyTarget;
        
        debugPrint('\n❌ LEAD COUNT API ERROR:');
        debugPrint('═══════════════════════════════════════');
        debugPrint('🚨 Error: $_error');
        debugPrint('🔄 Using Fallback Target: $_fallbackDailyTarget');
        debugPrint('═══════════════════════════════════════');
        
        if (kDebugMode) {
          debugPrint('❌ Lead count API error: $_error');
        }
      }
    } catch (e) {
      _error = e.toString();
      _dailyTargets = _fallbackDailyTarget;
      
      debugPrint('\n❌ LEAD COUNT API EXCEPTION:');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🚨 Exception: $e');
      debugPrint('🔄 Using Fallback Target: $_fallbackDailyTarget');
      debugPrint('═══════════════════════════════════════');
      
      if (kDebugMode) {
        debugPrint('❌ Lead count API exception: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      
      debugPrint('\n🏁 LEAD COUNT FETCH COMPLETED:');
      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ Loading: $_isLoading');
      debugPrint('🎯 Final Target: $_dailyTargets');
      debugPrint('❌ Error: $_error');
      debugPrint('═══════════════════════════════════════');
    }
  }
  
  Future<void> updateCompletedVisits(int completedCount) async {
    _currentSubmissions = completedCount;
    await _saveTargetData();
    notifyListeners();
    
    debugPrint('\n🎯 TARGET PROVIDER UPDATED:');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 Completed Visits: $_currentSubmissions');
    debugPrint('🎯 Daily Target: $_dailyTargets');
    debugPrint('📈 Remaining: $remainingTargets');
    debugPrint('📊 Progress: ${(progressPercentage * 100).toInt()}%');
    debugPrint('═══════════════════════════════════════');
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
