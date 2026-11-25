import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart';

/// ชื่อสีเดิมของเกม ผูกกับโทเคนของระบบดีไซน์กลาง ([DsColors]) ทั้งหมด
/// สีมีความหมายเดียวกันทั้งแอป: หลัก (ฟ้า-เขียวน้ำทะเล) / เน้น (เหลืองส้ม) / เตือน (แดง) / สำเร็จ (เขียว)
///
/// - [paper] = สีตัวอักษร/ไอคอน "บนพื้นสีเข้ม" (แถบบน เมนู ปุ่มสีทึบ) และพื้นการ์ดสีขาว
/// - [wood]… = พื้นแถบหลัก (สีหลักเข้ม) ไม่ใช่ลายไม้แล้ว
abstract final class AquaColors {
  // ตัวอักษรเข้ม / เส้นขอบ
  static const ink = DsColors.text;
  static const inkSoft = DsColors.textMuted;

  // แถบหลัก (เดิมเป็นไม้)
  static const woodDark = DsColors.primaryDark;
  static const wood = DsColors.primary;
  static const woodLight = DsColors.primary;
  static const woodHi = DsColors.primarySoft;

  // พื้นการ์ด
  static const cream = DsColors.surface;
  static const creamDark = DsColors.primarySoft;
  static const paper = DsColors.surface;

  // เขียว = สำเร็จ
  static const grass = DsColors.success;
  static const grassLight = Color(0xFF6CC48F);
  static const grassDark = Color(0xFF1F7A45);
  static const leaf = DsColors.success;
  static const leafLight = Color(0xFF6CC48F);

  // พื้นหลังหน้า
  static const bgGreen = DsColors.background;
  static const bgGreenDot = DsColors.border;
  static const bgGreenDeep = DsColors.background;

  // ฟ้าน้ำ = สีหลัก
  static const water = DsColors.primary;
  static const waterLight = Color(0xFF5FB8AF);
  static const waterDeep = DsColors.primaryDark;
  static const foam = DsColors.primarySoft;

  // เน้น (เหลืองส้ม)
  static const gold = DsColors.accent;
  static const goldLight = Color(0xFFFCD27A);
  static const goldPale = DsColors.accentSoft;
  static const goldDark = DsColors.accentDark;

  // เตือน
  static const red = DsColors.danger;
  static const redDark = Color(0xFFA83232);
  static const redPale = DsColors.dangerSoft;

  // ตัวอักษรบนพื้นสว่าง
  static const text = DsColors.text;
  static const textSoft = DsColors.textMuted;
  static const ok = DsColors.success;
  static const bad = DsColors.danger;

  // ค่าสถานะ (ไอคอนในแถบบนกำกับความหมายอยู่แล้ว ใช้สีชุดเดียวกัน)
  static const hunger = DsColors.accent;
  static const energy = DsColors.success;
  static const health = DsColors.danger;
  static const joy = DsColors.primary;
}
