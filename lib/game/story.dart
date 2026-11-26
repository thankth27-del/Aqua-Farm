/// โหมดเนื้อเรื่อง: สอนเล่นทีละบท 9 บท จบด้วยน้ำท่วมจริงครั้งแรก — ตรรกะล้วน ไม่ผูกกับ UI
///
/// สถานะบทอยู่ใน [StoryProgress] แยกจาก [GameState] (เกมหลักไม่รู้จักเนื้อเรื่อง)
/// UI เรียก [Story.check] หลังทุกการกระทำ และ [Story.afterDay] หลังจบวัน
library;

import 'dart:math';

import '../data/constants.dart';
import '../data/disaster_data.dart';
import '../data/equipment_data.dart';
import '../data/fish_data.dart';
import '../data/health_data.dart';
import '../data/food_data.dart';
import '../data/ingredients.dart';
import 'game_engine.dart';
import 'game_state.dart';
import 'tutorial.dart';

/// จำนวนบททั้งหมด
const int kStoryChapters = 9;

/// เลขบท (ใช้ชื่อแทนตัวเลขในตรรกะ เพิ่ม/สลับบทแล้วแก้ที่นี่ที่เดียว)
abstract final class StoryCh {
  static const farm = 1;
  static const water = 2;
  static const market = 3;
  static const kitchen = 4;
  static const preserve = 5;
  static const sick = 6;
  static const warning = 7;
  static const disaster = 8;
  static const summary = 9;
}

/// เซฟเนื้อเรื่องรุ่นเก่า (7 บท) → เลขบทใหม่ (index = บทเก่า 0-7)
const List<int> _oldChapter = [0, 1, 3, 4, 5, 7, 8, 9];

/// รุ่นของเลขบทในเซฟ (ไม่มี = รุ่นเก่า 7 บท)
const int _chapterVersion = 2;

/// ช่องเซฟของเนื้อเรื่อง (แยกจากช่อง 1-3 ของโหมดเอาชีวิตรอด)
const int kStorySlot = 0;

/// บท 1: จำนวนปลาที่ต้องปล่อยลงบ่อ (ใช้ขาย ทำอาหาร และถนอม บทละ 1 ตัว)
const int kStoryPondFish = 3;

/// บท 1: จำนวนวันที่ต้องดูแลบ่อ
const int kStoryCareDays = 2;

/// ภัยของเนื้อเรื่อง (บทคำเตือน-ภัยจริง)
const DisasterType kStoryDisaster = DisasterType.flood;

/// บทคำเตือน: อาหารต้องพอกินตลอดน้ำท่วม (4 วัน ตามต้นแบบ)
int get kStorySupplyDays => kDisasters[kStoryDisaster]!.duration;

/// สิ่งที่ผู้เล่นกดได้ในเนื้อเรื่อง (แต่ละบทเปิดให้กดเฉพาะที่เกี่ยวข้อง)
enum StoryTarget {
  // แท็บล่าง (ลำดับเดียวกับเมนูล่าง)
  tabFarm,
  tabFish,
  tabMarket,
  tabKitchen,
  tabStorage,

  /// ปุ่ม "ร้านปลา" ในบ่อ และปุ่มซื้อปลา
  buyFish,
  feed,

  /// เปลี่ยนน้ำ / เติมอากาศ
  water,
  catchFish,
  sellFish,
  buyIngredient,
  cook,
  preserve,

  /// ซื้ออุปกรณ์กันภัย (ส่วนเตรียมภัยในหน้าฟาร์ม)
  buyEquipment,

  /// ซื้ออุปกรณ์ครัว/ถนอมอาหาร (ในตลาด)
  buyTool,

  /// ซื้อยาปลา/อุปกรณ์บ่อ (ในตลาด แผ่นอุปกรณ์)
  buyMedicine,

  /// รักษาปลาป่วย (หน้าปลา ปุ่ม "รักษาปลา")
  treat,
  eat,
  sellFood,
  rest,
  endDay,

  /// ปุ่ม "บทถัดไป" (เมื่อผ่านเป้าหมายแล้ว)
  next,

  /// ปุ่ม "ลองบทนี้ใหม่" (เมื่อแพ้)
  retry,
}

/// แท็บล่างของแต่ละเป้าหมาย (null = อยู่ในแถบเป้าหมาย/แถบบน)
int? storyTabOf(StoryTarget t) => switch (t) {
  StoryTarget.tabFarm || StoryTarget.rest => 0,
  StoryTarget.tabFish ||
  StoryTarget.buyFish ||
  StoryTarget.feed ||
  StoryTarget.water ||
  StoryTarget.treat ||
  StoryTarget.catchFish => 1,
  StoryTarget.tabMarket ||
  StoryTarget.sellFish ||
  StoryTarget.buyIngredient ||
  StoryTarget.buyMedicine ||
  StoryTarget.buyTool => 2,
  StoryTarget.tabKitchen || StoryTarget.cook || StoryTarget.preserve => 3,
  StoryTarget.tabStorage || StoryTarget.eat || StoryTarget.sellFood => 4,
  StoryTarget.buyEquipment => 0,
  StoryTarget.endDay || StoryTarget.next || StoryTarget.retry => null,
};

class StoryChapter {
  const StoryChapter({
    required this.title,
    required this.goal,
    required this.hint,
    required this.tabs,
    required this.allowed,
  });

