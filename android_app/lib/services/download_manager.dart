import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadRecord {
  final String id;
  final String url;
  final String fileName;
  final DateTime downloadedAt;
  final String? schoolId;

  DownloadRecord({
    required this.id,
    required this.url,
    required this.fileName,
    required this.downloadedAt,
    this.schoolId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'fileName': fileName,
    'downloadedAt': downloadedAt.toIso8601String(),
    'schoolId': schoolId,
  };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) => DownloadRecord(
    id: json['id'] as String,
    url: json['url'] as String,
    fileName: json['fileName'] as String,
    downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    schoolId: json['schoolId'] as String?,
  );

  String get displayName {
    final name = fileName.split('/').last;
    final withoutExtension = name.replaceAll(RegExp(r'\.\w+$'), '');
    return withoutExtension.isEmpty ? fileName : withoutExtension;
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(downloadedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day ago';
    } else {
      return downloadedAt.toString().split(' ')[0];
    }
  }
}

class DownloadManager {
  static const String STORAGE_KEY = 'download_history';
  static const int MAX_HISTORY = 50;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('[DownloadManager] Initialized');
  }

  Future<void> addDownload({
    required String url,
    required String fileName,
    String? schoolId,
  }) async {
    try {
      final record = DownloadRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        fileName: fileName,
        downloadedAt: DateTime.now(),
        schoolId: schoolId,
      );

      final history = await getHistory();
      history.insert(0, record);

      // Keep only recent downloads
      if (history.length > MAX_HISTORY) {
        history.removeRange(MAX_HISTORY, history.length);
      }

      final jsonList = history.map((r) => r.toJson()).toList();
      await _prefs?.setString(STORAGE_KEY, jsonEncode(jsonList));

      print('[DownloadManager] Download added: ${record.fileName}');
    } catch (e) {
      print('[DownloadManager] Error adding download: $e');
    }
  }

  Future<List<DownloadRecord>> getHistory({String? schoolId}) async {
    try {
      final jsonString = _prefs?.getString(STORAGE_KEY);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final history = jsonList
          .map((json) => DownloadRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by schoolId if provided
      if (schoolId != null) {
        return history.where((r) => r.schoolId == schoolId).toList();
      }

      return history;
    } catch (e) {
      print('[DownloadManager] Error getting history: $e');
      return [];
    }
  }

  Future<void> clearHistory({String? schoolId}) async {
    try {
      if (schoolId == null) {
        await _prefs?.remove(STORAGE_KEY);
        print('[DownloadManager] Entire history cleared');
      } else {
        final history = await getHistory();
        history.removeWhere((r) => r.schoolId == schoolId);

        if (history.isEmpty) {
          await _prefs?.remove(STORAGE_KEY);
        } else {
          final jsonList = history.map((r) => r.toJson()).toList();
          await _prefs?.setString(STORAGE_KEY, jsonEncode(jsonList));
        }
        print('[DownloadManager] History cleared for school: $schoolId');
      }
    } catch (e) {
      print('[DownloadManager] Error clearing history: $e');
    }
  }

  Future<void> removeDownload(String id) async {
    try {
      final history = await getHistory();
      history.removeWhere((r) => r.id == id);

      if (history.isEmpty) {
        await _prefs?.remove(STORAGE_KEY);
      } else {
        final jsonList = history.map((r) => r.toJson()).toList();
        await _prefs?.setString(STORAGE_KEY, jsonEncode(jsonList));
      }
      print('[DownloadManager] Download removed: $id');
    } catch (e) {
      print('[DownloadManager] Error removing download: $e');
    }
  }
}
