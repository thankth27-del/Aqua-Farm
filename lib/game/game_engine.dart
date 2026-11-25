/// ตรรกะเกมทั้งหมด (Dart ล้วน ไม่ผูกกับ UI)
/// ย้ายจาก reference/index.html: ส่วน state / actions / day cycle & multi-day disaster
library;

import 'dart:math';

import '../data/constants.dart';
import '../data/difficulty.dart';
import '../data/disaster_data.dart';
import '../data/equipment_data.dart';
import '../data/fish_data.dart';
import '../data/food_data.dart';
import '../data/ingredients.dart';
import 'game_state.dart';
import 'js_math.dart';

/// ผลของการกระทำ — message เป็นข้อความภาษาไทยเดียวกับ toast ของต้นแบบ
class ActionResult {
  const ActionResult.ok(this.message, {this.warning = false}) : ok = true;
  const ActionResult.fail(this.message) : ok = false, warning = true;

  final bool ok;
  final String message;

  /// true = ควรแสดงแบบเตือน (สีแดง) เช่น ให้อาหารมากเกินไป
  final bool warning;

  @override
  String toString() => '${ok ? 'OK' : 'FAIL'}: $message';
}

/// สถานะคุณภาพน้ำ (wstat) — ต้นแบบใช้คำอังกฤษ ในเกมแสดงเป็นภาษาไทย
enum WaterStatus {
  excellent('ดีมาก', 0xFF65A30D),
  good('ดี', 0xFFA3C94A),
  warning('เฝ้าระวัง', 0xFFE9B949),
  critical('อันตราย', 0xFFE0584D);

  const WaterStatus(this.label, this.color);
  final String label;
  final int color;
}

/// ระดับของค่าน้ำแต่ละค่า (ใช้แสดงสีบนการ์ดค่าน้ำ ไม่มีผลต่อการคำนวณ)
enum ValueLevel {
  good('ปกติ'),
  watch('เริ่มสูง'),
  bad('อันตราย');

  const ValueLevel(this.label);
  final String label;
}

ValueLevel _levelAbove(double v, double watch, double bad) => v >= bad
    ? ValueLevel.bad
    : v >= watch
    ? ValueLevel.watch
    : ValueLevel.good;

/// สถานะความสดของอาหาร (stCls)
enum Freshness {
  fresh('สด', 0xFF65A30D),
  near('ใกล้หมดอายุ', 0xFFE9B949),
  expired('หมดอายุ', 0xFFE0584D);

  const Freshness(this.label, this.color);
  final String label;
  final int color;
}

/// ผล Readiness Check ก่อนภัย
class Readiness {
  const Readiness(
    this.equipmentRatio,
    this.pct, {
    this.equipmentPts = 0,
    this.supplyPts = 0,
    this.waterPts = 0,
    this.moneyPts = 0,
  });

  /// สัดส่วนอุปกรณ์ที่มี 0..1 (e)
  final double equipmentRatio;

  /// ความพร้อมรวม % (pct)
  final int pct;

  /// คะแนนแยกส่วน: อุปกรณ์ (เต็ม 50) เสบียง (30) น้ำ (10) เงิน (10)
  final int equipmentPts;
  final int supplyPts;
  final int waterPts;
  final int moneyPts;
}

/// คะแนนสรุปตอนจบเกม (หน้าชนะ / Game Over)
class GameSummary {
  const GameSummary({
    required this.mode,
    required this.won,
    required this.days,
    required this.targetDays,
    required this.grade,
    required this.disastersSurvived,
    required this.money,
  });

  final Difficulty mode;
  final bool won;

  /// รอดมาได้กี่วัน
  final int days;
  final int targetDays;

  /// เกรดรวม S/A/B
  final String grade;
  final int disastersSurvived;

  /// เงินคงเหลือ
  final int money;
}

class GameEngine {
  GameEngine(this.state, {Random? random}) : random = random ?? Random();

  /// เริ่มเกมใหม่ (newSlot ในต้นแบบ): สุ่มราคา แล้วตั้งราคาเมื่อวาน = วันนี้
  factory GameEngine.newGame(
    String slotName, {
    Random? random,
    Difficulty mode = Difficulty.normal,
  }) {
    final e = GameEngine(
      GameState.initial(slotName: slotName, mode: mode),
      random: random,
    );
    e.rollPrices();
    e.state.prevPrices = Map.of(e.state.prices);
    e.calcWater();
    return e;
  }

  GameState state;
  final Random random;

  GameState get s => state;

  // ---------------------------------------------------------------- queries

  int get fishTotal => s.fishStock.values.fold(0, (a, b) => a + b);
  int get matureCount => s.pond.where((f) => f.mature).length;

  double ageLeft(StockBatch b) => kFoods[b.food]!.shelfDays - b.age;
  bool isExpired(StockBatch b) => ageLeft(b) <= 0;
  bool isNearExpiry(StockBatch b) =>
      !isExpired(b) && ageLeft(b) <= max(1, kFoods[b.food]!.shelfDays * .3);
  Freshness freshness(StockBatch b) => isExpired(b)
      ? Freshness.expired
      : isNearExpiry(b)
      ? Freshness.near
      : Freshness.fresh;

