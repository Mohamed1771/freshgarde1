import '../models/app_notification.dart';
import '../models/inspection_result.dart';
import '../models/product.dart';
import '../models/sensor_reading.dart';
import '../models/shipment.dart';
import '../models/simulation_scenario.dart';
import '../models/trader.dart';
import '../models/trading_offer.dart';

/// Demo data. Every value here is fictional and for demonstration only.
abstract final class MockData {
  /// Documented demo credentials (see README).
  static const demoEmail = 'ahmad@gmail.com';
  static const demoPhone = '0791234567';
  static const demoPassword = '12345678';
  static const demoOtp = '123456';

  static const governorates = [
    'عمّان', 'إربد', 'الزرقاء', 'البلقاء', 'المفرق', 'جرش', 'عجلون', 'مادبا', 'الكرك', 'الطفيلة', 'معان', 'العقبة',
  ];
  static const originHubs = ['عمّان', 'الأغوار الشمالية', 'الأغوار الوسطى', 'إربد', 'المفرق', 'العقبة', 'الكرك'];
  /// Delivery cities (Jordanian governorates).
  static const destinations = governorates;
  static const packagingTypes = ['صناديق بلاستيك 10 كغ', 'كراتين 5 كغ', 'صناديق خشب 15 كغ', 'أكياس شبكية 25 كغ'];
  static const truckTypes = ['براد 40 قدم (Reefer)', 'براد 20 قدم', 'شاحنة مبرّدة متوسطة 12 طن'];

  static Trader demoTrader() => Trader(
        id: 'TR-1001',
        fullName: 'أحمد الخطيب',
        email: demoEmail,
        phone: demoPhone,
        companyName: 'شركة وادي الأردن للتصدير الزراعي',
        role: TraderRole.both,
        businessType: BusinessType.company,
        city: 'عمّان',
        commercialRegNo: '204587',
        establishmentNationalNo: '200145879',
        chamberMembershipNo: '58741',
        status: VerificationStatus.verified,
        joinedAt: DateTime(2025, 3, 14),
        documents: [
          UploadedDocument(type: 'شهادة السجل التجاري', fileName: 'commercial_registration.pdf', uploadedAt: DateTime(2025, 3, 14)),
          UploadedDocument(type: 'شهادة عضوية الغرفة', fileName: 'chamber_membership.pdf', uploadedAt: DateTime(2025, 3, 14)),
          UploadedDocument(type: 'رخصة المهن', fileName: 'vocational_license.jpg', uploadedAt: DateTime(2025, 3, 15)),
        ],
      );

  /// The three marketplace offers (two export, one import), with real product photos.
  static List<TradingOffer> offers() => const [
        TradingOffer(
          id: 'OF-201',
          type: OfferType.export,
          product: Products.tomato,
          variety: 'بندورة بلدية',
          imageAsset: 'assets/images/offer_tomato.png',
          quantityTons: 24,
          pricePerTonJod: 520,
          origin: 'الأغوار الشمالية',
          destination: 'عمّان',
          partner: 'شركة وادي الأردن للتصدير الزراعي',
          description: 'بندورة مقطوفة حديثًا ومفروزة في صناديق 10 كغ، جاهزة للنقل المبرّد عند 12°C.',
        ),
        TradingOffer(
          id: 'OF-202',
          type: OfferType.export,
          product: Products.cucumber,
          variety: 'خيار بلدي',
          imageAsset: 'assets/images/offer_cucumber.png',
          quantityTons: 18,
          pricePerTonJod: 310,
          origin: 'الأغوار الوسطى',
          destination: 'العقبة',
          partner: 'شركة وادي الأردن للتصدير الزراعي',
          description: 'خيار متوسط الحجم مغلّف بأكياس حفظ الرطوبة داخل صناديق مهوّاة.',
        ),
        TradingOffer(
          id: 'OF-203',
          type: OfferType.import,
          product: Products.potato,
          variety: 'بطاطا سبونتا',
          imageAsset: 'assets/images/offer_potato.png',
          quantityTons: 40,
          pricePerTonJod: 240,
          origin: 'مصر — الإسكندرية',
          destination: 'عمّان',
          partner: 'مؤسسة الدلتا للتصدير',
          description: 'بطاطا للاستيراد بأحجام متجانسة، مناسبة للتخزين الطويل عند 7°C.',
        ),
      ];

  static SensorReading _reading(double t, double h, double sp, {int minutesAgo = 5}) => SensorReading(
        time: DateTime.now().subtract(Duration(minutes: minutesAgo)),
        temperatureC: t,
        humidityPct: h,
        setpointC: sp,
        outsideTempC: 31,
      );

