/// สถานะเกมทั้งหมด (ตัวแปร S ในต้นแบบ) + แปลง JSON สำหรับเซฟ
/// คีย์ JSON ใช้ชื่อเดียวกับต้นแบบ (เซฟ v4)
library;

import '../data/constants.dart';
import '../data/difficulty.dart';
import '../data/disaster_data.dart';
import '../data/fish_data.dart';
import '../data/ingredients.dart';
import 'js_math.dart';

double _d(Object? v, [double def = 0]) =>
    v == null ? def : (v as num).toDouble();
int _i(Object? v, [int def = 0]) => v == null ? def : (v as num).toInt();
Map<String, int> _intMap(Object? v) => v == null
    ? {}
    : (v as Map).map((k, x) => MapEntry(k as String, (x as num).toInt()));

DisasterType disasterFromName(String n) => DisasterType.values.byName(n);

/// ปลา 1 ตัวในบ่อ
class PondFish {
  PondFish({
    required this.type,
    this.growth = 0,
    this.health = 100,
    this.disease,
    this.sickDays = 0,
    this.treatDays = 0,
    this.quarantine = false,
  });

  /// id ปลา (t)
  final String type;

  /// การเติบโต 0-100 (g) — 100 = พร้อมจับ
  int growth;

  /// สุขภาพ 0-100 (h) — อาจเป็นทศนิยม
  double health;

  /// โรคที่เป็นอยู่ (id ใน kDiseases) · null = ปกติ
  String? disease;

  /// ป่วยมาแล้วกี่วัน (ไม่รักษา ครบกำหนด = ตาย)
  int sickDays;

  /// กำลังรักษาด้วยยาที่ถูก เหลืออีกกี่วันหาย · 0 = ไม่ได้รักษา
  int treatDays;

  /// อยู่ในบ่อพักแยกปลา (ไม่แพร่เชื้อ ไม่ติดเชื้อ)
  bool quarantine;

  bool get mature => growth >= 100;
  bool get sick => disease != null;

  Map<String, dynamic> toJson() => {
    't': type,
    'g': growth,
    'h': health,
    'dz': ?disease,
    if (sickDays > 0) 'sd': sickDays,
    if (treatDays > 0) 'td': treatDays,
    if (quarantine) 'q': true,
  };
  factory PondFish.fromJson(Map<String, dynamic> j) => PondFish(
    type: j['t'] as String,
    growth: _i(j['g']),
    health: _d(j['h'], 100),
    disease: j['dz'] as String?,
    sickDays: _i(j['sd']),
    treatDays: _i(j['td']),
    quarantine: (j['q'] as bool?) ?? false,
  );
}

/// อาหาร 1 ล็อตในคลัง (อายุ a เพิ่มทีละ 0.5/1/1.5 ต่อวัน)
class StockBatch {
  StockBatch({required this.food, required this.qty, this.age = 0});

  /// id อาหาร (k)
  final String food;

  /// จำนวนจาน (q)
  int qty;

  /// อายุที่ผ่านไป (a)
  double age;

  Map<String, dynamic> toJson() => {'k': food, 'q': qty, 'a': age};
  factory StockBatch.fromJson(Map<String, dynamic> j) =>
      StockBatch(food: j['k'] as String, qty: _i(j['q']), age: _d(j['a']));
}

/// งานถนอมอาหารที่กำลังทำ
class PreserveJob {
  PreserveJob({
    required this.method,
    required this.qty,
    required this.daysLeft,
  });
  final String method;
  final int qty;
  int daysLeft;

  Map<String, dynamic> toJson() => {'k': method, 'q': qty, 'left': daysLeft};
  factory PreserveJob.fromJson(Map<String, dynamic> j) => PreserveJob(
    method: j['k'] as String,
    qty: _i(j['q']),
    daysLeft: _i(j['left']),
  );
}

