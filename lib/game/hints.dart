/// คำแนะนำบนหน้าฟาร์ม (hint() ในต้นแบบ ไม่รวมส่วนบทเรียน)
library;

import '../data/disaster_data.dart';
import 'game_engine.dart';
import 'tutorial.dart';

/// null ระหว่างบทเรียน (ต้นแบบซ่อนคำแนะนำจนกว่าจะจบบทเรียน)
String? farmHint(GameEngine e) {
  if (e.tutorialActive) return null;
  final s = e.state;
  final a = s.active;
  if (a != null) {
    return '${kDisasters[a.type]!.name}กำลังเกิด (วันที่ ${a.dayIndex + 1}/${a.duration}) — ตรวจฟาร์มและเสบียง แล้วกด "จบวัน"';
  }
  final w = e.warnDays;
  if (w > 0) {
    return 'ข่าวเตือน${kDisasters[s.upcoming!.type]!.name} อีก $w วัน — ตรวจความพร้อมที่ "เตรียมภัย"';
  }
  if (s.damaged) return 'ฟาร์มเสียหาย ซ่อมแซมได้ที่ "เตรียมภัย"';
  if (s.hunger < 40) {
    return 'หิวแล้ว! เลือกกินอาหารที่ "บ้าน" หรือ "คลังสินค้า"';
  }
  if (s.pond.isEmpty) return 'ซื้อปลาที่ร้านปลา แล้วปล่อยลงบ่อ';
  if (s.fed == 0) return 'ให้อาหารปลาที่บ่อ แล้วกด "จบวัน"';
  if (e.matureCount > 0) return 'มีปลาโตพอจับแล้ว! ไปที่บ่อแล้วกด "จับปลา"';
  if (e.fishTotal > 0) return 'มีปลาในคลัง: ขาย ทำอาหาร หรือถนอมอาหารที่ครัว';
  return 'ดูแลบ่อ ทำอาหาร เก็บเสบียง แล้วกด "จบวัน"';
}

/// ที่ที่แถบ "ตอนนี้ควรทำ" พาไป
enum NextPlace { farm, pond, shop, market, kitchen, storage, endDay }

/// แท็บของแต่ละที่ (0 ฟาร์ม · 1 ปลา · 2 ตลาด · 3 ครัว · 4 คลัง) — null = ปุ่มจบวัน
int? tabOfPlace(NextPlace p) => switch (p) {
  NextPlace.farm => 0,
  NextPlace.pond || NextPlace.shop => 1,
  NextPlace.market => 2,
  NextPlace.kitchen => 3,
  NextPlace.storage => 4,
  NextPlace.endDay => null,
};

/// แถบ "ตอนนี้ควรทำ": ข้อความสั้น 1 บรรทัด + ที่ที่ต้องไป (เรียงตามความเร่งด่วน)
/// null ระหว่างบทเรียน
({String text, NextPlace place})? nextStep(GameEngine e) {
  if (e.tutorialActive) return null;
  final s = e.state;
  final a = s.active;
  if (a != null) {
    return (
      text:
          '${kDisasters[a.type]!.name}วันที่ ${a.dayIndex + 1}/${a.duration} ตรวจฟาร์มแล้วกด "จบวัน"',
      place: NextPlace.farm,
    );
  }
  final w = e.warnDays;
  if (w > 0) {
    final name = kDisasters[s.upcoming!.type]!.name;
    return (
      text: w == 1
          ? 'พรุ่งนี้มี$name ไปเตรียมอุปกรณ์ที่ฟาร์ม'
          : 'อีก $w วันมี$name ไปเตรียมอุปกรณ์ที่ฟาร์ม',
      place: NextPlace.farm,
    );
  }
  if (s.damaged) {
    return (text: 'ฟาร์มเสียหาย ไปซ่อมที่ฟาร์ม', place: NextPlace.farm);
  }
  if (s.hunger < 40 && e.edible.isNotEmpty) {
    return (text: 'หิวแล้ว ไปกินอาหารที่คลัง', place: NextPlace.storage);
  }
  if (s.pond.isEmpty) {
    return (text: 'บ่อว่าง ไปซื้อปลาที่ร้านปลา', place: NextPlace.shop);
  }
  if (s.fed == 0) {
    return (text: 'ปลายังไม่ได้กิน ไปให้อาหารที่บ่อ', place: NextPlace.pond);
  }
  if (e.matureCount > 0) {
    return (
      text: 'ปลาโตแล้ว ${e.matureCount} ตัว ไปจับที่บ่อ',
      place: NextPlace.pond,
    );
  }
  if (e.fishTotal > 0) {
    return (text: 'มีปลาในคลัง ไปทำอาหารที่ครัว', place: NextPlace.kitchen);
  }
  return (text: 'วันนี้ทำครบแล้ว กด "จบวัน" ได้เลย', place: NextPlace.endDay);
}

/// ป้ายบนเมนูแต่ละแท็บ: null = ไม่มี · 0 = จุด · n = ตัวเลข
List<int?> tabBadges(GameEngine e) {
  final s = e.state;
  final near = s.stock.where(e.isNearExpiry).length;
  return [
    // ฟาร์ม: มีภัยกำลังมา/เกิด หรือฟาร์มเสียหาย
    (s.active != null || e.warnDays > 0 || s.damaged) ? 0 : null,
    // ปลา: ปลาโตพอจับ (ตัวเลข) หรือยังไม่ได้ให้อาหาร (จุด)
    e.matureCount > 0
        ? e.matureCount
        : (s.pond.isNotEmpty && s.fed == 0 ? 0 : null),
    // ตลาด: ปลาในคลังที่ขายได้
    e.fishTotal > 0 && !s.marketClosed ? e.fishTotal : null,
    // ครัว: มีปลาให้ทำอาหาร
    e.fishTotal > 0 ? 0 : null,
    // คลัง: อาหารใกล้เสีย
    near > 0 ? near : null,
  ];
}