  /// วันที่เหลือก่อนหมดอายุ (แสดงผล)
  int daysLeft(StockBatch b) => ageLeft(b).ceil();

  Iterable<StockBatch> get edible => s.stock.where((b) => !isExpired(b));

  /// จำนวนจานที่กินได้
  int get servings => edible.fold(0, (a, b) => a + b.qty);

  /// ความอิ่มรวมของเสบียงที่กินได้
  int get supplyHunger =>
      edible.fold(0, (a, b) => a + kFoods[b.food]!.hunger * b.qty);

  /// เสบียงอยู่ได้กี่วัน (คำนวณจากความอิ่ม ไม่ใช่นับจาน)
  double get supplyDays => round1(supplyHunger / kHungerPerDay);

  int get feedUnit => s.pond.fold(0, (a, f) => a + kFish[f.type]!.feed);
  int feedCost(int level) =>
      jsRound(kFeedCostMultiplier[level] * feedUnit * buyMultiplier);

  /// ค่าอาหารปลา "พอดี" [kFeedReserveDays] วัน (รวมปลาที่กำลังจะซื้อเพิ่ม [extraUnits] หน่วย)
  int feedReserve({int extraUnits = 0}) =>
      jsRound(
        kFeedCostMultiplier[2] * (feedUnit + extraUnits) * buyMultiplier,
      ) *
      kFeedReserveDays;

  /// ซื้อของราคา [cost] แล้วเงินเหลือไม่พอค่าอาหารปลา → ข้อความเตือน (null = ไม่ต้องเตือน)
  String? lowMoneyWarning(int cost, {int extraUnits = 0}) {
    final reserve = feedReserve(extraUnits: extraUnits);
    final left = s.money - cost;
    if (reserve <= 0 || left >= reserve) return null;
    return 'ระวัง! เหลือเงิน $left บาท ไม่พอค่าอาหารปลา '
        '$kFeedReserveDays วัน ($reserve บาท)';
  }

  /// เงินไม่พอแม้แต่ให้อาหาร "น้อย" → ลุงทองแบ่งอาหารปลาให้ฟรี (กันเลี้ยงต่อไม่ได้)
  bool get freeFeed => s.pond.isNotEmpty && s.money < feedCost(1);

  // ---------------------------------------------------------- difficulty

  DifficultySpec get difficulty => kDifficulties[s.mode]!;

  /// ต้องรอดครบกี่วันจึงชนะ
  int get targetDays => difficulty.targetDays;

  /// ความคืบหน้า = วันปัจจุบัน ÷ วันเป้าหมาย (0..1)
  double get progress => min(1.0, s.day / targetDays);

  /// ขั้นความยาก 0..5 (ขึ้นเป็นขั้นตามความคืบหน้า)
  int get stage => difficultyStage(s.day, targetDays);

  /// ตัวคูณราคาซื้อ (วัตถุดิบ อุปกรณ์ อาหารปลา)
  double get buyMultiplier => difficulty.buy * kStageBuy[stage];

  /// ตัวคูณราคาขาย (ปลา อาหาร) — ขึ้นช้ากว่าราคาซื้อ
  double get sellMultiplier => difficulty.sell * kStageSell[stage];

  /// ตัวคูณความรุนแรงของภัยที่ประกาศใหม่
  double get severityMultiplier => difficulty.severity * kStageSeverity[stage];

  /// ตัวคูณของเสียที่เกิดในบ่อต่อวัน (น้ำเสียเร็วขึ้น)
  double get waterMultiplier => difficulty.water * kStageWater[stage];

  /// ภัยชนิดนี้ถ้าประกาศตอนนี้ จะนานกี่วัน / เตือนล่วงหน้ากี่วัน
  int disasterDuration(DisasterType t) =>
      kDisasters[t]!.duration + kStageExtraDays[stage];
  int disasterWarnDays(DisasterType t) =>
      max(kMinWarnDays, kDisasters[t]!.leadDays - kStageWarnCut[stage]);

  int equipmentPrice(String id) =>
      jsRound(kEquipment[id]!.price * buyMultiplier);
  int fishSellPrice(String type) =>
      jsRound(kFish[type]!.sellPrice * sellMultiplier);
  int foodSellPrice(String food) =>
      jsRound(kFoods[food]!.value * kFoodSellScale * sellMultiplier);

  /// ตัวคูณการเติบโตของปลาวันนี้: ระหว่างภัยโตตามความพร้อมของอุปกรณ์
  /// และฟาร์มที่เสียหายยังไม่ซ่อมโตช้าลง (1 = ปกติ)
  double get farmGrowth {
    var g = 1.0;
    final a = s.active;
    if (a != null) {
      g *= kDisasterGrowthBase + (1 - kDisasterGrowthBase) * protection(a.type);
    }
    if (s.damaged) g *= kDamagedGrowth;
    return g;
  }

