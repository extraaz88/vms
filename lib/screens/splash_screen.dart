import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../utils/responsive_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();

    // Start text animation after a delay
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();

    // Initialize auth and navigate
    await Future.delayed(const Duration(milliseconds: 2000));
    await _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeAuth();

    if (mounted) {
      if (authProvider.isLoggedIn) {
        context.go('/dashboard');
      } else {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Animation
                    AnimatedBuilder(
                      animation: _logoScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              120,
                            ),
                            height: ResponsiveUtils.getResponsiveIconSize(
                              context,
                              120,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.getResponsiveBorderRadius(
                                  context,
                                  24,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: ResponsiveUtils.getResponsivePadding(
                                context,
                              ),
                              child: AppLogo(
                                width: ResponsiveUtils.getResponsiveIconSize(
                                  context,
                                  88,
                                ),
                                height: ResponsiveUtils.getResponsiveIconSize(
                                  context,
                                  88,
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 2.5,
                    ),

                    // App Name Animation
                    AnimatedBuilder(
                      animation: _textOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'VMS',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            48,
                                          ),
                                    ),
                              ),
                              SizedBox(
                                height:
                                    ResponsiveUtils.getResponsiveSpacing(
                                      context,
                                    ) *
                                    0.5,
                              ),
                              Text(
                                'Field Visit Tracker',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w300,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            20,
                                          ),
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(
                      height:
                          ResponsiveUtils.getResponsiveSpacing(context) * 3.75,
                    ),

                    // Loading Animation
                    AnimatedBuilder(
                      animation: _textOpacity,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                              SizedBox(
                                height: ResponsiveUtils.getResponsiveSpacing(
                                  context,
                                ),
                              ),
                              Text(
                                'Initializing...',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontSize:
                                          ResponsiveUtils.getResponsiveFontSize(
                                            context,
                                            14,
                                          ),
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Info
              AnimatedBuilder(
                animation: _textOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Padding(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      child: Column(
                        children: [
                          Text(
                            'Track • Monitor • Manage',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white60,
                                  letterSpacing: 1,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        12,
                                      ),
                                ),
                          ),
                          SizedBox(
                            height:
                                ResponsiveUtils.getResponsiveSpacing(context) *
                                0.5,
                          ),
                          Text(
                            'Version 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white54,
                                  fontSize:
                                      ResponsiveUtils.getResponsiveFontSize(
                                        context,
                                        12,
                                      ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
