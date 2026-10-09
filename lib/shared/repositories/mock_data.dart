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
  static const demoEmail = 'demo@freshroute.jo';
  static const demoPhone = '0791234567';
  static const demoPassword = 'Demo1234';
  static const demoOtp = '123456';

  static const governorates = [
    'عمّان', 'إربد', 'الزرقاء', 'البلقاء', 'المفرق', 'جرش', 'عجلون', 'مادبا', 'الكرك', 'الطفيلة', 'معان', 'العقبة',
  ];
  static const originHubs = ['عمّان', 'الأغوار الشمالية', 'الأغوار الوسطى', 'إربد', 'المفرق', 'العقبة', 'الكرك'];
  static const destinations = ['دبي', 'الرياض', 'جدة', 'الدوحة', 'الكويت', 'مسقط', 'المنامة', 'بغداد', 'عمّان'];
  static const countries = ['الإمارات', 'السعودية', 'قطر', 'الكويت', 'عُمان', 'البحرين', 'العراق', 'الأردن'];
  static const packagingTypes = ['صناديق بلاستيك 10 كغ', 'كراتين 5 كغ', 'صناديق خشب 15 كغ', 'أكياس شبكية 25 كغ'];
  static const truckTypes = ['براد 40 قدم (Reefer)', 'براد 20 قدم', 'شاحنة مبرّدة متوسطة 12 طن'];
  static const paymentTerms = ['دفع مسبق 100%', '30% مقدمًا و70% عند التسليم', 'اعتماد مستندي (L/C)', 'دفع عند التسليم'];

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

  static List<TradingOffer> offers() {
    final now = DateTime.now();
    TradingOffer o(String id, Product p, String variety, double qty, double min, double price, String from, String to,
            String seller, bool verified, double rating, Availability a, int inDays, String grade, String desc) =>
        TradingOffer(
          id: id,
          product: p,
          variety: variety,
          quantityTons: qty,
          minOrderTons: min,
          pricePerTonJod: price,
          origin: from,
          destination: to,
          sellerName: seller,
          sellerVerified: verified,
          sellerRating: rating,
          availability: a,
          availableFrom: now.add(Duration(days: inDays)),
          grade: grade,
          description: desc,
          publishedAt: now.subtract(Duration(hours: inDays * 7 + 3)),
        );

    return [
      o('OF-201', Products.tomato, 'بندورة شيري', 24, 4, 520, 'الأغوار الشمالية', 'دبي', 'مزارع الغور الذهبي', true, 4.8, Availability.available, 1, 'درجة أولى',
          'بندورة شيري مقطوفة حديثًا في مرحلة بداية التلوّن، مناسبة للنقل المبرّد حتى 72 ساعة.'),
      o('OF-202', Products.cucumber, 'خيار بلدي', 18, 3, 310, 'الأغوار الوسطى', 'الرياض', 'تعاونية دير علا', true, 4.6, Availability.available, 2, 'درجة أولى',
          'خيار بلدي متوسط الحجم، معبأ في صناديق بلاستيكية مهوّاة.'),
      o('OF-203', Products.pepper, 'فلفل ملوّن', 10, 2, 780, 'المفرق', 'الدوحة', 'البيوت المحمية الحديثة', true, 4.9, Availability.limited, 3, 'ممتاز',
          'فلفل حلو بثلاثة ألوان من بيوت محمية، فرز آلي حسب الحجم واللون.'),
      o('OF-204', Products.potato, 'بطاطا سبونتا', 60, 10, 240, 'المفرق', 'بغداد', 'مزارع الصحراء الخضراء', false, 4.2, Availability.available, 0, 'درجة أولى',
          'بطاطا سبونتا للتصدير، مناسبة للتخزين الطويل.'),
      o('OF-205', Products.dates, 'تمر مجهول ملكي', 8, 1, 4200, 'الأغوار الوسطى', 'الكويت', 'نخيل وادي الأردن', true, 5.0, Availability.preOrder, 10, 'ملكي',
          'تمر مجهول حجم كبير جدًا، تعبئة كرتونية 5 كغ.'),
      o('OF-206', Products.eggplant, 'باذنجان أسود', 15, 3, 290, 'الأغوار الشمالية', 'جدة', 'مزارع الشونة', true, 4.4, Availability.available, 1, 'درجة أولى',
          'باذنجان لامع متجانس الحجم.'),
      o('OF-207', Products.strawberry, 'فراولة فستيفال', 4, 0.5, 1650, 'إربد', 'دبي', 'مزارع الشمال', true, 4.7, Availability.limited, 2, 'ممتاز',
          'فراولة حسّاسة تتطلب تبريدًا قريبًا من 2°C ونقلًا سريعًا.'),
      o('OF-208', Products.lemon, 'ليمون أضاليا', 30, 5, 450, 'الأغوار الوسطى', 'مسقط', 'تعاونية الكرامة', false, 4.1, Availability.available, 4, 'درجة ثانية',
          'ليمون عالي العصارة، مناسب للأسواق والمطاعم.'),
      o('OF-209', Products.zucchini, 'كوسا بلدي', 12, 2, 360, 'الأغوار الشمالية', 'المنامة', 'مزارع الغور الذهبي', true, 4.8, Availability.available, 1, 'درجة أولى',
          'كوسا بلدي صغير الحجم مطلوب في أسواق الخليج.'),
      o('OF-210', Products.watermelon, 'بطيخ أحمر', 40, 8, 180, 'الكرك', 'الرياض', 'مزارع الجنوب', true, 4.3, Availability.preOrder, 7, 'درجة أولى',
          'بطيخ موسم مبكر بوزن 6–9 كغ للحبة.'),
    ];
  }

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
        importerName: 'خالد المنصوري',
        importerCompany: 'مؤسسة الإمارات للأغذية الطازجة',
        importerCountry: 'الإمارات',
        product: Products.tomato,
        variety: 'بندورة شيري',
        quantityTons: 18,
        packaging: 'صناديق بلاستيك 10 كغ',
        origin: 'الأغوار الشمالية',
        destination: 'دبي',
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
        importerName: 'سعود القحطاني',
        importerCompany: 'أسواق الرياض المركزية',
        importerCountry: 'السعودية',
        product: Products.cucumber,
        variety: 'خيار بلدي',
        quantityTons: 12,
        packaging: 'كراتين 5 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'الرياض',
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
        importerName: 'ناصر الكواري',
        importerCompany: 'الدوحة للخضار والفواكه',
        importerCountry: 'قطر',
        product: Products.pepper,
        variety: 'فلفل ملوّن',
        quantityTons: 6,
        packaging: 'كراتين 5 كغ',
        origin: 'المفرق',
        destination: 'الدوحة',
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
        importerName: 'فهد العنزي',
        importerCompany: 'شركة الكويت للتموين',
        importerCountry: 'الكويت',
        product: Products.dates,
        variety: 'تمر مجهول ملكي',
        quantityTons: 4,
        packaging: 'كراتين 5 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'الكويت',
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
        importerName: 'حسن البلوشي',
        importerCompany: 'مسقط للمواد الغذائية',
        importerCountry: 'عُمان',
        product: Products.lemon,
        variety: 'ليمون أضاليا',
        quantityTons: 20,
        packaging: 'أكياس شبكية 25 كغ',
        origin: 'الأغوار الوسطى',
        destination: 'مسقط',
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
        id: 'N-2', type: NotificationType.deal,
        title: 'طلب صفقة جديد',
        body: 'أرسلت "مؤسسة الإمارات للأغذية الطازجة" طلب شراء 6 طن من البندورة الشيري.',
        time: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: 'N-3', type: NotificationType.shipment, shipmentId: 'FR-24017',
        title: 'الشحنة FR-24017 عبرت الحدود',
        body: 'عبرت الشحنة معبر العمري وتتجه نحو دبي. الوصول المتوقع خلال 26 ساعة.',
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