  /// เกรดรวมของทั้งเกม จากเกรดรายวันเฉลี่ย (S=3 A=2 B=1)
  String get overallGrade {
    if (s.gradeDays == 0) return 'B';
    final avg = s.gradePoints / s.gradeDays;
    return avg >= kOverallS ? 'S' : (avg >= kOverallA ? 'A' : 'B');
  }

  /// คะแนนสรุปตอนจบเกม
  GameSummary get summary => GameSummary(
    mode: s.mode,
    won: s.won,
    // แพ้: จบวันแล้ววันขยับไปแล้ว จึงนับวันสุดท้ายที่เล่นจริง
    days: s.won ? targetDays : (s.over ? s.day - 1 : s.day),
    targetDays: targetDays,
    grade: overallGrade,
    disastersSurvived: s.survived,
    money: s.money,
  );

  /// อีกกี่วันภัยจะมา (0 = ไม่มีการเตือน)
  int get warnDays {
    final dz = s.upcoming;
    if (dz == null) return 0;
    final d = dz.startDay - s.day;
    return d >= 1 && d <= dz.warnDays ? d : 0;
  }

  /// จำนวนอุปกรณ์ที่ต้องมีสำหรับภัยชนิดนี้
  ///
  /// แก้บั๊กจากต้นแบบ: กระสอบทรายถูกใช้หมดวันละ 1 ใบ แต่ต้นแบบยังเทียบกับ 4 ใบตลอด
  /// ทำให้ซื้อครบ 4 ใบแล้วความพร้อมก็ยังลดลงทุกวัน ที่นี่จึงนับเฉพาะวันที่เหลือของภัย
  int requiredEquipment(DisasterType type, String id) {
    final base = kDisasters[type]!.equipment[id]!;
    final a = s.active;
    if (id == kSandbagId && a != null && a.type == type && a.dayIndex >= 0) {
      return min(base, a.duration - a.dayIndex);
    }
    return base;
  }

  /// ความพร้อมของอุปกรณ์ 0..1 (protOf)
  double protection(DisasterType type) {
    final ids = kDisasters[type]!.equipment.keys.toList();
    final sum = ids.fold<double>(
      0,
      (a, k) => a + min(1.0, s.equipmentCount(k) / requiredEquipment(type, k)),
    );
    return sum / ids.length;
  }

  /// Readiness Check สำหรับภัยที่ประกาศล่วงหน้า (null ถ้ายังไม่มีประกาศ)
  Readiness? readiness() {
    final dz = s.upcoming;
    if (dz == null) return null;
    final e = protection(dz.type);
    final sup = min(1.0, supplyDays / dz.duration);
    final pct = jsRound(
      (e * .5 +
              sup * .3 +
              (s.water >= 60 ? .1 : 0) +
              (s.money >= 100 ? .1 : 0)) *
          100,
    );
    return Readiness(
      e,
      pct,
      equipmentPts: jsRound(e * 50),
      supplyPts: jsRound(sup * 30),
      waterPts: s.water >= 60 ? 10 : 0,
      moneyPts: s.money >= 100 ? 10 : 0,
    );
  }

  // ------------------------------------------------ ค่าน้ำรายตัว (แสดงผล)
  // เกณฑ์ตั้งจากสูตร calcWater: แต่ละค่าลดคะแนนน้ำราว 10 = เริ่มสูง, 30 = อันตราย

  ValueLevel get ammoniaLevel => _levelAbove(s.ammonia, .5, 1.5);
  ValueLevel get nitriteLevel => _levelAbove(s.nitrite, .5, 1.5);
  ValueLevel get nitrateLevel => _levelAbove(s.nitrate, 7, 20);
  ValueLevel get tempLevel => _levelAbove(s.temp, 31.5, 34);

  /// ออกซิเจนที่ปลาในบ่อต้องการ (ปลาที่ต้องการมากที่สุด)
  int get pondO2Need => s.pond.fold(0, (a, f) => max(a, kFish[f.type]!.o2Need));

  /// ต่ำกว่าที่ปลาต้องการ = ปลาเสียสุขภาพทุกวัน
  ValueLevel get o2Level {
    final need = s.pond.isEmpty ? 35 : pondO2Need;
    return s.o2 < need
        ? ValueLevel.bad
        : s.o2 < need + 15
        ? ValueLevel.watch
        : ValueLevel.good;
  }

  /// ค่าของเสีย (แอมโมเนีย ไนไตรต์ ไนเตรต) ที่แย่ที่สุด
  ValueLevel get wasteLevel => [
    ammoniaLevel,
    nitriteLevel,
    nitrateLevel,
  ].reduce((a, b) => a.index >= b.index ? a : b);

