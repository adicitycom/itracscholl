import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class SchoolConfig {
  final String id;
  final String appName;
  final String applicationId;
  final String websiteUrl;
  final String allowedDomain;
  final Color themeColor;

  SchoolConfig({
    required this.id,
    required this.appName,
    required this.applicationId,
    required this.websiteUrl,
    required this.allowedDomain,
    required this.themeColor,
  });

  factory SchoolConfig.fromJson(Map<String, dynamic> json) {
    return SchoolConfig(
      id: json['id'],
      appName: json['appName'],
      applicationId: json['applicationId'],
      websiteUrl: json['websiteUrl'],
      allowedDomain: json['allowedDomain'],
      themeColor: _parseColor(json['themeColor'] ?? '#1565C0'),
    );
  }

  static Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

/// SCHOOL_ID diisi lewat --dart-define=SCHOOL_ID=<id> saat build
/// (harus sama persis dengan salah satu "id" di schools.json).
/// Kalau tidak diisi (misal waktu `flutter run` biasa tanpa flavor),
/// default ke sekolah pertama di schools.json supaya tetap bisa jalan.
const String _kSchoolIdFromBuild = String.fromEnvironment('SCHOOL_ID');

Future<SchoolConfig> loadCurrentSchoolConfig() async {
  final raw = await rootBundle.loadString('schools/schools.json');
  final List<dynamic> list = jsonDecode(raw);

  if (_kSchoolIdFromBuild.isNotEmpty) {
    final match = list.firstWhere(
      (s) => s['id'] == _kSchoolIdFromBuild,
      orElse: () => null,
    );
    if (match != null) return SchoolConfig.fromJson(match);
  }

  // Fallback: sekolah pertama di daftar (dev/testing tanpa --dart-define).
  return SchoolConfig.fromJson(list.first);
}
