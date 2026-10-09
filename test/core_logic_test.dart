import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshroute_platform/features/simulation/mock_simulation_bridge.dart';
import 'package:freshroute_platform/features/simulation/mock_simulation_engine.dart';
import 'package:freshroute_platform/shared/models/inspection_result.dart';
import 'package:freshroute_platform/shared/models/shipment.dart';
import 'package:freshroute_platform/shared/models/simulation_scenario.dart';
import 'package:freshroute_platform/shared/models/simulation_state.dart';
import 'package:freshroute_platform/shared/repositories/notification_repository.dart';
import 'package:freshroute_platform/shared/repositories/shipment_repository.dart';
import 'package:freshroute_platform/shared/services/ai_inspection_service.dart';

void main() {
  group('MockAiInspectionService', () {
    final media = InspectionMedia(name: 'crate.jpg', bytes: Uint8List.fromList(List.generate(4096, (i) => i % 251)), type: MediaType.image);

    test('is deterministic and labelled as simulated', () async {
      const svc = MockAiInspectionService();
      final a = await svc.analyzeImage(media, productHint: 'tomato');
      final b = await svc.analyzeImage(media, productHint: 'tomato');
      expect(a.maturityStage, b.maturityStage);
      expect(a.confidence, b.confidence);
      expect(a.isSimulated, isTrue);
      expect(svc.isSimulated, isTrue);
    });

    test('JSON round trip keeps the typed fields', () async {
      final r = await const MockAiInspectionService().analyzeImage(media);
      final back = InspectionResult.fromJson(r.toJson(), mediaType: r.mediaType, fileName: r.fileName);
      expect(back.maturityStage, r.maturityStage);
      expect(back.defects.length, r.defects.length);
      expect(back.isSimulated, isTrue);
    });
  });

  group('MockSimulationEngine scenarios', () {
    final repo = ShipmentRepository(NotificationRepository());
    final ship = repo.byId('FR-24017')!; // seed 24017 → no time shift
    EngineParams params(SimulationScenario sc, [MaturityStage stage = MaturityStage.turning]) => EngineParams(
          shipmentId: ship.id,
          product: ship.product,
          baseSetpointC: 12,
          initialStage: stage,
          extraDeterioration: 0,
          appearanceSource: AppearanceSource.aiInspection,
          inspectionWasSimulated: true,
          departure: DateTime(2026),
          scenario: sc,
        );

    test('inspection stage seeds ripeness, kept separate from deterioration', () {
      final green = MockSimulationEngine.compute(params(SimulationScenario.stable, MaturityStage.matureGreen), 0);
      final ripe = MockSimulationEngine.compute(params(SimulationScenario.stable, MaturityStage.ripe), 0);
      expect(ripe.ripeness, greaterThan(green.ripeness));
      expect(green.deterioration, lessThan(0.01));
    });

    test('scenarios produce different trips', () {
      final results = {
        for (final sc in SimulationScenario.values) sc: MockSimulationEngine.compute(params(sc), 48),
      };
      final qualities = results.values.map((r) => r.qualityPct.toStringAsFixed(1)).toSet();
      expect(qualities.length, greaterThanOrEqualTo(5));
      expect(results[SimulationScenario.lateFailure]!.qualityPct, lessThan(results[SimulationScenario.stable]!.qualityPct));
    });

    test('cooling failure scenario heats cargo and triggers an AI alert, stable does not', () {
      final failed = MockSimulationEngine.compute(params(SimulationScenario.coolingFailure), 30);
      final stable = MockSimulationEngine.compute(params(SimulationScenario.stable), 30);
      expect(failed.coolingFailure, isTrue);
      expect(stable.coolingFailure, isFalse);
      expect(failed.cargoTempC, greaterThan(stable.cargoTempC + 4));
      expect(failed.alerts, isNotEmpty);
      expect(failed.decisions.any((d) => d.kind == DecisionKind.alert), isTrue);
      expect(failed.predictedArrivalQualityPct, lessThan(stable.predictedArrivalQualityPct));
    });

    test('scenario timing varies per shipment but is stable for the same ID', () {
      final a = SimulationScenario.coolingFailure.timeline(SimulationScenario.seedOf('FR-24017'));
      final b = SimulationScenario.coolingFailure.timeline(SimulationScenario.seedOf('FR-24018'));
      expect(a.last.start, isNot(b.last.start));
      expect(SimulationScenario.forId('FR-24031'), SimulationScenario.forId('FR-24031'));
    });
  });

  group('Shipment flow', () {
    test('applying an inspection updates the shipment and seeds the simulation', () async {
      final repo = ShipmentRepository(NotificationRepository());
      final ship = repo.byId('FR-24017')!;
      final r = await const MockAiInspectionService().analyzeImage(
        InspectionMedia(name: 'x.jpg', bytes: Uint8List.fromList([1, 2, 3, 4, 5]), type: MediaType.image),
      );
      repo.applyInspection(ship, r);
      expect(ship.inspection, same(r));
      expect(ship.initialStage, r.maturityStage);

      final bridge = MockSimulationBridge();
      await bridge.initializeShipment(ship);
      expect(bridge.state.initialStage, r.maturityStage);
      expect(bridge.state.appearanceSource, AppearanceSource.aiInspection);
      expect(bridge.state.scenario, SimulationScenario.coolingFailure);

      await bridge.setTime(28);
      expect(bridge.state.coolingFailure, isTrue);
      expect(bridge.state.alerts, isNotEmpty);

      repo.applySimulation(ship, bridge.state);
      expect(ship.reading.temperatureC, closeTo(bridge.state.cargoTempC, 1e-9));
      bridge.dispose();
    });

    test('created shipments are listed under pending', () async {
      final repo = ShipmentRepository(NotificationRepository());
      final base = repo.byId('FR-24025')!;
      final s = Shipment(
        id: repo.nextId(),
        exporterName: 'a',
        exporterCompany: 'b',
        importerName: 'c',
        importerCompany: 'd',
        importerCountry: 'قطر',
        product: base.product,
        variety: 'v',
        quantityTons: 3,
        packaging: 'p',
        origin: 'عمّان',
        destination: 'الدوحة',
        departure: DateTime.now(),
        eta: DateTime.now().add(const Duration(days: 2)),
        status: ShipmentStatus.pending,
        truckType: 't',
        truckPlate: '22-12345',
        driverName: 'd',
        coolingSetpointC: 8,
        smartCooling: true,
        reading: base.reading,
        qualityPct: 95,
        forecast: base.forecast,
      );
      await repo.create(s);
      expect(repo.byStatus(ShipmentStatus.pending).first.id, s.id);
    });
  });
}
