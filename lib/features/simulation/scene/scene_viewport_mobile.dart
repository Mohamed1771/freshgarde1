import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../simulation_bridge.dart';
import 'scene_config.dart';

/// Android / iOS: embeds the Three.js scene with webview_flutter.
/// The page talks back through the `FR` JavaScript channel (`window.FR.postMessage`).
class SceneViewport extends StatefulWidget {
  const SceneViewport({super.key, required this.onReady, required this.onClosed});
  final SceneReady onReady;
  final VoidCallback onClosed;

  @override
  State<SceneViewport> createState() => _SceneViewportState();
}

class _SceneViewportState extends State<SceneViewport> {
  WebViewController? _controller;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  bool _loading = true;
  String? _error;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF122033))
      ..setNavigationDelegate(NavigationDelegate(
        onWebResourceError: (e) {
          if (e.isForMainFrame ?? true) setState(() => _error = e.description);
        },
      ))
      ..addJavaScriptChannel('FR', onMessageReceived: _onMessage);
    final hosted = SceneConfig.hostedUrl;
    hosted == null ? c.loadFlutterAsset(SceneConfig.bundledAsset) : c.loadRequest(Uri.parse(hosted));
    _controller = c;
  }

  void _onMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      if (data['type'] == 'ready' && _loading) {
        setState(() => _loading = false);
        widget.onReady(_Channel(_controller!, _messages.stream));
      }
      _messages.add(data);
    } catch (e) {
      debugPrint('Scene message ignored: $e');
    }
  }

  @override
  void dispose() {
    widget.onClosed();
    _messages.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) return const SceneFallback(message: 'المشهد ثلاثي الأبعاد متاح على Android وiOS والويب.');
    if (_error != null) return SceneFallback(message: 'تعذّر تحميل المشهد: $_error');
    return Stack(fit: StackFit.expand, children: [
      WebViewWidget(controller: c),
      if (_loading) const ColoredBox(color: Color(0xFF122033), child: Center(child: CircularProgressIndicator())),
    ]);
  }
}

class _Channel implements SceneChannel {
  _Channel(this._c, this.messages);
  final WebViewController _c;

  @override
  final Stream<Map<String, dynamic>> messages;

  @override
  Future<void> run(String js) => _c.runJavaScript(js);
}
