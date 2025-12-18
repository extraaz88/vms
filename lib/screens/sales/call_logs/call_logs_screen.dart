import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vms/core/theme/app_theme.dart';
import 'package:vms/widgets/app_logo.dart';
import 'package:vms/widgets/custom_bottom_navigation.dart';
import 'package:vms/widgets/custom_drawer.dart';


class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(width: 24, height: 24),
            const SizedBox(width: 8),
            const Text('Call Logs'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              // Filter logic will be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Filter: $value'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Calls')),
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(
                value: 'This Month',
                child: Text('This Month'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.phone, size: 20)),
            Tab(text: 'Incoming', icon: Icon(Icons.call_received, size: 20)),
            Tab(text: 'Outgoing', icon: Icon(Icons.call_made, size: 20)),
            Tab(text: 'Missed', icon: Icon(Icons.call_missed, size: 20)),
          ],
        ),
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          _buildStatsSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCallLogsList('All'),
                _buildCallLogsList('Incoming'),
                _buildCallLogsList('Outgoing'),
                _buildCallLogsList('Missed'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigation(currentIndex: -1),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCallDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.phone, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.phone,
            label: 'Total',
            value: '248',
            color: Colors.white,
          ),
          _buildStatItem(
            icon: Icons.call_received,
            label: 'Incoming',
            value: '142',
            color: Colors.green.shade300,
          ),
          _buildStatItem(
            icon: Icons.call_made,
            label: 'Outgoing',
            value: '89',
            color: Colors.blue.shade300,
          ),
          _buildStatItem(
            icon: Icons.call_missed,
            label: 'Missed',
            value: '17',
            color: Colors.red.shade300,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCallLogsList(String type) {
    final calls = _getFilteredCalls(type);

    if (calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No $type Calls',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your call history will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: calls.length,
        itemBuilder: (context, index) {
          return _buildCallLogCard(calls[index], index);
        },
      ),
    );
  }

  Widget _buildCallLogCard(Map<String, dynamic> call, int index) {
    final callType = call['type'] as String;
    final isIncoming = callType == 'Incoming';
    final isOutgoing = callType == 'Outgoing';

    Color iconColor;
    IconData iconData;

    if (isIncoming) {
      iconColor = Colors.green;
      iconData = Icons.call_received;
    } else if (isOutgoing) {
      iconColor = Colors.blue;
      iconData = Icons.call_made;
    } else {
      iconColor = Colors.red;
      iconData = Icons.call_missed;
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            title: Text(
              call['name'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      call['phone'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      call['time'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (call['duration'] != null) ...[
                      Icon(Icons.timer, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        call['duration'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  onPressed: () => _makeCall(call['phone']),
                ),
                IconButton(
                  icon: Icon(
                    Icons.message,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  onPressed: () => _sendMessage(call['phone']),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .slideX(begin: 0.2, end: 0);
  }

  List<Map<String, dynamic>> _getFilteredCalls(String type) {
    // Sample call logs data
    final allCalls = [
      {
        'name': 'Rajesh Kumar',
        'phone': '+91 98765 43210',
        'type': 'Incoming',
        'time': '10:30 AM, Today',
        'duration': '5m 32s',
        'date': DateTime.now(),
      },
      {
        'name': 'Priya Sharma',
        'phone': '+91 98765 43211',
        'type': 'Outgoing',
        'time': '9:15 AM, Today',
        'duration': '3m 45s',
        'date': DateTime.now(),
      },
      {
        'name': 'Amit Singh',
        'phone': '+91 98765 43212',
        'type': 'Missed',
        'time': '8:00 AM, Today',
        'duration': null,
        'date': DateTime.now(),
      },
      {
        'name': 'Neha Gupta',
        'phone': '+91 98765 43213',
        'type': 'Incoming',
        'time': 'Yesterday, 6:45 PM',
        'duration': '12m 20s',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'name': 'Vikram Patel',
        'phone': '+91 98765 43214',
        'type': 'Outgoing',
        'time': 'Yesterday, 4:30 PM',
        'duration': '2m 15s',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'name': 'Sanjay Mehta',
        'phone': '+91 98765 43215',
        'type': 'Incoming',
        'time': 'Yesterday, 2:20 PM',
        'duration': '8m 50s',
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'name': 'Anita Desai',
        'phone': '+91 98765 43216',
        'type': 'Missed',
        'time': 'Yesterday, 11:00 AM',
        'duration': null,
        'date': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'name': 'Rahul Verma',
        'phone': '+91 98765 43217',
        'type': 'Outgoing',
        'time': '2 days ago, 5:15 PM',
        'duration': '6m 40s',
        'date': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'name': 'Pooja Reddy',
        'phone': '+91 98765 43218',
        'type': 'Incoming',
        'time': '2 days ago, 3:30 PM',
        'duration': '4m 25s',
        'date': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'name': 'Karan Malhotra',
        'phone': '+91 98765 43219',
        'type': 'Outgoing',
        'time': '3 days ago, 10:00 AM',
        'duration': '15m 10s',
        'date': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'name': 'Divya Iyer',
        'phone': '+91 98765 43220',
        'type': 'Incoming',
        'time': '3 days ago, 1:45 PM',
        'duration': '7m 30s',
        'date': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'name': 'Arjun Nair',
        'phone': '+91 98765 43221',
        'type': 'Missed',
        'time': '4 days ago, 9:20 AM',
        'duration': null,
        'date': DateTime.now().subtract(const Duration(days: 4)),
      },
    ];

    if (type == 'All') {
      return allCalls;
    } else {
      return allCalls.where((call) => call['type'] == type).toList();
    }
  }

  void _makeCall(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Calling $phone...')),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sendMessage(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.message, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Opening message to $phone...')),
          ],
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Call Logs'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter name or phone number',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon!'),
                ),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Make a Call'),
          ],
        ),
        content: TextField(
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.phone, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Initiating call...'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
