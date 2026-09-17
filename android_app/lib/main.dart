import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  Future<void> _showFlutterDatePicker(String fieldName) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) {
      // User batal -- reset flag supaya bisa klik lagi
      await _controller.runJavaScript('window._pickerOpen = false;');
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) {
      // User batal -- reset flag supaya bisa klik lagi
      await _controller.runJavaScript('window._pickerOpen = false;');
      return;
    }

    // Format YYYY-MM-DDTHH:mm (format datetime-local HTML standard)
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T'
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    // Set nilai ke field HTML dan reset flag debounce
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

  // JS debounce: pastikan picker hanya terbuka 1x per tap
  static const String _datePickerJs = r"""
(function() {
  window._pickerOpen = false;

  function attachPicker(el) {
    if (el._flutterPicker) return;
    el._flutterPicker = true;
    el.readOnly = true;
    el.style.caretColor = 'transparent';

    function openPicker() {
      if (window._pickerOpen) return;
      window._pickerOpen = true;
      FlutterDateTimePicker.postMessage(el.name);
    }

    el.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      openPicker();
    });
    el.addEventListener('focus', function() {
      el.blur();
      // Beri jeda kecil supaya tidak bentrok dengan click event
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
})();
""";

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterDateTimePicker',
        onMessageReceived: (JavaScriptMessage msg) {
          _showFlutterDatePicker(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_datePickerJs);
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            if (uri.host.endsWith(widget.school.allowedDomain)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
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
      ),
    );
  }
}