/// ภัยที่ประกาศล่วงหน้า (dz)
class UpcomingDisaster {
  UpcomingDisaster({
    required this.type,
    required this.startDay,
    required this.severity,
    this.customDuration,
    this.customWarnDays,
  });
  final DisasterType type;
  final int startDay;
  final double severity;

  /// ความยาวภัย / ข่าวเตือนล่วงหน้า (ตามขั้นความยากตอนประกาศ)
  /// null = เท่าต้นแบบ (เซฟเก่าและภัยแรกของเกม)
  final int? customDuration;
  final int? customWarnDays;

  int get duration => customDuration ?? kDisasters[type]!.duration;
  int get warnDays => customWarnDays ?? kDisasters[type]!.leadDays;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'start': startDay,
    'sev': severity,
    'dur': ?customDuration,
    'warn': ?customWarnDays,
  };
  factory UpcomingDisaster.fromJson(Map<String, dynamic> j) => UpcomingDisaster(
    type: disasterFromName(j['type'] as String),
    startDay: _i(j['start']),
    severity: _d(j['sev']),
    customDuration: j['dur'] == null ? null : _i(j['dur']),
    customWarnDays: j['warn'] == null ? null : _i(j['warn']),
  );
}

/// ภัยที่กำลังเกิด (act)
class ActiveDisaster {
  ActiveDisaster({
    required this.type,
    required this.duration,
    required this.severity,
    required this.fishBefore,
    this.dayIndex = -1,
    this.lost = 0,
    this.cost = 0,
    this.sandUsed = 0,
    this.foodLost = 0,
  });

  final DisasterType type;
  final int duration;
  final double severity;
  final int fishBefore;

  /// วันของภัย เริ่ม 0 (i)
  int dayIndex;
  int lost;
  int cost;
  int sandUsed;
  int foodLost;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'i': dayIndex,
    'dur': duration,
    'sev': severity,
    'before': fishBefore,
    'lost': lost,
    'cost': cost,
    'used': sandUsed,
    'food': foodLost,
  };
  factory ActiveDisaster.fromJson(Map<String, dynamic> j) => ActiveDisaster(
    type: disasterFromName(j['type'] as String),
    dayIndex: _i(j['i']),
    duration: _i(j['dur']),
    severity: _d(j['sev']),
    fishBefore: _i(j['before']),
    lost: _i(j['lost']),
    cost: _i(j['cost']),
    sandUsed: _i(j['used']),
    foodLost: _i(j['food']),
  );
}

/// รายงานภัยประจำวัน (ผลของ actDay)
class EventReport {
  EventReport({
    required this.type,
    required this.dayIndex,
    required this.duration,
    required this.text,
    required this.lost,
    required this.cumulativeLost,
    required this.fishBefore,
    required this.fishAfter,
    required this.protectionPct,
    required this.cost,
    required this.cumulativeCost,
    required this.food,
    required this.cumulativeFood,
    required this.sandUsed,
    required this.last,
    required this.outage,
    required this.marketClosed,
    this.supplyDaysAfter,
  });

  final DisasterType type;
  final int dayIndex;
  final int duration;
  final String text;
  final int lost;
  final int cumulativeLost;
  final int fishBefore;
  final int fishAfter;
  final int protectionPct;
  final int cost;
  final int cumulativeCost;
  final int food;
  final int cumulativeFood;
  final int sandUsed;
  final bool last;
  final bool outage;
  final bool marketClosed;