  final String title;

  /// เป้าหมายบทนี้ (แถบบนสุด)
  final String goal;

  /// คำอธิบายสั้น (ไม่เกิน 2 บรรทัด)
  final String hint;

  /// แท็บล่างที่เปิดให้ใช้ (0 ฟาร์ม 1 ปลา 2 ตลาด 3 ครัว 4 คลัง)
  final Set<int> tabs;

  /// ปุ่มที่กดได้ในบทนี้ (นอกจากแท็บ)
  final Set<StoryTarget> allowed;
}

const _care = {
  StoryTarget.buyFish,
  StoryTarget.feed,
  StoryTarget.water,
  StoryTarget.catchFish,
  StoryTarget.endDay,
};

/// ปุ่มของบทถนอมอาหารขึ้นไป
const _kitchen = {
  ..._care,
  StoryTarget.sellFish,
  StoryTarget.buyIngredient,
  StoryTarget.cook,
  StoryTarget.eat,
  StoryTarget.preserve,
  StoryTarget.buyTool,
};

/// ดูแลปลาป่วย (ตั้งแต่บทปลาป่วย)
const _heal = {StoryTarget.treat, StoryTarget.buyMedicine};

/// บทที่ 1-9 (index 0-8)
const List<StoryChapter> kStory = [
  StoryChapter(
    title: 'ลงบ่อ',
    goal: 'ซื้อปลา 1 ชนิด 3 ตัวลงบ่อ แล้วดูแล 2 วัน',
    hint:
        'เปิดร้านปลา เลือกปลาโตเร็ว เช่น ปลานิล · ให้อาหารทุกวันก่อนกด "จบวัน"',
    tabs: {1},
    allowed: {
      StoryTarget.buyFish,
      StoryTarget.feed,
      StoryTarget.water,
      StoryTarget.endDay,
    },
  ),
  StoryChapter(
    title: 'คุณภาพน้ำ',
    goal: 'ล้างตัวกรอง แล้วดูแลให้น้ำกลับมา "ดี"',
    hint: 'หน้าปลา กด "ดูแลน้ำ" · ตัวกรองสกปรกกรองของเสียได้น้อยลง',
    tabs: {1},
    allowed: _care,
  ),
  StoryChapter(
    title: 'ตลาด',
    goal: 'จับปลาที่โตแล้ว แล้วขายที่ตลาด 1 ตัว',
    hint: 'ขายปลาในคลังที่ตลาด · ราคาวัตถุดิบเปลี่ยนทุกวัน ดูลูกศรเทียบกับเมื่อวาน',
    tabs: {1, 2},
    allowed: {..._care, StoryTarget.sellFish, StoryTarget.buyIngredient},
  ),
  StoryChapter(
    title: 'ครัว',
    goal: 'ทำอาหารเมนูแรก',
    hint:
        'ซื้อวัตถุดิบที่ตลาด แล้วใช้ปลาในคลังทำอาหาร · หิวเมื่อไรไปกินที่คลัง',
    tabs: {1, 2, 3, 4},
    allowed: {
      ..._care,
      StoryTarget.sellFish,
      StoryTarget.buyIngredient,
      StoryTarget.cook,
      StoryTarget.eat,
    },
  ),
  StoryChapter(
    title: 'ถนอมอาหาร',
    goal: 'ถนอมปลา 1 วิธี (ตากแห้ง/เค็ม/ดอง/กระป๋อง)',
    hint: 'อาหารถนอมเก็บได้นานกว่าอาหารสุกมาก ต้องมีอุปกรณ์ เช่น แผงตากปลา',
    tabs: {1, 2, 3, 4},
    allowed: _kitchen,
  ),
  StoryChapter(
    title: 'ปลาป่วย',
    goal: 'รักษาปลาป่วยให้หาย: ดูอาการ แล้วเลือกยาให้ตรงโรค',
    hint: 'ซื้อยาที่ตลาด ("อุปกรณ์และยาปลา") แล้วกด "รักษาปลา" ที่หน้าปลา',
    tabs: {1, 2, 3, 4},
    allowed: {..._kitchen, ..._heal},
  ),
  StoryChapter(
    title: 'คำเตือน',
    goal: 'ซื้ออุปกรณ์กันน้ำท่วม และเก็บอาหารให้พอ 4 วัน',
    hint: 'ประกาศน้ำท่วมล่วงหน้าแล้ว! ดู "อาหารพอกิน" ในคลังว่าพอหรือยัง',
    tabs: {0, 1, 2, 3, 4},
    allowed: {
      ..._kitchen,
      ..._heal,
      StoryTarget.buyEquipment,
      StoryTarget.rest,
    },
  ),
  StoryChapter(
    title: 'ภัยพิบัติจริง',
    goal: 'รอดน้ำท่วม 4 วัน: กินเมื่อหิว อย่าให้ปลาตายหมด',
    hint: 'ตลาดปิดและไฟอาจดับ ต้องใช้เสบียงที่เตรียมไว้',
    tabs: {0, 1, 2, 3, 4},
    allowed: {
      ..._kitchen,
      ..._heal,
      StoryTarget.buyEquipment,
      StoryTarget.rest,
    },
  ),
  StoryChapter(
    title: 'สรุป',
    goal: 'ดูผลการเล่น แล้วปลดล็อกโหมดเอาชีวิตรอด',
    hint: 'เกรดคิดจากเกรดรายวันเฉลี่ยตลอดเนื้อเรื่อง',
    tabs: {},
    allowed: {},
  ),
];

