import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/visit_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../services/mock_data_service.dart';
import '../../widgets/custom_button.dart';

class MockDataTestScreen extends StatefulWidget {
  const MockDataTestScreen({super.key});

  @override
  State<MockDataTestScreen> createState() => _MockDataTestScreenState();
}

class _MockDataTestScreenState extends State<MockDataTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mock Data Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.storage, size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Mock Data Testing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test local storage functionality',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Auth Test
            _buildTestSection(
              'Real Sign-in API Test',
              'Test sign-in with real server',
              Icons.login,
              () => _testRealSignIn(),
            ),

            const SizedBox(height: 16),

            // Visit Test
            _buildTestSection(
              'Visit Management Test',
              'Test visit check-in/check-out',
              Icons.business,
              () => _testVisitManagement(),
            ),

            const SizedBox(height: 16),

            // API Test
            _buildTestSection(
              'Real Check-in API Test',
              'Test check-in with real API endpoint',
              Icons.api,
              () => _testRealApi(),
            ),

            const SizedBox(height: 16),

            // Check-out API Test
            _buildTestSection(
              'Real Check-out API Test',
              'Test check-out with real API endpoint',
              Icons.logout,
              () => _testRealCheckOut(),
            ),

            const SizedBox(height: 16),

            // Location Test
            _buildTestSection(
              'Location Tracking Test',
              'Test location logging',
              Icons.location_on,
              () => _testLocationTracking(),
            ),

            const SizedBox(height: 24),

            // Current User Info
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                          'Current User',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Name', authProvider.user!.name),
                        _buildInfoRow('Email', authProvider.user!.email),
                        _buildInfoRow('Role', authProvider.user!.role),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // Clear Data Button
            CustomButton(
              text: 'Clear All Mock Data',
              onPressed: _clearMockData,
              backgroundColor: AppTheme.errorColor,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testRealSignIn() async {
    final authProvider = context.read<AuthProvider>();

    try {
      // Test with real credentials
      final success = await authProvider.login(
        'info@extraaazpos.com',
        'Admin@2025',
      );

      if (success) {
        _showSnackBar(
          '✅ Sign-in successful! Check terminal for token and user details.',
          AppTheme.successColor,
        );
      } else {
        _showSnackBar(
          '❌ Sign-in failed: ${authProvider.error}',
          AppTheme.errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('❌ Sign-in Error: $e', AppTheme.errorColor);
    }
  }

  Future<void> _testVisitManagement() async {
    final visitProvider = context.read<VisitProvider>();

    try {
      // Test check-in with old format (working format)
      final success = await visitProvider.checkIn(
        latitude: 18.5204,
        longitude: 73.8567,
        clientName: "Test Client",
        notes: "Test visit from mock data screen",
        visitingReason: "Demo",
        visitingArea: "Test Area",
      );

      if (success) {
        _showSnackBar(
          'Check-in successful! Check terminal for API logs.',
          AppTheme.successColor,
        );
      } else {
        _showSnackBar(
          'Check-in failed: ${visitProvider.error}',
          AppTheme.errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppTheme.errorColor);
    }
  }

  Future<void> _testRealApi() async {
    final visitProvider = context.read<VisitProvider>();

    try {
      // Test real API check-in with exact format from your specification
      final success = await visitProvider.checkIn(
        userId: 3,
        userName: "Shubham",
        inLatitude: 18.5204,
        inLongitude: 73.8567,
        checkInTime: "2025-10-03 09:30",
        inAccuracy: 2,
        inBatteryPercent: 15,
        inNotes: "Demo meeting scheduled - Test from Test Screen",
      );

      if (success) {
        _showSnackBar(
          '✅ API Check-in successful! Check terminal for detailed logs.',
          AppTheme.successColor,
        );
      } else {
        _showSnackBar(
          '❌ API Check-in failed: ${visitProvider.error}',
          AppTheme.errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('❌ API Error: $e', AppTheme.errorColor);
    }
  }

  Future<void> _testRealCheckOut() async {
    final visitProvider = context.read<VisitProvider>();

    try {
      // Test real API check-out with exact format from your specification
      final success = await visitProvider.checkOut(
        visitId: '1', // Use existing visit ID
        userId: 3,
        outLatitude: 19.5204,
        outLongitude: 74.8567,
        checkOutTime: "2025-10-03 06:30",
        outAccuracy: 9,
        outBatteryPercent: 25,
        outNotes: "Task Completed dfdf - Test from Test Screen",
      );

      if (success) {
        _showSnackBar(
          '✅ API Check-out successful! Check terminal for detailed logs.',
          AppTheme.successColor,
        );
      } else {
        _showSnackBar(
          '❌ API Check-out failed: ${visitProvider.error}',
          AppTheme.errorColor,
        );
      }
    } catch (e) {
      _showSnackBar('❌ API Error: $e', AppTheme.errorColor);
    }
  }

  Future<void> _testLocationTracking() async {
    final locationProvider = context.read<LocationProvider>();

    try {
      // Test location logging
      final position = await locationProvider.getCurrentLocation();

      if (position != null) {
        _showSnackBar(
          'Location logged: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          AppTheme.successColor,
        );
      } else {
        _showSnackBar('Failed to get location', AppTheme.errorColor);
      }
    } catch (e) {
      _showSnackBar('Error: $e', AppTheme.errorColor);
    }
  }

  Future<void> _clearMockData() async {
    try {
      await MockDataService.clearAllMockData();
      _showSnackBar('Mock data cleared successfully!', AppTheme.successColor);
    } catch (e) {
      _showSnackBar('Error clearing data: $e', AppTheme.errorColor);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
