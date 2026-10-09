import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/features/simulation/live_simulation_service.dart';
import 'package:freshroute_platform/shared/models/shipment.dart';
import 'package:freshroute_platform/shared/models/simulation_scenario.dart';
import 'package:freshroute_platform/shared/repositories/notification_repository.dart';
import 'package:freshroute_platform/shared/repositories/settings_repository.dart';
import 'package:freshroute_platform/shared/repositories/shipment_repository.dart';

void main() {
  // DateTime.now() is real time while the test clock is fake, so disable the real-time gap here.
  setUp(() => LiveSession.minGapReal = Duration.zero);

  for (final id in ['FR-24017', 'FR-24021']) {
    testWidgets('alerts are spaced and not repeated during a whole trip ($id)', (t) async {
      final repo = ShipmentRepository(NotificationRepository());
      final ship = repo.byId(id)!;
      ship.progress = 0;
      ship.alerts.clear();
      final service = LiveSimulationService(repo, SettingsRepository()..simulationSpeed = 2);
      final session = service.sessionFor(ship);
      final fired = <(double, String)>[];
      final sub = session.newAlerts.listen((a) => fired.add((session.state.hour, a)));

      while (ship.status == ShipmentStatus.active) {
        await t.pump(const Duration(milliseconds: 200));
      }
      await sub.cancel();

      expect(fired, isNotEmpty, reason: 'scenario ${ship.scenario.label} should raise alerts');
      expect(fired.length, lessThanOrEqualTo(10));
      for (var i = 1; i < fired.length; i++) {
        expect(fired[i].$1 - fired[i - 1].$1, greaterThanOrEqualTo(LiveSession.minGapHours - 0.01),
            reason: 'gap between "${fired[i - 1].$2}" and "${fired[i].$2}"');
      }
      // ignore: avoid_print
      print('${ship.scenario.label}: ${fired.map((f) => 'h${f.$1.toStringAsFixed(1)} ${f.$2}').join(' | ')}');
      expect(ship.scenario, isIn(SimulationScenario.values));
      service.dispose();
    });
  }
}