  /// สถานะบ่อรวม (ป้ายบนสุด): คะแนนน้ำ แต่ไม่ดีกว่าค่าที่แย่ที่สุด
  /// ค่าเริ่มสูง → ไม่เกิน "ดี" · ค่าอันตราย → ไม่เกิน "เฝ้าระวัง"
  /// · ออกซิเจนต่ำกว่าที่ปลาต้องการ → "อันตราย"
  WaterStatus get pondStatus {
    var st = waterStatus;
    final worst = [
      wasteLevel,
      tempLevel,
      o2Level,
    ].reduce((a, b) => a.index >= b.index ? a : b);
    final cap = o2Level == ValueLevel.bad
        ? WaterStatus.critical
        : worst == ValueLevel.bad
        ? WaterStatus.warning
        : worst == ValueLevel.watch
        ? WaterStatus.good
        : WaterStatus.excellent;
    if (cap.index > st.index) st = cap;
    return st;
  }

  /// คำแนะนำสั้นๆ ว่าควรทำอะไรกับบ่อ (null = ไม่ต้องทำอะไร)
  String? get waterAdvice {
    final tips = <String>[
      if (o2Level != ValueLevel.good)
        'ออกซิเจน${o2Level == ValueLevel.bad ? 'ไม่พอ' : 'เริ่มต่ำ'} → กด "เติมอากาศ"',
      if (wasteLevel != ValueLevel.good)
        'ของเสียสะสม → กด "เปลี่ยนน้ำ" หรือให้อาหารน้อยลง',
      if (tempLevel != ValueLevel.good) 'น้ำร้อนเกินไป ปลาเครียด',
    ];
    return tips.isEmpty ? null : tips.join('\n');
  }

  /// การโตสูงสุดของปลาในบ่อ (%)
  int get maxPondGrowth => s.pond.fold(0, (a, f) => max(a, f.growth));

  WaterStatus get waterStatus => s.water >= 80
      ? WaterStatus.excellent
      : s.water >= 60
      ? WaterStatus.good
      : s.water >= 40
      ? WaterStatus.warning
      : WaterStatus.critical;

  /// เสบียงที่ต้องใช้ช่วงภัยครั้งถัดไป (วัน) — หน้า "คลังสินค้า"
  int get supplyNeedDays {
    final a = s.active;
    if (s.upcoming != null && a == null) {
      return s.upcoming!.duration;
    }
    if (a != null) return a.duration - a.dayIndex - 1;
    return 0;
  }

  /// เสบียงหลังภัย (+ = เหลือ, − = ขาด)
  double get supplyAfterDisaster => round1(supplyDays - supplyNeedDays);

  /// เปอร์เซ็นต์ความคืบหน้าเป้าหมายเสบียง
  int get goalProgressPct => min(100, jsRound(supplyDays / s.goal * 100));
  bool get goalReached => supplyDays >= s.goal;
  double get goalShortfall => round1(s.goal - supplyDays);

  /// ปลาที่จะใช้ทำอาหาร/ถนอม (pickFish)
  String get fishForCooking {
    if (s.cookFish.isNotEmpty && (s.fishStock[s.cookFish] ?? 0) > 0) {
      return s.cookFish;
    }
    for (final k in s.fishStock.keys) {
      if (s.fishStock[k]! > 0) return k;
    }
    return '';
  }

  bool _hasIngredients(Map<String, int> need) =>
      need.entries.every((e) => (s.inventory[e.key] ?? 0) >= e.value);

  bool canCook(String recipe) =>
      fishForCooking.isNotEmpty && _hasIngredients(kRecipes[recipe]!.need);

  /// จำนวนอุปกรณ์ที่ถูกใช้โดยงานถนอมที่กำลังทำ
  int usedCapacity(String equipmentId) => s.processing
      .where((p) => kPreserveMethods[p.method]!.equipment == equipmentId)
      .length;

  int freeCapacity(String equipmentId) =>
      s.equipmentCount(equipmentId) - usedCapacity(equipmentId);

  bool canPreserve(String method) {
    final p = kPreserveMethods[method]!;
    return fishForCooking.isNotEmpty &&
        freeCapacity(p.equipment) > 0 &&
        _hasIngredients(p.need);
  }

  /// ตู้เย็นทำงานอยู่ไหม
  bool get fridgeWorking => s.equipmentCount('fridge') > 0 && s.power;

  // ---------------------------------------------------------------- helpers

  void calcWater() {
    s.water = clampInt(
      jsRound(
        100 -
            s.ammonia * 22 -
            s.nitrite * 18 -
            s.nitrate * 1.5 -
            max(0, s.temp - 31) * 3,
      ),
      0,
      100,
    );
  }

  /// สุ่มราคาวัตถุดิบวันใหม่ (roll)
  void rollPrices() {
    s.prevPrices = Map.of(s.prices);
    for (final ing in kIngredients.values) {
      s.prices[ing.id] = max(
        2,
        jsRound(
          ing.basePrice * (0.6 + random.nextDouble() * 0.9) * buyMultiplier,
        ),
      );
    }
  }

  ActionResult? _pay(int cost, int energy) {
    if (s.money < cost) return ActionResult.fail('เงินไม่พอ ต้องใช้ $cost บาท');
    if (s.energy < energy) {
      return const ActionResult.fail('พลังงานไม่พอ ไปพักผ่อนที่บ้านก่อน');
    }
    s.money -= cost;
    s.energy -= energy;
    return null;
  }