/// ข้อความตอนจบตามเกรดรวม
const Map<String, String> kStoryEnding = {
  'S': 'ยอดเยี่ยม! ฟาร์มของคุณรอดน้ำท่วมอย่างแข็งแกร่ง พร้อมรับภัยครั้งต่อไปแล้ว',
  'A': 'เก่งมาก! ผ่านน้ำท่วมครั้งแรกได้ ลองเตรียมเสบียงให้มากขึ้นอีกนิด',
  'B': 'รอดมาได้! ครั้งหน้าเตรียมอุปกรณ์และอาหารล่วงหน้าให้พร้อมกว่านี้',
};

/// ความคืบหน้าเนื้อเรื่อง (เซฟคู่กับสถานะเกม)
class StoryProgress {
  StoryProgress({
    this.chapter = 1,
    this.startDay = 1,
    this.done = false,
    this.failReason,
    this.snapshot,
    this.retryChapter = 1,
    this.talked = 0,
    Set<String>? heard,
    Map<String, String>? choices,
    List<String>? cards,
  }) : heard = heard ?? {},
       choices = choices ?? {},
       cards = cards ?? [];

  /// บทปัจจุบัน 1-9 (ดู [StoryCh])
  int chapter;

  /// วันที่เริ่มบทนี้
  int startDay;

  /// ทำเป้าหมายบทนี้สำเร็จแล้ว (กด "บทถัดไป" ได้)
  bool done;

  /// เหตุผลที่แพ้ (null = ยังไม่แพ้)
  String? failReason;

  /// สถานะเกมตอนเริ่มบท (ใช้ลองบทนี้ใหม่)
  Map<String, dynamic>? snapshot;

  /// บทที่กลับไปเมื่อกดลองใหม่ (บทภัยจริงที่เริ่มโดยยังเตรียมไม่ครบ = กลับไปบทคำเตือน)
  int retryChapter;

  /// บทล่าสุดที่ลุงทองเล่าเปิดบทแล้ว (น้อยกว่า [chapter] = ต้องเล่าบทนี้)
  int talked;

  /// บทพูดของบทนี้ที่ลุงพูดไปแล้ว (เช่น 't:feed', 'done', 'card') — ล้างเมื่อเปลี่ยนบท
  final Set<String> heard;

  /// ตัวเลือกที่ผู้เล่นตัดสินใจแล้ว (id จุดตัดสินใจ → id ตัวเลือก)
  final Map<String, String> choices;

  /// การ์ดความรู้ที่เก็บในสมุดบันทึกลุงทองแล้ว (ตามลำดับที่ได้)
  final List<String> cards;

  /// ลุงยังไม่ได้เล่าเปิดบทปัจจุบัน
  bool get needsIntro => talked < chapter;

  bool get failed => failReason != null;
  StoryChapter get spec => kStory[chapter - 1];
  bool get finished => chapter == kStoryChapters;

  StoryProgress copy() => StoryProgress(
    chapter: chapter,
    startDay: startDay,
    done: done,
    failReason: failReason,
    snapshot: snapshot,
    retryChapter: retryChapter,
    talked: talked,
    heard: {...heard},
    choices: {...choices},
    cards: [...cards],
  );

  Map<String, dynamic> toJson() => {
    'sv': _chapterVersion,
    'ch': chapter,
    'start': startDay,
    'done': done,
    'fail': failReason,
    'snap': snapshot,
    'retry': retryChapter,
    'talk': talked,
    'heard': heard.toList(),
    'pick': choices,
    'cards': cards,
  };

  factory StoryProgress.fromJson(Map<String, dynamic> j) {
    // เซฟรุ่น 7 บท: เลื่อนเลขบทไปบทเดียวกันในชุด 9 บท (บทใหม่ที่ผ่านไปแล้วข้ามได้)
    final old = ((j['sv'] as num?)?.toInt() ?? 1) < _chapterVersion;
    int ch(Object? v, int def) {
      final n = (v as num?)?.toInt() ?? def;
      if (!old) return n;
      return _oldChapter[n.clamp(0, _oldChapter.length - 1)];
    }

    return StoryProgress(
      chapter: ch(j['ch'], 1).clamp(1, kStoryChapters),
      startDay: (j['start'] as num?)?.toInt() ?? 1,
      done: j['done'] == true,
      failReason: j['fail'] as String?,
      snapshot: j['snap'] == null
          ? null
          : Map<String, dynamic>.from(j['snap'] as Map),
      retryChapter: ch(j['retry'], 1).clamp(1, kStoryChapters),
      talked: ch(j['talk'], 0).clamp(0, kStoryChapters),
      heard: {...((j['heard'] as List?) ?? const []).cast<String>()},
      choices: Map<String, String>.from((j['pick'] as Map?) ?? const {}),
      cards: [...((j['cards'] as List?) ?? const []).cast<String>()],
    );
  }
}

