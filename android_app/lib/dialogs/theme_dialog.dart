import 'package:flutter/material.dart';
import '../services/theme_manager.dart';

void showThemeDialog(BuildContext context, ThemeManager themeManager) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Theme'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: themeManager.currentMode,
            onChanged: (mode) {
              Navigator.pop(ctx);
              themeManager.setThemeMode(mode!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: themeManager.currentMode,
            onChanged: (mode) {
              Navigator.pop(ctx);
              themeManager.setThemeMode(mode!);
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: themeManager.currentMode,
            onChanged: (mode) {
              Navigator.pop(ctx);
              themeManager.setThemeMode(mode!);
            },
          ),
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

Future<void> showCacheStatsDialog(
  BuildContext context,
  Map<String, dynamic> stats,
) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cache Statistics'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cached pages: ${stats['cachedPages']}/${stats['maxSize']}'),
          const SizedBox(height: 8),
          Text('Total size: ${(stats['totalSize'] as int) ~/ 1024} KB'),
          const SizedBox(height: 12),
          const Text(
            'Cache helps you access pages offline and improves loading speed.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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
