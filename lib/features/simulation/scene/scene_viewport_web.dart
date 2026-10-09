import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../simulation_bridge.dart';
import 'scene_config.dart';

/// Flutter Web: embeds the Three.js scene in an <iframe> platform view.
///
/// For a same-origin page (the bundled asset) we install `window.FR` inside the iframe and
/// evaluate commands directly. For a cross-origin hosted scene, commands are sent with
/// `postMessage({type:'fr-command', js})` and snapshots are expected back via
/// `parent.postMessage({source:'freshroute-sim', ...snapshot}, '*')` (see README).
class SceneViewport extends StatefulWidget {
  const SceneViewport({super.key, required this.onReady, required this.onClosed});
  final SceneReady onReady;
  final VoidCallback onClosed;

  @override
  State<SceneViewport> createState() => _SceneViewportState();
}

class _SceneViewportState extends State<SceneViewport> {
  static int _seq = 0;
  late final String _viewType = 'freshroute-sim-${_seq++}';
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  web.HTMLIFrameElement? _iframe;
  JSFunction? _windowListener;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final src = SceneConfig.hostedUrl ?? '${ui_web.assetManager.getAssetUrl(SceneConfig.bundledAsset)}?app=1';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = src
        ..allow = 'fullscreen'
        ..setAttribute('scrolling', 'no')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor = '#122033';
      iframe.addEventListener('load', ((web.Event _) => _onLoad()).toJS);
      _iframe = iframe;
      return iframe;
    });

    // Cross-origin scenes report through window.postMessage.
    _windowListener = ((web.MessageEvent e) {
      final data = e.data.dartify();
      if (data is Map && data['source'] == 'freshroute-sim') {
        _messages.add(data.map((k, v) => MapEntry(k.toString(), v)));
      }
    }).toJS;
    web.window.addEventListener('message', _windowListener);
  }

  void _onLoad() {
    final iframe = _iframe;
    if (iframe == null) return;
    final channel = _IframeChannel(iframe, _messages);
    channel.installBridge();
    if (mounted) setState(() => _loading = false);
    widget.onReady(channel);
  }

  @override
  void dispose() {
    widget.onClosed();
    if (_windowListener != null) web.window.removeEventListener('message', _windowListener);
    _messages.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        HtmlElementView(viewType: _viewType),
        if (_loading) const IgnorePointer(child: ColoredBox(color: Color(0xFF122033), child: Center(child: CircularProgressIndicator()))),
      ]);
}

class _IframeChannel implements SceneChannel {
  _IframeChannel(this._iframe, this._sink);
  final web.HTMLIFrameElement _iframe;
  final StreamController<Map<String, dynamic>> _sink;
  bool _sameOrigin = true;

  @override
  Stream<Map<String, dynamic>> get messages => _sink.stream;

  JSObject? get _win => _iframe.contentWindow as JSObject?;

  /// Defines `window.FR.postMessage` inside the iframe so the scene runs in "app" mode.
  void installBridge() {
    try {
      final fr = JSObject();
      fr['postMessage'] = ((JSString s) {
        try {
          if (!_sink.isClosed) _sink.add(jsonDecode(s.toDart) as Map<String, dynamic>);
        } catch (_) {}
      }).toJS;
      _win?['FR'] = fr;
      _win?.callMethod('eval'.toJS, 'document.body.classList.add("app");document.documentElement.style.overflow="hidden";document.body.style.overflow="hidden";window.dispatchEvent(new Event("resize"))'.toJS);
    } catch (_) {
      _sameOrigin = false; // Cross-origin: fall back to postMessage.
    }
  }

  @override
  Future<void> run(String js) async {
    final win = _iframe.contentWindow;
    if (win == null) return;
    if (_sameOrigin) {
      try {
        (win as JSObject).callMethod('eval'.toJS, js.toJS);
        return;
      } catch (_) {
        _sameOrigin = false;
      }
    }
    win.postMessage({'type': 'fr-command', 'js': js}.jsify(), '*'.toJS);
  }
}
