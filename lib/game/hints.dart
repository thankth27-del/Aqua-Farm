/// คำแนะนำบนหน้าฟาร์ม (hint() ในต้นแบบ ไม่รวมส่วนบทเรียน)
library;

import '../data/disaster_data.dart';
import 'game_engine.dart';

String farmHint(GameEngine e) {
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
