import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import 'app_logo.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildMenuItems(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: user?.avatar != null
                    ? ClipOval(
                        child: Image.network(
                          user!.avatar!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(12),
                        child: AppLogo(
                          width: 56,
                          height: 56,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'User',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (user?.role ?? 'user').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 20),
          _buildMenuItem(context,
              icon: Icons.dashboard, title: 'Dashboard', route: '/dashboard'),
          _buildMenuItem(context,
              icon: Icons.people, title: 'Leads', route: '/leads'),
          // _buildMenuItem(context,
          //     icon: Icons.location_on,
          //     title: 'Visit Check-in',
          //     route: '/visits/checkin'),
          // _buildMenuItem(context,
          //     icon: Icons.location_off,
          //     title: 'Visit Check-out',
          //     route: '/visits/checkout'),
          _buildMenuItem(context,
              icon: Icons.history,
              title: 'Visit History',
              route: '/visit/history'),
          _buildMenuItem(context,
              icon: Icons.route,
              title: 'Journey Tracking',
              route: '/tracking/journey'),
          _buildMenuItem(context,
              icon: Icons.location_searching,
              title: 'Live Tracking',
              route: '/tracking/live'),
           _buildMenuItem(context,
               icon: Icons.person, title: 'Profile', route: '/profile'),
           _buildMenuItem(context,
               icon: Icons.access_time, title: 'Attendance', route: '/attendance'),
           const Divider(),
          _buildMenuItem(context,
              icon: Icons.bug_report, title: 'Mock Data Test', route: '/test'),
          _buildMenuItem(context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => _showHelpDialog(context)),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      String? route,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          context.push(route);
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(),
          OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'VMS App v1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Help & Support'),
        content: Text('Email: support@vms.com\nPhone: +91 98765 43210'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
