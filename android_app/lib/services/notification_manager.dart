import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationRecord {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final Map<String, dynamic> data;
  bool isRead;

  NotificationRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.data,
    this.isRead = false,
  });
}

class NotificationManager {
  static const int MAX_NOTIFICATIONS = 50;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  List<NotificationRecord> _notifications = [];

  VoidCallback? onNotificationReceived;
  ValueChanged<RemoteMessage>? onMessageOpen;

  List<NotificationRecord> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true,
      );

      print('[NotificationManager] Permission status: ${settings.authorizationStatus}');

      // Get FCM token
      final token = await _messaging.getToken();
      print('[NotificationManager] FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message);
      });

      // Handle message open (background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('[NotificationManager] Message opened: ${message.messageId}');
        onMessageOpen?.call(message);
      });

      print('[NotificationManager] Initialized');
    } catch (e) {
      print('[NotificationManager] Error during initialization: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    try {
      print('[NotificationManager] Message received: ${message.messageId}');
      print('[NotificationManager] Title: ${message.notification?.title}');
      print('[NotificationManager] Body: ${message.notification?.body}');

      final record = NotificationRecord(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
        data: message.data,
      );

      _notifications.insert(0, record);

      // Keep only recent notifications
      if (_notifications.length > MAX_NOTIFICATIONS) {
        _notifications = _notifications.sublist(0, MAX_NOTIFICATIONS);
      }

      onNotificationReceived?.call();
    } catch (e) {
      print('[NotificationManager] Error handling message: $e');
    }
  }

  void markAsRead(String notificationId) {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        _notifications[index].isRead = true;
        print('[NotificationManager] Marked as read: $notificationId');
      }
    } catch (e) {
      print('[NotificationManager] Error marking as read: $e');
    }
  }

  void clearNotification(String notificationId) {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      print('[NotificationManager] Cleared: $notificationId');
    } catch (e) {
      print('[NotificationManager] Error clearing notification: $e');
    }
  }

  void clearAllNotifications() {
    try {
      _notifications.clear();
      print('[NotificationManager] All notifications cleared');
    } catch (e) {
      print('[NotificationManager] Error clearing all: $e');
    }
  }

  String get formattedUnreadCount {
    final count = unreadCount;
    return count > 9 ? '9+' : count.toString();
  }
}
