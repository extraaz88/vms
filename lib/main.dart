import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/visit_provider.dart';
import 'core/providers/lead_provider.dart';
import 'core/providers/target_provider.dart';
import 'core/providers/checkin_checkout_history_provider.dart';
import 'core/providers/leave_provider.dart';
import 'core/providers/notification_provider.dart';
import 'services/mock_data_service.dart';
import 'services/local_notification_service.dart';
import 'services/checkin_reminder_service.dart';
import 'widgets/app_lifecycle_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Mock Data
  await MockDataService.initializeMockData();
  // Clear any existing dummy visits and locations (keep user data)
  await MockDataService.clearVisitsAndLocations();
  // Ensure a user is logged in for visit creation
  await MockDataService.ensureUserLoggedIn();

  // Initialize Local Notifications
  await LocalNotificationService().initialize();

  // Initialize Check-in Reminder Service
  await CheckInReminderService().initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(VMSApp(prefs: prefs));
}

class VMSApp extends StatelessWidget {
  final SharedPreferences prefs;

  const VMSApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(prefs)),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
        ChangeNotifierProvider(create: (_) => TargetProvider()),
        ChangeNotifierProvider(create: (_) => CheckInCheckOutHistoryProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      builder: (context, child) {
        // Connect providers
        final locationProvider = context.read<LocationProvider>();
        final visitProvider = context.read<VisitProvider>();
        final authProvider = context.read<AuthProvider>();

        // Connect LocationProvider with VisitProvider for auto checkout
        locationProvider.setVisitProvider(visitProvider);

        // Connect AuthProvider with LocationProvider for user updates
        authProvider.setLocationProvider(locationProvider);

        // Connect LeadProvider with NotificationProvider for notifications
        final leadProvider = context.read<LeadProvider>();
        final notificationProvider = context.read<NotificationProvider>();
        leadProvider.setNotificationProvider(notificationProvider);

        // Initialize location and start periodic logging when app opens
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Wait for auth to be initialized
          await authProvider.initializeAuth();

          // Set current user in location provider for role-based checks
          locationProvider.setCurrentUser(authProvider.user);

          await locationProvider.initializeLocation();
          // Start periodic location logging (every 2 seconds)
          // Will be skipped if user is Flutter Developer
          locationProvider.startPeriodicLocationLogging();

          // Check and show reminder if needed
          await CheckInReminderService().checkAndShowReminder();
        });

        return child!;
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return AppLifecycleObserver(
            child: MaterialApp.router(
              title: 'VMS - Field Visit Tracker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