  static const _closedMsg = ActionResult.fail(
    'ตลาดปิดชั่วคราว เส้นทางถูกตัดขาดจากภัยพิบัติ',
  );

  void _addStock(String food, int qty) {
    for (final b in s.stock) {
      if (b.food == food && b.age == 0) {
        b.qty += qty;
        return;
      }
    }
    s.stock.add(StockBatch(food: food, qty: qty));
  }

  // ---------------------------------------------------------------- actions

  /// ซื้อปลา (askBuy + buyFish) — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult buyFish(String type, int qty) {
    final f = kFish[type]!;
    if (qty < 1) return const ActionResult.fail('จำนวนไม่ถูกต้อง');
    if (s.marketClosed) return _closedMsg;
    if (s.pond.length + qty > kPondCapacity) {
      return ActionResult.fail(
        'พื้นที่ในบ่อไม่พอ (ว่าง ${kPondCapacity - s.pond.length} ตัว)',
      );
    }
    final total = f.buyPrice * qty;
    if (s.money < total) {
      return ActionResult.fail('เงินไม่พอ ต้องใช้ $total บาท');
    }
    s.money -= total;
    for (var i = 0; i < qty; i++) {
      s.pond.add(PondFish(type: type));
    }
    return ActionResult.ok('ซื้อ${f.name} $qty ตัว ปล่อยลงบ่อแล้ว');
  }

  /// ให้อาหารปลา level 1=น้อย 2=พอดี 3=มาก
  ActionResult feed(int level) {
    if (s.pond.isEmpty) return const ActionResult.fail('ยังไม่มีปลาในบ่อ');
    if (s.fed != 0) return const ActionResult.fail('วันนี้ให้อาหารแล้ว');
    // เงินหมด: ให้ "น้อย" ได้ฟรี ปลายังโตต่อ จับขายแล้วตั้งตัวใหม่ได้
    if (level == 1 && freeFeed) {
      final err = _pay(0, kFeedEnergy);
      if (err != null) return err;
      s.fed = 1;
      return const ActionResult.ok(
        'ลุงทองแบ่งอาหารปลาให้ฟรี (น้อย) จับปลาขายได้แล้วค่อยซื้อเองนะ',
      );
    }
    final err = _pay(feedCost(level), kFeedEnergy);
    if (err != null) return err;
    s.fed = level;
    const msg = [
      '',
      'ให้อาหารน้อย ปลาโตช้า',
      'ให้อาหารพอดี ปลาโตดี',
      'ให้อาหารมากเกินไป ของเสียจะสะสม',
    ];
    return ActionResult.ok(msg[level], warning: level == 3);
  }

  ActionResult changeWater() {
    final err = _pay(kChangeWaterCost, kChangeWaterEnergy);
    if (err != null) return err;
    s.ammonia *= .3;
    s.nitrite *= .3;
    s.nitrate *= .3;
    s.o2 = min(100.0, s.o2 + 15);
    calcWater();
    return const ActionResult.ok('เปลี่ยนน้ำแล้ว ของเสียลดลง');
  }

  ActionResult aerate() {
    final err = _pay(kAerateCost, kAerateEnergy);
    if (err != null) return err;
    s.o2 = 100;
    return const ActionResult.ok('เติมอากาศแล้ว ออกซิเจนเต็ม');
  }

  ActionResult catchFish() {
    final m = s.pond.where((f) => f.mature).toList();
    if (m.isEmpty) return const ActionResult.fail('ยังไม่มีปลาที่โตพอจับ');
    final err = _pay(0, kCatchEnergy);
    if (err != null) return err;
    for (final f in m) {
      s.fishStock[f.type] = (s.fishStock[f.type] ?? 0) + 1;
    }
    s.pond.removeWhere((f) => f.mature);
    return ActionResult.ok('จับปลาได้ ${m.length} ตัว');
  }

  /// ขายปลา 1 ตัวจากคลัง — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult sellFish(String type) {
    if (s.marketClosed) return _closedMsg;
    if ((s.fishStock[type] ?? 0) <= 0) {
      return const ActionResult.fail('ไม่มีปลาชนิดนี้ในคลัง');
    }
    final f = kFish[type]!;
    s.fishStock[type] = s.fishStock[type]! - 1;
    final price = fishSellPrice(type);
    s.money += price;
    s.earned += price;
    return ActionResult.ok('ขาย${f.name} +$price บาท');
  }

  /// ซื้อวัตถุดิบ 1 ชิ้น ราคาตามวันนี้ — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult buyIngredient(String id) {
    if (s.marketClosed) return _closedMsg;
    final err = _pay(s.prices[id]!, 0);
    if (err != null) return err;
    s.inventory[id] = (s.inventory[id] ?? 0) + 1;
    return ActionResult.ok('ซื้อ${kIngredients[id]!.name}');
  }

  /// ซื้ออุปกรณ์ (askEq + buyEq) — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult buyEquipment(String id) {
    final e = kEquipment[id]!;
    if (s.marketClosed) return _closedMsg;
    final err = _pay(equipmentPrice(id), kBuyEquipmentEnergy);
    if (err != null) return err;
    s.equipment[id] = s.equipmentCount(id) + 1;
    return ActionResult.ok('ซื้อ${e.name}แล้ว');
  }

  void setCookFish(String type) => s.cookFish = type;

  /// ทำอาหาร: ใช้ปลา 1 ตัว + วัตถุดิบ ได้จาน = yield ของปลา
  ActionResult cook(String recipe) {
    if (!canCook(recipe)) return const ActionResult.fail('วัตถุดิบไม่พอ');
    final err = _pay(0, kCookEnergy);
    if (err != null) return err;
    final t = fishForCooking;
    s.fishStock[t] = s.fishStock[t]! - 1;
    kRecipes[recipe]!.need.forEach(
      (k, v) => s.inventory[k] = s.inventory[k]! - v,
    );
    final q = kFish[t]!.yieldDishes;
    _addStock(recipe, q);
    return ActionResult.ok(
      'ทำ${kFoods[recipe]!.name}ได้ $q จาน (ใช้${kFish[t]!.name})',
    );
  }

  /// เริ่มถนอมอาหาร (startProc)
  ActionResult startPreserve(String method) {
    final p = kPreserveMethods[method]!;
    if (fishForCooking.isEmpty) {
      return const ActionResult.fail('ไม่มีปลาในคลัง');
    }
    if (freeCapacity(p.equipment) <= 0) {
      return ActionResult.fail(
        'ต้องมี${kEquipment[p.equipment]!.name}ว่างอยู่ (ซื้อที่ตลาด)',
      );
    }
    if (!_hasIngredients(p.need)) {
      return const ActionResult.fail('วัตถุดิบไม่พอ');
    }
    final err = _pay(0, kPreserveEnergy);
    if (err != null) return err;
    final t = fishForCooking;
    s.fishStock[t] = s.fishStock[t]! - 1;
    p.need.forEach((k, v) => s.inventory[k] = s.inventory[k]! - v);
    s.processing.add(
      PreserveJob(method: method, qty: kFish[t]!.yieldDishes, daysLeft: p.days),
    );
    return ActionResult.ok('เริ่ม${p.name} ใช้เวลา ${p.days} วัน');
  }

  /// ขายอาหาร 1 จาน (sellBatch) — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult sellStock(int index) {
    if (index < 0 || index >= s.stock.length) {
      return const ActionResult.fail('ไม่พบอาหาร');
    }
    final b = s.stock[index];
    if (isExpired(b)) return const ActionResult.fail('อาหารหมดอายุ ขายไม่ได้');
    if (s.marketClosed) return _closedMsg;
    final it = kFoods[b.food]!;
    b.qty--;
    final price = foodSellPrice(b.food);
    s.money += price;
    s.earned += price;
    if (b.qty <= 0) s.stock.removeAt(index);
    return ActionResult.ok('ขาย${it.name} +$price บาท');
  }

  /// กินอาหาร 1 จาน (askEat + eatBatch)
  ActionResult eatStock(int index) {
    if (index < 0 || index >= s.stock.length) {
      return const ActionResult.fail('ไม่พบอาหาร');
    }
    final b = s.stock[index];
    if (isExpired(b)) return const ActionResult.fail('อาหารหมดอายุ กินไม่ได้');
    if (s.hunger >= 100) return const ActionResult.fail('อิ่มแล้ว');
    final it = kFoods[b.food]!;
    s.hunger = min(100, s.hunger + it.hunger);
    s.energy = min(100, s.energy + it.energy);
    s.joy = min(100, s.joy + 4);
    b.qty--;
    if (b.qty <= 0) s.stock.removeAt(index);
    return ActionResult.ok(
      'กิน${it.name} อิ่ม +${it.hunger} พลังงาน +${it.energy}',
    );
  }

  /// ทิ้งอาหารทั้งล็อต (askDiscard) — UI ต้องแสดงหน้ายืนยันก่อนเรียก
  ActionResult discardStock(int index) {
    if (index < 0 || index >= s.stock.length) {
      return const ActionResult.fail('ไม่พบอาหาร');
    }
    final b = s.stock.removeAt(index);
    return ActionResult.ok('ทิ้ง${kFoods[b.food]!.name} ${b.qty} จาน');
  }

  ActionResult rest() {
    if (s.energy >= 100) return const ActionResult.fail('พลังงานเต็มแล้ว');
    s.energy = min(100, s.energy + kRestEnergyGain);
    s.hunger = max(0, s.hunger - kRestHungerCost);
    s.joy = min(100, s.joy + 3);
    return const ActionResult.ok('พักผ่อนแล้ว พลังงาน +40 (หิวขึ้นเล็กน้อย)');
  }

  /// ซ่อมแซมและฟื้นฟูฟาร์มหลังภัย
  ActionResult repair() {
    if (!s.damaged) return const ActionResult.fail('ฟาร์มไม่เสียหาย');
    final err = _pay(s.repairCost, kRepairEnergy);
    if (err != null) return err;
    s.damaged = false;
    s.repairCost = 0;
    s.ammonia *= .5;
    s.joy = min(100, s.joy + 10);
    return const ActionResult.ok('ซ่อมแซมและฟื้นฟูฟาร์มเรียบร้อย');
  }

  ActionResult setGoal(int days) {
    if (!kSupplyGoals.contains(days)) {
      return const ActionResult.fail('เป้าหมายไม่ถูกต้อง');
    }
    s.goal = days;
    return ActionResult.ok('ตั้งเป้าหมายเสบียง $days วัน');
  }

  // ---------------------------------------------------------------- day cycle

  /// เกรดประจำวัน S/A/B
  String grade(DayReport r) {
    var p = r.earned >= 200 ? 2 : (r.earned >= 50 ? 1 : 0);
    if (s.water >= 60) p++;
    if (supplyDays >= 2) p++;
    final ev = r.event;
    if (ev != null) {
      if (ev.protectionPct >= 66) p++;
      if (ev.lost > 0) p--;
    } else if (warnDays > 0 && (readiness()?.pct ?? 0) >= 60) {
      p++;
    }
    if (s.damaged) p--;
    return p >= 4 ? 'S' : (p >= 2 ? 'A' : 'B');
  }

  /// ผลของภัย 1 วัน (actDay)
  EventReport _disasterDay() {
    final a = s.active!;
    final d = kDisasters[a.type]!;
    final i = a.dayIndex;
    // ภัยที่ถูกยืด: วันที่เพิ่มใช้ข้อมูลของวันที่รุนแรงที่สุด
    final bi = disasterBaseDay(a.type, a.duration, i);
    final prot = protection(a.type);
    final weights = [
      for (var k = 0; k < a.duration; k++)
        kDisasterDayWeights[disasterBaseDay(a.type, a.duration, k)],
    ];
    final w = weights[i] / weights.reduce((x, y) => x + y);
    final n = s.pond.length;
    final lost = min(
      n,
      jsRound(
        a.fishBefore *
            a.severity *
            w *
            (1 - .75 * prot) *
            (s.water < 50 ? 1.25 : 1),
      ),
    );
    s.pond = s.pond.sublist(0, n - lost);
    a.lost += lost;

    switch (a.type) {
      case DisasterType.flood:
        s.ammonia += .4 * (1 - .7 * prot);
        s.o2 = max(15.0, s.o2 - 8);
      case DisasterType.drought:
        s.temp += 1.2 * (1 - .6 * prot);
      case DisasterType.poll:
        s.ammonia += .7 * (1 - .7 * prot);
      case DisasterType.heat:
        s.temp += 1.6 * (1 - .6 * prot);
        s.o2 = max(15.0, s.o2 - 10 * (1 - .7 * prot));
    }

    final cost = jsRound(40 * a.severity * (1 - .6 * prot));
    if (cost > 0) {
      s.repairCost += cost;
      s.damaged = true;
      a.cost += cost;
    }
    if (a.type == DisasterType.flood && s.equipmentCount(kSandbagId) > 0) {
      s.equipment[kSandbagId] = s.equipmentCount(kSandbagId) - 1;
      a.sandUsed++;
    }

    var foodLost = 0;
    if (a.type == DisasterType.flood && d.marketClosed[bi]) {
      for (final b in s.stock) {
        final it = kFoods[b.food]!;
        if (it.kind == FoodKind.meal || b.food == 'dried') {
          final l = jsRound(b.qty * .3 * (1 - prot));
          b.qty -= l;
          foodLost += l;
        }
      }
      s.stock.removeWhere((b) => b.qty <= 0);
      a.foodLost += foodLost;
    }

    calcWater();
    s.power = !d.powerOut[bi];
    s.marketClosed = d.marketClosed[bi];

    return EventReport(
      type: a.type,
      dayIndex: i,
      duration: a.duration,
      text: disasterDayText(a.type, a.duration, i),
      lost: lost,
      cumulativeLost: a.lost,
      fishBefore: a.fishBefore,
      fishAfter: s.pond.length,
      protectionPct: jsRound(prot * 100),
      cost: cost,
      cumulativeCost: a.cost,
      food: foodLost,
      cumulativeFood: a.foodLost,
      sandUsed: a.sandUsed,
      last: i == a.duration - 1,
      outage: d.powerOut[bi],
      marketClosed: d.marketClosed[bi],
    );
  }

  /// จบวัน (endDay) — คืนรายงานประจำวัน; ถ้า report.gameOver = true ห้ามเซฟ
  DayReport endDay() {
    final r = DayReport(day: s.day, earned: s.earned);
    final n0 = s.pond.length;
    final fu = feedUnit;

    // ของเสียจากอาหารปลา + วงจรไนโตรเจนผ่านไบโอฟิลเตอร์
    s.ammonia +=
        (kFeedAmmonia[s.fed] * (fu > 14 ? 1.3 : 1) * max(1, fu / 4) +
            fu * .05) *
        waterMultiplier;
    final c = s.bio / 100;
    var t = s.ammonia * .6 * c;
    s.ammonia -= t;
    s.nitrite += t;
    t = s.nitrite * .6 * c;
    s.nitrite -= t;
    s.nitrate += t;
    if (n0 > 0) s.bio = min(100, s.bio + 8);
    s.ammonia = toFixed2(s.ammonia);
    s.nitrite = toFixed2(s.nitrite);
    s.nitrate = toFixed2(s.nitrate);
    s.temp += (28 - s.temp) * .5;
    s.o2 = max(0.0, s.o2 - 10 - n0 * 1.5);
    calcWater();

    // สุขภาพและการเติบโตของปลา
    final fg = farmGrowth;
    for (final f in s.pond) {
      final spec = kFish[f.type]!;
      double st = s.water < 40 ? -25 : (s.water < 60 ? -10 : 5);
      if (st < 0) st *= 1.4 - spec.toughness * .15;
      if (s.o2 < spec.o2Need) st -= 12;
      f.health = clampDouble(f.health + st, 0, 100);
      f.growth = min(
        100,
        jsRound(
          f.growth +
              kFeedGrowth[s.fed] *
                  spec.growthMul *
                  max(.5, f.health / 100) *
                  (s.water >= 60 ? 1 : .6) *
                  fg,
        ),
      );
    }
    s.pond.removeWhere((f) => f.health <= 0);
    r.died = n0 - s.pond.length;

    // งานถนอมอาหาร
    for (final p in s.processing) {
      p.daysLeft--;
    }
    for (final p in s.processing.where((p) => p.daysLeft <= 0)) {
      _addStock(p.method, p.qty);
      r.done.add(DoneItem(p.method, p.qty));
    }
    s.processing.removeWhere((p) => p.daysLeft <= 0);

    // อาหารเสื่อม: อาหารสุก ตู้เย็น+ไฟ = 0.5, มีไฟ = 1, ไฟดับ = 1.5 / อาหารถนอม = 1
    for (final b in s.stock) {
      final it = kFoods[b.food]!;
      final was = isExpired(b);
      b.age += it.coolable ? (fridgeWorking ? .5 : (s.power ? 1 : 1.5)) : 1;
      if (!was && isExpired(b)) r.spoiled += b.qty;
    }

    // ตัวละคร
    s.hunger = max(0, s.hunger - kHungerPerDay);
    s.energy = min(100, s.energy + kNightEnergyGain);
    if (s.hunger <= 0) {
      s.health = max(0, s.health - 20);
    } else if (s.hunger < 20) {
      s.health = max(0, s.health - 5);
    } else if (s.hunger > 50) {
      s.health = min(100, s.health + 5);
    }
    s.joy = max(0, s.joy - 2);
    s.fed = 0;
    s.day++;
    s.power = true;
    s.marketClosed = false;

    // ภัยพิบัติหลายวัน
    final dz = s.upcoming;
    if (dz != null && s.day == dz.startDay) {
      s.active = ActiveDisaster(
        type: dz.type,
        duration: dz.duration,
        severity: dz.severity,
        fishBefore: s.pond.length,
      );
      s.upcoming = null;
    }
    final a = s.active;
    if (a != null) {
      a.dayIndex++;
      final ev = _disasterDay();
      r.event = ev;
      r.died += ev.lost;
      if (ev.last) {
        ev.supplyDaysAfter = supplyDays;
        s.survived++;
        s.joy = max(0, s.joy - (ev.protectionPct >= 100 ? 5 : 15));
        final next =
            kDisasterOrder[(kDisasterOrder.indexOf(a.type) + 1) %
                kDisasterOrder.length];
        // ภัยถัดไปหนักขึ้นตามขั้นความยาก: รุนแรงขึ้น นานขึ้น เตือนช้าลง
        // (ช่วงห่างระหว่างภัยเท่าต้นแบบ เตือนสั้นลงอย่างเดียว)
        final dur = disasterDuration(next);
        final warn = disasterWarnDays(next);
        s.upcoming = UpcomingDisaster(
          type: next,
          startDay: s.day + kDisasters[next]!.leadDays + kDisasterGapDays,
          severity: toFixed2(
            (.4 + random.nextDouble() * .3) * severityMultiplier,
          ),
          customDuration: dur == kDisasters[next]!.duration ? null : dur,
          customWarnDays: warn == kDisasters[next]!.leadDays ? null : warn,
        );
        s.active = null;
      }
    }

    r.water = s.water;
    r.o2 = s.o2;
    r.servings = servings;
    r.supplyDays = supplyDays;
    r.fish = s.pond.length;
    r.money = s.money;
    r.grade = grade(r);
    if (r.grade == 'S') s.joy = min(100, s.joy + 10);
    s.gradePoints += kGradePoints[r.grade]!;
    s.gradeDays++;

    s.lastReport = r;
    s.earned = 0;
    rollPrices();
    if (s.health <= 0) {
      s.over = true;
      r.gameOver = true;
    } else if (r.day >= targetDays) {
      // รอดครบวันเป้าหมาย = ชนะ
      s.won = true;
      r.won = true;
    }
    return r;
  }
}
