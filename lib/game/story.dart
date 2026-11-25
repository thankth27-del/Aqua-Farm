/// โหมดเนื้อเรื่อง: สอนเล่นทีละบท 7 บท จบด้วยน้ำท่วมจริงครั้งแรก — ตรรกะล้วน ไม่ผูกกับ UI
///
/// สถานะบทอยู่ใน [StoryProgress] แยกจาก [GameState] (เกมหลักไม่รู้จักเนื้อเรื่อง)
/// UI เรียก [Story.check] หลังทุกการกระทำ และ [Story.afterDay] หลังจบวัน
library;

import 'dart:math';

import '../data/disaster_data.dart';
import '../data/food_data.dart';
import 'game_engine.dart';
import 'game_state.dart';
import 'tutorial.dart';

/// จำนวนบททั้งหมด
const int kStoryChapters = 7;

/// ช่องเซฟของเนื้อเรื่อง (แยกจากช่อง 1-3 ของโหมดเอาชีวิตรอด)
const int kStorySlot = 0;

/// บท 1: จำนวนปลาที่ต้องปล่อยลงบ่อ (ใช้ขาย ทำอาหาร และถนอม บทละ 1 ตัว)
const int kStoryPondFish = 3;

/// บท 1: จำนวนวันที่ต้องดูแลบ่อ
const int kStoryCareDays = 2;

/// ภัยของเนื้อเรื่อง (บท 5-6)
const DisasterType kStoryDisaster = DisasterType.flood;

/// บท 5: อาหารต้องพอกินตลอดน้ำท่วม (4 วัน ตามต้นแบบ)
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
  StoryTarget.catchFish => 1,
  StoryTarget.tabMarket ||
  StoryTarget.sellFish ||
  StoryTarget.buyIngredient ||
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