  /// เสบียงเหลือกี่วันเมื่อภัยจบ (sup) — มีเฉพาะวันสุดท้าย
  double? supplyDaysAfter;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'i': dayIndex,
    'dur': duration,
    'text': text,
    'lost': lost,
    'cum': cumulativeLost,
    'before': fishBefore,
    'after': fishAfter,
    'prot': protectionPct,
    'cost': cost,
    'cumCost': cumulativeCost,
    'food': food,
    'cumFood': cumulativeFood,
    'used': sandUsed,
    'last': last,
    'outage': outage,
    'closed': marketClosed,
    'sup': supplyDaysAfter,
  };
  factory EventReport.fromJson(Map<String, dynamic> j) => EventReport(
    type: disasterFromName(j['type'] as String),
    dayIndex: _i(j['i']),
    duration: _i(j['dur']),
    text: j['text'] as String,
    lost: _i(j['lost']),
    cumulativeLost: _i(j['cum']),
    fishBefore: _i(j['before']),
    fishAfter: _i(j['after']),
    protectionPct: _i(j['prot']),
    cost: _i(j['cost']),
    cumulativeCost: _i(j['cumCost']),
    food: _i(j['food']),
    cumulativeFood: _i(j['cumFood']),
    sandUsed: _i(j['used']),
    last: j['last'] as bool,
    outage: j['outage'] as bool,
    marketClosed: j['closed'] as bool,
    supplyDaysAfter: j['sup'] == null ? null : _d(j['sup']),
  );
}

/// อาหารถนอมที่เสร็จในวันนั้น
class DoneItem {
  const DoneItem(this.food, this.qty);
  final String food;
  final int qty;
  Map<String, dynamic> toJson() => {'k': food, 'q': qty};
  factory DoneItem.fromJson(Map<String, dynamic> j) =>
      DoneItem(j['k'] as String, _i(j['q']));
}

/// รายงานประจำวัน (rep)
class DayReport {
  DayReport({required this.day, required this.earned});

  final int day;
  final int earned;
  int died = 0;
  EventReport? event;
  final List<DoneItem> done = [];

  /// จำนวนจานที่เพิ่งหมดอายุ
  int spoiled = 0;
  int water = 0;
  double o2 = 0;

  /// จำนวนจานที่กินได้ (sup)
  int servings = 0;

  /// เสบียงอยู่ได้กี่วัน (days)
  double supplyDays = 0;
  int fish = 0;
  int money = 0;

  /// โรคปลา: ป่วยใหม่ (ชื่อโรค) ตายจากโรค หายป่วย ยาไม่ได้ผลเพราะน้ำแย่
  final List<String> sickNew = [];
  int diseaseDied = 0;
  int cured = 0;
  int treatFailed = 0;

  /// ค่าไฟเครื่องเติมอากาศที่จ่ายคืนนี้ · ปิดเองเพราะเงินไม่พอ
  int aeratorCost = 0;
  bool aeratorOff = false;

  /// เกรด S/A/B
  String grade = 'B';

  /// สุขภาพหมด จบเกม
  bool gameOver = false;

  /// รอดครบวันเป้าหมาย ชนะ
  bool won = false;

  Map<String, dynamic> toJson() => {
    'day': day,
    'earned': earned,
    'died': died,
    'ev': event?.toJson(),
    'done': done.map((d) => d.toJson()).toList(),
    'spoil': spoiled,
    'water': water,
    'o2': o2,
    'sup': servings,
    'days': supplyDays,
    'fish': fish,
    'money': money,
    'g': grade,
    'over': gameOver,
    'won': won,
    if (sickNew.isNotEmpty) 'sick': sickNew,
    if (diseaseDied > 0) 'dzDied': diseaseDied,
    if (cured > 0) 'cured': cured,
    if (treatFailed > 0) 'tFail': treatFailed,
    if (aeratorCost > 0) 'airCost': aeratorCost,
    if (aeratorOff) 'airOff': true,
  };