abstract final class Story {
  /// เกมใหม่ของเนื้อเรื่อง: ไม่มีภัยสุ่ม (น้ำท่วมมาตามบทคำเตือน) และไม่ใช้บทเรียนเดิม
  static GameEngine newEngine({Random? random}) {
    final e = GameEngine.newGame('เนื้อเรื่อง', random: random);
    e.state
      ..upcoming = null
      // โรคปลาเปิดเมื่อถึงบทปลาป่วย
      ..diseaseOn = false
      ..tut = kTutorialSteps;
    return e;
  }

  /// เริ่มบท 1
  static StoryProgress start(GameEngine e) =>
      StoryProgress(startDay: e.state.day, snapshot: e.state.toJson());

  static int _fish(GameEngine e) => e.fishTotal;

  /// บทถนอมอาหาร: วิธีถนอมที่ผู้เล่นเลือก (ยังไม่เลือก = ตากแห้ง วิธีที่ถูกที่สุด)
  static String preserveMethod(StoryProgress p) {
    final m = p.choices['method'];
    return m != null && kPreserveMethods.containsKey(m) ? m : 'dried';
  }

  /// ของที่ขาดตาม [need] (id → จำนวนที่ยังขาด)
  static Map<String, int> _lack(GameEngine e, Map<String, int> need) => {
    for (final n in need.entries)
      if ((e.state.inventory[n.key] ?? 0) < n.value)
        n.key: n.value - (e.state.inventory[n.key] ?? 0),
  };

  /// ของที่ขั้นถัดไปของบทต้องใช้แต่ยังไม่มี (วัตถุดิบ/อุปกรณ์ id → จำนวน)
  /// ว่าง = มีครบแล้ว หรือขั้นนี้ไม่ต้องซื้ออะไร
  static Map<String, int> missing(StoryProgress p, GameEngine e) {
    final s = e.state;
    if (p.done || p.failed) return const {};
    // ปลาป่วยรอรักษา: ยาที่ตรงโรคยังไม่พอ (ตลาดเปิด)
    if (p.chapter >= StoryCh.sick && !s.marketClosed) {
      final med = _medLack(e);
      if (med.isNotEmpty) return med;
    }
    switch (p.chapter) {
      case StoryCh.farm:
        // ปลาให้ครบบ่อของบท (นับเป็นปลานิล ปลาที่ถูกและโตเร็ว)
        final n = kStoryPondFish - s.pond.length;
        return n > 0 ? {'nila': n} : const {};
      case StoryCh.kitchen:
        if (_fish(e) == 0 || kRecipes.keys.any(e.canCook)) return const {};
        return _lack(e, kRecipes['fry']!.need);
      case StoryCh.preserve:
        if (_fish(e) == 0 || s.processing.isNotEmpty) return const {};
        final m = kPreserveMethods[preserveMethod(p)]!;
        return {
          if (e.freeCapacity(m.equipment) <= 0) m.equipment: 1,
          ..._lack(e, m.need),
        };
      case StoryCh.warning:
        final eq = kDisasters[kStoryDisaster]!.equipment.keys;
        if (!eq.any((k) => s.equipmentCount(k) > 0)) {
          // ชิ้นที่คุ้มที่สุด (ตรงกับชิ้นที่หน้าฟาร์มชี้)
          return {e.equipmentByValue(kStoryDisaster).first: 1};
        }
        return _foodLack(e);
      case StoryCh.disaster:
        return s.active == null && !s.marketClosed ? _floodLack(e) : const {};
    }
    return const {};
  }

  /// ปลาป่วยตัวแรกที่ยังไม่ได้รักษา → id โรค (null = ไม่มี)
  static String? sickToTreat(GameEngine e) {
    for (final f in e.state.pond) {
      if (f.sick && f.treatDays == 0 && f.health > 0) return f.disease;
    }
    return null;
  }

  /// ยาที่ตรงโรคของปลาป่วยยังไม่พอ 1 ครั้ง
  static Map<String, int> _medLack(GameEngine e) {
    final d = sickToTreat(e);
    if (d == null) return const {};
    final med = kDiseases[d]!.medicine;
    final n = kMedicines[med]!.dose - e.medCount(med);
    return n > 0 ? {med: n} : const {};
  }

  /// ยาปลาที่อยู่ในช่องยา (ไม่ใช่วัตถุดิบ เช่น เกลือ)
  static bool _isMed(String id) => kMedicines[id]?.ingredient == false;

  /// เตรียมเสบียง: มีปลาแต่ถนอม/ทำอาหารไม่ได้ เพราะขาดเครื่องปรุง
  static Map<String, int> _foodLack(GameEngine e) {
    if (e.supplyDays >= kStorySupplyDays + 1 || _fish(e) == 0) return const {};
    if (kPreserveMethods.keys.any(e.canPreserve)) return const {};
    if (kRecipes.keys.any(e.canCook)) return const {};
    return _lack(e, kRecipes['fry']!.need);
  }

  /// วันที่เหลือจนน้ำลด (นับวันนี้) · 0 = ไม่มีภัยรออยู่
  static int daysToFloodEnd(GameEngine e) {
    final s = e.state;
    final d = kDisasters[kStoryDisaster]!.duration;
    if (s.active != null) return d - s.active!.dayIndex;
    final u = s.upcoming;
    return u == null ? 0 : u.startDay - s.day + d;
  }

