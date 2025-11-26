import 'package:flutter/foundation.dart';
import '../../models/leave_model.dart';

class LeaveProvider with ChangeNotifier {
  List<LeaveApplication> _leaveApplications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LeaveApplication> get leaveApplications => _leaveApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get pending leaves
  List<LeaveApplication> get pendingLeaves =>
      _leaveApplications.where((leave) => leave.status == 'pending').toList();

  // Get approved leaves
  List<LeaveApplication> get approvedLeaves =>
      _leaveApplications.where((leave) => leave.status == 'approved').toList();

  // Get rejected leaves
  List<LeaveApplication> get rejectedLeaves =>
      _leaveApplications.where((leave) => leave.status == 'rejected').toList();

  // Get total leave days for a status
  int getTotalDays(String status) {
    return _leaveApplications
        .where((leave) => leave.status == status)
        .fold(0, (sum, leave) => sum + leave.numberOfDays);
  }

  // Add new leave application
  Future<bool> addLeaveApplication(LeaveApplication leave) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('📝 LEAVE PROVIDER: Adding new leave application');
        print('Leave Type: ${leave.leaveType}');
        print('Duration: ${leave.numberOfDays} days');
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Generate ID
      final newLeave = leave.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        appliedDate: DateTime.now(),
      );

      _leaveApplications.insert(0, newLeave);

      if (kDebugMode) {
        print('✅ LEAVE PROVIDER: Leave application added successfully');
        print('Total Applications: ${_leaveApplications.length}');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LEAVE PROVIDER: Error adding leave application: $e');
      }
      _setError('Failed to submit leave application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update leave status (for testing/demo purposes)
  Future<bool> updateLeaveStatus(String leaveId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('📝 LEAVE PROVIDER: Updating leave status');
        print('Leave ID: $leaveId');
        print('New Status: $newStatus');
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      final index = _leaveApplications.indexWhere((l) => l.id == leaveId);
      if (index != -1) {
        _leaveApplications[index] = _leaveApplications[index].copyWith(
          status: newStatus,
        );

        if (kDebugMode) {
          print('✅ LEAVE PROVIDER: Leave status updated successfully');
        }

        notifyListeners();
        return true;
      } else {
        _setError('Leave application not found');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ LEAVE PROVIDER: Error updating leave status: $e');
      }
      _setError('Failed to update leave status');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete leave application
  Future<bool> deleteLeaveApplication(String leaveId) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🗑️ LEAVE PROVIDER: Deleting leave application');
        print('Leave ID: $leaveId');
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      _leaveApplications.removeWhere((l) => l.id == leaveId);

      if (kDebugMode) {
        print('✅ LEAVE PROVIDER: Leave application deleted successfully');
        print('Remaining Applications: ${_leaveApplications.length}');
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LEAVE PROVIDER: Error deleting leave application: $e');
      }
      _setError('Failed to delete leave application');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch leave applications (for future API integration)
  Future<void> fetchLeaveApplications(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        print('🔄 LEAVE PROVIDER: Fetching leave applications for user: $userId');
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In real app, this would fetch from API
      // For now, we just keep existing data

      if (kDebugMode) {
        print('✅ LEAVE PROVIDER: Fetched ${_leaveApplications.length} leave applications');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ LEAVE PROVIDER: Error fetching leave applications: $e');
      }
      _setError('Failed to fetch leave applications');
    } finally {
      _setLoading(false);
    }
  }

  // Clear all leave applications
  void clearLeaveApplications() {
    _leaveApplications.clear();
    notifyListeners();
    
    if (kDebugMode) {
      print('🧹 LEAVE PROVIDER: All leave applications cleared');
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
  }

  // Clear error manually
  void clearError() {
    _clearError();
    notifyListeners();
  }
}

