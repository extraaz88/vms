import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.dashboard_rounded,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/dashboard',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on_rounded,
                label: 'VMS',
                route: '/visit/management',
                isDisabled: !isCheckedIn,
                disabledMessage: 'Please check in first',
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.login_outlined,
                activeIcon: Icons.login_rounded,
                label: 'Check-in/out',
                route: '/checkin-checkout',
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                route: '/profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    bool isDisabled = false,
    String? disabledMessage,
  }) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (!isActive && !isDisabled) {
          context.go(route);
        } else if (isDisabled && disabledMessage != null) {
          _showDisabledMessage(context, disabledMessage);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : isDisabled
                  ? Colors.grey.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppTheme.primaryColor
                    : isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive 
                    ? Colors.white
                    : isDisabled
                        ? Colors.grey.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isActive 
                    ? AppTheme.primaryColor
                    : isDisabled
                        ? Colors.grey.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.6),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisabledMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
