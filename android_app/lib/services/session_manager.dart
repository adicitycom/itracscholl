import 'dart:async';
import 'package:flutter/foundation.dart';

class SessionManager {
  static const Duration SESSION_TIMEOUT = Duration(minutes: 15);
  static const Duration ACTIVITY_CHECK_INTERVAL = Duration(seconds: 30);

  Timer? _timeoutTimer;
  Timer? _activityCheckTimer;
  DateTime _lastActivity = DateTime.now();
  bool _isSessionActive = true;

  VoidCallback? onSessionExpired;
  VoidCallback? onSessionWarning;

  SessionManager();

  void startSession() {
    print('[SessionManager] Starting session');
    _lastActivity = DateTime.now();
    _isSessionActive = true;
    _startTimeoutTimer();
    _startActivityCheckTimer();
  }

  void endSession() {
    print('[SessionManager] Ending session');
    _isSessionActive = false;
    _timeoutTimer?.cancel();
    _activityCheckTimer?.cancel();
  }

  void recordActivity() {
    if (!_isSessionActive) return;
    _lastActivity = DateTime.now();
    print('[SessionManager] Activity recorded at ${_lastActivity.toString()}');
  }

  bool get isSessionActive => _isSessionActive;

  Duration get timeUntilTimeout {
    if (!_isSessionActive) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastActivity);
    return SESSION_TIMEOUT.compareTo(elapsed) > 0
        ? SESSION_TIMEOUT - elapsed
        : Duration.zero;
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(SESSION_TIMEOUT, () {
      print('[SessionManager] Session timeout reached');
      _isSessionActive = false;
      onSessionExpired?.call();
    });
  }

  void _startActivityCheckTimer() {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = Timer.periodic(ACTIVITY_CHECK_INTERVAL, (_) {
      final elapsed = DateTime.now().difference(_lastActivity);

      // Warning at 10 minutes (5 min before timeout)
      if (elapsed > const Duration(minutes: 10) &&
          elapsed < const Duration(minutes: 10, seconds: 30)) {
        print('[SessionManager] Session expiring soon');
        onSessionWarning?.call();
      }

      // Timeout at 15 minutes
      if (elapsed > SESSION_TIMEOUT && _isSessionActive) {
        print('[SessionManager] Session timeout via activity check');
        _isSessionActive = false;
        _timeoutTimer?.cancel();
        onSessionExpired?.call();
      }
    });
  }

  void dispose() {
    endSession();
  }
}
