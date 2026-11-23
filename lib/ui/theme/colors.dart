import 'package:material_ui/material_ui.dart';

/// ชุดสีกลาง: ฟาร์มพิกเซลโทนธรรมชาติ (เขียว ฟ้าน้ำ ไม้ ครีม) และสีทองเป็นจุดเด่น
/// สีไม้/ทอง/น้ำ ส่วนใหญ่มาจากฉากในต้นแบบ (reference/index.html)
abstract final class AquaColors {
  // เส้นขอบและตัวอักษรเข้ม (น้ำตาลเข้ม ไม่ใช่ดำล้วน ให้ภาพนุ่มตา)
  static const ink = Color(0xFF2A1C12);
  static const inkSoft = Color(0xFF4A3322);

  // ไม้
  static const woodDark = Color(0xFF5E3B26);
  static const wood = Color(0xFF8A5A3A);
  static const woodLight = Color(0xFFA8714A);
  static const woodHi = Color(0xFFC9985E);

  // ครีม / กระดาษ
  static const cream = Color(0xFFF6E8C6);
  static const creamDark = Color(0xFFE2CB98);
  static const paper = Color(0xFFFFF7E2);

  // เขียว
  static const grass = Color(0xFF65A30D);
  static const grassLight = Color(0xFF8BC34A);
  static const grassDark = Color(0xFF3D6B22);
  static const leaf = Color(0xFF2F7D3A);
  static const leafLight = Color(0xFF5DB857);
  static const bgGreen = Color(0xFF34603A);
  static const bgGreenDot = Color(0xFF3B6B40);
  static const bgGreenDeep = Color(0xFF244A2C);

  // ฟ้าน้ำ
  static const water = Color(0xFF0E7490);
  static const waterLight = Color(0xFF38BDF8);
  static const waterDeep = Color(0xFF164E63);
  static const foam = Color(0xFFA5DDF5);

  // ทอง (จุดเด่น)
  static const gold = Color(0xFFE9B949);
  static const goldLight = Color(0xFFFFE08A);
  static const goldPale = Color(0xFFFFF3C4);
  static const goldDark = Color(0xFFB98A25);

  // แดง (เตือนภัย / ลบ)
  static const red = Color(0xFFE0584D);
  static const redDark = Color(0xFF9A3027);
  static const redPale = Color(0xFFFFE1DC);

  // ตัวอักษรบนพื้นครีม
  static const text = Color(0xFF3B2614);
  static const textSoft = Color(0xFF7A5A3E);
  static const ok = Color(0xFF2F7D3A);
  static const bad = Color(0xFFC0392B);

  // ค่าสถานะ
  static const hunger = Color(0xFFE9B949);
  static const energy = Color(0xFF65A30D);
  static const health = Color(0xFFE0584D);
  static const joy = Color(0xFF38BDF8);
}
