/// บทเรียนสอนเล่น 9 ขั้น (TUT / tutGo ในต้นแบบ) — ตรรกะล้วน ไม่ผูกกับ UI
///
/// สถานะอยู่ใน [GameState.tut] (ขั้นปัจจุบัน 0-8, 9 = จบ/ข้าม) และ
/// [GameState.tutOk] (ขั้นที่ทำเงื่อนไขสำเร็จแล้ว จึงกด "ถัดไป" ได้)
library;

import '../data/food_data.dart';
import 'game_engine.dart';

/// จำนวนขั้นทั้งหมด
const int kTutorialSteps = 9;

/// หน้าที่ผู้เล่นเปิดอยู่ (cur ในต้นแบบ) — UI เป็นผู้บอก
enum GameScreen { farm, pond, shop, market, kitchen, storage }

/// ส่วนของจอที่บทเรียนชี้ (hl ในต้นแบบ)
enum TutorialTarget {
  /// การ์ดเจ้าของฟาร์ม (แถบสถานะ)
  status,

  /// ปุ่มพักผ่อนในหน้าฟาร์ม (บ้าน)
  home,
  pond,
  shop,
  kitchen,
  storage,

  /// ส่วนเตรียมภัยในหน้าฟาร์ม
  prepare,
}

class TutorialStep {
  const TutorialStep(this.text, this.target, [this.done, this.onEnter]);

  final String text;
  final TutorialTarget target;

  /// เงื่อนไขที่ต้องทำก่อนกด "ถัดไป" (null = กดได้เลย)
  final bool Function(GameEngine e, GameScreen screen)? done;

  /// ทำเมื่อเข้าขั้นนี้ (เช่น แจกปลาและเครื่องปรุง)
  final void Function(GameEngine e)? onEnter;
}

/// ข้อความตามต้นแบบ ปรับชื่อหน้าให้ตรงกับเมนูของแอป
final List<TutorialStep> kTutorial = [
  const TutorialStep(
    'นี่คือแถบสถานะของคุณในหน้าฟาร์ม: ความอิ่ม พลังงาน สุขภาพ ความสุข',
    TutorialTarget.status,
  ),
  const TutorialStep(
    'เงินใช้ซื้อปลา วัตถุดิบ และอุปกรณ์ พลังงานลดลงเมื่อทำกิจกรรม กด "พักผ่อน" เพื่อฟื้นพลังงาน ความอิ่มลดลงทุกวัน ต้องเลือกกินเองที่ "คลัง"',
    TutorialTarget.home,
  ),
  TutorialStep(
    'ไปที่เมนู "ปลา" เพื่อเข้าไปดูแลบ่อปลา',
    TutorialTarget.pond,
    (e, cur) => cur == GameScreen.pond,
  ),
  TutorialStep(
    'ไปที่ "ร้านปลา" เลือกปลาดูรายละเอียด เลือกจำนวน แล้วกด "ซื้อปลา" และยืนยัน',
    TutorialTarget.shop,
    (e, cur) => e.state.pond.isNotEmpty,
  ),
  TutorialStep(
    'กลับไปที่ "บ่อปลา" แล้วกดให้อาหารปลา (แนะนำ "พอดี")',
    TutorialTarget.pond,
    (e, cur) => e.state.fed > 0,
  ),
  TutorialStep(
    'ดูค่า Ammonia, Nitrite, Nitrate และออกซิเจนของบ่อ ถ้าค่าแย่ให้เปลี่ยนน้ำหรือเติมอากาศ',
    TutorialTarget.pond,
    (e, cur) => cur == GameScreen.pond,
  ),
  TutorialStep(
    'ลองทำอาหาร: ระบบแจกปลา 1 ตัวและเครื่องปรุงให้แล้ว ไปที่ "ครัว" แล้วกดทำปลาทอด',
    TutorialTarget.kitchen,
    (e, cur) =>
        e.state.stock.any((b) => kFoods[b.food]!.kind == FoodKind.meal),
    (e) {
      final s = e.state;
      s.fishStock['nila'] = (s.fishStock['nila'] ?? 0) + 1;
      s.inventory['spice'] = (s.inventory['spice'] ?? 0) + 1;
    },
  ),
  TutorialStep(
    'อาหารที่ทำไว้อยู่ใน "คลัง" มีวันหมดอายุ ถนอมอาหารเพื่อเก็บให้นานขึ้น และดูว่าเสบียงอยู่ได้กี่วัน',
    TutorialTarget.storage,
    (e, cur) => cur == GameScreen.storage,
  ),
  TutorialStep(
    'ข่าวเตือนภัยจะแจ้งล่วงหน้า ภัยพิบัติเกิดต่อเนื่องหลายวัน ตรวจความพร้อมและซื้ออุปกรณ์ที่ "เตรียมภัย" ในหน้าฟาร์ม',
    TutorialTarget.prepare,
    (e, cur) => cur == GameScreen.farm,
  ),
];

extension Tutorial on GameEngine {
  /// กำลังอยู่ในบทเรียน
  bool get tutorialActive => state.tut < kTutorialSteps;

  /// ขั้นปัจจุบัน (null เมื่อจบบทเรียนแล้ว)
  TutorialStep? get tutorialStep =>
      tutorialActive ? kTutorial[state.tut] : null;

  /// บันทึกว่าขั้นนี้ทำเงื่อนไขสำเร็จแล้ว (ต้นแบบเช็กทุกครั้งที่วาดจอ)
  /// คืน true เมื่อสถานะเปลี่ยน
  bool tutorialCheck(GameScreen screen) {
    final t = tutorialStep;
    if (t == null || t.done == null || state.tutOk == state.tut) return false;
    if (!t.done!(this, screen)) return false;
    state.tutOk = state.tut;
    return true;
  }

  /// กด "ถัดไป" ได้ไหม
  bool get tutorialCanNext {
    final t = tutorialStep;
    return t != null && (t.done == null || state.tutOk == state.tut);
  }

  /// ถัดไป (tutGo(1)) — ทำไม่ได้ถ้ายังไม่ผ่านเงื่อนไข
  void tutorialNext() {
    if (!tutorialCanNext) return;
    state.tut = (state.tut + 1).clamp(0, kTutorialSteps);
    tutorialStep?.onEnter?.call(this);
  }

  /// ย้อนกลับ (tutGo(-1))
  void tutorialBack() => state.tut = (state.tut - 1).clamp(0, kTutorialSteps);

  /// ข้ามบทเรียน
  void tutorialSkip() => state.tut = kTutorialSteps;

  /// เล่นบทเรียนซ้ำ (เมนูตั้งค่าในต้นแบบ)
  void tutorialRestart() => state.tut = 0;
}
