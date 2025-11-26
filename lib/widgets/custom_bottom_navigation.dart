import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/theme/app_theme.dart';
import '../utils/responsive_utils.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final bool isCheckedIn;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    this.isCheckedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final isFlutterDeveloper = user?.isFlutterDeveloper ?? false;

        //-------------bottom bar based on roles----------------------// 
        final List<BottomNavigationBarItem> items = [ 
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard_rounded,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            activeIcon: Icon(
              Icons.dashboard_rounded,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            label: 'Dashboard',
          ),
         
          if (isFlutterDeveloper)
            BottomNavigationBarItem(
              icon: Icon(
                Icons.event_note_outlined,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
              activeIcon: Icon(
                Icons.event_note,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
              label: 'Leave',
            )
          else
            BottomNavigationBarItem(
              icon: Icon(
                Icons.location_on_outlined,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
                color: !isCheckedIn ? Colors.grey.withOpacity(0.4) : null,
              ),
              activeIcon: Icon(
                Icons.location_on_rounded,
                size: ResponsiveUtils.getResponsiveIconSize(context, 24),
              ),
              label: 'VMS',
            ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.login_outlined,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            activeIcon: Icon(
              Icons.login_rounded,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            label: 'Check-in',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline_rounded,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            activeIcon: Icon(
              Icons.person_rounded,
              size: ResponsiveUtils.getResponsiveIconSize(context, 24),
            ),
            label: 'Profile',
          ),
        ];

        return BottomNavigationBar(
          currentIndex: currentIndex >= 0 && currentIndex < items.length
              ? currentIndex
              : 0,
          onTap: (index) {
            String route;
            bool isDisabled = false;

            switch (index) {
              case 0:
                route = '/dashboard';
                break;
              case 1:
                if (isFlutterDeveloper) {
                  route = '/leave/application';
                } else {
                  route = '/visit/management';
                  isDisabled = !isCheckedIn;
                }
                break;
              case 2:
                route = '/checkin-checkout';
                break;
              case 3:
                route = '/profile';
                break;
              default:
                route = '/dashboard';
            }

            if (isDisabled) {
              _showDisabledMessage(context, 'Please check in first');
            } else if (currentIndex != index) {
              context.go(route);
            }
          },
          type: BottomNavigationBarType.fixed,
          items: items,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
          unselectedFontSize: ResponsiveUtils.getResponsiveFontSize(
            context,
            11,
          ),
          iconSize: ResponsiveUtils.getResponsiveIconSize(context, 24),
          elevation: ResponsiveUtils.getResponsiveElevation(context, 8),
          backgroundColor: Colors.white,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 12),
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 11),
          ),
        );
      },
    );
  }

  void _showDisabledMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          ),
        ),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 8),
          ),
        ),
        action: SnackBarAction(
          label: 'Check In',
          textColor: Colors.white,
          onPressed: () {
            context.go('/checkin-checkout');
          },
        ),
      ),
    );
  }
}
