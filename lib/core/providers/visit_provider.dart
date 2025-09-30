import 'package:flutter/foundation.dart';
import '../../models/visit_model.dart';
import '../../services/api_service.dart';

class VisitProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Visit> _visits = [];
  Visit? _currentVisit;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Visit> get visits => _visits;
  Visit? get currentVisit => _currentVisit;
  Visit? get activeVisit => _currentVisit?.checkOutTime == null ? _currentVisit : null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveVisit => _currentVisit != null && _currentVisit!.checkOutTime == null;
  
  // Initialize visits
  Future<void> initializeVisits() async {
    await Future.wait([
      loadVisits(),
      loadCurrentActiveVisit(),
    ]);
  }
  
  // Load current active visit
  Future<void> loadCurrentActiveVisit() async {
    try {
      final activeVisit = await _apiService.getCurrentActiveVisit();
      _currentVisit = activeVisit;
      notifyListeners();
    } catch (e) {
      // No active visit found, which is normal
      _currentVisit = null;
    }
  }
  
  // Load visits history
  Future<void> loadVisits() async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.getVisits();
      _visits = response;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load visits: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a visit directly (without check-in/check-out)
  Future<bool> createVisit({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.createVisit(
        latitude: latitude,
        longitude: longitude,
        clientName: clientName,
        notes: notes,
        visitingReason: visitingReason,
        visitingArea: visitingArea,
        photoPath: photoPath,
      );
      
      if (response['success'] == true) {
        final newVisit = Visit.fromJson(response['visit']);
        // Add directly to visits list
        _visits.insert(0, newVisit);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Visit creation failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check-in to a visit (kept for backward compatibility)
  Future<bool> checkIn({
    required double latitude,
    required double longitude,
    String? clientName,
    String? notes,
    String? visitingReason,
    String? visitingArea,
    String? photoPath,
  }) async {
    if (hasActiveVisit) {
      _setError('You already have an active visit. Please check out first.');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.checkIn(
        latitude: latitude,
        longitude: longitude,
        clientName: clientName,
        notes: notes,
        visitingReason: visitingReason,
        visitingArea: visitingArea,
        photoPath: photoPath,
      );
      
      if (response['success'] == true) {
        _currentVisit = Visit.fromJson(response['visit']);
        // Don't add to visits list yet - only add when checked out
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Check-in failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Check-out from current visit
  Future<bool> checkOut({required String visitId, String? notes}) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.checkOut(
        visitId: visitId,
        notes: notes,
      );
      
      if (response['success'] == true) {
        final updatedVisit = Visit.fromJson(response['visit']);
        
        // Clear current visit
        if (_currentVisit?.id == visitId) {
          _currentVisit = null;
        }
        
        // Add completed visit to history (since it wasn't added during check-in)
        _visits.insert(0, updatedVisit);
        
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Check-out failed');
        return false;
      }
    } catch (e) {
      _setError('Network error: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update visit notes
  Future<bool> updateVisitNotes(String visitId, String notes) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _apiService.updateVisitNotes(visitId, notes);
      
      if (response['success'] == true) {
        final updatedVisit = Visit.fromJson(response['visit']);
        
        // Update in visits list
        final index = _visits.indexWhere((v) => v.id == updatedVisit.id);
        if (index != -1) {
          _visits[index] = updatedVisit;
        }
        
        // Update current visit if it's the same
        if (_currentVisit?.id == updatedVisit.id) {
          _currentVisit = updatedVisit;
        }
        
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
  
  // Get visits by date range
  Future<List<Visit>> getVisitsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _apiService.getVisitsByDateRange(startDate, endDate);
    } catch (e) {
      _setError('Failed to fetch visits: ${e.toString()}');
      return [];
    }
  }
  
  // Get visit statistics
  Future<Map<String, dynamic>> getVisitStatistics() async {
    try {
      return await _apiService.getVisitStatistics();
    } catch (e) {
      _setError('Failed to fetch statistics: ${e.toString()}');
      return {};
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