  /// เสบียงที่ "ยังไม่เสีย" ตอนน้ำลด (วัน) — อาหารสุกเก็บได้ 3 วัน เสียก่อนน้ำลด
  /// นับของที่กำลังถนอมอยู่ด้วย
  static double floodSupply(GameEngine e) {
    final end = daysToFloodEnd(e);
    var h = 0;
    for (final b in e.state.stock) {
      if (e.ageLeft(b) > end) h += kFoods[b.food]!.hunger * b.qty;
    }
    for (final j in e.state.processing) {
      h += kFoods[j.method]!.hunger * j.qty;
    }
    return h / kHungerPerDay;
  }

  /// บทภัยจริง ก่อนน้ำมา: ของกินที่เก็บได้นานไม่พอช่วงน้ำท่วม
  /// มีปลา → ถนอม (ขาดวัตถุดิบก็ชี้ไปซื้อ) · ทำไม่ได้/ไม่มีปลา → ลุงแบ่งปลาแห้งให้
  static Map<String, int> _floodLack(GameEngine e) {
    final short = kStorySupplyDays - floodSupply(e);
    if (short <= 0) return const {};
    if (_fish(e) > 0) {
      if (kPreserveMethods.keys.any(e.canPreserve)) return const {};
      for (final m in kPreserveMethods.values) {
        if (e.freeCapacity(m.equipment) <= 0) continue;
        final lack = _lack(e, m.need);
        if (missingCost(e, lack) <= e.state.money) return lack;
      }
    }
    final dish = kFoods['dried']!.hunger;
    return {'dried': (short * kHungerPerDay / dish).ceil()};
  }

  /// ราคารวมของที่ขาด (ราคาวันนี้)
  static int missingCost(GameEngine e, Map<String, int> m) => m.entries.fold(
    0,
    (a, x) =>
        a +
        x.value *
            (kEquipment.containsKey(x.key)
                ? e.equipmentPrice(x.key)
                : kFish.containsKey(x.key)
                ? kFish[x.key]!.buyPrice
                : kFoods.containsKey(x.key)
                ? 1 <<
                      20 // อาหารสำเร็จซื้อไม่ได้ ได้จากลุงเท่านั้น
                : _isMed(x.key)
                ? e.medicinePrice(x.key)
                : (e.state.prices[x.key] ?? kIngredients[x.key]!.basePrice)),
  );

  /// เงินไม่พอซื้อของที่บทนี้ต้องใช้ → ลุงทองให้ฟรี (กันผู้เล่นค้าง) · null = ไม่ต้องให้
  static Map<String, int>? giftNeeded(StoryProgress p, GameEngine e) {
    final m = missing(p, e);
    if (m.isNotEmpty && e.state.money < missingCost(e, m)) return m;
    // หิว ไม่มีอะไรกิน ไม่มีปลา เงินไม่พอซื้อปลา → ลุงแบ่งปลาแห้งให้ประทังไปก่อน
    final s = e.state;
    if (!p.finished &&
        s.hunger <= 40 &&
        e.servings == 0 &&
        _fish(e) == 0 &&
        e.matureCount == 0 &&
        s.money < kFish['nila']!.buyPrice) {
      return const {'dried': 2};
    }
    return null;
  }

  /// ของขวัญพิเศษ: ลุงช่วยเปลี่ยนน้ำให้ (ไม่ใช่ของในคลัง)
  static const kWaterGift = 'water';

  /// น้ำแย่ ตัวกรองยังไม่ต้องล้าง และเงินไม่พอเปลี่ยนน้ำ → ลุงช่วยเปลี่ยนให้ (วันละครั้ง)
  /// กันผู้เล่นที่เงินหมดติดอยู่กับน้ำเสียจนปลาตาย
  static bool waterGiftNeeded(StoryProgress p, GameEngine e) {
    final s = e.state;
    return p.chapter >= StoryCh.water &&
        !p.done &&
        !p.failed &&
        !p.finished &&
        s.pond.isNotEmpty &&
        s.water < kWaterGoodLine &&
        s.filterDirt < kCleanFilterMin &&
        s.money < kChangeWaterCost &&
        !p.heard.contains(waterGiftKey(e));
  }

  /// รหัสของขวัญเปลี่ยนน้ำของวันนี้ (ฟังแล้ว = วันนี้ให้ไปแล้ว)
  static String waterGiftKey(GameEngine e) => 'gift:water:${e.state.day}';

  /// ชื่อของ (วัตถุดิบหรืออุปกรณ์) พร้อมจำนวน เช่น "เกลือ 2"
  static String itemsText(Map<String, int> m) => m.entries
      .map(
        (x) => x.key == kWaterGift
            ? 'เปลี่ยนน้ำ'
            : '${kEquipment[x.key]?.name ?? kFish[x.key]?.name ?? kFoods[x.key]?.name ?? (_isMed(x.key) ? kMedicines[x.key]!.name : kIngredients[x.key]!.name)}'
                  '${x.value > 1 ? ' ${x.value}' : ''}',
      )
      .join(' + ');

