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
import 'services/mock_data_service.dart';

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
      ],
      builder: (context, child) {
        // Connect LocationProvider with VisitProvider for auto checkout
        final locationProvider = context.read<LocationProvider>();
        final visitProvider = context.read<VisitProvider>();
        locationProvider.setVisitProvider(visitProvider);
        
        return child!;
      },
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'VMS - Field Visit Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}