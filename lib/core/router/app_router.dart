import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../screens/visits/visit_history_screen.dart';
import '../../screens/visits/visit_management_screen.dart';
import '../../screens/visits/visit_details_screen.dart';
import '../../screens/checkin_checkout/checkin_checkout_screen.dart';
import '../../screens/tracking/journey_tracking_screen.dart';
import '../../screens/tracking/live_tracking_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/test/mock_data_test_screen.dart';
import '../../screens/leads/lead_list_screen.dart';
import '../../screens/leads/lead_create_screen.dart';
import '../../screens/leads/lead_details_screen.dart';
import '../../screens/attendance/attendance_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = authProvider.isLoggedIn;
      
      // Skip redirect for splash screen
      if (state.uri.path == '/splash') {
        return null;
      }
      
      // Redirect to login if not authenticated
      if (!isLoggedIn && state.uri.path != '/login') {
        return '/login';
      }
      
      // Redirect to dashboard if authenticated and on login page
      if (isLoggedIn && state.uri.path == '/login') {
        return '/dashboard';
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Visit Management Routes
      GoRoute(
        path: '/visit/management',
        builder: (context, state) => const VisitManagementScreen(),
      ),
      GoRoute(
        path: '/visit/details/:visitId',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return VisitDetailsScreen(visitId: visitId);
        },
      ),
   
      GoRoute(
        path: '/visit/history',
        builder: (context, state) => const VisitHistoryScreen(),
      ),
      GoRoute(
        path: '/checkin-checkout',
        builder: (context, state) => const CheckinCheckoutScreen(),
      ),
      
      // Tracking Routes
      GoRoute(
        path: '/tracking/journey',
        builder: (context, state) => const JourneyTrackingScreen(),
      ),
      GoRoute(
        path: '/tracking/live',
        builder: (context, state) => const LiveTrackingScreen(),
      ),
      
      // Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Test Route
        GoRoute(
          path: '/test',
          builder: (context, state) => const MockDataTestScreen(),
        ),
        GoRoute(
          path: '/leads',
          builder: (context, state) => const LeadListScreen(),
        ),
        GoRoute(
          path: '/leads/create',
          builder: (context, state) => const LeadCreateScreen(),
        ),
        GoRoute(
          path: '/leads/:leadId',
          builder: (context, state) {
            final leadId = state.pathParameters['leadId']!;
            return LeadDetailsScreen(leadId: leadId);
          },
        ),
        
        // Attendance Route
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendanceScreen(),
        ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}
