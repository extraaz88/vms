import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vms/widgets/app_logo.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validation_utils.dart';
import '../../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoScale;
  late Animation<Offset> _formSlide;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    _startAnimations();
  }

  void _startAnimations() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _formController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = authProvider.user;
      // Check if user is telecaller (Field Sales)
      if (user?.isTelecaller ?? false) {
        context.go('/telecalling-dashboard');
      } else {
        context.go('/dashboard');
      }
    } else if (mounted) {
      // Show simple error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Invalid credentials. Please check and try again',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: ConstrainedBox(
              constraints: ResponsiveUtils.getResponsiveConstraints(
                context,
                ResponsiveUtils.getResponsiveFormWidth(context),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Logo Animation
                    _buildResponsiveLogo(context),

                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context),
                    ),

                    // Welcome Text
                    _buildResponsiveWelcomeText(context),

                    SizedBox(
                      height: ResponsiveUtils.getResponsiveSpacing(context) * 2,
                    ),

                    // Form Animation
                    _buildResponsiveForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLogo(BuildContext context) {
    return AnimatedBuilder(
      animation: _logoScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Container(
            width: ResponsiveUtils.getResponsiveLogoSize(context),
            height: ResponsiveUtils.getResponsiveLogoSize(context),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: ResponsiveUtils.getResponsiveElevation(
                    context,
                    20,
                  ),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: AppLogo(width: 50, height: 50),
            //Icon(
            //   Icons.location_on,
            //   size: ResponsiveUtils.getResponsiveIconSize(context, 50),
            //   color: Colors.white,
            // ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveWelcomeText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 32),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),

        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context) * 0.5),

        Text(
          'Sign in to continue',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryColor,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
      ],
    );
  }

  Widget _buildResponsiveForm(BuildContext context) {
    return AnimatedBuilder(
      animation: _formSlide,
      builder: (context, child) {
        return SlideTransition(
          position: _formSlide,
          child: FadeTransition(
            opacity: _formController,
            child: Column(
              children: [
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                  ),
                  validator: ValidationUtils.validateEmail,
                ),

                SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: ResponsiveUtils.getResponsiveIconSize(context, 20),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: ValidationUtils.validatePassword,
                ),

                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                ),

                // Login Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return SizedBox(
                      width: ResponsiveUtils.getResponsiveButtonWidth(context),
                      child: CustomButton(
                        text: 'Sign In',
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        isLoading: authProvider.isLoading,
                      ),
                    );
                  },
                ),

                SizedBox(
                  height: ResponsiveUtils.getResponsiveSpacing(context) * 1.5,
                ),

                // Forgot Password
                // TextButton(
                //   onPressed: () {
                //     // TODO: Implement forgot password
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(
                //         content: Text('Forgot password feature coming soon'),
                //       ),
                //     );
                //   },
                //   child: Text(
                //     'Forgot Password?',
                //     style: TextStyle(
                //       color: AppTheme.primaryColor,
                //       fontWeight: FontWeight.w500,
                //       fontSize: ResponsiveUtils.getResponsiveFontSize(
                //         context,
                //         14,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }
}
