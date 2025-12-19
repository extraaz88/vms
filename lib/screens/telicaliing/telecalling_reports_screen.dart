import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'telecalling_add_report_screen.dart';
import 'telecalling_report_model.dart';

class TelecallingReportsScreen extends StatefulWidget {
  const TelecallingReportsScreen({super.key});

  @override
  State<TelecallingReportsScreen> createState() =>
      _TelecallingReportsScreenState();
}

class _TelecallingReportsScreenState extends State<TelecallingReportsScreen> {
  static const _storageKey = 'telecalling_daily_reports';

  final List<TelecallingDailyReport> _reports = [];
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
  ];
  String _selectedFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    final filteredReports = _getFilteredReports();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Calling Reports'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/telecalling-dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddReport,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: spacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            child: _buildSearchField(context),
          ),
          SizedBox(height: spacing),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            child: _buildFilterChips(context),
          ),
          SizedBox(height: spacing),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                spacing,
                0,
                spacing,
                spacing * 2,
              ),
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: _buildReportCard(context, report),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1, // Reports tab selected
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/telecalling-dashboard');
            break;
          case 1:
            break;
          case 2:
            context.go('/checkin-checkout');
            break;
          case 3:
            context.go('/telecalling-records');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.login_outlined),
          activeIcon: Icon(Icons.login),
          label: 'Check-in',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Records',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search by date...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 20),
          ),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: spacing * 0.75),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
            ),
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    TelecallingDailyReport report,
  ) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    final dateText = DateFormat('MMM dd, yyyy').format(report.date);
    final percent = report.successPercent;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: spacing * 0.5),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.75),
            Row(
              children: [
                _buildMetricBox(
                  context,
                  title: 'Total Calls',
                  value: report.totalCalls.toString(),
                ),
                SizedBox(width: spacing * 0.5),
                _buildMetricBox(
                  context,
                  title: 'Ringing',
                  value: report.ringing.toString(),
                  valueColor: Colors.green,
                ),
                SizedBox(width: spacing * 0.5),
                _buildMetricBox(
                  context,
                  title: 'Not Connected',
                  value: report.notConnected.toString(),
                  valueColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    Color? valueColor,
  }) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(spacing * 0.75),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            SizedBox(height: spacing * 0.25),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor ?? AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<TelecallingDailyReport> _getFilteredReports() {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    DateTime? start;
    switch (_selectedFilter) {
      case 'Today':
        start = startOfToday;
        break;
      case 'This Week':
        start = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        start = null;
    }

    return _reports.where((r) {
      if (start != null && r.date.isBefore(start)) return false;
      if (query.isNotEmpty) {
        final dateStr = DateFormat('yyyy-MM-dd').format(r.date).toLowerCase();
        if (!dateStr.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _onAddReport() async {
    final newReport = await Navigator.of(context).push<TelecallingDailyReport>(
      MaterialPageRoute(
        builder: (_) => const TelecallingAddReportScreen(),
      ),
    );

    if (newReport != null) {
      setState(() {
        _reports.add(newReport);
      });
      await _saveReports();
    }
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      setState(() {
        _reports
          ..clear()
          ..addAll(
            list
                .whereType<Map<String, dynamic>>()
                .map(TelecallingDailyReport.fromJson),
          );
      });
    }
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _reports.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(list));
  }
}


