import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
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
  late final Dio _dio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _requestPermissions();
    _setupFcm();
    _initWebView();
  }

  Future<void> _downloadFile(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final filename = uri.pathSegments.last.isNotEmpty
          ? uri.pathSegments.last
          : 'download.pdf';

      final tempDir = await getTemporaryDirectory();
      final filepath = '${tempDir.path}/$filename';

      final options = Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
      );

      final response = await _dio.get(
        urlString,
        options: options,
      );

      if (response.statusCode == 200) {
        final file = File(filepath);
        await file.writeAsBytes(response.data);

        final result = await OpenFilex.open(filepath);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tidak bisa membuka file: ${result.message}')),
            );
          }
        }
      } else {
        throw Exception('Download gagal: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error download: $e')),
        );
      }
    }
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
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  // JS yang di-inject setelah halaman load:
  // 1. Intercept window.open() untuk semua cetak/PDF
  // 2. Intercept a[target="_blank"] dan download link
  // 3. Intercept form[target="_blank"] submit
  // 4. Handle datetime picker
  static const String _injectedJs = r"""
(function() {
  // 1. Intercept window.open() -- dipakai banyak tombol cetak/PDF
  var _origOpen = window.open;
  window.open = function(url, target, features) {
    if (url && url !== '' && url !== 'about:blank') {
      FlutterFileDownloader.postMessage(url);
      return null;
    }
    return _origOpen.call(window, url, target, features);
  };

  // 2. Intercept link clicks:
  //    - a[download] dan file extension (.pdf, .xlsx, .docx)
  //    - a[target="_blank"] atau a[target="print"]
  //    - link yang path-nya mengindikasikan cetak (cetak, print, rapor, export, action=export)
  document.addEventListener('click', function(e) {
    var el = e.target.closest('a');
    if (!el || !el.href) return;

    var href = el.href.toLowerCase();
    var isFileLink = el.hasAttribute('download') ||
                     href.endsWith('.pdf') || href.endsWith('.xlsx') ||
                     href.endsWith('.docx');
    var isTargetBlank = el.target === '_blank' || el.target === 'print';
    var isCetakIndication = /\b(cetak|print|rapor|laporan|export|download)\b/i.test(href) ||
                            /[?&](action|format|type)=(cetak|print|rapor|export|pdf|xlsx)/i.test(href);

    if (isFileLink || isTargetBlank || isCetakIndication) {
      e.preventDefault();
      e.stopPropagation();
      FlutterFileDownloader.postMessage(href);
      return false;
    }
  }, true);

  // 3. Intercept form submit jika target adalah _blank
  var _origFormSubmit = HTMLFormElement.prototype.submit;
  HTMLFormElement.prototype.submit = function() {
    if (this.target === '_blank' || this.target === 'print') {
      var form = this;
      var url = form.action || window.location.href;
      var formData = new FormData(form);

      // POST jadi GET dengan query string (simplification)
      if (form.method.toUpperCase() === 'POST') {
        var params = new URLSearchParams(formData);
        url = url + (url.indexOf('?') !== -1 ? '&' : '?') + params.toString();
      }

      FlutterFileDownloader.postMessage(url);
      return;
    }
    return _origFormSubmit.call(this);
  };

  // 4. DateTime picker (debounced)
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
        'FlutterExternalUrl',
        onMessageReceived: (JavaScriptMessage msg) {
          _openExternal(msg.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterFileDownloader',
        onMessageReceived: (JavaScriptMessage msg) {
          _downloadFile(msg.message);
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
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) {
            setState(() => _isLoading = false);
            _controller.runJavaScript(_injectedJs);
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            final host = uri.host;
            final pathAndQuery = '${uri.path}${uri.query}'.toLowerCase();

            // Blok navigasi ke domain lain
            if (!host.endsWith(widget.school.allowedDomain)) {
              _openExternal(request.url);
              return NavigationDecision.prevent;
            }

            // Heuristic: jika URL mengindikasikan cetak/export, download instead of navigate
            const cetakPatterns = [
              'cetak', 'print', 'rapor', 'laporan', 'export',
              'download', 'unduh', 'generate', 'format=pdf',
              'action=export', 'action=cetak', 'type=pdf',
            ];
            final shouldDownload = cetakPatterns.any(
              (pattern) => pathAndQuery.contains(pattern),
            );

            if (shouldDownload) {
              _downloadFile(request.url);
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
      ),
    );
  }
}