  /// ลุงทองให้ของที่ขาดฟรี
  static ActionResult giveGift(GameEngine e, Map<String, int> m) {
    final s = e.state;
    if (m.containsKey(kWaterGift)) {
      final r = e.changeWater(free: true);
      return r.ok
          ? const ActionResult.ok('ลุงทองช่วยเปลี่ยนน้ำให้ฟรี ของเสียลดลง')
          : r;
    }
    for (final x in m.entries) {
      if (kEquipment.containsKey(x.key)) {
        s.equipment[x.key] = s.equipmentCount(x.key) + x.value;
      } else if (kFish.containsKey(x.key)) {
        for (var i = 0; i < x.value; i++) {
          s.pond.add(PondFish(type: x.key));
        }
      } else if (kFoods.containsKey(x.key)) {
        s.stock.add(StockBatch(food: x.key, qty: x.value));
      } else if (_isMed(x.key)) {
        s.meds[x.key] = (s.meds[x.key] ?? 0) + x.value;
      } else {
        s.inventory[x.key] = (s.inventory[x.key] ?? 0) + x.value;
      }
    }
    return ActionResult.ok('ลุงทองให้${itemsText(m)} ฟรี');
  }

  /// ทำเป้าหมายบทปัจจุบันสำเร็จหรือยัง (ไม่นับบทภัยจริงที่ตัดสินตอนจบวัน)
  static bool goalMet(StoryProgress p, GameEngine e) {
    final s = e.state;
    return switch (p.chapter) {
      StoryCh.farm =>
        s.pond.length >= kStoryPondFish && s.day - p.startDay >= kStoryCareDays,
      // ล้างตัวกรองแล้วในบทนี้ (สกปรก 0 ได้จากการล้างเท่านั้น เมื่อตอนเริ่มบทหรือวันก่อนสกปรกอยู่)
      // และน้ำกลับมาดี
      StoryCh.water =>
        s.pond.isNotEmpty &&
            s.filterDirt == 0 &&
            s.water >= kWaterGoodLine &&
            (((p.snapshot?['dirt'] as num?) ?? 0) > 0 || s.day > p.startDay),
      StoryCh.market => s.earned > 0,
      StoryCh.kitchen => s.stock.any(
        (b) => kFoods[b.food]!.kind == FoodKind.meal,
      ),
      StoryCh.preserve => s.processing.isNotEmpty,
      // ปลาที่ลุงพบว่าป่วยหายแล้ว และไม่มีตัวไหนป่วยอยู่
      StoryCh.sick => p.heard.contains(_seeded) && e.sickCount == 0,
      StoryCh.warning => prepared(e),
      _ => false,
    };
  }

  /// รหัสใน [StoryProgress.heard]: บทปลาป่วยเริ่มให้ปลาป่วยแล้ว
  static const _seeded = 'seed:sick';

  /// บทปลาป่วย: ลุงพบปลาเป็นโรคจุดขาว 1 ตัว (ตัวแรกที่ยังแข็งแรงในบ่อ)
  static void _seedSickness(StoryProgress p, GameEngine e) {
    if (p.chapter != StoryCh.sick || p.heard.contains(_seeded)) return;
    for (final f in e.state.pond) {
      if (f.sick || f.health <= 0) continue;
      f
        ..disease = 'ich'
        ..sickDays = 0
        ..treatDays = 0;
      p.heard.add(_seeded);
      return;
    }
  }

  /// ระบบโรคปลาเปิดตั้งแต่บทปลาป่วย (เซฟเก่าก็ปรับตามบท)
  static void sync(StoryProgress p, GameEngine e) {
    e.state.diseaseOn = p.chapter >= StoryCh.sick;
  }

  /// เตรียมรับน้ำท่วมครบ: มีอุปกรณ์กันภัยอย่างน้อย 1 ชิ้น และอาหารพอ [kStorySupplyDays] วัน
  static bool prepared(GameEngine e) =>
      kDisasters[kStoryDisaster]!.equipment.keys.any(
        (k) => e.state.equipmentCount(k) > 0,
      ) &&
      e.supplyDays >= kStorySupplyDays;

  /// บทภัยจริง: วันของน้ำท่วมที่จะผ่านไปเมื่อกด "จบวัน" ครั้งถัดไป (0 = วันแรก)
  /// null = ยังไม่ถึงคืนก่อนน้ำมา หรือน้ำลดแล้ว
  static int? floodDayAhead(GameEngine e) {
    final s = e.state;
    final a = s.active;
    if (a != null) {
      final i = a.dayIndex + 1;
      return i < a.duration ? i : null;
    }
    final up = s.upcoming;
    if (up != null && up.type == kStoryDisaster && up.startDay == s.day + 1) {
      return 0;
    }
    return null;
  }

  /// เรียกหลังทุกการกระทำ: ทำเป้าหมายสำเร็จ → done (ติดค้างจนเปลี่ยนบท)
  static bool check(StoryProgress p, GameEngine e) {
    sync(p, e);
    if (p.done || p.failed || p.chapter >= StoryCh.disaster) return false;
    _seedSickness(p, e);
    if (!goalMet(p, e)) return false;
    p.done = true;
    return true;
  }

  /// จบวันได้ไหม (บท 1 ต้องมีปลาครบและให้อาหารก่อน, ผ่านบทแล้วต้องกด "บทถัดไป")
  static bool canEndDay(StoryProgress p, GameEngine e) =>
      endDayBlock(p, e) == null;

  /// คำแนะนำตามสถานการณ์ (null = ใช้คำแนะนำประจำบท)
  /// บทภัยจริง ก่อนน้ำมาถึง: ตลาดยังเปิด ให้รู้ว่าต้องรออีกกี่วัน
  static String? situationHint(StoryProgress p, GameEngine e) {
    final s = e.state;
    final up = s.upcoming;
    if (p.chapter == StoryCh.disaster && s.active == null && up != null) {
      final left = up.startDay - s.day;
      return 'น้ำท่วมมาในอีก $left วัน · ตลาดยังเปิด เตรียมเพิ่มได้ แล้วกด "จบวัน" รอ';
    }
    return null;
  }

