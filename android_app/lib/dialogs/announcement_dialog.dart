import 'package:flutter/material.dart';
import '../services/announcement_manager.dart';

void showAnnouncementsDialog(
  BuildContext context,
  AnnouncementManager announcementManager,
  String schoolId,
) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Announcements'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              announcementManager.getUnreadCount(schoolId: schoolId).toString(),
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
        child: _buildAnnouncementsList(context, announcementManager, schoolId),
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

Widget _buildAnnouncementsList(
  BuildContext context,
  AnnouncementManager announcementManager,
  String schoolId,
) {
  final announcements = announcementManager.getAnnouncements(schoolId: schoolId);

  if (announcements.isEmpty) {
    return const Center(child: Text('No announcements'));
  }

  return ListView.separated(
    itemCount: announcements.length,
    separatorBuilder: (_, __) => const Divider(),
    itemBuilder: (_, idx) {
      final announcement = announcements[idx];
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: announcement.isRead ? Colors.grey : Colors.blue,
          child: Icon(
            Icons.campaign,
            color: Colors.white,
            size: 18,
          ),
        ),
        title: Text(
          announcement.title,
          style: TextStyle(
            fontWeight: announcement.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              announcement.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(announcement.postedAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          announcementManager.markAsRead(announcement.id);
          if (announcement.actionUrl != null) {
            // TODO: Handle action URL (deep link)
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            announcementManager.deleteAnnouncement(announcement.id);
            Navigator.pop(context);
            showAnnouncementsDialog(context, announcementManager, schoolId);
          },
        ),
      );
    },
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
