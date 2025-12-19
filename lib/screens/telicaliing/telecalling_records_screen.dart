import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'telecalling_add_record_screen.dart';
import 'telecalling_record_model.dart';

class TelecallingRecordsScreen extends StatefulWidget {
  const TelecallingRecordsScreen({super.key});

  @override
  State<TelecallingRecordsScreen> createState() =>
      _TelecallingRecordsScreenState();
}

class _TelecallingRecordsScreenState extends State<TelecallingRecordsScreen> {
  static const _storageKey = 'telecalling_records';

  final List<TelecallingRecord> _records = [];

  final List<String> _filters = ['All', 'Demo', 'Follow up', 'Closed'];
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Records'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _onAddPressed),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                spacing,
                spacing,
                spacing,
                spacing * 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(context),
                  SizedBox(height: spacing),
                  _buildFilterChips(context),
                  SizedBox(height: spacing),
                  ..._buildRecordCards(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3, // Records tab selected
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            // Dashboard
            context.go('/telecalling-dashboard');
            break;
          case 1:
            context.go('/telecalling-reports');
            break;
          case 2:
            // Check-in
            context.go('/checkin-checkout');
            break;
          case 3:
            // Already on Records
            break;
          case 4:
            // Profile
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

  Widget _buildSummaryHeader(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        spacing,
        spacing * 1.5,
        spacing,
        spacing * 1.5,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard(context, title: 'Overdue', count: 2),
              SizedBox(width: spacing),
              _buildSummaryCard(context, title: 'Due Today', count: 5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required int count,
  }) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(spacing),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.white),
                SizedBox(width: spacing * 0.5),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.75),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search records...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, 20),
          ),
          borderSide: BorderSide.none,
        ),
      ),
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

  List<Widget> _buildRecordCards(BuildContext context) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);

    final filtered = <MapEntry<int, TelecallingRecord>>[];
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      if (_selectedFilter == 'All' || r.status == _selectedFilter) {
        filtered.add(MapEntry(i, r));
      }
    }

    return filtered
        .map(
          (entry) => Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: _buildRecordCard(context, entry.value, entry.key),
          ),
        )
        .toList();
  }

  Widget _buildRecordCard(
    BuildContext context,
    TelecallingRecord record,
    int index,
  ) {
    final spacing = ResponsiveUtils.getResponsiveSpacing(context);
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      (record.leadName.isNotEmpty ? record.leadName[0] : 'N')
                          .toUpperCase(),
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.leadName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                      ),
                      SizedBox(height: spacing * 0.2),
                      Text(
                        record.status,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: record.status == 'Closed'
                              ? Colors.blue
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.5),
            // Product type + phone
            Text(
              '${record.productType}  •  ${record.phoneNumber}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            SizedBox(height: spacing * 0.25),
            // Location line
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: spacing * 0.25),
                Expanded(
                  child: Text(
                    record.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: spacing * 0.5),
                Text(
                  record.nextReminderDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                SizedBox(width: spacing),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: spacing * 0.5),
                Text(
                  record.time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.status == 'Closed'
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 14,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.status == 'Closed' ? 'Done' : 'Overdue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.call, color: AppTheme.primaryColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${record.phoneNumber}...'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                  onPressed: () => _onEditRecord(index, record),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.errorColor,
                  ),
                  onPressed: () => _onDeleteRecord(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddPressed() async {
    final newRecord = await Navigator.of(context).push<TelecallingRecord>(
      MaterialPageRoute(builder: (_) => const TelecallingAddRecordScreen()),
    );

    if (newRecord != null) {
      setState(() {
        _records.insert(0, newRecord);
      });
      await _saveRecords();
    }
  }

  Future<void> _onEditRecord(int index, TelecallingRecord record) async {
    final updated = await Navigator.of(context).push<TelecallingRecord>(
      MaterialPageRoute(
        builder: (_) => TelecallingAddRecordScreen(initialRecord: record),
      ),
    );

    if (updated != null) {
      setState(() {
        _records[index] = updated;
      });
      await _saveRecords();
    }
  }

  Future<void> _onDeleteRecord(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text(
          'Are you sure you want to delete this telecalling record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _records.removeAt(index);
      });
      await _saveRecords();
    }
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null && jsonStr.isNotEmpty) {
      final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
      setState(() {
        _records
          ..clear()
          ..addAll(
            list.whereType<Map<String, dynamic>>().map(
              TelecallingRecord.fromJson,
            ),
          );
      });
    } else {
      // Seed with some dummy data for first time
      setState(() {
        _records.addAll([
          TelecallingRecord(
            leadName: 'Mango lal',
            status: 'Demo',
            businessType: 'Hotel',
            productType: 'SPOS',
            location: 'Mumbai',
            phoneNumber: '9876543210',
            amount: '1500',
            remark: 'Schedule demo for POS machine',
            nextReminderDate: 'Dec 14, 2025',
            time: '02:00 PM',
          ),
          TelecallingRecord(
            leadName: 'Rahul Sharma',
            status: 'Follow up',
            businessType: 'Restaurant',
            productType: 'SPOS',
            location: 'Pune',
            phoneNumber: '9876501234',
            amount: '2500',
            remark: 'Call back for final confirmation',
            nextReminderDate: 'Dec 15, 2025',
            time: '11:30 AM',
          ),
          TelecallingRecord(
            leadName: 'Priya Traders',
            status: 'Closed',
            businessType: 'Retail',
            productType: 'Billing Software',
            location: 'Delhi',
            phoneNumber: '9988776655',
            amount: '5000',
            remark: 'Deal closed, installation pending',
            nextReminderDate: 'Dec 20, 2025',
            time: '04:00 PM',
          ),
        ]);
      });
      await _saveRecords();
    }
  }

  Future<void> _saveRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _records.map((r) => r.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(list));
  }
}