  factory DayReport.fromJson(Map<String, dynamic> j) {
    final r = DayReport(day: _i(j['day']), earned: _i(j['earned']))
      ..died = _i(j['died'])
      ..event = j['ev'] == null
          ? null
          : EventReport.fromJson(Map<String, dynamic>.from(j['ev'] as Map))
      ..spoiled = _i(j['spoil'])
      ..water = _i(j['water'])
      ..o2 = _d(j['o2'])
      ..servings = _i(j['sup'])
      ..supplyDays = _d(j['days'])
      ..fish = _i(j['fish'])
      ..money = _i(j['money'])
      ..grade = j['g'] as String
      ..gameOver = (j['over'] as bool?) ?? false
      ..won = (j['won'] as bool?) ?? false
      ..diseaseDied = _i(j['dzDied'])
      ..cured = _i(j['cured'])
      ..treatFailed = _i(j['tFail'])
      ..aeratorCost = _i(j['airCost'])
      ..aeratorOff = (j['airOff'] as bool?) ?? false;
    r.sickNew.addAll([for (final x in (j['sick'] as List? ?? const [])) '$x']);
    for (final d in (j['done'] as List? ?? const [])) {
      r.done.add(DoneItem.fromJson(Map<String, dynamic>.from(d as Map)));
    }
    return r;
  }
}

class GameState {
  GameState._();

  /// สถานะเริ่มต้นของเกมใหม่ (def() ในต้นแบบ) — ยังไม่สุ่มราคา
  factory GameState.initial({
    String slotName = '',
    Difficulty mode = Difficulty.normal,
  }) {
    final s = GameState._()
      ..slotName = slotName
      ..mode = mode;
    s.fishStock = {for (final k in kFish.keys) k: 0};
    s.inventory = {for (final k in kIngredients.keys) k: 0};
    s.stock = [StockBatch(food: 'dried', qty: 2)];
    s.upcoming = UpcomingDisaster(
      type: kFirstDisaster,
      startDay: kFirstDisasterDay,
      // ภัยแรกของเกมรุนแรงตามโหมด (ปานกลาง = ต้นแบบ)
      severity: toFixed2(
        kFirstDisasterSeverity * kDifficulties[mode]!.severity,
      ),
    );
    return s;
  }

  int version = kSaveVersion;
  String slotName = '';
  String character = 'น้ำใส';
  int money = 500;
  int day = 1;

  /// ความอิ่ม พลังงาน สุขภาพ ความสุข (0-100)
  int hunger = 80;
  int energy = 100;
  int health = 100;
  int joy = 70;

  List<PondFish> pond = [];

  /// คุณภาพน้ำ: แอมโมเนีย ไนไตรต์ ไนเตรต (ppm)
  double ammonia = .2;
  double nitrite = 0;
  double nitrate = 0;

  /// ไบโอฟิลเตอร์ (กรองชีวภาพ) %
  int bio = 10;
  double temp = 28;

  /// คะแนนคุณภาพน้ำ 0-100 (คำนวณจาก calcWater)
  int water = 96;
  double o2 = 90;

  /// ระดับการให้อาหารวันนี้ 0=ยังไม่ให้ 1/2/3
  int fed = 0;

  /// ปลาที่จับแล้วในคลัง (fi)
  Map<String, int> fishStock = {};

  /// วัตถุดิบ (inv)
  Map<String, int> inventory = {};
  List<StockBatch> stock = [];
  List<PreserveJob> processing = [];
  Map<String, int> equipment = {};

  /// ราคาวัตถุดิบวันนี้ (pr) และเมื่อวาน (pp)
  Map<String, int> prices = {};
  Map<String, int> prevPrices = {};

  UpcomingDisaster? upcoming;
  ActiveDisaster? active;
  bool power = true;
  bool marketClosed = false;
  bool damaged = false;
  int repairCost = 0;
  int earned = 0;
  DayReport? lastReport;

  /// สถานะบทเรียน (ยังไม่ย้ายตรรกะ เก็บไว้ในเซฟเท่านั้น)
  int tut = 0;
  int tutOk = -1;
  int goal = 5;
  bool over = false;
  String cookFish = '';

  /// โหมดความยาก (เซฟเก่าที่ไม่มี = ปานกลาง)
  Difficulty mode = Difficulty.normal;

  /// รอดครบวันเป้าหมายแล้ว (ชนะ) — เกมที่จบแล้วไม่ถูกเซฟทับ
  bool won = false;

