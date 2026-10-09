// Picks the platform implementation at compile time so web-only libraries never reach
// mobile builds and webview_flutter is never used on the web.
export 'scene_viewport_stub.dart'
    if (dart.library.js_interop) 'scene_viewport_web.dart'
    if (dart.library.io) 'scene_viewport_mobile.dart';
