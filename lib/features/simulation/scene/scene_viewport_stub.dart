import 'package:flutter/material.dart';

import 'scene_config.dart';

/// Fallback for platforms without an embedding implementation.
class SceneViewport extends StatelessWidget {
  const SceneViewport({super.key, required this.onReady, required this.onClosed});
  final SceneReady onReady;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) => const SceneFallback(message: 'المشهد ثلاثي الأبعاد غير مدعوم على هذه المنصة.');
}