  /// คะแนนเกรดรายวันสะสม และจำนวนวันที่ได้เกรด (ใช้คิดเกรดรวม)
  int gradePoints = 0;
  int gradeDays = 0;

  /// จำนวนภัยที่ผ่านพ้นมาได้
  int survived = 0;

  // ---------------------------------------------------------------- ดูแลน้ำ/โรค

  /// เปิดเครื่องเติมอากาศอยู่ (ต้องมีอุปกรณ์ 'air')
  bool aeratorOn = false;

  /// ความสกปรกของตัวกรอง 0-100
  int filterDirt = 0;

  /// วันที่ตรวจน้ำด้วยชุดตรวจล่าสุด (0 = ยังไม่เคย)
  int testedDay = 0;

  /// ยาปลาที่มี (ไม่รวมเกลือ ซึ่งอยู่ในวัตถุดิบ)
  Map<String, int> meds = {};

  /// น้ำต่ำกว่าเส้นดีติดกันกี่วัน
  int badWaterDays = 0;

  /// โรคระบาดช่วงหลังภัย (id โรค) และเหลืออีกกี่วัน
  String? outbreak;
  int outbreakDays = 0;

  /// ระบบโรคปลาทำงาน (เนื้อเรื่องเปิดเมื่อถึงบทปลาป่วย)
  bool diseaseOn = true;

  /// เกมของโหมดเนื้อเรื่อง (ลุงทองช่วยเพิ่ม เช่น ให้ยืมเครื่องเติมอากาศ) — โหมดเอาชีวิตรอด = false
  bool storyMode = false;

  /// ให้ยาผิดโรคครั้งล่าสุดของวันนี้: ยาที่ใช้ และโรคของปลาตัวนั้น (null = ไม่มี)
  /// ลุงทองอธิบายแล้วให้เลือกใหม่ · ล้างเมื่อให้ยาถูกหรือจบวัน
  String? wrongMed;
  String? wrongFor;

  /// ตรวจน้ำแล้ววันนี้
  bool get testedToday => testedDay == day;

  /// เกมจบแล้ว (แพ้หรือชนะ)
  bool get finished => over || won;

  int equipmentCount(String id) => equipment[id] ?? 0;

  Map<String, dynamic> toJson() => {
    'v': version,
    'slotName': slotName,
    'char': character,
    'money': money,
    'day': day,
    'hun': hunger,
    'en': energy,
    'hp': health,
    'joy': joy,
    'pond': pond.map((f) => f.toJson()).toList(),
    'am': ammonia,
    'ni': nitrite,
    'na': nitrate,
    'bio': bio,
    'temp': temp,
    'water': water,
    'o2': o2,
    'fed': fed,
    'fi': Map<String, int>.from(fishStock),
    'inv': Map<String, int>.from(inventory),
    'stock': stock.map((b) => b.toJson()).toList(),
    'proc': processing.map((p) => p.toJson()).toList(),
    'eq': Map<String, int>.from(equipment),
    'pr': Map<String, int>.from(prices),
    'pp': Map<String, int>.from(prevPrices),
    'dz': upcoming?.toJson(),
    'act': active?.toJson(),
    'power': power,
    'mkClosed': marketClosed,
    'dmg': damaged,
    'repair': repairCost,
    'earned': earned,
    'rep': lastReport?.toJson(),
    'tut': tut,
    'tutOk': tutOk,
    'goal': goal,
    'over': over,
    'cookFish': cookFish,
    'mode': mode.name,
    'won': won,
    'gp': gradePoints,
    'gd': gradeDays,
    'surv': survived,
    'air': aeratorOn,
    'dirt': filterDirt,
    'test': testedDay,
    'meds': Map<String, int>.from(meds),
    'bad': badWaterDays,
    'ob': ?outbreak,
    'obd': outbreakDays,
    'dzOn': diseaseOn,
    'sm': storyMode,
    'wm': ?wrongMed,
    'wf': ?wrongFor,
  };