  /// เหตุผลที่จบวันไม่ได้ (null = จบได้)
  static String? endDayBlock(StoryProgress p, GameEngine e) {
    if (p.failed) return 'ลองบทนี้ใหม่ก่อน';
    if (p.done || p.finished) return 'กด "บทถัดไป" ก่อน';
    if (p.chapter == StoryCh.farm) {
      if (e.state.pond.length < kStoryPondFish) {
        return 'ซื้อปลาให้ครบ $kStoryPondFish ตัวก่อน';
      }
      if (e.state.fed == 0) return 'ให้อาหารปลาก่อนจบวัน';
    }
    return null;
  }

  /// แท็บนี้เปิดในบทนี้ไหม
  static bool tabOpen(StoryProgress p, int tab) => p.spec.tabs.contains(tab);

  /// ปุ่มนี้กดได้ในบทนี้ไหม
  static bool allows(StoryProgress p, GameEngine e, StoryTarget t) {
    if (t == StoryTarget.next) return p.done && !p.failed;
    if (t == StoryTarget.retry) return p.failed;
    if (p.failed || p.done) return false;
    if (t == StoryTarget.endDay) return canEndDay(p, e);
    final tab = switch (t) {
      StoryTarget.tabFarm => 0,
      StoryTarget.tabFish => 1,
      StoryTarget.tabMarket => 2,
      StoryTarget.tabKitchen => 3,
      StoryTarget.tabStorage => 4,
      _ => null,
    };
    if (tab != null) return tabOpen(p, tab);
    return p.spec.allowed.contains(t);
  }

  /// น้ำต่ำกว่าเส้นดี และยังทำอะไรได้ (ล้างตัวกรองฟรี หรือมีเงินเปลี่ยนน้ำ)
  static bool needsWaterCare(GameEngine e) {
    final s = e.state;
    if (s.pond.isEmpty) return false;
    // ออกซิเจนต่ำกว่าที่ปลาต้องการ: เติมอากาศได้เสมอ (เงินไม่พอ ลุงให้ยืมเครื่อง)
    if (s.o2 < e.pondO2Need) return true;
    return s.water < kWaterGoodLine &&
        (s.filterDirt >= kCleanFilterMin || s.money >= kChangeWaterCost);
  }

  /// สิ่งที่ควรกดต่อไป (ไฮไลต์) — null = ไม่มี
  static StoryTarget? nextTarget(StoryProgress p, GameEngine e) {
    final s = e.state;
    if (p.failed) return StoryTarget.retry;
    if (p.done) return StoryTarget.next;
    final canEat =
        p.spec.allowed.contains(StoryTarget.eat) &&
        s.hunger < 40 &&
        e.servings > 0;
    if (canEat) return StoryTarget.eat;
    // ปลาป่วยรอรักษา: มียาที่ตรงโรค → รักษา · ยังไม่มี → ซื้อที่ตลาด
    if (p.chapter >= StoryCh.sick) {
      final d = sickToTreat(e);
      if (d != null) {
        final med = kDiseases[d]!.medicine;
        if (e.medCount(med) >= kMedicines[med]!.dose) return StoryTarget.treat;
        if (!s.marketClosed) return StoryTarget.buyMedicine;
      }
    }
    StoryTarget grow() {
      if (s.pond.isEmpty) return StoryTarget.buyFish;
      if (e.matureCount > 0) return StoryTarget.catchFish;
      if (s.fed == 0) return StoryTarget.feed;
      if (needsWaterCare(e)) return StoryTarget.water;
      return StoryTarget.endDay;
    }

    /// มีปลาในคลัง → ถนอม (เก็บนาน) หรือทำอาหาร หรือซื้อเครื่องปรุง · null = ไม่มีปลา
    StoryTarget? stock() {
      if (_fish(e) == 0) return null;
      if (kPreserveMethods.keys.any(e.canPreserve)) return StoryTarget.preserve;
      if (kRecipes.keys.any(e.canCook)) return StoryTarget.cook;
      return StoryTarget.buyIngredient;
    }

    switch (p.chapter) {
      case StoryCh.farm:
        if (s.pond.length < kStoryPondFish) return StoryTarget.buyFish;
        if (s.fed == 0) return StoryTarget.feed;
        return StoryTarget.endDay;
      case StoryCh.water:
        if (s.pond.isEmpty) return StoryTarget.buyFish;
        // ตัวกรองสกปรก → ล้าง · น้ำยังไม่ดี → เปลี่ยนน้ำ (ถ้ามีเงิน) · ไม่งั้นรอพรุ่งนี้
        if (s.filterDirt >= kCleanFilterMin || needsWaterCare(e)) {
          return StoryTarget.water;
        }
        return grow();
      case StoryCh.market:
        return _fish(e) > 0 ? StoryTarget.sellFish : grow();
      case StoryCh.kitchen:
        if (_fish(e) == 0) return grow();
        final any = kRecipes.keys.any(e.canCook);
        return any ? StoryTarget.cook : StoryTarget.buyIngredient;
      case StoryCh.preserve:
        if (_fish(e) == 0) return grow();
        // ตามวิธีที่เลือก: ขาดอุปกรณ์ → ซื้ออุปกรณ์ · ขาดวัตถุดิบ → ซื้อวัตถุดิบ · ครบ → ถนอม
        final m = missing(p, e);
        if (m.keys.any(kEquipment.containsKey)) return StoryTarget.buyTool;
        if (m.isNotEmpty) return StoryTarget.buyIngredient;
        return StoryTarget.preserve;
      case StoryCh.sick:
        // รักษาแล้ว: ดูแลบ่อ รอปลาหาย
        return grow();
      case StoryCh.warning:
        final eq = kDisasters[kStoryDisaster]!.equipment.keys.any(
          (k) => s.equipmentCount(k) > 0,
        );
        if (!eq) return StoryTarget.buyEquipment;
        if (e.supplyDays >= kStorySupplyDays) return null;
        return stock() ?? grow();
      case StoryCh.disaster:
        // ก่อนน้ำมา: อาหารสุกจะเสียก่อนน้ำลด → ถนอมปลาให้เก็บได้นาน
        if (s.active == null && floodSupply(e) < kStorySupplyDays) {
          if (_fish(e) > 0) {
            if (kPreserveMethods.keys.any(e.canPreserve)) {
              return StoryTarget.preserve;
            }
            final m = missing(p, e);
            if (m.keys.any(kIngredients.containsKey)) {
              return StoryTarget.buyIngredient;
            }
          }
          if (e.matureCount > 0) return StoryTarget.catchFish;
        }
        // ระหว่างน้ำท่วม: มีปลาในคลังก็ทำอาหารกินได้
        if (s.active != null && _fish(e) > 0 && kRecipes.keys.any(e.canCook)) {
          return StoryTarget.cook;
        }
        return StoryTarget.endDay;
      default:
        return null;
    }
  }

