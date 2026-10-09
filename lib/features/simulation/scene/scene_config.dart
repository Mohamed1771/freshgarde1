import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../simulation_bridge.dart';

/// Where the Three.js scene is loaded from.
abstract final class SceneConfig {
  /// Bundled offline build of the existing simulation (copied from `freshroute_app/assets/sim`).
  static const bundledAsset = 'assets/sim/index.html';

  /// Set to a URL (e.g. `https://sim.example.com/?app=1`) to load a hosted scene instead.
  /// On Flutter Web a hosted scene must be same-origin, or implement the postMessage
  /// protocol described in the README.
  static const String? hostedUrl = null;

  /// Embedded mode: hide the page's own side panel, label and toasts so only the 3D canvas
  /// (and the crate inspector) is shown; the Flutter UI renders everything else.
  static const embedJs = '''
(function(){
  if(document.getElementById('fr-embed'))return;
  var s=document.createElement('style');s.id='fr-embed';
  s.textContent='html,body{overflow:hidden!important;height:100%!important;margin:0!important}'
   +'.side,.scene-label,.toast,.hint{display:none!important}'
   +'.layout{display:block!important;height:100vh!important;padding:0!important}'
   +'.scene{height:100vh!important;margin:0!important;border-radius:0!important}';
  document.head.appendChild(s);
  document.body.classList.add('app');
  window.dispatchEvent(new Event('resize'));
})();''';
}

typedef SceneReady = void Function(SceneChannel channel);

/// Shown when no embedded 3D scene is available on the current platform.
class SceneFallback extends StatelessWidget {
  const SceneFallback({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.navy,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.view_in_ar_outlined, size: 56, color: AppColors.sky),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white)),
          const SizedBox(height: 6),
          const Text('اللوحات أدناه تعمل بالمحاكاة الداخلية.', style: TextStyle(color: AppColors.ice, fontSize: 13)),
        ]),
      );
}