/// บทที่ 1-7 (index 0-6)
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
    allowed: {
      ..._care,
      StoryTarget.sellFish,
      StoryTarget.buyIngredient,
      StoryTarget.cook,
      StoryTarget.eat,
      StoryTarget.preserve,
      StoryTarget.buyTool,
    },
  ),
  StoryChapter(
    title: 'คำเตือน',
    goal: 'ซื้ออุปกรณ์กันน้ำท่วม และเก็บอาหารให้พอ 4 วัน',
    hint: 'ประกาศน้ำท่วมล่วงหน้าแล้ว! ดู "อาหารพอกิน" ในคลังว่าพอหรือยัง',
    tabs: {0, 1, 2, 3, 4},
    allowed: {
      ..._care,
      StoryTarget.sellFish,
      StoryTarget.buyIngredient,
      StoryTarget.cook,
      StoryTarget.eat,
      StoryTarget.preserve,
      StoryTarget.buyTool,
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
      ..._care,
      StoryTarget.sellFish,
      StoryTarget.buyIngredient,
      StoryTarget.cook,
      StoryTarget.eat,
      StoryTarget.preserve,
      StoryTarget.buyTool,
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

  /// บทปัจจุบัน 1-7
  int chapter;

  /// วันที่เริ่มบทนี้
  int startDay;

  /// ทำเป้าหมายบทนี้สำเร็จแล้ว (กด "บทถัดไป" ได้)
  bool done;

  /// เหตุผลที่แพ้ (null = ยังไม่แพ้)
  String? failReason;

  /// สถานะเกมตอนเริ่มบท (ใช้ลองบทนี้ใหม่)
  Map<String, dynamic>? snapshot;

  /// บทที่กลับไปเมื่อกดลองใหม่ (บท 6 ที่เริ่มโดยยังเตรียมไม่ครบ = กลับไปบท 5)
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

  factory StoryProgress.fromJson(Map<String, dynamic> j) => StoryProgress(
    chapter: ((j['ch'] as num?)?.toInt() ?? 1).clamp(1, kStoryChapters),
    startDay: (j['start'] as num?)?.toInt() ?? 1,
    done: j['done'] == true,
    failReason: j['fail'] as String?,
    snapshot: j['snap'] == null
        ? null
        : Map<String, dynamic>.from(j['snap'] as Map),
    retryChapter: (j['retry'] as num?)?.toInt() ?? 1,
    talked: (j['talk'] as num?)?.toInt() ?? 0,
    heard: {...((j['heard'] as List?) ?? const []).cast<String>()},
    choices: Map<String, String>.from((j['pick'] as Map?) ?? const {}),
    cards: [...((j['cards'] as List?) ?? const []).cast<String>()],
  );
}

abstract final class Story {
  /// เกมใหม่ของเนื้อเรื่อง: ไม่มีภัยสุ่ม (น้ำท่วมมาตามบท 5) และไม่ใช้บทเรียนเดิม
  static GameEngine newEngine({Random? random}) {
    final e = GameEngine.newGame('เนื้อเรื่อง', random: random);
    e.state
      ..upcoming = null
      ..tut = kTutorialSteps;
    return e;
  }

  /// เริ่มบท 1
  static StoryProgress start(GameEngine e) =>
      StoryProgress(startDay: e.state.day, snapshot: e.state.toJson());

  static int _fish(GameEngine e) => e.fishTotal;

  /// ทำเป้าหมายบทปัจจุบันสำเร็จหรือยัง (ไม่นับบท 6 ที่ตัดสินตอนจบวัน)
  static bool goalMet(StoryProgress p, GameEngine e) {
    final s = e.state;
    return switch (p.chapter) {
      1 =>
        s.pond.length >= kStoryPondFish && s.day - p.startDay >= kStoryCareDays,
      2 => s.earned > 0,
      3 => s.stock.any((b) => kFoods[b.food]!.kind == FoodKind.meal),
      4 => s.processing.isNotEmpty,
      5 => prepared(e),
      _ => false,
    };
  }

  /// เตรียมรับน้ำท่วมครบ: มีอุปกรณ์กันภัยอย่างน้อย 1 ชิ้น และอาหารพอ [kStorySupplyDays] วัน
  static bool prepared(GameEngine e) =>
      kDisasters[kStoryDisaster]!.equipment.keys.any(
        (k) => e.state.equipmentCount(k) > 0,
      ) &&
      e.supplyDays >= kStorySupplyDays;

  /// บท 6: วันของน้ำท่วมที่จะผ่านไปเมื่อกด "จบวัน" ครั้งถัดไป (0 = วันแรก)
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
    if (p.done || p.failed || p.chapter >= 6) return false;
    if (!goalMet(p, e)) return false;
    p.done = true;
    return true;
  }

  /// จบวันได้ไหม (บท 1 ต้องมีปลาครบและให้อาหารก่อน, ผ่านบทแล้วต้องกด "บทถัดไป")
  static bool canEndDay(StoryProgress p, GameEngine e) =>
      endDayBlock(p, e) == null;

  /// คำแนะนำตามสถานการณ์ (null = ใช้คำแนะนำประจำบท)
  /// บท 6 ก่อนน้ำมาถึง: ตลาดยังเปิด ให้รู้ว่าต้องรออีกกี่วัน
  static String? situationHint(StoryProgress p, GameEngine e) {
    final s = e.state;
    final up = s.upcoming;
    if (p.chapter == 6 && s.active == null && up != null) {
      final left = up.startDay - s.day;
      return 'น้ำท่วมมาในอีก $left วัน · ตลาดยังเปิด เตรียมเพิ่มได้ แล้วกด "จบวัน" รอ';
    }
    return null;
  }

  /// เหตุผลที่จบวันไม่ได้ (null = จบได้)
  static String? endDayBlock(StoryProgress p, GameEngine e) {
    if (p.failed) return 'ลองบทนี้ใหม่ก่อน';
    if (p.done || p.finished) return 'กด "บทถัดไป" ก่อน';
    if (p.chapter == 1) {
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
    StoryTarget grow() {
      if (s.pond.isEmpty) return StoryTarget.buyFish;
      if (e.matureCount > 0) return StoryTarget.catchFish;
      if (s.fed == 0) return StoryTarget.feed;
      return StoryTarget.endDay;
    }

    switch (p.chapter) {
      case 1:
        if (s.pond.length < kStoryPondFish) return StoryTarget.buyFish;
        if (s.fed == 0) return StoryTarget.feed;
        return StoryTarget.endDay;
      case 2:
        return _fish(e) > 0 ? StoryTarget.sellFish : grow();
      case 3:
        if (_fish(e) == 0) return grow();
        final any = kRecipes.keys.any(e.canCook);
        return any ? StoryTarget.cook : StoryTarget.buyIngredient;
      case 4:
        if (_fish(e) == 0) return grow();
        final tool = kPreserveMethods.values.any(
          (m) => e.freeCapacity(m.equipment) > 0,
        );
        return tool ? StoryTarget.preserve : StoryTarget.buyTool;
      case 5:
        final eq = kDisasters[kStoryDisaster]!.equipment.keys.any(
          (k) => s.equipmentCount(k) > 0,
        );
        if (!eq) return StoryTarget.buyEquipment;
        if (e.supplyDays >= kStorySupplyDays) return null;
        if (_fish(e) > 0) {
          return kRecipes.keys.any(e.canCook)
              ? StoryTarget.cook
              : StoryTarget.buyIngredient;
        }
        return grow();
      case 6:
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
    // น้ำท่วมมาถึงทั้งที่บท 5 ยังเตรียมไม่ครบ → เข้าบท 6 เลย (ลองใหม่ = กลับไปบท 5)
    if (p.chapter == 5 && s.active != null) {
      p
        ..chapter = 6
        ..startDay = s.day
        ..done = false
        ..retryChapter = 5;
    }
    final ev = r.event;
    if (p.chapter == 6 && ev != null && !p.failed) {
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
    if (p.chapter == 5) {
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