  /// โหลดจาก JSON — ฟิลด์ที่ขาดใช้ค่าเริ่มต้น (เหมือน Object.assign(def(), o))
  factory GameState.fromJson(Map<String, dynamic> j) {
    final s = GameState.initial();
    Map<String, dynamic> m(Object? o) => Map<String, dynamic>.from(o as Map);
    s
      ..version = _i(j['v'], kSaveVersion)
      ..slotName = (j['slotName'] as String?) ?? ''
      ..character = (j['char'] as String?) ?? s.character
      ..money = _i(j['money'], s.money)
      ..day = _i(j['day'], s.day)
      ..hunger = _i(j['hun'], s.hunger)
      ..energy = _i(j['en'], s.energy)
      ..health = _i(j['hp'], s.health)
      ..joy = _i(j['joy'], s.joy)
      ..ammonia = _d(j['am'], s.ammonia)
      ..nitrite = _d(j['ni'], s.nitrite)
      ..nitrate = _d(j['na'], s.nitrate)
      ..bio = _i(j['bio'], s.bio)
      ..temp = _d(j['temp'], s.temp)
      ..water = _i(j['water'], s.water)
      ..o2 = _d(j['o2'], s.o2)
      ..fed = _i(j['fed'])
      ..power = (j['power'] as bool?) ?? true
      ..marketClosed = (j['mkClosed'] as bool?) ?? false
      ..damaged = (j['dmg'] as bool?) ?? false
      ..repairCost = _i(j['repair'])
      ..earned = _i(j['earned'])
      ..tut = _i(j['tut'])
      ..tutOk = _i(j['tutOk'], -1)
      ..goal = _i(j['goal'], 5)
      ..over = (j['over'] as bool?) ?? false
      ..cookFish = (j['cookFish'] as String?) ?? ''
      ..mode = difficultyFromName(j['mode'] as String?)
      ..won = (j['won'] as bool?) ?? false
      ..gradePoints = _i(j['gp'])
      ..gradeDays = _i(j['gd'])
      ..survived = _i(j['surv'])
      ..aeratorOn = (j['air'] as bool?) ?? false
      ..filterDirt = _i(j['dirt'])
      ..testedDay = _i(j['test'])
      ..badWaterDays = _i(j['bad'])
      ..outbreak = j['ob'] as String?
      ..outbreakDays = _i(j['obd'])
      ..diseaseOn = (j['dzOn'] as bool?) ?? true
      ..storyMode = (j['sm'] as bool?) ?? false
      ..wrongMed = j['wm'] as String?
      ..wrongFor = j['wf'] as String?;
    s.meds = _intMap(j['meds']);
    if (j['pond'] != null) {
      s.pond = [for (final f in j['pond'] as List) PondFish.fromJson(m(f))];
    }
    s.fishStock.addAll(_intMap(j['fi']));
    s.inventory.addAll(_intMap(j['inv']));
    if (j['stock'] != null) {
      s.stock = [for (final b in j['stock'] as List) StockBatch.fromJson(m(b))];
    }
    if (j['proc'] != null) {
      s.processing = [
        for (final p in j['proc'] as List) PreserveJob.fromJson(m(p)),
      ];
    }
    s.equipment = _intMap(j['eq']);
    s.prices = _intMap(j['pr']);
    s.prevPrices = _intMap(j['pp']);
    // dz เป็น null ได้ระหว่างภัยกำลังเกิด
    s.upcoming = j.containsKey('dz')
        ? (j['dz'] == null ? null : UpcomingDisaster.fromJson(m(j['dz'])))
        : s.upcoming;
    s.active = j['act'] == null ? null : ActiveDisaster.fromJson(m(j['act']));
    s.lastReport = j['rep'] == null ? null : DayReport.fromJson(m(j['rep']));
    return s;
  }
}
