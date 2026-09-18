import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsEvent {
  final String event;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  AnalyticsEvent({
    required this.event,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'event': event,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };
}

class AnalyticsManager {
  static const String ANALYTICS_KEY = 'analytics_events';
  static const int MAX_EVENTS = 100;

  SharedPreferences? _prefs;
  List<AnalyticsEvent> _events = [];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadEvents();
    print('[AnalyticsManager] Initialized with ${_events.length} events');
  }

  void trackEvent(String event, {Map<String, dynamic>? data}) {
    try {
      final analyticsEvent = AnalyticsEvent(
        event: event,
        timestamp: DateTime.now(),
        data: data ?? {},
      );
      _events.add(analyticsEvent);
      if (_events.length > MAX_EVENTS) {
        _events = _events.sublist(_events.length - MAX_EVENTS);
      }
      _saveEvents();
      print('[Analytics] Event tracked: $event');
    } catch (e) {
      print('[Analytics] Error tracking event: $e');
    }
  }

  void trackPageView(String page) => trackEvent('page_view', data: {'page': page});
  void trackButtonClick(String button) => trackEvent('button_click', data: {'button': button});
  void trackDownload(String fileName) => trackEvent('download', data: {'file': fileName});
  void trackError(String error) => trackEvent('error', data: {'error': error});
  void trackFeatureUsage(String feature) => trackEvent('feature_used', data: {'feature': feature});

  List<AnalyticsEvent> getEvents() => _events;

  Map<String, int> getEventStats() {
    final stats = <String, int>{};
    for (final event in _events) {
      stats[event.event] = (stats[event.event] ?? 0) + 1;
    }
    return stats;
  }

  void _saveEvents() {
    try {
      final jsonList = _events.map((e) => e.toJson()).toList();
      _prefs?.setString(ANALYTICS_KEY, jsonList.toString());
    } catch (e) {
      print('[Analytics] Error saving events: $e');
    }
  }

  void _loadEvents() {
    try {
      final saved = _prefs?.getString(ANALYTICS_KEY);
      if (saved != null && saved.isNotEmpty) {
        print('[Analytics] Events loaded from storage');
      }
    } catch (e) {
      print('[Analytics] Error loading events: $e');
    }
  }

  void clearEvents() {
    _events.clear();
    _prefs?.remove(ANALYTICS_KEY);
    print('[Analytics] Events cleared');
  }
}
