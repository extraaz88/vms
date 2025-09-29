import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisitProvider>().loadVisits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Monthly Attendance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<VisitProvider>().loadVisits(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<VisitProvider>(
        builder: (context, visitProvider, child) {
          final visits = visitProvider.visits;
          
          if (visitProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (visits.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => visitProvider.loadVisits(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(visits)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Statistics Cards
                  _buildStatisticsCards(visits)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // Attendance List
                  _buildAttendanceList(visits)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Attendance Records',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your attendance records will appear here\nonce you start checking in and out.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(List visits) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final completedVisits = visits.where((visit) => visit.checkOutTime != null).length;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentMonth,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedVisits completed visits',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(List visits) {
    final completedVisits = visits.where((visit) => visit.checkOutTime != null).length;
    final activeVisits = visits.where((visit) => visit.checkOutTime == null).length;
    final totalHours = _calculateTotalHours(visits);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            title: 'Completed',
            value: completedVisits.toString(),
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending_rounded,
            title: 'Active',
            value: activeVisits.toString(),
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_rounded,
            title: 'Total Hours',
            value: '${totalHours}h',
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List visits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Records',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...visits.map((visit) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAttendanceCard(visit),
        )),
      ],
    );
  }

  Widget _buildAttendanceCard(visit) {
    final isCompleted = visit.checkOutTime != null;
    final duration = isCompleted 
        ? visit.checkOutTime!.difference(visit.checkInTime)
        : DateTime.now().difference(visit.checkInTime);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('dd MMM yyyy').format(visit.checkInTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'COMPLETED' : 'ACTIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Client Name
          Text(
            visit.clientName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Check-in Time
          Row(
            children: [
              Icon(
                Icons.login_rounded,
                color: AppTheme.successColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Check-in: ${DateFormat('h:mm a').format(visit.checkInTime)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Check-out Time
          Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: isCompleted ? AppTheme.errorColor : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isCompleted 
                    ? 'Check-out: ${DateFormat('h:mm a').format(visit.checkOutTime!)}'
                    : 'Check-out: In progress',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isCompleted ? AppTheme.textSecondaryColor : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Duration
          Row(
            children: [
              Icon(
                Icons.timer_rounded,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Duration: ${_formatDuration(duration)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  int _calculateTotalHours(List visits) {
    double totalMinutes = 0;
    for (final visit in visits) {
      if (visit.checkOutTime != null) {
        totalMinutes += visit.checkOutTime!.difference(visit.checkInTime).inMinutes.toDouble();
      }
    }
    return (totalMinutes / 60).round();
  }
}
