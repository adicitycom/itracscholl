import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/material.dart' as material show ThemeMode;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'school_config.dart';
import 'services/error_handler.dart';
import 'services/session_manager.dart';
import 'services/download_manager.dart';
import 'services/cache_manager.dart';
import 'services/theme_manager.dart';
import 'services/connectivity_manager.dart';
import 'services/biometric_auth.dart';
import 'services/notification_manager.dart';
import 'dialogs/theme_dialog.dart';
import 'dialogs/auth_dialog.dart';
import 'dialogs/notification_dialog.dart';
import 'services/analytics_manager.dart';
import 'services/announcement_manager.dart';
import 'services/camera_permission_manager.dart';
import 'dialogs/analytics_dialog.dart';
import 'dialogs/announcement_dialog.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final school = await loadCurrentSchoolConfig();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(SekolahApp(school: school));
}

class SekolahApp extends StatefulWidget {
  final SchoolConfig school;
  const SekolahApp({super.key, required this.school});

  @override
  State<SekolahApp> createState() => _SekolahAppState();
}

class _SekolahAppState extends State<SekolahApp> {
  late ThemeManager _themeManager;

  @override
  void initState() {
    super.initState();
    _initThemeManager();
  }

  Future<void> _initThemeManager() async {
    _themeManager = ThemeManager();
    await _themeManager.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeManager.themeNotifier,
      builder: (context, mode, _) {
        final lightTheme = _themeManager.getLightTheme(widget.school.themeColor);
        final darkTheme = _themeManager.getDarkTheme(widget.school.themeColor);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: widget.school.appName,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode == ThemeMode.system
              ? material.ThemeMode.system
              : mode == ThemeMode.dark
                  ? material.ThemeMode.dark
                  : material.ThemeMode.light,
          home: WebViewScreen(
            school: widget.school,
            themeManager: _themeManager,
          ),
        );
      },
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final SchoolConfig school;
  final ThemeManager themeManager;
  const WebViewScreen({
    super.key,
    required this.school,
    required this.themeManager,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  late SessionManager _sessionManager;
  late DownloadManager _downloadManager;
  late CacheManager _cacheManager;
  late ConnectivityManager _connectivityManager;
  late BiometricAuth _biometricAuth;
  late NotificationManager _notificationManager;
  late AnalyticsManager _analyticsManager;
  late AnnouncementManager _announcementManager;
  late String _testUrl;
  bool _isOnline = true;
  bool _showOfflineIndicator = false;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _testUrl = '';
    _initializeManagers();
    _requestPermissions();
    _setupFcm();
    _initWebView();
  }

  Future<void> _initializeManagers() async {
    _sessionManager = SessionManager();
    _sessionManager.onSessionExpired = _handleSessionExpired;
    _sessionManager.onSessionWarning = _handleSessionWarning;
    _sessionManager.startSession();

    _downloadManager = DownloadManager();
    await _downloadManager.initialize();

    _cacheManager = CacheManager();
    await _cacheManager.initialize();

    _connectivityManager = ConnectivityManager();
    _connectivityManager.onConnectionChanged = _handleConnectionChange;
    await _connectivityManager.initialize();
    _isOnline = _connectivityManager.isOnline;

    _biometricAuth = BiometricAuth();
    await _biometricAuth.initialize();

    _notificationManager = NotificationManager();
    _notificationManager.onNotificationReceived = _handleNotificationReceived;
    await _notificationManager.initialize();

    _analyticsManager = AnalyticsManager();
    await _analyticsManager.initialize();

    _announcementManager = AnnouncementManager();
    await _announcementManager.initialize();

    print('[App] Managers initialized');
  }

  void _handleNotificationReceived() {
    setState(() {
      _unreadNotifications = _notificationManager.unreadCount;
    });
  }

  void _handleConnectionChange() {
    setState(() {
      _isOnline = _connectivityManager.isOnline;
      _showOfflineIndicator = _connectivityManager.isOffline;
    });
    print('[App] Connection changed: $_isOnline');

    if (!_isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are offline. Showing cached content.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handleSessionWarning() {
    print('[App] Session warning - 5 minutes remaining');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Expiring'),
        content: const Text('Your session will expire in 5 minutes due to inactivity. Click "Continue" to stay logged in.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sessionManager.recordActivity();
              print('[App] Session activity recorded from warning');
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSessionExpired();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleSessionExpired() {
    print('[App] Session expired');
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired due to inactivity. Please refresh or go back to login.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _controller.reload();
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    print('[Permissions] Requesting all permissions...');
    final results = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    print('[Permissions] Camera permission: ${results[Permission.camera]}');
    print('[Permissions] Microphone permission: ${results[Permission.microphone]}');
    print('[Permissions] Location permission: ${results[Permission.location]}');
    print('[Permissions] Notification permission: ${results[Permission.notification]}');

    // If camera permission not granted, ensure it's requested
    if (!results[Permission.camera]!.isGranted) {
      print('[Permissions] Camera permission not granted, checking status...');
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        print('[Permissions] Camera permission denied, will retry on demand...');
      } else if (cameraStatus.isPermanentlyDenied) {
        print('[Permissions] Camera permission permanently denied');
      }
    } else {
      print('[Permissions] Camera permission already granted');
    }
  }

  Future<void> _setupFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.getToken();
  }

  Future<void> _openExternal(String url) async {
    try {
      print('[FlutterExternalUrl] ===== START =====');
      print('[FlutterExternalUrl] Received URL: $url');

      _sessionManager.recordActivity();

      final uri = Uri.parse(url);
      print('[FlutterExternalUrl] Parsed URI: ${uri.scheme}://${uri.host}${uri.path}');

      final canLaunch = await canLaunchUrl(uri);
      print('[FlutterExternalUrl] Can launch URL: $canLaunch');

      if (canLaunch) {
        print('[FlutterExternalUrl] Launching external app...');
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[FlutterExternalUrl] Launch result: $launched');

        if (launched) {
          final fileName = uri.path.split('/').last;
          await _downloadManager.addDownload(
            url: url,
            fileName: fileName.isEmpty ? 'download' : fileName,
            schoolId: widget.school.id,
          );
          _analyticsManager.trackDownload(fileName.isEmpty ? 'unknown' : fileName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening: ${fileName.isEmpty ? 'document' : fileName}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            AppError.generic('Failed to open document. Try again.').showSnackBar(context);
          }
        }
      } else {
        print('[FlutterExternalUrl] ERROR: Cannot launch this URL');
        if (mounted) {
          AppError.generic('Cannot open this type of file').showSnackBar(context);
        }
      }
      print('[FlutterExternalUrl] ===== END =====');
    } catch (e, st) {
      print('[FlutterExternalUrl] EXCEPTION: $e');
      print('[FlutterExternalUrl] Stack: $st');
      if (mounted) {
        final error = ErrorHandler.handleException(e, st);
        error.showSnackBar(context);
      }
    }
  }

  Future<void> _showFlutterDatePicker(String fieldName) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) {
      await _controller.runJavaScript('window._pickerOpen = false;');
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) {
      await _controller.runJavaScript('window._pickerOpen = false;');
      return;
    }
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T'
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    await _controller.runJavaScript('''
      (function() {
        var el = document.querySelector('[name="${fieldName}"]');
        if (el) {
          el.value = '${formatted}';
          el.dispatchEvent(new Event('change'));
          el.dispatchEvent(new Event('input'));
        }
        window._pickerOpen = false;
      })();
    ''');
  }

  // JS yang di-inject setelah halaman load untuk intercept:
  // 1. window.open() - tombol cetak/PDF
  // 2. form submit - terutama target="_blank"
  // 3. link klik - download/cetak
  // 4. DateTime picker
  // 5. Camera access optimization
  static const String _injectedJs = r"""
(function() {
  try {
    console.log('[Sekolah App JS] ===== INJECTION START =====');
    console.log('[Sekolah App JS] URL:', window.location.href);
    console.log('[Sekolah App JS] FlutterExternalUrl available:', typeof FlutterExternalUrl !== 'undefined');
    console.log('[Sekolah App JS] FlutterDateTimePicker available:', typeof FlutterDateTimePicker !== 'undefined');

    // Optimize camera access - reduce permission dialogs
    var _origGetUserMedia = navigator.mediaDevices.getUserMedia;
    navigator.mediaDevices.getUserMedia = function(constraints) {
      console.log('[Camera] getUserMedia called with:', constraints);
      return _origGetUserMedia.call(navigator.mediaDevices, constraints).catch(function(error) {
        console.error('[Camera] getUserMedia error:', error.message);
        throw error;
      });
    };

    // 1. Intercept window.open() -- dipakai banyak tombol cetak/PDF
    var _origOpen = window.open;
    window.open = function(url, target, features) {
      console.log('[window.open] ===== CALLED =====');
      console.log('[window.open] URL:', url);
      console.log('[window.open] Target:', target);
      console.log('[window.open] Type of URL:', typeof url);

      if (url && url.trim && url.trim() !== '' && url !== 'about:blank') {
        console.log('[window.open] URL valid, forwarding to Flutter');
        if (typeof FlutterExternalUrl === 'undefined') {
          console.error('[window.open] ERROR: FlutterExternalUrl channel not available!');
          return _origOpen.call(window, url, target, features);
        }
        try {
          console.log('[window.open] Posting message to Flutter...');
          FlutterExternalUrl.postMessage(url);
          console.log('[window.open] Message posted successfully');
        } catch(err) {
          console.error('[window.open] Exception:', err.message, err.stack);
        }
        return null;
      }
      console.log('[window.open] URL empty or about:blank, using original');
      return _origOpen.call(window, url, target, features);
    };

    // 2. Intercept form submit dengan target="_blank" atau cetak
    var _origFormSubmit = HTMLFormElement.prototype.submit;
    HTMLFormElement.prototype.submit = function() {
      var action = this.action || window.location.href;
      var method = this.method.toUpperCase();
      console.log('[form.submit] Called, action:', action, 'target:', this.target);

      if (this.target === '_blank' || this.target === 'print' ||
          action.includes('cetak') || action.includes('print')) {
        console.log('[form.submit] Print form detected, forwarding to Flutter');
        var formData = new FormData(this);
        var params = new URLSearchParams(formData);
        var finalUrl = action + (action.indexOf('?') !== -1 ? '&' : '?') + params.toString();
        try {
          FlutterExternalUrl.postMessage(finalUrl);
        } catch(err) {
          console.error('[form.submit] Error posting to Flutter:', err.message);
        }
        return;
      }
      return _origFormSubmit.call(this);
    };

    // 3. Intercept link klik (terutama download/print)
    document.addEventListener('click', function(e) {
      var el = e.target.closest('a');
      if (el && el.href) {
        var href = el.href.toLowerCase();
        var isDownload = el.hasAttribute('download') ||
                        href.endsWith('.pdf') || href.endsWith('.xlsx') || href.endsWith('.docx') ||
                        el.target === '_blank' || el.target === 'print' ||
                        href.includes('cetak') || href.includes('print') || href.includes('rapor');

        if (isDownload) {
          console.log('[link.click] Download/print link detected:', el.href);
          e.preventDefault();
          try {
            FlutterExternalUrl.postMessage(el.href);
          } catch(err) {
            console.error('[link.click] Error posting to Flutter:', err.message);
          }
        }
      }
    }, true);

    // 4. DateTime picker
    window._pickerOpen = false;
    function attachPicker(el) {
      if (el._flutterPicker) return;
      el._flutterPicker = true;
      el.readOnly = true;
      el.style.caretColor = 'transparent';
      function openPicker() {
        if (window._pickerOpen) return;
        window._pickerOpen = true;
        try {
          FlutterDateTimePicker.postMessage(el.name);
        } catch(err) {
          console.error('[picker] Error posting to Flutter:', err.message);
        }
      }
      el.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        openPicker();
      });
      el.addEventListener('focus', function() {
        el.blur();
        setTimeout(openPicker, 100);
      });
    }
    document.querySelectorAll(
      'input[type="datetime-local"], input.datetime-picker'
    ).forEach(attachPicker);
    new MutationObserver(function(muts) {
      muts.forEach(function(m) {
        m.addedNodes.forEach(function(n) {
          if (n.querySelectorAll) {
            n.querySelectorAll(
              'input[type="datetime-local"], input.datetime-picker'
            ).forEach(attachPicker);
          }
        });
      });
    }).observe(document.body, { childList: true, subtree: true });

    console.log('[Sekolah App JS] ===== INJECTION SUCCESS =====');
    console.log('[Sekolah App JS] All interceptors ready');
    console.log('[Sekolah App JS] window.open:', typeof window.open);
    console.log('[Sekolah App JS] Ready to handle: window.open(), form.submit(), link.click()');
  } catch(e) {
    console.error('[Sekolah App JS] ===== INJECTION FAILED =====');
    console.error('[Sekolah App JS] Error:', e.message);
    console.error('[Sekolah App JS] Stack:', e.stack);
  }
})();
""";

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterExternalUrl',
        onMessageReceived: (JavaScriptMessage msg) {
          _openExternal(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterDateTimePicker',
        onMessageReceived: (JavaScriptMessage msg) {
          _showFlutterDatePicker(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            print('[WebView] Page started loading');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            print('[WebView] ===== PAGE FINISHED =====');
            print('[WebView] URL: $url');
            _sessionManager.recordActivity();
            _analyticsManager.trackPageView(url ?? 'unknown');

            // Check camera permission status when page loads
            final hasCameraPermission = await CameraPermissionManager.checkCameraPermission();
            print('[WebView] Camera permission status: $hasCameraPermission');

            setState(() => _isLoading = false);
            print('[WebView] Running JS injection...');
            _controller.runJavaScript(_injectedJs).then((_) {
              print('[WebView] JS injection executed successfully');
              _controller.runJavaScript('console.log("[WebView] JS injection confirmed at: " + window.location.href)');
            }).catchError((e) {
              print('[WebView] ERROR executing JS injection: $e');
            });
          },
          onNavigationRequest: (request) {
            _sessionManager.recordActivity();
            final uri = Uri.parse(request.url);
            if (!uri.host.endsWith(widget.school.allowedDomain)) {
              _openExternal(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.school.websiteUrl));
  }

  @override
  void dispose() {
    _sessionManager.dispose();
    _connectivityManager.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: widget.school.themeColor,
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
              if (_showOfflineIndicator)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Offline Mode - Showing cached content',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isOnline)
                          GestureDetector(
                            onTap: () => setState(() => _showOfflineIndicator = false),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDownloadHistory() async {
    final history = await _downloadManager.getHistory(schoolId: widget.school.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Download History (${history.length})'),
        content: history.isEmpty
            ? const Text('No downloads yet')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, idx) {
                    final record = history[idx];
                    return ListTile(
                      leading: const Icon(Icons.file_download, size: 24),
                      title: Text(
                        record.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(record.formattedDate, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openExternal(record.url);
                        },
                      ),
                      onLongPress: () {
                        _downloadManager.removeDownload(record.id);
                        Navigator.pop(ctx);
                        _showDownloadHistory();
                      },
                    );
                  },
                ),
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

  void _showSessionInfo() {
    final timeLeft = _sessionManager.timeUntilTimeout;
    final isActive = _sessionManager.isSessionActive;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${isActive ? 'Active' : 'Expired'}'),
            const SizedBox(height: 8),
            Text(
              'Time remaining: ${timeLeft.inMinutes}m ${timeLeft.inSeconds % 60}s',
              style: TextStyle(
                color: timeLeft.inMinutes < 5 ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Timeout: ${SessionManager.SESSION_TIMEOUT.inMinutes} minutes'),
            const SizedBox(height: 8),
            const Text('Activity will extend your session'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sessionManager.recordActivity();
            },
            child: const Text('Refresh Activity'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
