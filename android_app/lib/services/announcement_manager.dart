import 'package:shared_preferences/shared_preferences.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime postedAt;
  final String schoolId;
  final String? actionUrl;
  bool isRead;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.postedAt,
    required this.schoolId,
    this.actionUrl,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'postedAt': postedAt.toIso8601String(),
    'schoolId': schoolId,
    'actionUrl': actionUrl,
    'isRead': isRead,
  };

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    postedAt: DateTime.parse(json['postedAt'] as String),
    schoolId: json['schoolId'] as String,
    actionUrl: json['actionUrl'] as String?,
    isRead: json['isRead'] as bool? ?? false,
  );
}

class AnnouncementManager {
  static const String ANNOUNCEMENTS_KEY = 'announcements';
  static const int MAX_ANNOUNCEMENTS = 50;

  SharedPreferences? _prefs;
  List<Announcement> _announcements = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('[AnnouncementManager] Initialized');
  }

  void addAnnouncement(Announcement announcement) {
    try {
      _announcements.insert(0, announcement);
      if (_announcements.length > MAX_ANNOUNCEMENTS) {
        _announcements = _announcements.sublist(0, MAX_ANNOUNCEMENTS);
      }
      print('[AnnouncementManager] Added: ${announcement.title}');
    } catch (e) {
      print('[AnnouncementManager] Error adding announcement: $e');
    }
  }

  List<Announcement> getAnnouncements({String? schoolId}) {
    if (schoolId == null) return _announcements;
    return _announcements.where((a) => a.schoolId == schoolId).toList();
  }

  int getUnreadCount({String? schoolId}) {
    final list = getAnnouncements(schoolId: schoolId);
    return list.where((a) => !a.isRead).length;
  }

  void markAsRead(String announcementId) {
    try {
      final index = _announcements.indexWhere((a) => a.id == announcementId);
      if (index >= 0) {
        _announcements[index].isRead = true;
        print('[AnnouncementManager] Marked as read: $announcementId');
      }
    } catch (e) {
      print('[AnnouncementManager] Error marking as read: $e');
    }
  }

  void deleteAnnouncement(String announcementId) {
    try {
      _announcements.removeWhere((a) => a.id == announcementId);
      print('[AnnouncementManager] Deleted: $announcementId');
    } catch (e) {
      print('[AnnouncementManager] Error deleting: $e');
    }
  }

  void clearAnnouncements({String? schoolId}) {
    try {
      if (schoolId != null) {
        _announcements.removeWhere((a) => a.schoolId == schoolId);
      } else {
        _announcements.clear();
      }
      print('[AnnouncementManager] Cleared');
    } catch (e) {
      print('[AnnouncementManager] Error clearing: $e');
    }
  }
}
