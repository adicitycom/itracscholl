import 'package:flutter/material.dart';
import '../services/notification_manager.dart';

void showNotificationsDialog(
  BuildContext context,
  NotificationManager notificationManager,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Notifications'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              notificationManager.formattedUnreadCount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: notificationManager.notifications.isEmpty
            ? const Center(
                child: Text('No notifications yet'),
              )
            : ListView.separated(
                itemCount: notificationManager.notifications.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, idx) {
                  final notification = notificationManager.notifications[idx];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? Colors.grey
                          : Colors.blue,
                      child: Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.receivedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      notificationManager.markAsRead(notification.id);
                      showNotificationDetailDialog(context, notification);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        notificationManager.clearNotification(notification.id);
                        Navigator.pop(ctx);
                        showNotificationsDialog(context, notificationManager);
                      },
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (notificationManager.notifications.isNotEmpty)
          TextButton(
            onPressed: () {
              notificationManager.clearAllNotifications();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void showNotificationDetailDialog(
  BuildContext context,
  NotificationRecord notification,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(notification.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 12),
          Text(
            'Received: ${_formatTime(notification.receivedAt)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (notification.data.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Additional Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...notification.data.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _formatTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return dateTime.toString().split(' ')[0];
  }
}
