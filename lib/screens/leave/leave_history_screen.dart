import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/leave_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/leave_model.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';

class LeaveHistoryScreen extends StatefulWidget {
  const LeaveHistoryScreen({super.key});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(width: 24, height: 24),
            const SizedBox(width: 8),
            const Text('Leave History'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list, size: 20)),
            Tab(text: 'Pending', icon: Icon(Icons.pending, size: 20)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle, size: 20)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel, size: 20)),
          ],
        ),
        ),
        drawer: const CustomDrawer(),
        body: Column(
        children: [
          _buildStatsSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveList('all'),
                _buildLeaveList('pending'),
                _buildLeaveList('approved'),
                _buildLeaveList('rejected'),
              ],
            ),
          ),
        ],
        ),
        bottomNavigationBar: Consumer<VisitProvider>(
          builder: (context, visitProvider, child) {
            return CustomBottomNavigation(
              currentIndex: 1, // Leave History for Flutter Developer
              isCheckedIn: visitProvider.hasActiveVisit,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Consumer<LeaveProvider>(
      builder: (context, leaveProvider, child) {
        final totalLeaves = leaveProvider.leaveApplications.length;
        final pendingCount = leaveProvider.pendingLeaves.length;
        final approvedCount = leaveProvider.approvedLeaves.length;
        final rejectedCount = leaveProvider.rejectedLeaves.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.list,
                label: 'Total',
                value: totalLeaves.toString(),
                color: Colors.white,
              ),
              _buildStatItem(
                icon: Icons.pending,
                label: 'Pending',
                value: pendingCount.toString(),
                color: Colors.orange.shade300,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Approved',
                value: approvedCount.toString(),
                color: Colors.green.shade300,
              ),
              _buildStatItem(
                icon: Icons.cancel,
                label: 'Rejected',
                value: rejectedCount.toString(),
                color: Colors.red.shade300,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLeaveList(String filterType) {
    return Consumer<LeaveProvider>(
      builder: (context, leaveProvider, child) {
        List<LeaveApplication> leaves;

        switch (filterType) {
          case 'pending':
            leaves = leaveProvider.pendingLeaves;
            break;
          case 'approved':
            leaves = leaveProvider.approvedLeaves;
            break;
          case 'rejected':
            leaves = leaveProvider.rejectedLeaves;
            break;
          default:
            leaves = leaveProvider.leaveApplications;
        }

        if (leaveProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (leaves.isEmpty) {
          return _buildEmptyState(filterType);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh logic here
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              return _buildLeaveCard(leaves[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String filterType) {
    String message;
    IconData icon;

    switch (filterType) {
      case 'pending':
        message = 'No Pending Leaves';
        icon = Icons.pending;
        break;
      case 'approved':
        message = 'No Approved Leaves';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'No Rejected Leaves';
        icon = Icons.cancel;
        break;
      default:
        message = 'No Leave Applications';
        icon = Icons.event_note;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your leave applications will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(LeaveApplication leave, int index) {
    Color statusColor;
    IconData statusIcon;
    Color statusBgColor;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusBgColor = Colors.orange.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.leaveType,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${leave.numberOfDays} day${leave.numberOfDays > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    leave.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'From',
                        DateFormat('dd MMM yyyy').format(leave.fromDate),
                        Icons.event,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoRow(
                        'To',
                        DateFormat('dd MMM yyyy').format(leave.toDate),
                        Icons.event,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Applied Date
                if (leave.appliedDate != null)
                  _buildInfoRow(
                    'Applied On',
                    DateFormat('dd MMM yyyy, hh:mm a').format(leave.appliedDate!),
                    Icons.schedule,
                  ),
                const SizedBox(height: 12),

                // Description
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        leave.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Remarks (if rejected)
                if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.comment, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Remarks',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          leave.remarks!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons (for pending leaves only)
                if (leave.status.toLowerCase() == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(leave),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(LeaveApplication leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Leave Application'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this leave application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteLeave(leave);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLeave(LeaveApplication leave) async {
    final leaveProvider = context.read<LeaveProvider>();
    final success = await leaveProvider.deleteLeaveApplication(leave.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Leave application deleted successfully'
                : 'Failed to delete leave application',
          ),
          backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
        ),
      );
    }
  }
}

