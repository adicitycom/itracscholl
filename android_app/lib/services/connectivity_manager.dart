import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityManager {
  bool _isOnline = true;
  Timer? _checkTimer;

  VoidCallback? onConnectionChanged;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Future<void> initialize() async {
    await _checkConnectivity();
    _startPeriodicCheck();
    print('[ConnectivityManager] Initialized');
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (wasOnline != _isOnline) {
        print('[ConnectivityManager] Status changed: $_isOnline');
        onConnectionChanged?.call();
      }
    } on SocketException catch (e) {
      final wasOnline = _isOnline;
      _isOnline = false;
      print('[ConnectivityManager] No internet connection: $e');
      if (wasOnline != _isOnline) {
        onConnectionChanged?.call();
      }
    } catch (e) {
      print('[ConnectivityManager] Error checking connectivity: $e');
    }
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  void dispose() {
    _checkTimer?.cancel();
  }
}
