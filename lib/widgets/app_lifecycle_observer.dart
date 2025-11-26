import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/location_provider.dart';

/// Widget that observes app lifecycle and checks timer state when app resumes
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, check timer state
      final locationProvider = context.read<LocationProvider>();
      locationProvider.checkTimerOnResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

