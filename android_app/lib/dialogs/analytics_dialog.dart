import 'package:flutter/material.dart';
import '../services/analytics_manager.dart';

void showAnalyticsDialog(BuildContext context, AnalyticsManager analyticsManager) {
  final stats = analyticsManager.getEventStats();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Usage Analytics'),
      content: SizedBox(
        width: double.maxFinite,
        child: stats.isEmpty
            ? const Text('No analytics data yet')
            : ListView.builder(
                itemCount: stats.length,
                itemBuilder: (_, idx) {
                  final entry = stats.entries.toList()[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        if (stats.isNotEmpty)
          TextButton(
            onPressed: () {
              analyticsManager.clearEvents();
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
