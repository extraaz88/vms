import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/checkin_checkout_history_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/checkin_checkout_history_model.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../services/location_validation_service.dart';
import '../../utils/responsive_utils.dart';

/// Developer Dashboard Screen - For Flutter developers and similar roles
class DeveloperDashboardScreen extends StatefulWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  State<DeveloperDashboardScreen> createState() => _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState extends State<DeveloperDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();
    final historyProvider = context.read<CheckInCheckOutHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    // Get current user ID for attendance history
    final userId = authProvider.user?.id;
    final userIdInt = int.tryParse(userId ?? '') ?? 0;

    // Initialize basic data first
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
      if (userIdInt > 0) historyProvider.loadCheckInCheckOutHistory(userIdInt),
    ]);

    // Start location tracking for auto checkout
    if (!locationProvider.isTracking && locationProvider.hasPermission) {
      await locationProvider.startTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog(context) ?? false;
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: AppTheme.backgroundColor,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => context.push('/notifications'),
                  tooltip: 'Notifications',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () => context.push('/profile'),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _initializeData,
          backgroundColor: Colors.white.withOpacity(0.2),
          color: Colors.white,
          child: SingleChildScrollView(
            child: Container(
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Animation Section for Flutter Developers
                  _buildWelcomeAnimationSection(),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),
                  // Current Status Section with Timer (for developers)
                  _buildCurrentStatus(),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),
                  // Monthly Attendance Section
                  _buildMonthlyAttendanceCard(),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                  ),
                  // Employee Birthday Section
                  _buildEmployeeBirthdaySection(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Consumer2<VisitProvider, AuthProvider>(
          builder: (context, visitProvider, authProvider, child) {
            final isFlutterDeveloper =
                authProvider.user?.isFlutterDeveloper ?? false;
            final profileIndex = isFlutterDeveloper ? 3 : 4;
            return CustomBottomNavigation(
              currentIndex: profileIndex,
              isCheckedIn: visitProvider.hasActiveVisit,
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Exit App'),
          ],
        ),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeAnimationSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.name ?? 'Developer';

        return Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                Colors.purple.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text with Animation - Row layout for better spacing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to Office!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize:
                                    ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      26,
                                    ),
                              ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms)
                            .slideX(
                              begin: -0.3,
                              end: 0,
                              curve: Curves.easeOut,
                            ),
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(
                                context,
                              ) *
                              0.75,
                        ),
                        Text(
                          'Good to see you, $userName! 👋',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize:
                                    ResponsiveUtils.getResponsiveFontSize(
                                      context,
                                      18,
                                    ),
                              ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 200.ms)
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              curve: Curves.easeOut,
                            ),
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(
                                context,
                              ) *
                              1,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveUtils.getResponsiveSpacing(
                                  context,
                                ) *
                                1,
                            vertical:
                                ResponsiveUtils.getResponsiveSpacing(
                                  context,
                                ) *
                                0.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getResponsiveBorderRadius(
                                context,
                                20,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.code,
                                color: Colors.white,
                                size:
                                    ResponsiveUtils.getResponsiveIconSize(
                                      context,
                                      18,
                                    ),
                              ),
                              SizedBox(
                                width: ResponsiveUtils.getResponsiveSpacing(
                                  context,
                                ) *
                                    0.5,
                              ),
                              Text(
                                (user?.role ?? 'USER').toUpperCase(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            13,
                                          ),
                                    ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 400.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                            ),
                        // Office Status Indicator
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(
                                context,
                              ) *
                              0.75,
                        ),
                        Consumer<LocationProvider>(
                          builder: (context, locationProvider, child) {
                            return _buildOfficeStatusBadge(
                              context,
                              locationProvider,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context) * 1,
                  ),
                  // Developer Icon/Logo on right side with better animation
                  Container(
                    width: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      90,
                    ),
                    height: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      90,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveBorderRadius(
                          context,
                          20,
                        ),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        Container(
                          width: ResponsiveUtils.getResponsiveIconSize(
                            context,
                            70,
                          ),
                          height: ResponsiveUtils.getResponsiveIconSize(
                            context,
                            70,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate()
                            .scale(
                              duration: 2000.ms,
                              curve: Curves.easeInOut,
                            ),
                        // Code icon
                        Icon(
                          Icons.code,
                          color: Colors.white,
                          size: ResponsiveUtils.getResponsiveIconSize(
                            context,
                            45,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 300.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfficeStatusBadge(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    final isInOffice = locationProvider.currentPosition != null &&
        LocationValidationService.isUserInOffice(
          locationProvider.currentPosition!,
        );

    final statusText = isInOffice ? 'In Office' : 'Outside Office';
    final statusIcon = isInOffice ? Icons.location_on : Icons.location_off;
    final statusColor = isInOffice ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 500.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _buildCurrentStatus() {
    return Consumer2<VisitProvider, LocationProvider>(
      builder: (context, visitProvider, locationProvider, child) {
        final hasActiveVisit = visitProvider.hasActiveVisit;
        final Duration? autoCheckoutRemaining =
            locationProvider.autoCheckoutRemaining;
        final bool showAutoCheckoutTimer =
            hasActiveVisit &&
            locationProvider.isOutsideOfficeRadius &&
            locationProvider.isAutoCheckoutTimerActive;

        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                child: Text(
                  'Today\'s Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              Container(
                padding: ResponsiveUtils.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.getResponsiveSpacing(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Checked In',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
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
                            'Ready to start your day',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showAutoCheckoutTimer) ...[
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                _buildAutoCheckoutTimerCard(
                  context,
                  autoCheckoutRemaining ?? Duration.zero,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoCheckoutTimerCard(BuildContext context, Duration remaining) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 16),
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context) * 0.625,
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Colors.orange,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outside office boundary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      16,
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                Text(
                  'Auto check-out in ${_formatCountdown(remaining)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
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

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) {
      return '00:00';
    }
    final hours = duration.inHours;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMonthlyAttendanceCard() {
    return Consumer<CheckInCheckOutHistoryProvider>(
      builder: (context, historyProvider, child) {
        final now = DateTime.now();
        final currentMonth = DateFormat('MMMM yyyy').format(now);
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final startingWeekday = firstDayOfMonth.weekday;
        final currentDay = now.day;

        final monthDetails = historyProvider.currentMonthDetails;

        // Calculate which days user was present (checked in)
        final presentDays = <int>{};
        for (final detail in monthDetails) {
          if (detail.isCompleted) {
            final day = detail.checkInTime.day;
            presentDays.add(day);
          }
        }

        // Calculate Sundays (holidays)
        final sundays = <int>[];
        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(now.year, now.month, day);
          if (date.weekday == 7) {
            sundays.add(day);
          }
        }

        // Calculate working days (excluding Sundays)
        final workingDays = <int>[];
        for (int day = 1; day <= currentDay; day++) {
          final date = DateTime(now.year, now.month, day);
          if (date.weekday != 7) {
            workingDays.add(day);
          }
        }

        // Absent days = working days where user didn't check in
        final absentDays = workingDays
            .where((day) => !presentDays.contains(day))
            .toSet();

        // For now, leave days empty (can be fetched from leave provider later)
        final leaveDays = <int>{};

        final presentCount = presentDays.length;
        final absentCount = absentDays.length;
        final leaveCount = leaveDays.length;
        final holidayCount = sundays.where((d) => d <= currentDay).length;
        final totalWorking = presentCount + absentCount + leaveCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Attendance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Container(
              padding: ResponsiveUtils.getResponsivePadding(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentMonth,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        22,
                                      ),
                                ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.25,
                          ),
                          Text(
                            'Working Days: $totalWorking',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        14,
                                      ),
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveBorderRadius(
                              context,
                              12,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: ResponsiveUtils.getResponsiveIconSize(
                            context,
                            32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height:
                        ResponsiveUtils.getResponsiveSpacing(context) * 1.25,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceStat(
                          'Present',
                          presentCount.toString(),
                          Icons.check_circle,
                          Colors.green.shade300,
                        ),
                      ),
                      Expanded(
                        child: _buildAttendanceStat(
                          'Absent',
                          absentCount.toString(),
                          Icons.cancel,
                          Colors.red.shade300,
                        ),
                      ),
                      Expanded(
                        child: _buildAttendanceStat(
                          'Leave',
                          leaveCount.toString(),
                          Icons.event_note,
                          Colors.orange.shade300,
                        ),
                      ),
                      Expanded(
                        child: _buildAttendanceStat(
                          'Holiday',
                          holidayCount.toString(),
                          Icons.weekend,
                          Colors.purple.shade300,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height:
                        ResponsiveUtils.getResponsiveSpacing(context) * 1.25,
                  ),
                  Container(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final padding = ResponsiveUtils.getResponsivePadding(
                          context,
                        );
                        final horizontalPadding = padding.left + padding.right;
                        final availableWidthForDays =
                            availableWidth - horizontalPadding;
                        final daySize =
                            (availableWidthForDays / 7) -
                            (ResponsiveUtils.getResponsiveSpacing(context) *
                                0.125 *
                                2);
                        final responsiveDaySize = daySize.clamp(28.0, 40.0);

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final day = entry.value;
                                    final isSunday = index == 6;

                                    return SizedBox(
                                      width: responsiveDaySize,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSunday
                                              ? Colors.red.shade700
                                              : Colors.grey.shade700,
                                          fontSize:
                                              ResponsiveUtils.getResponsiveFontSize(
                                                context,
                                                12,
                                              ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.75,
                            ),
                            _buildCalendarGrid(
                              daysInMonth,
                              startingWeekday,
                              currentDay,
                              presentDays.toList(),
                              absentDays.toList(),
                              leaveDays.toList(),
                              now,
                              monthDetails,
                              daySize: responsiveDaySize,
                            ),
                            SizedBox(
                              height: ResponsiveUtils.getResponsiveSpacing(
                                context,
                              ),
                            ),
                            _buildColorLegend(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: ResponsiveUtils.getResponsiveIconSize(context, 24),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    int daysInMonth,
    int startingWeekday,
    int currentDay,
    List<int> presentDays,
    List<int> absentDays,
    List<int> leaveDays,
    DateTime now,
    List<CheckInCheckOutHistory> monthDetails, {
    double? daySize,
  }) {
    final responsiveDaySize =
        daySize ?? ResponsiveUtils.getResponsiveIconSize(context, 36);
    final dayMargin = ResponsiveUtils.getResponsiveSpacing(context) * 0.125;

    List<Widget> rows = [];
    List<Widget> dayWidgets = [];

    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(
        SizedBox(width: responsiveDaySize, height: responsiveDaySize),
      );
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(now.year, now.month, day);
      final weekday = currentDate.weekday;
      final isSunday = weekday == 7;

      Color? bgColor;
      Color? textColor = Colors.grey.shade800;
      bool isBold = false;
      String? attendanceStatus;

      if (day == currentDay) {
        bgColor = AppTheme.primaryColor;
        textColor = Colors.white;
        isBold = true;
      } else if (isSunday) {
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      } else if (presentDays.contains(day)) {
        final dayDetails = monthDetails
            .where((detail) => detail.checkInTime.day == day)
            .toList();
        if (dayDetails.isNotEmpty) {
          final detail = dayDetails.first;
          final workingHours = detail.duration.inMinutes / 60.0;
          const double thresholdHours = 7.8;

          if (workingHours < thresholdHours) {
            bgColor = Colors.orange.shade100;
            textColor = Colors.orange.shade900;
            attendanceStatus = 'HD';
          } else {
            bgColor = Colors.green.shade100;
            textColor = Colors.green.shade900;
            attendanceStatus = 'FD';
          }
        } else {
          bgColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
        }
      } else if (absentDays.contains(day)) {
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      } else if (leaveDays.contains(day)) {
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
      } else if (day < currentDay) {
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade500;
      }

      dayWidgets.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: responsiveDaySize,
          height: responsiveDaySize,
          margin: EdgeInsets.all(dayMargin),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 8),
            ),
            border: day == currentDay
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      12,
                    ),
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
              if (attendanceStatus != null && day != currentDay)
                Positioned(
                  top: dayMargin,
                  right: dayMargin,
                  child: Container(
                    width: ResponsiveUtils.getResponsiveIconSize(context, 12),
                    height: ResponsiveUtils.getResponsiveIconSize(context, 12),
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        attendanceStatus,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            6,
                          ),
                          fontWeight: FontWeight.bold,
                          color: bgColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ).animate().scale(duration: 200.ms, delay: (day * 20).ms),
      );

      if (dayWidgets.length == 7) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.from(dayWidgets),
          ),
        );
        dayWidgets.clear();
      }
    }

    if (dayWidgets.isNotEmpty) {
      while (dayWidgets.length < 7) {
        dayWidgets.add(
          SizedBox(width: responsiveDaySize, height: responsiveDaySize),
        );
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayWidgets,
        ),
      );
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
          ),
          child: row,
        );
      }).toList(),
    );
  }

  Widget _buildColorLegend() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(
              'Full Day',
              Colors.green.shade100,
              Colors.green.shade900,
            ),
            _buildLegendItem(
              'Half Day',
              Colors.orange.shade100,
              Colors.orange.shade900,
            ),
            _buildLegendItem(
              'Partial Day',
              Colors.blue.shade100,
              Colors.blue.shade900,
            ),
            _buildLegendItem(
              'Absent',
              Colors.red.shade100,
              Colors.red.shade900,
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem(
              'Leave',
              Colors.purple.shade100,
              Colors.purple.shade900,
            ),
            _buildLegendItem(
              'Holiday',
              Colors.red.shade100,
              Colors.red.shade900,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
        ),
        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.25),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeBirthdaySection() {
    final now = DateTime.now();
    final employees = [
      {'name': 'Saurabh', 'birthday': DateTime(now.year, 10, 15)},
      {'name': 'Urmish', 'birthday': DateTime(now.year, 10, 20)},
      {'name': 'Harsad', 'birthday': DateTime(now.year, 11, 5)},
      {'name': 'Pratik', 'birthday': DateTime(now.year, 12, 25)},
    ];

    final upcomingBirthdays = employees.map((emp) {
      DateTime birthday = emp['birthday'] as DateTime;
      if (birthday.isBefore(now)) {
        birthday = DateTime(now.year + 1, birthday.month, birthday.day);
      }
      final daysUntil = birthday.difference(now).inDays;
      return {
        'name': emp['name'],
        'birthday': birthday,
        'daysUntil': daysUntil,
      };
    }).toList();

    upcomingBirthdays.sort(
      (a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Birthdays 🎂',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cake,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(
                    width: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employee Birthdays',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context) *
                              0.25,
                        ),
                        Text(
                          'Celebrate with your team!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 1.25,
              ),
              ...upcomingBirthdays.take(3).map((emp) {
                final daysUntil = emp['daysUntil'] as int;
                final birthday = emp['birthday'] as DateTime;
                final name = emp['name'] as String;

                String dateText;
                Color badgeColor;
                String badgeText;

                if (daysUntil == 0) {
                  dateText = 'Today!';
                  badgeColor = Colors.yellow.shade300;
                  badgeText = 'TODAY 🎉';
                } else if (daysUntil == 1) {
                  dateText = 'Tomorrow';
                  badgeColor = Colors.orange.shade300;
                  badgeText = 'TOMORROW';
                } else if (daysUntil < 7) {
                  dateText = 'In $daysUntil days';
                  badgeColor = Colors.green.shade300;
                  badgeText = 'THIS WEEK';
                } else if (daysUntil < 30) {
                  dateText = 'In $daysUntil days';
                  badgeColor = Colors.blue.shade300;
                  badgeText = 'THIS MONTH';
                } else {
                  dateText = DateFormat('dd MMM').format(birthday);
                  badgeColor = Colors.grey.shade300;
                  badgeText = 'UPCOMING';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: ResponsiveUtils.getResponsiveSpacing(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.25,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                SizedBox(
                                  width:
                                      ResponsiveUtils.getResponsiveSpacing(
                                        context,
                                      ) *
                                      0.375,
                                ),
                                Text(
                                  dateText,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(
                  duration: 400.ms,
                  delay: (upcomingBirthdays.indexOf(emp) * 100).ms,
                );
              }).toList(),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

