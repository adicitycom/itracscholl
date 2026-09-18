import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'school_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final school = await loadCurrentSchoolConfig();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  runApp(SekolahApp(school: school));
}

class SekolahApp extends StatelessWidget {
  final SchoolConfig school;
  const SekolahApp({super.key, required this.school});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: school.appName,
      theme: ThemeData(
        colorSchemeSeed: school.themeColor,
        useMaterial3: true,
      ),
      home: WebViewScreen(school: school),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final SchoolConfig school;
  const WebViewScreen({super.key, required this.school});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupFcm();
    _initWebView();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
    ].request();
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
      print('[FlutterExternalUrl] URL length: ${url.length}');

      final uri = Uri.parse(url);
      print('[FlutterExternalUrl] Parsed URI: ${uri.scheme}://${uri.host}${uri.path}');

      final canLaunch = await canLaunchUrl(uri);
      print('[FlutterExternalUrl] Can launch URL: $canLaunch');

      if (canLaunch) {
        print('[FlutterExternalUrl] Launching external app...');
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('[FlutterExternalUrl] Launch result: $launched');
      } else {
        print('[FlutterExternalUrl] ERROR: Cannot launch this URL');
        print('[FlutterExternalUrl] Trying to launch with URL scheme...');
        final launched = await launchUrl(uri);
        print('[FlutterExternalUrl] Fallback launch result: $launched');
      }
      print('[FlutterExternalUrl] ===== END =====');
    } catch (e) {
      print('[FlutterExternalUrl] EXCEPTION: $e');
      print('[FlutterExternalUrl] Stack: ${StackTrace.current}');
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
  static const String _injectedJs = r"""
(function() {
  try {
    console.log('[Sekolah App JS] ===== INJECTION START =====');
    console.log('[Sekolah App JS] URL:', window.location.href);
    console.log('[Sekolah App JS] FlutterExternalUrl available:', typeof FlutterExternalUrl !== 'undefined');
    console.log('[Sekolah App JS] FlutterDateTimePicker available:', typeof FlutterDateTimePicker !== 'undefined');

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
          onPageFinished: (url) {
            print('[WebView] ===== PAGE FINISHED =====');
            print('[WebView] URL: $url');
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
            // Hanya blok navigasi ke domain lain
            // (link ke domain sendiri tetap dibuka di WebView)
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
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Test PDF Open'),
                content: TextField(
                  onChanged: (val) => _testUrl = val,
                  decoration: const InputDecoration(
                    hintText: 'Paste PDF URL here',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (_testUrl.isNotEmpty) {
                        print('[DEBUG] Testing URL: $_testUrl');
                        _openExternal(_testUrl);
                      }
                    },
                    child: const Text('Open URL'),
                  ),
                ],
              ),
            );
          },
          tooltip: 'Test URL Launcher (Debug)',
          child: const Icon(Icons.bug_report),
        ),
      ),
    );
  }

  late String _testUrl = '';
}
