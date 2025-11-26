import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/target_provider.dart';
import '../../core/providers/checkin_checkout_history_provider.dart';
import '../../models/checkin_checkout_history_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/custom_bottom_navigation.dart';
import '../../widgets/app_logo.dart';
import '../../services/location_validation_service.dart';
import '../../utils/responsive_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _blinkingController;

  @override
  void initState() {
    super.initState();
    _blinkingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _blinkingController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _blinkingController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final visitProvider = context.read<VisitProvider>();
    final locationProvider = context.read<LocationProvider>();
    final targetProvider = context.read<TargetProvider>();
    final historyProvider = context.read<CheckInCheckOutHistoryProvider>();
    final authProvider = context.read<AuthProvider>();

    // Get current user ID for attendance history
    final userId = authProvider.user?.id;
    final userIdInt = int.tryParse(userId ?? '') ?? 0;

    // Initialize basic data first
    await Future.wait([
      visitProvider.initializeVisits(),
      locationProvider.initializeLocation(),
      targetProvider.initializeTargets(),
      if (userIdInt > 0) historyProvider.loadCheckInCheckOutHistory(userIdInt),
    ]);

    // Fetch lead count from API if user ID is available
    if (userId != null && userId.isNotEmpty) {
      await targetProvider.fetchLeadCountFromAPI(userId);
    }

    // Start location tracking for auto checkout (works for all users including developers)
    // This ensures auto checkout works when user goes outside office radius
    if (!locationProvider.isTracking && locationProvider.hasPermission) {
      await locationProvider.startTracking();
    }

    // Sync target provider with actual visit count
    _syncTargetWithVisits(visitProvider, targetProvider);

    // Set up callback to automatically update target when visits are completed
    visitProvider.onVisitCompleted = (int completedCount) {
      targetProvider.updateCompletedVisits(completedCount);
    };
  }

  void _syncTargetWithVisits(
    VisitProvider visitProvider,
    TargetProvider targetProvider,
  ) {
    final todayVisitsCount = _getTodayVisitsCount(visitProvider.visits);
    targetProvider.updateCompletedVisits(todayVisitsCount);

    debugPrint('\n🔄 DASHBOARD SYNC:');
    debugPrint('═══════════════════════════════════════');
    debugPrint('📊 Today Visits Count: $todayVisitsCount');
    debugPrint('🎯 Target Provider Updated');
    debugPrint('═══════════════════════════════════════');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog on dashboard
        return await _showExitDialog(context) ?? false;
      },
      child: Scaffold(
        drawer: const CustomDrawer(),
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Row(
            children: [
              AppLogo(
                width: ResponsiveUtils.getResponsiveIconSize(context, 24),
                height: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),
              const Text('VMS'),
            ],
          ),
          actions: [
            // Notification Icon
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined),
                  // Badge for unread notifications
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: ResponsiveUtils.getResponsiveIconSize(
                          context,
                          16,
                        ),
                        minHeight: 16,
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
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
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.push('/profile'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _handleLogout(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _initializeData,
          child: SingleChildScrollView(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Conditionally show content based on role
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    final isFlutterDeveloper =
                        user?.isFlutterDeveloper ?? false;

                    if (isFlutterDeveloper) {
                      // Show Flutter Developer specific content (no progress section)
                      return _buildFlutterDeveloperContent();
                    } else {
                      // Show default content for other roles
                      return Column(
                        children: [
                          // Welcome Section
                          _buildWelcomeSection(),

                          // Current Status
                          _buildCurrentStatus(),

                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                1.5,
                          ),

                          // Statistics Cards
                          _buildStatisticsCards(),

                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                1.5,
                          ),

                          // Lead Management Section
                          _buildLeadManagementSection(),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                1.5,
                          ),

                          // Visiting History Section
                          _buildVisitingHistorySection(),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                1.5,
                          ),

                          // Recent Activity
                          _buildRecentActivity(),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Consumer3<VisitProvider, LocationProvider, AuthProvider>(
          builder: (context, visitProvider, locationProvider, authProvider, child) {
            // Show FAB for all users including Flutter Developers
            final hasLocation = locationProvider.currentPosition != null;
            final isInOffice = hasLocation
                ? LocationValidationService.isUserInOffice(
                    locationProvider.currentPosition!,
                  )
                : false;

            // Check user role - only Flutter Developers need to be in office
            final isFlutterDeveloper =
                authProvider.user?.isFlutterDeveloper ?? false;
            final isSalesPerson = authProvider.user?.isSalesPerson ?? false;

            // For check-in: Flutter developers must be in office, sales people can check-in from anywhere
            // For check-out: location doesn't matter for anyone
            final canCheckIn = isSalesPerson
                ? hasLocation // Sales people just need location, can be anywhere
                : (hasLocation && isInOffice); // Developers must be in office

            // Get check-in ID from API (stored in VisitProvider)
            final activeCheckInId = visitProvider.activeCheckInId;
            final hasActiveCheckIn = visitProvider.hasActiveVisit;

            // Determine which visit ID to use for checkout
            String? checkoutVisitId;
            if (hasActiveCheckIn) {
              // Priority: 1. activeCheckInId from API, 2. currentVisit.id, 3. activeVisit.id
              checkoutVisitId =
                  activeCheckInId ??
                  visitProvider.currentVisit?.id ??
                  visitProvider.activeVisit?.id;
            }

            return CustomFloatingActionButton(
              icon: hasActiveCheckIn ? Icons.check_outlined : Icons.location_on,
              tooltip: hasActiveCheckIn
                  ? 'Check Out'
                  : canCheckIn
                  ? 'Check In'
                  : isFlutterDeveloper
                  ? 'You are not in office'
                  : isSalesPerson
                  ? 'Location not available'
                  : 'Location not available',
              onPressed: () {
                if (hasActiveCheckIn && checkoutVisitId != null) {
                  // User is checked in, navigate to checkout with the ID from API
                  context.push('/visit/checkout/$checkoutVisitId');
                } else if (canCheckIn) {
                  // User can check in
                  context.push('/visit/checkin');
                } else {
                  // Show error message based on user role
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasLocation
                            ? (isFlutterDeveloper
                                  ? 'You are not in office. Please come within 50 meters of the office to check in.'
                                  : isSalesPerson
                                  ? 'Location not available. Please enable location services to check in.'
                                  : 'Location not available. Please enable location services.')
                            : 'Location not available. Please enable location services.',
                      ),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            );
          },
        ),
        bottomNavigationBar: Consumer<VisitProvider>(
          builder: (context, visitProvider, child) {
            return CustomBottomNavigation(
              currentIndex: 0,
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

  Widget _buildCurrentStatus() {
    return Consumer2<VisitProvider, LocationProvider>(
      builder: (context, visitProvider, locationProvider, child) {
        final currentVisit = visitProvider.currentVisit;
        final hasActiveVisit = visitProvider.hasActiveVisit;
        final Duration? autoCheckoutRemaining =
            locationProvider.autoCheckoutRemaining;
        // Show timer if it's active (even if remaining is 0, show it until it expires)
        final bool showAutoCheckoutTimer =
            hasActiveVisit &&
            locationProvider.isOutsideOfficeRadius &&
            locationProvider.isAutoCheckoutTimerActive;

        return Container(
          margin: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              // Status Card
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
                    // Status Icon
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: hasActiveVisit
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(
                            context,
                            12,
                          ),
                        ),
                      ),
                      child: Icon(
                        hasActiveVisit ? Icons.location_on : Icons.check_circle,
                        color: hasActiveVisit
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveUtils.getResponsiveSpacing(context),
                    ),

                    // Status Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasActiveVisit ? 'Checked In' : 'Not Checked In',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: hasActiveVisit
                                      ? AppTheme.warningColor
                                      : AppTheme.textSecondaryColor,
                                ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.25,
                          ),
                          if (hasActiveVisit && currentVisit != null) ...[
                            Text(
                              'Since: ${_formatCheckInTime(currentVisit.checkInTime)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                            SizedBox(
                              height:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.25,
                            ),
                            Text(
                              'Duration: ${_formatDuration(DateTime.now().difference(currentVisit.checkInTime))}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ] else ...[
                            Text(
                              'Ready to start your day',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondaryColor,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Button
                    if (hasActiveVisit) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Inactive',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
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

  Widget _buildWelcomeSection() {
    return Consumer2<AuthProvider, LocationProvider>(
      builder: (context, authProvider, locationProvider, child) {
        return Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 16),
            ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                    ),
                    Text(
                      authProvider.user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              24,
                            ),
                          ),
                    ),
                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                    ),
                    Text(
                      'Ready for your field visits?',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    if (authProvider.user?.isFlutterDeveloper ?? false) ...[
                      SizedBox(
                        height:
                            ResponsiveUtils.getResponsiveSpacing(context) *
                            0.75,
                      ),
                      _buildDeveloperOfficeStatus(context, locationProvider),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                  ),
                ),
                child: AppLogo(
                  width: ResponsiveUtils.getResponsiveIconSize(context, 32),
                  height: ResponsiveUtils.getResponsiveIconSize(context, 32),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
      },
    );
  }

  Widget _buildStatisticsCards() {
    return Consumer2<TargetProvider, VisitProvider>(
      builder: (context, targetProvider, visitProvider, child) {
        // Use target provider's data for consistency
        final todayVisitsCount = targetProvider.currentSubmissions;
        final isTargetCompleted = targetProvider.isTargetCompleted;
        final remainingTargets = targetProvider.remainingTargets;
        final progressPercentage = targetProvider.progressPercentage;
        final isLoading = targetProvider.isLoading;
        final error = targetProvider.error;

        // Sync target provider with actual visits if there's a mismatch
        final actualTodayVisits = _getTodayVisitsCount(visitProvider.visits);
        if (actualTodayVisits != todayVisitsCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncTargetWithVisits(visitProvider, targetProvider);
          });
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with loading indicator
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                child: Row(
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              20,
                            ),
                          ),
                    ),
                    if (isLoading) ...[
                      SizedBox(
                        width:
                            ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                      ),
                      SizedBox(
                        width: ResponsiveUtils.getResponsiveIconSize(
                          context,
                          16,
                        ),
                        height: ResponsiveUtils.getResponsiveIconSize(
                          context,
                          16,
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

              // Main Progress Card
              Container(
                padding: ResponsiveUtils.getResponsivePadding(context),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Show error message if API failed
                    if (error != null) ...[
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                        ),
                        margin: EdgeInsets.only(
                          bottom: ResponsiveUtils.getResponsiveSpacing(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveBorderRadius(
                              context,
                              8,
                            ),
                          ),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 20),
                            SizedBox(
                              width:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.5,
                            ),
                            Expanded(
                              child: Text(
                                'Using fallback target (${targetProvider.dailyTargets}). API Error: $error',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Circular Progress Indicator
                    _buildCircularProgress(
                      progress: progressPercentage,
                      completed: todayVisitsCount,
                      total: targetProvider.dailyTargets,
                      isCompleted: isTargetCompleted,
                    ),

                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                    ),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            value: todayVisitsCount.toString(),
                            label: 'Completed',
                            color: AppTheme.successColor,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[200],
                        ),
                        Expanded(
                          child: _buildBlinkingStatItem(
                            value: remainingTargets.toString(),
                            label: 'Remaining',
                            color: remainingTargets > 0
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                            icon: remainingTargets > 0
                                ? Icons.pending_outlined
                                : Icons.celebration_outlined,
                            shouldBlink:
                                !isTargetCompleted && remainingTargets > 0,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                    ),

                    // Lead Count API Response Display
                    Container(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      margin: EdgeInsets.only(
                        top:
                            ResponsiveUtils.getResponsiveSpacing(context) *
                            0.75,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(
                            context,
                            12,
                          ),
                        ),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.api, color: Colors.blue, size: 20),
                              SizedBox(
                                width:
                                    ResponsiveUtils.getResponsiveSpacing(
                                      context,
                                    ) *
                                    0.5,
                              ),
                              Text(
                                'Lead Count API Response',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.5,
                          ),
                          Text(
                            'Total Lead Target: ${targetProvider.dailyTargets}',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.25,
                          ),
                          Text(
                            'Completed Visits: $todayVisitsCount',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                13,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.25,
                          ),
                          Text(
                            'Remaining Target: $remainingTargets',
                            style: TextStyle(
                              color: remainingTargets > 0
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/visit/management'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTargetCompleted
                              ? Colors.red
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getResponsiveBorderRadius(
                                context,
                                16,
                              ),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isTargetCompleted
                              ? 'Continue Excellence'
                              : remainingTargets > 0
                              ? 'Complete ${remainingTargets} More Visit${remainingTargets > 1 ? 's' : ''}'
                              : 'Add Visit',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              16,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // // Debug Button to Test API
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton(
                    //     onPressed: () async {
                    //       final authProvider = context.read<AuthProvider>();
                    //       final userId = authProvider.user?.id;
                    //       if (userId != null && userId.isNotEmpty) {
                    //         debugPrint('\n🔧 MANUAL API TEST TRIGGERED:');
                    //         debugPrint('═══════════════════════════════════════');
                    //         debugPrint('👤 User ID: $userId');
                    //         debugPrint('═══════════════════════════════════════');

                    //         await targetProvider.fetchLeadCountFromAPI(userId);
                    //       } else {
                    //         debugPrint('❌ No user ID available for API test');
                    //       }
                    //     },
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.orange,
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 12),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       elevation: 0,
                    //     ),
                    //     child: const Text(
                    //       '🔄 Test Lead Count API',
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildCircularProgress({
    required double progress,
    required int completed,
    required int total,
    required bool isCompleted,
  }) {
    final size = ResponsiveUtils.getResponsiveIconSize(context, 120);
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
          ),
          // Completed portion (static/dark)
          Container(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: ResponsiveUtils.getResponsiveIconSize(context, 8),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted
                    ? Colors
                          .red // Red when completed
                    : AppTheme.primaryColor, // Dark blue when in progress
              ),
            ),
          ),
          // Blinking remaining portion (only when not completed)
          if (!isCompleted && progress < 1.0)
            AnimatedBuilder(
              animation: _createBlinkingAnimation(),
              builder: (context, child) {
                return Container(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: 1.0, // Full circle for remaining portion
                    strokeWidth: ResponsiveUtils.getResponsiveIconSize(
                      context,
                      8,
                    ),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor.withOpacity(
                        0.4 + (0.4 * _blinkingController.value),
                      ), // Darker color with blinking opacity
                    ),
                  ),
                );
              },
            ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.red : AppTheme.primaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      24,
                    ),
                  ),
                ),
                Text(
                  '$completed/$total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      12,
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

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.getResponsiveIconSize(context, 24),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBlinkingStatItem({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
    required bool shouldBlink,
  }) {
    return AnimatedBuilder(
      animation: _createBlinkingAnimation(),
      builder: (context, child) {
        // Zoom effect: scale from 1.0 to 1.3 and back
        final scaleValue = shouldBlink
            ? 1.0 + (0.3 * _blinkingController.value)
            : 1.0;

        return Column(
          children: [
            Transform.scale(
              scale: scaleValue,
              child: Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, 12),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                ),
              ),
            ),
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            Transform.scale(
              scale: scaleValue,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Animation<double> _createBlinkingAnimation() {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _blinkingController, curve: Curves.easeInOut),
    );
  }

  Widget _buildLeadManagementSection() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lead Management',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      20,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/leads'),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Leads',
                    subtitle: 'Manage leads',
                    icon: Icons.people,
                    color: AppTheme.secondaryColor,
                    onTap: () => context.push('/leads'),
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
                ),
                Expanded(
                  child: DashboardCard(
                    title: 'New Lead',
                    subtitle: 'Add new lead',
                    icon: Icons.person_add,
                    color: AppTheme.primaryColor,
                    onTap: () => context.push('/leads/create'),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVisitingHistorySection() {
    return Consumer<VisitProvider>(
          builder: (context, visitProvider, child) {
            final totalVisitsCount = visitProvider.visits.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visiting History ($totalVisitsCount)',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => context.push('/visit/history'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
                if (visitProvider.isLoading)
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
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (visitProvider.visits.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: AppTheme.textSecondaryColor.withOpacity(0.5),
                        ),
                        SizedBox(
                          height: ResponsiveUtils.getResponsiveSpacing(context),
                        ),
                        Text(
                          'No visits yet',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                        ),
                        SizedBox(
                          height:
                              ResponsiveUtils.getResponsiveSpacing(context) *
                              0.5,
                        ),
                        Text(
                          'Your visit history will appear here',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: ResponsiveUtils.getResponsiveSpacing(context),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/visit/management'),
                          icon: const Icon(Icons.add),
                          label: const Text('Start First Visit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: visitProvider.visits
                        .take(3)
                        .map((visit) => _buildVisitHistoryCard(visit))
                        .toList(),
                  ),
              ],
            );
          },
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 700.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildVisitHistoryCard(visit) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
      ),
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        ),
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
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
            ),
            decoration: BoxDecoration(
              color: visit.isActive
                  ? AppTheme.warningColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 8),
              ),
            ),
            child: Icon(
              visit.isActive ? Icons.location_on : Icons.check_circle,
              color: visit.isActive
                  ? AppTheme.warningColor
                  : AppTheme.successColor,
              size: ResponsiveUtils.getResponsiveIconSize(context, 20),
            ),
          ),
          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context) * 0.75),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.clientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                Text(
                  _formatVisitDate(visit.visitTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                if (visit.visitingReason != null &&
                    visit.visitingReason!.isNotEmpty) ...[
                  SizedBox(
                    height:
                        ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                  ),
                  Text(
                    visit.visitingReason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
            ),
            decoration: BoxDecoration(
              color: visit.isActive
                  ? AppTheme.warningColor.withOpacity(0.1)
                  : AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 12),
              ),
            ),
            child: Text(
              visit.isActive ? 'Active' : 'Completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: visit.isActive
                    ? AppTheme.warningColor
                    : AppTheme.successColor,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCheckInTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
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
                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                ),
                Text(
                  'Return within 150 meters of the office within the next hour to stay checked in.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      12,
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

  // Build office status badge for welcome section (compact version)
  Widget _buildOfficeStatusBadge(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    final position = locationProvider.currentPosition;
    bool isInOffice;
    if (position != null) {
      isInOffice = LocationValidationService.isUserInOffice(position);
    } else {
      isInOffice = !locationProvider.isOutsideOfficeRadius;
    }

    final Color statusColor = isInOffice
        ? Colors.greenAccent.shade400
        : Colors.orangeAccent.shade400;
    final IconData statusIcon = isInOffice
        ? Icons.location_on
        : Icons.location_off;
    final String statusText = isInOffice ? 'In Office' : 'Out of Office';

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
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }

  Widget _buildDeveloperOfficeStatus(
    BuildContext context,
    LocationProvider locationProvider,
  ) {
    final position = locationProvider.currentPosition;
    final bool hasLocation = position != null;
    bool isInOffice;
    if (position != null) {
      isInOffice = LocationValidationService.isUserInOffice(position);
    } else {
      isInOffice = !locationProvider.isOutsideOfficeRadius;
    }
    final Color statusColor = isInOffice
        ? Colors.greenAccent.shade100
        : Colors.orangeAccent.shade100;
    final Color statusTextColor = isInOffice
        ? Colors.greenAccent.shade700
        : Colors.orangeAccent.shade700;
    final String statusLabel = isInOffice
        ? 'Office Range: In Range'
        : 'Office Range: Out of Range';

    final Duration countdownDuration =
        locationProvider.autoCheckoutRemaining ?? Duration.zero;
    final bool showTimer =
        locationProvider.isAutoCheckoutTimerActive &&
        countdownDuration.inSeconds > 0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context) * 0.75,
        vertical: ResponsiveUtils.getResponsiveSpacing(context) * 0.625,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 12),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(context) * 0.375,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInOffice ? Icons.verified : Icons.warning_amber_rounded,
                  color: statusTextColor,
                  size: ResponsiveUtils.getResponsiveIconSize(context, 16),
                ),
              ),
              SizedBox(
                width: ResponsiveUtils.getResponsiveSpacing(context) * 0.625,
              ),
              Expanded(
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: statusTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showTimer) ...[
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.375,
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: Colors.orange,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 14),
                  ),
                ),
                SizedBox(
                  width: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                ),
                Expanded(
                  child: Text(
                    'Auto check-out in ${_formatCountdown(countdownDuration)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade200,
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
          ],
          if (!hasLocation) ...[
            SizedBox(
              height: ResponsiveUtils.getResponsiveSpacing(context) * 0.375,
            ),
            Text(
              'Location not available. Please enable GPS.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatVisitDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(date.year, date.month, date.day);

    if (visitDate == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (visitDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildRecentActivity() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/visit/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            Container(
              padding: const EdgeInsets.all(20),
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
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context),
                  ),
                  Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  SizedBox(
                    height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
                  ),
                  Text(
                    'Your visit history will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0);
  }

  int _getTodayVisitsCount(List visits) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return visits.where((visit) {
      final visitDate = DateTime(
        visit.visitTime.year,
        visit.visitTime.month,
        visit.visitTime.day,
      );
      return visitDate.isAtSameMomentAs(today);
    }).length;
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

        // Get real attendance data from history provider
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
            // Sunday
            sundays.add(day);
          }
        }

        // Calculate working days (excluding Sundays)
        final workingDays = <int>[];
        for (int day = 1; day <= currentDay; day++) {
          final date = DateTime(now.year, now.month, day);
          if (date.weekday != 7) {
            // Not Sunday
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
                  // Header
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

                  // Stats Row
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

                  // Calendar Grid
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
                        // Calculate responsive day size based on available width
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
                            // Weekday headers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final day = entry.value;
                                    final isSunday =
                                        index == 6; // Last 'S' is Sunday

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
                            // Calendar days
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
                            // Color Legend
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
    // Use provided daySize or calculate responsive size
    final responsiveDaySize =
        daySize ?? ResponsiveUtils.getResponsiveIconSize(context, 36);
    final dayMargin = ResponsiveUtils.getResponsiveSpacing(context) * 0.125;

    List<Widget> rows = [];
    List<Widget> dayWidgets = [];

    // Add empty spaces for days before the first day of month
    // In Dart, weekday 1 = Monday, 7 = Sunday
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(
        SizedBox(width: responsiveDaySize, height: responsiveDaySize),
      );
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      // Calculate weekday for this date (1 = Monday, 7 = Sunday)
      final currentDate = DateTime(now.year, now.month, day);
      final weekday = currentDate.weekday;
      final isSunday = weekday == 7;

      Color? bgColor;
      Color? textColor = Colors.grey.shade800;
      bool isBold = false;
      String? attendanceStatus; // Track attendance status

      if (day == currentDay) {
        bgColor = AppTheme.primaryColor;
        textColor = Colors.white;
        isBold = true;
      } else if (isSunday) {
        // Sunday - Holiday (Red)
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
      } else if (presentDays.contains(day)) {
        // Check if it's a half day or full day
        final dayDetails = monthDetails
            .where((detail) => detail.checkInTime.day == day)
            .toList();
        if (dayDetails.isNotEmpty) {
          final detail = dayDetails.first;
          final workingHours = detail.duration.inMinutes / 60.0;

          // 7 hours 48 minutes = 7.8 hours
          const double thresholdHours = 7.8;

          if (workingHours < thresholdHours) {
            // Half day (less than 7 hours 48 minutes)
            bgColor = Colors.orange.shade100;
            textColor = Colors.orange.shade900;
            attendanceStatus = 'HD'; // Half Day indicator
          } else {
            // Full day (7 hours 48 minutes or more)
            bgColor = Colors.green.shade100;
            textColor = Colors.green.shade900;
            attendanceStatus = 'FD'; // Full Day indicator
          }
        } else {
          // Default present (if no details available)
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
              // Attendance status indicator
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

      // Create a new row after every 7 days
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

    // Add remaining days to the last row
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

    // Employee birthday data (in real app, fetch from API)
    final employees = [
      {'name': 'Saurabh', 'birthday': DateTime(now.year, 10, 15)},
      {'name': 'Urmish', 'birthday': DateTime(now.year, 10, 20)},
      {'name': 'Harsad', 'birthday': DateTime(now.year, 11, 5)},
      {'name': 'Pratik', 'birthday': DateTime(now.year, 12, 25)},
    ];

    // Calculate days until birthday and sort
    final upcomingBirthdays = employees.map((emp) {
      DateTime birthday = emp['birthday'] as DateTime;
      if (birthday.isBefore(now)) {
        // Birthday already passed this year, use next year
        birthday = DateTime(now.year + 1, birthday.month, birthday.day);
      }
      final daysUntil = birthday.difference(now).inDays;
      return {
        'name': emp['name'],
        'birthday': birthday,
        'daysUntil': daysUntil,
      };
    }).toList();

    // Sort by nearest birthday first
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
              // Header
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
              // Birthday List
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
                      // Avatar
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
                      // Name and Date
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
                      // Badge
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

  Widget _buildFlutterDeveloperContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Animation Section for Flutter Developers
        _buildWelcomeAnimationSection(),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),

        // Current Status Section with Timer (for developers)
        _buildCurrentStatus(),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),

        // Monthly Attendance Section (Below Welcome Animation)
        _buildMonthlyAttendanceCard(),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5),

        // Employee Birthday Section (Below Attendance)
        _buildEmployeeBirthdaySection(),
      ],
    );
  }

  Widget _buildWelcomeAnimationSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?.name ?? 'Developer';

        return Container(
              padding: ResponsiveUtils.getResponsivePadding(context),
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
                  // Welcome Text with Animation
                  Row(
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
                                              24,
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
                                  0.5,
                            ),

                            Text(
                                  'Good to see you, $userName! 👋',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize:
                                            ResponsiveUtils.getResponsiveFontSize(
                                              context,
                                              16,
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
                                  0.75,
                            ),

                            Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        ResponsiveUtils.getResponsiveSpacing(
                                          context,
                                        ) *
                                        0.75,
                                    vertical:
                                        ResponsiveUtils.getResponsiveSpacing(
                                          context,
                                        ) *
                                        0.375,
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
                                              16,
                                            ),
                                      ),
                                      Text(
                                        (user?.role ?? 'USER').toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1,
                                              fontSize:
                                                  ResponsiveUtils.getResponsiveFontSize(
                                                    context,
                                                    12,
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

                            // Office Status Indicator (only for developers)
                            SizedBox(
                              height:
                                  ResponsiveUtils.getResponsiveSpacing(
                                    context,
                                  ) *
                                  0.5,
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

                      // Animated Flutter Logo
                      Container(
                            width: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              80,
                            ),
                            height: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              80,
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
                                    60,
                                  ),
                                  height: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    60,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ).animate().scale(
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                ),

                                // Flutter icon with rotation
                                Icon(
                                  Icons.flutter_dash,
                                  color: Colors.white,
                                  size: ResponsiveUtils.getResponsiveIconSize(
                                    context,
                                    40,
                                  ),
                                ).animate().rotate(duration: 3000.ms),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 300.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                          ),
                    ],
                  ),

                  SizedBox(
                    height:
                        ResponsiveUtils.getResponsiveSpacing(context) * 1.25,
                  ),

                  // Animated Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Today',
                          'Ready to Code!',
                          Icons.today,
                          Colors.white.withOpacity(0.2),
                          600,
                        ),
                      ),
                      SizedBox(
                        width:
                            ResponsiveUtils.getResponsiveSpacing(context) *
                            0.75,
                      ),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          'Status',
                          'Online',
                          Icons.circle,
                          Colors.green.withOpacity(0.3),
                          800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 1000.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildAnimatedStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    int delay,
  ) {
    return Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 12),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ).animate().scale(duration: 500.ms, delay: delay.ms),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5,
              ),

              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
                ),
              ),

              SizedBox(
                height: ResponsiveUtils.getResponsiveSpacing(context) * 0.25,
              ),

              Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        14,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: (delay + 200).ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: delay.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      context.go('/login');
    }
  }
}
