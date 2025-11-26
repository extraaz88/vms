import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/providers/visit_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/checkin_checkout_history_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/checkin_checkout_history_model.dart';
import '../../utils/responsive_utils.dart';

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
      // Load check-in/check-out history for the current user
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        final userId = int.tryParse(authProvider.user!.id);
        if (userId != null) {
          context
              .read<CheckInCheckOutHistoryProvider>()
              .loadCheckInCheckOutHistory(userId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Monthly Attendance',
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: ResponsiveUtils.getResponsiveIconSize(context, 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
            onPressed: () async {
              await context.read<VisitProvider>().loadVisits();
              final authProvider = context.read<AuthProvider>();
              if (authProvider.user != null) {
                final userId = int.tryParse(authProvider.user!.id);
                if (userId != null) {
                  await context
                      .read<CheckInCheckOutHistoryProvider>()
                      .loadCheckInCheckOutHistory(userId);
                }
              }
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer2<VisitProvider, CheckInCheckOutHistoryProvider>(
        builder: (context, visitProvider, historyProvider, child) {
          final visits = visitProvider.visits;
          final historyDetails = historyProvider.currentMonthDetails;
          final statistics = historyProvider.currentMonthStatistics;

          if (visitProvider.isLoading || historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyDetails.isEmpty && visits.isEmpty) {
            return _buildEmptyState();
          }

          // Show error if there's an error loading history
          if (historyProvider.error != null) {
            return _buildErrorState(historyProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await visitProvider.loadVisits();
              final authProvider = context.read<AuthProvider>();
              if (authProvider.user != null) {
                final userId = int.tryParse(authProvider.user!.id);
                if (userId != null) {
                  await historyProvider.loadCheckInCheckOutHistory(userId);
                }
              }
            },
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeaderSection(historyDetails, statistics)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),

                  // Statistics Cards
                  _buildStatisticsCards(historyDetails, statistics)
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),

                  // Attendance List
                  _buildAttendanceList(historyDetails)
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

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.red.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Error Loading Attendance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load attendance history.\nPlease check your internet connection and try again.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red.withOpacity(0.7)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.user != null) {
                    final userId = int.tryParse(authProvider.user!.id);
                    if (userId != null) {
                      await context
                          .read<CheckInCheckOutHistoryProvider>()
                          .loadCheckInCheckOutHistory(userId);
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    List<CheckInCheckOutHistory> historyDetails,
    Map<String, dynamic> statistics,
  ) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    final completedSessions = statistics['completedSessions'] ?? 0;

    return Container(
      width: ResponsiveUtils.getResponsiveWidth(context, 1000),
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: ResponsiveUtils.getResponsiveElevation(context, 12),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ResponsiveUtils.isMobile(context)
          ? Column(
              children: [
                Container(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveBorderRadius(context, 16),
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 32),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Monthly Attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          24,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Text(
                      currentMonth,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                      ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                    ),
                    Text(
                      '$completedSessions completed sessions',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveBorderRadius(context, 16),
                    ),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 32),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            24,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                      ),
                      Text(
                        currentMonth,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            16,
                          ),
                        ),
                      ),
                      SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context) *
                            0.25,
                      ),
                      Text(
                        '$completedSessions completed sessions',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatisticsCards(
    List<CheckInCheckOutHistory> historyDetails,
    Map<String, dynamic> statistics,
  ) {
    final completedSessions = statistics['completedSessions'] ?? 0;
    final activeSessions = statistics['activeSessions'] ?? 0;
    final totalHours = (statistics['totalHours'] as double?)?.round() ?? 0;

    return ResponsiveUtils.isMobile(context)
        ? Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Completed',
                  value: completedSessions.toString(),
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_rounded,
                  title: 'Active',
                  value: activeSessions.toString(),
                  color: AppTheme.warningColor,
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_rounded,
                  title: 'Total Hours',
                  value: '${totalHours}h',
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle_rounded,
                  title: 'Completed',
                  value: completedSessions.toString(),
                  color: AppTheme.successColor,
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
              ),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pending_rounded,
                  title: 'Active',
                  value: activeSessions.toString(),
                  color: AppTheme.warningColor,
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
              ),
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
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        ),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: ResponsiveUtils.getResponsiveElevation(context, 8),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            ),
          ),
          SizedBox(
            height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<CheckInCheckOutHistory> historyDetails) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Records',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...historyDetails.map(
          (detail) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAttendanceCard(detail),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(CheckInCheckOutHistory detail) {
    final isCompleted = detail.isCompleted;
    final duration = detail.duration;

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
                  DateFormat('dd MMM yyyy').format(detail.checkInTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCompleted
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
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
                    color: isCompleted
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // User Name
          Text(
            detail.userName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Check-in Time
          Row(
            children: [
              Icon(Icons.login_rounded, color: AppTheme.successColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Check-in: ${DateFormat('h:mm a').format(detail.checkInTime)}',
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
                detail.checkOutTime != null
                    ? 'Check-out: ${DateFormat('h:mm a').format(detail.checkOutTime!)}'
                    : 'Check-out: --',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: detail.checkOutTime != null
                      ? AppTheme.textSecondaryColor
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration
          Row(
            children: [
              Icon(Icons.timer_rounded, color: AppTheme.primaryColor, size: 16),
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

          // Notes section if available
          if (detail.inNotes.isNotEmpty || detail.outNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detail.inNotes.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Check-in Notes:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.inNotes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  if (detail.outNotes.isNotEmpty) ...[
                    if (detail.inNotes.isNotEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.note_alt,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Check-out Notes:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.outNotes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
}
