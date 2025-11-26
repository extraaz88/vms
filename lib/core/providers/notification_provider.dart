import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/local_notification_service.dart';
import '../../utils/auth_helper.dart';

// Notification Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? time,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      time: DateTime.parse(json['time'] as String),
      isRead: json['isRead'] as bool? ?? false,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.system,
      ),
    );
  }
}

enum NotificationType {
  visit,
  lead,
  reminder,
  achievement,
  system,
  checkin,
  checkout,
}

class NotificationProvider with ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  static const String _storageKey = 'notifications_storage';

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _loadNotifications();
  }

  // Load notifications from storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_storageKey);

      if (notificationsJson != null) {
        final List<dynamic> decoded = json.decode(notificationsJson);
        _notifications.clear();
        _notifications.addAll(
          decoded.map(
            (item) => NotificationItem.fromJson(item as Map<String, dynamic>),
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading notifications: $e');
      }
    }
  }

  // Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = json.encode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString(_storageKey, notificationsJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving notifications: $e');
      }
    }
  }

  // Add a new notification
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    bool showSystemNotification = true,
  }) async {
    try {
      // Get logged-in user's name
      final user = await AuthHelper.getAuthenticatedUser();
      final userName = (user?['name']?.toString().trim() ?? '').isNotEmpty
          ? user!['name'].toString().trim()
          : 'User';

      // Create notification with user's name in message
      final notification = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: '$message - $userName',
        time: DateTime.now(),
        isRead: false,
        type: type,
      );

      _notifications.insert(0, notification);

      // Keep only last 100 notifications
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }

      await _saveNotifications();
      notifyListeners();

      // Show system notification if requested
      if (showSystemNotification) {
        await _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: '$message - $userName',
          payload: type.toString().split('.').last,
        );
      }

      if (kDebugMode) {
        print('✅ Notification added: $title - $userName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding notification: $e');
      }
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    await _saveNotifications();
    notifyListeners();
  }

  // Delete notification
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}