  /// เรียกหลังจบวัน (ก่อน UI วาดใหม่): เนื้อเรื่องไม่ชนะด้วยจำนวนวัน
  /// และไม่ Game Over — แพ้ = ลองบทนั้นใหม่
  static void afterDay(StoryProgress p, GameEngine e, DayReport r) {
    final s = e.state;
    if (r.won) {
      s.won = false;
      r.won = false;
    }
    if (s.over) {
      s.over = false;
      r.gameOver = false;
      p.failReason ??= 'สุขภาพหมด ตัวละครล้มป่วย';
    }
    // น้ำท่วมมาถึงทั้งที่บทคำเตือนยังเตรียมไม่ครบ → เข้าบทภัยจริงเลย (ลองใหม่ = กลับไปบทคำเตือน)
    if (p.chapter == StoryCh.warning && s.active != null) {
      p
        ..chapter = StoryCh.disaster
        ..startDay = s.day
        ..done = false
        ..retryChapter = StoryCh.warning;
    }
    // บทปลาป่วย: ปลาตายเพราะโรค = ลองบทนี้ใหม่
    if (p.chapter == StoryCh.sick && r.diseaseDied > 0 && !p.failed) {
      p.failReason = 'ปลาป่วยตาย เพราะรักษาไม่ทัน';
    }
    final ev = r.event;
    if (p.chapter == StoryCh.disaster && ev != null && !p.failed) {
      if (s.hunger <= 0) {
        p.failReason = 'อาหารไม่พอ ตัวละครหิวจนหมดแรง';
      } else if (ev.fishBefore > 0 && s.pond.isEmpty) {
        p.failReason = 'ปลาในบ่อตายหมด';
      } else if (ev.last) {
        p.done = true;
      }
    }
    check(p, e);
  }

  /// ไปบทถัดไป (ต้องผ่านเป้าหมายแล้ว) — คืน false ถ้ายังไปไม่ได้
  static bool next(StoryProgress p, GameEngine e) {
    if (!p.done || p.failed || p.finished) return false;
    final s = e.state;
    final n = p.chapter + 1;
    p
      ..chapter = n
      ..startDay = s.day
      // บทสรุปไม่มีเป้าหมาย: ผ่านทันที
      ..done = n == kStoryChapters
      ..retryChapter = n;
    p.heard.clear();
    sync(p, e);
    if (p.chapter == StoryCh.warning) {
      // ประกาศน้ำท่วมล่วงหน้าตามต้นแบบ (เตือน 5 วัน ความรุนแรงเท่าภัยแรก)
      s.upcoming = UpcomingDisaster(
        type: kStoryDisaster,
        startDay: s.day + kDisasters[kStoryDisaster]!.leadDays,
        severity: kFirstDisasterSeverity,
      );
    }
    p.snapshot = s.toJson();
    check(p, e);
    return true;
  }

  /// ลองบทนี้ใหม่: คืนเกมจากสถานะตอนเริ่มบท
  static GameEngine retry(StoryProgress p, {Random? random}) {
    final s = GameState.fromJson(p.snapshot!);
    final e = GameEngine(s, random: random)..calcWater();
    p
      ..chapter = p.retryChapter
      ..startDay = s.day
      ..done = false
      ..failReason = null;
    // ลองใหม่: ลุงเล่าคำแนะนำระหว่างบทซ้ำได้ (เปิดบทไม่ต้องเล่าซ้ำ)
    p.heard.clear();
    check(p, e);
    return e;
  }
}
