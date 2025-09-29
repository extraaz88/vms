import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(),
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(user),
                      
                      const SizedBox(height: 24),
                      
                      // Profile Information
                      _buildProfileInformation(user),
                      
                      const SizedBox(height: 24),
                      
                      // Settings Section
                      _buildSettingsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Logout Button
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
              const CustomBottomNavigation(currentIndex: 3),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDarkColor],
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
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
            ),
            child: user.avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(46),
                    child: Image.network(
                      user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Email
          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: -0.2, end: 0);
  }

  Widget _buildProfileInformation(user) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildInfoRow(
            'Full Name',
            user.name,
            Icons.person_outline,
            AppTheme.primaryColor,
          ),
          
          _buildInfoRow(
            'Email Address',
            user.email,
            Icons.email_outlined,
            AppTheme.secondaryColor,
          ),
          
          if (user.phone != null)
            _buildInfoRow(
              'Phone Number',
              user.phone!,
              Icons.phone_outlined,
              AppTheme.successColor,
            ),
          
          _buildInfoRow(
            'Role',
            user.role,
            Icons.work_outline,
            AppTheme.accentColor,
          ),
          
          if (user.lastLoginAt != null)
            _buildInfoRow(
              'Last Login',
              _formatDateTime(user.lastLoginAt!),
              Icons.access_time,
              AppTheme.textSecondaryColor,
            ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 200.ms)
    .slideY(begin: 0.2, end: 0);
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          _buildSettingsItem(
            'Notifications',
            'Manage notification preferences',
            Icons.notifications_outlined,
            () => _showComingSoonDialog('Notifications'),
          ),
          
          _buildSettingsItem(
            'Privacy',
            'Manage privacy settings',
            Icons.privacy_tip_outlined,
            () => _showComingSoonDialog('Privacy'),
          ),
          
          _buildSettingsItem(
            'Location Settings',
            'Manage location permissions',
            Icons.location_on_outlined,
            () => _showLocationSettingsDialog(),
          ),
          
          _buildSettingsItem(
            'App Version',
            'Version 1.0.0',
            Icons.info_outline,
            () => _showAboutDialog(),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 400.ms)
    .slideY(begin: 0.2, end: 0);
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          return AlertDialog(
            title: const Text('Location Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto Checkout Settings'),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Auto Checkout on Location Off'),
                  subtitle: const Text('Automatically checkout when location is turned off'),
                  value: locationProvider.autoCheckoutEnabled,
                  onChanged: (value) {
                    locationProvider.setAutoCheckoutEnabled(value);
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'When enabled, the app will automatically checkout from active visits if:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                const Text('• Location permission is denied'),
                const Text('• Location service is disabled'),
                const Text('• GPS is turned off'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return CustomButton(
          text: 'Logout',
          onPressed: authProvider.isLoading ? null : _handleLogout,
          isLoading: authProvider.isLoading,
          width: double.infinity,
          backgroundColor: AppTheme.errorColor,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature'),
        content: Text('$feature feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'VMS - Field Visit Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('A comprehensive field visit tracking and journey monitoring application.'),
      ],
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