  static List<SensorReading> _history(double base, double sp) => List.generate(
        12,
        (i) => SensorReading(
          time: DateTime.now().subtract(Duration(hours: 11 - i)),
          temperatureC: base + ((i * 37) % 7 - 3) * 0.15,
          humidityPct: 89 + ((i * 13) % 5 - 2) * 0.6,
          setpointC: sp,
          outsideTempC: 28 + (i % 6),
        ),
      );

  static List<Shipment> shipments() {
    final now = DateTime.now();
    InspectionResult ins(String id, MaturityStage s, double c, double q) => InspectionResult(
          id: id,
          mediaType: MediaType.image,
          fileName: 'sample_$id.jpg',
          detectedProduct: 'tomato',
          maturityStage: s,
          confidence: c,
          qualityScore: q,
          defects: const [DetectedDefect(label: 'كدمات سطحية', severity: 0.2, areaPct: 3)],
          recommendation: 'الحفاظ على 12°C ورطوبة 90%.',
          modelVersion: 'mock-v1',
          isSimulated: true,
          createdAt: now.subtract(const Duration(hours: 20)),
        );

    return [
      Shipment(
        id: 'FR-24017',
        scenario: SimulationScenario.coolingFailure,
        exporterName: 'أحمد الخطيب',
        exporterCompany: 'شركة وادي الأردن للتصدير الزراعي',
        importerName: 'خالد العبادي',
        importerCompany: 'أسواق السلطان المركزية',
        importerGovernorate: 'عمّان',
        product: Products.tomato,
        variety: 'بندورة شيري',
        quantityTons: 18,
        packaging: 'صناديق بلاستيك 10 كغ',
        origin: 'الأغوار الشمالية',
        destination: 'عمّان',
        departure: now.subtract(const Duration(hours: 22)),
        eta: now.add(const Duration(hours: 26)),
        status: ShipmentStatus.active,
        truckType: 'براد 40 قدم (Reefer)',
        truckPlate: '22-45871',
        driverName: 'محمود العلي',
        coolingSetpointC: 12,
        smartCooling: true,
        reading: _reading(12.3, 89.5, 12),
        readings: _history(12.2, 12),
        qualityPct: 91,
        progress: 0.46,
        inspection: ins('INS-9001', MaturityStage.turning, 0.9, 88),
        forecast: const QualityForecast(arrivalQualityPct: 87, shelfLifeDays: 6, arrivalStage: MaturityStage.ripe, basis: 'تقدير تجريبي'),
        alerts: [
          ShipmentAlert(time: now.subtract(const Duration(hours: 6)), message: 'ارتفاع مؤقت في الحرارة عند معبر الحدود (تجريبي)', severity: AlertSeverity.warning),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Shipment(
        id: 'FR-24021',
        scenario: SimulationScenario.heatwaveBorder,
        exporterName: 'أحمد الخطيب',
        exporterCompany: 'شركة وادي الأردن للتصدير الزراعي',
        importerName: 'معاذ الحياري',
        importerCompany: 'مخازن الشمال للخضار',
        importerGovernorate: 'إربد',
        product: Products.cucumber,
        variety: 'خيار بلدي',
        quantityTons: 12,
        packaging: 'كراتين 5 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'إربد',
        departure: now.subtract(const Duration(hours: 8)),
        eta: now.add(const Duration(hours: 22)),
        status: ShipmentStatus.active,
        truckType: 'براد 20 قدم',
        truckPlate: '13-80214',
        driverName: 'يوسف حداد',
        coolingSetpointC: 11,
        smartCooling: false,
        reading: _reading(14.8, 82, 11),
        readings: _history(13.6, 11),
        qualityPct: 76,
        progress: 0.27,
        forecast: const QualityForecast(arrivalQualityPct: 70, shelfLifeDays: 4, arrivalStage: MaturityStage.ripe, basis: 'تقدير تجريبي'),
        alerts: [
          ShipmentAlert(time: now.subtract(const Duration(minutes: 40)), message: 'حرارة الحمولة أعلى من نقطة الضبط بـ 3.8°C (تجريبي)', severity: AlertSeverity.critical),
          ShipmentAlert(time: now.subtract(const Duration(hours: 2)), message: 'الرطوبة أقل من 85%', severity: AlertSeverity.warning),
        ],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Shipment(
        id: 'FR-24025',
        scenario: SimulationScenario.powerFluctuation,
        exporterName: 'أحمد الخطيب',
        exporterCompany: 'شركة وادي الأردن للتصدير الزراعي',
        importerName: 'ناصر الروسان',
        importerCompany: 'العقبة للتموين الفندقي',
        importerGovernorate: 'العقبة',
        product: Products.pepper,
        variety: 'فلفل ملوّن',
        quantityTons: 6,
        packaging: 'كراتين 5 كغ',
        origin: 'المفرق',
        destination: 'العقبة',
        departure: now.add(const Duration(days: 2)),
        eta: now.add(const Duration(days: 4)),
        status: ShipmentStatus.pending,
        truckType: 'شاحنة مبرّدة متوسطة 12 طن',
        truckPlate: '41-11902',
        driverName: 'سامر بني هاني',
        coolingSetpointC: 8,
        smartCooling: true,
        reading: _reading(8, 92, 8, minutesAgo: 60),
        qualityPct: 96,
        forecast: const QualityForecast(arrivalQualityPct: 92, shelfLifeDays: 12, arrivalStage: MaturityStage.ripe, basis: 'تقدير تجريبي'),
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Shipment(
        id: 'FR-23988',
        scenario: SimulationScenario.stable,
        exporterName: 'أحمد الخطيب',
        exporterCompany: 'شركة وادي الأردن للتصدير الزراعي',
        importerName: 'فهد الدعجة',
        importerCompany: 'شركة الزرقاء للتموين',
        importerGovernorate: 'الزرقاء',
        product: Products.dates,
        variety: 'تمر مجهول ملكي',
        quantityTons: 4,
        packaging: 'كراتين 5 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'الزرقاء',
        departure: now.subtract(const Duration(days: 6)),
        eta: now.subtract(const Duration(days: 4)),
        status: ShipmentStatus.delivered,
        truckType: 'براد 20 قدم',
        truckPlate: '22-30417',
        driverName: 'عمر الزعبي',
        coolingSetpointC: 4,
        smartCooling: true,
        reading: _reading(4.1, 70, 4, minutesAgo: 60 * 24 * 4),
        qualityPct: 95,
        progress: 1,
        forecast: const QualityForecast(arrivalQualityPct: 95, shelfLifeDays: 60, arrivalStage: MaturityStage.ripe, basis: 'قيمة نهائية تجريبية'),
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Shipment(
        id: 'FR-23940',
        scenario: SimulationScenario.humidityLoss,
        exporterName: 'أحمد الخطيب',
        exporterCompany: 'شركة وادي الأردن للتصدير الزراعي',
        importerName: 'حسن المجالي',
        importerCompany: 'أسواق الكرك المركزية',
        importerGovernorate: 'الكرك',
        product: Products.lemon,
        variety: 'ليمون أضاليا',
        quantityTons: 20,
        packaging: 'أكياس شبكية 25 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'الكرك',
        departure: now.subtract(const Duration(days: 30)),
        eta: now.subtract(const Duration(days: 27)),
        status: ShipmentStatus.archived,
        truckType: 'براد 40 قدم (Reefer)',
        truckPlate: '13-77810',
        driverName: 'رامي القضاة',
        coolingSetpointC: 11,
        smartCooling: false,
        reading: _reading(11.2, 88, 11, minutesAgo: 60 * 24 * 27),
        qualityPct: 84,
        progress: 1,
        forecast: const QualityForecast(arrivalQualityPct: 84, shelfLifeDays: 18, arrivalStage: MaturityStage.ripe, basis: 'قيمة نهائية تجريبية'),
        createdAt: now.subtract(const Duration(days: 32)),
      ),
    ];
  }

  static List<AppNotification> notifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'N-1', type: NotificationType.alert, shipmentId: 'FR-24021',
        title: 'تنبيه حرارة — FR-24021',
        body: 'حرارة حمولة الخيار أعلى من نقطة الضبط بـ 3.8°C. يُنصح بفحص وحدة التبريد والتواصل مع السائق. (بيانات تجريبية)',
        time: now.subtract(const Duration(minutes: 40)),
      ),
      AppNotification(
        id: 'N-3', type: NotificationType.shipment, shipmentId: 'FR-24017',
        title: 'الشحنة FR-24017 عبرت الحدود',
        body: 'مرّت الشحنة بمدينة السلط وتتجه نحو السوق المركزي في عمّان.',
        time: now.subtract(const Duration(hours: 6)), read: true,
      ),
      AppNotification(
        id: 'N-4', type: NotificationType.system,
        title: 'تم توثيق حسابك',
        body: 'تمت مراجعة وثائق منشأتك وتوثيق الحساب. يمكنك الآن نشر عروض التصدير.',
        time: now.subtract(const Duration(days: 3)), read: true,
      ),
    ];
  }
}
