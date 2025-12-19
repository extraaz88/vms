import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/target_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// Telecalling Dashboard Screen
/// UI is inspired by the provided design:
/// - Top green target card (monthly & daily targets)
/// - "Today's Status" section with Checked In & Records cards
/// - Bottom navigation where Check-in and Profile use the same
///   working screens that developers currently use.
class TelecallingDashboardScreen extends StatefulWidget {
  const TelecallingDashboardScreen({super.key});

  @override
  State<TelecallingDashboardScreen> createState() =>
      _TelecallingDashboardScreenState();
}

class _TelecallingDashboardScreenState
    extends State<TelecallingDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTargets();
    });
  }

  Future<void> _initializeTargets() async {
    final authProvider = context.read<AuthProvider>();
    final targetProvider = context.read<TargetProvider>();

    final userId = authProvider.user?.id ?? '1';
    await targetProvider.initializeTargets();
    await targetProvider.fetchLeadCountFromAPI(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Drawer removed for telecaller users
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // Menu button removed for telecaller users
        title: const Text('Dashboard'),
        centerTitle: false,
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
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: ResponsiveUtils.getResponsiveSpacing(context),
          right: ResponsiveUtils.getResponsiveSpacing(context),
          top: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
          bottom: ResponsiveUtils.getResponsiveSpacing(context) * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTargetCard(context),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 2),
            _buildTodayStatusTitle(context),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            _buildCheckedInCard(context),
            SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
            _buildRecordsCard(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildTargetCard(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return Consumer<TargetProvider>(
      builder: (context, targetProvider, child) {
        final isLoading = targetProvider.isLoading;
        final monthlyTarget = targetProvider.monthlyTargetAmount;
        final dailyTarget = targetProvider.dailyTargets;
        final completedAmount =
            (monthlyTarget * targetProvider.progressPercentage);

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacing * 1.2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, 20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.25),
                blurRadius: 16,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly target amount',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  15,
                                ),
                              ),
                        ),
                        SizedBox(height: spacing * 0.25),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : '₹ ${monthlyTarget.toStringAsFixed(0)}',
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
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: spacing * 4,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: spacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Calls Target',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        15,
                                      ),
                                ),
                          ),
                          SizedBox(height: spacing * 0.25),
                          Text(
                            isLoading ? '---' : dailyTarget.toString(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        24,
                                      ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing * 1.5),
              Text(
                isLoading
                    ? 'Fetching target from server...'
                    : '₹${completedAmount.toStringAsFixed(0)} Completed',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
              ),
              SizedBox(height: spacing * 0.75),
              _buildProgressBar(
                context,
                progress: isLoading ? 0 : targetProvider.progressPercentage,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, {double progress = 0.0}) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        // Slider thumb
        Positioned(
          left:
              (MediaQuery.of(context).size.width - (spacing * 2)) *
                  progress.clamp(0.0, 1.0) -
              6,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayStatusTitle(BuildContext context) {
    return Text(
      "Today's Status",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
      ),
    );
  }

  Widget _buildCheckedInCard(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Container(
      padding: EdgeInsets.all(spacing),
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
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
              size: ResponsiveUtils.getResponsiveIconSize(context, 32),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checked In',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      18,
                    ),
                  ),
                ),
                SizedBox(height: spacing * 0.25),
                Text(
                  'Ready to start your day',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Active',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsCard(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Container(
      padding: EdgeInsets.all(spacing),
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
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: ResponsiveUtils.getResponsiveIconSize(context, 32),
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Records',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      18,
                    ),
                  ),
                ),
                SizedBox(height: spacing * 0.25),
                Text(
                  'Track and manage records',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '5',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });

        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            // Reports
            context.go('/telecalling-reports');
            break;
          case 2:
            // Check-in - use the same working screen as developers
            context.go('/checkin-checkout');
            break;
          case 3:
            // Records - navigate via router
            context.go('/telecalling-records');
            break;
          case 4:
            // Profile - use the same working screen as developers
            context.go('/profile');
            break;
          default:
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.login_outlined),
          activeIcon: Icon(Icons.login),
          label: 'Check-in',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Records',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
