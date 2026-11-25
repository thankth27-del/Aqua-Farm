/// ฉากพิกเซลเต็มจอของหน้า ตลาด / ครัว / คลัง (320x180 วาดด้วยสี่เหลี่ยมล้วน ไม่เบลอ)
/// แถวบนสุดและล่างสุดของแต่ละฉากเป็นสีเรียบ/ลายต่อเนื่อง เพราะถูกยืดเติมจอสูง
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'pixel_scene.dart';

const _ink = Color(0xFF2A1C12);

/// ตลาดสด: แผงลอย 3 ร้าน (ผัก · ปลา · ของแห้ง) — [closed] = ตลาดปิด (ม่านเหล็กลง)
class MarketPainter extends PixelPainter {
  MarketPainter(super.tick, {this.closed = false});
  final bool closed;

  @override
  void draw(int t) {
    // ท้องฟ้า (แถวบนสีเรียบ)
    rect(0, 0, 320, 70, const Color(0xFF7DD3FC));
    rect(0, 40, 320, 30, const Color(0xFF93DCFD));
    for (var i = 0; i < 3; i++) {
      final x = ((t * .2 + i * 120) % 380) - 40;
      ellipse(x, 18 + i * 9, 16, 4, const Color(0xFFF4FBFF));
      ellipse(x + 10, 16 + i * 9, 9, 4, const Color(0xFFF4FBFF));
    }
    // ตึกแถวด้านหลัง
    for (final b in const [
      (0, 34, 60, 0xFFE8C9A0),
      (58, 26, 70, 0xFFD9B48A),
      (126, 38, 64, 0xFFEAD2AE),
      (188, 22, 72, 0xFFD2A97C),
      (258, 32, 62, 0xFFE3C196),
    ]) {
      rect(b.$1, b.$2, b.$3, 100 - b.$2, Color(b.$4));
      for (var wx = b.$1 + 8; wx < b.$1 + b.$3 - 10; wx += 16) {
        for (var wy = b.$2 + 8; wy < 84; wy += 16) {
          rect(wx, wy, 8, 8, const Color(0xFF5B8FB0));
          rect(wx, wy, 8, 2, const Color(0xFF9CC9E0));
        }
      }
      rect(b.$1, b.$2, b.$3, 3, const Color(0xFF8A5A3A));
    }
    // ธงราวพลิ้ว
    for (var x = 0; x < 320; x += 10) {
      final y = 46 + (math.sin(x / 30) * 3).round();
      final c = const [
        Color(0xFFD8453A),
        Color(0xFFE9B949),
        Color(0xFF3FA34D),
        Color(0xFF3B82C4),
      ][(x ~/ 10) % 4];
      final sway = ((t + x) % 20 < 10) ? 0 : 1;
      rect(x, y, 1, 1, _ink);
      rect(x + 2, y + 1, 5, 4 + sway, c);
    }
    // พื้นทางเดิน (แถวล่างลายต่อเนื่อง)
    rect(0, 100, 320, 80, const Color(0xFFC9A57A));
    for (var y = 104; y < 180; y += 12) {
      rect(0, y, 320, 1, const Color(0xFFB08A5E));
    }
    for (var x = 0; x < 320; x += 24) {
      rect(x, 100, 1, 80, const Color(0xFFB08A5E));
    }
    // แผงลอย 3 ร้าน
    _stall(14, const Color(0xFFD8453A), 0);
    _stall(116, const Color(0xFF3B82C4), 1);
    _stall(218, const Color(0xFF3FA34D), 2);
    // ตะกร้าและลังบนพื้น
    rect(96, 142, 18, 12, const Color(0xFFB07A3E));
    rect(96, 142, 18, 2, const Color(0xFF8A5A2E));
    ellipse(101, 140, 3, 3, const Color(0xFFE05A3A));
    ellipse(108, 140, 3, 3, const Color(0xFF7CC242));
    rect(200, 146, 16, 10, const Color(0xFFC9985E));
    rect(200, 146, 16, 2, const Color(0xFF8A5A3A));
  }

  /// แผง 1 ร้าน: กันสาดลายทาง เสา เคาน์เตอร์ และสินค้า
  void _stall(int x, Color stripe, int kind) {
    const w = 88;
    // เสา
    rect(x + 2, 60, 4, 72, const Color(0xFF6B4528));
    rect(x + w - 6, 60, 4, 72, const Color(0xFF6B4528));
    // กันสาด
    for (var i = 0; i < w; i += 8) {
      rect(
        x + i,
        54,
        8,
        14,
        (i ~/ 8).isEven ? stripe : const Color(0xFFFFF6E5),
      );
      ellipse(
        x + i + 4,
        68,
        4,
        2,
        (i ~/ 8).isEven ? stripe : const Color(0xFFFFF6E5),
      );
    }
    rect(x - 2, 52, w + 4, 3, _ink);
    // ป้ายราคา
    rect(x + 30, 72, 28, 10, const Color(0xFFF4EBC8));
    rect(x + 30, 72, 28, 1, _ink);
    rect(x + 34, 76, 20, 2, const Color(0xFF8A5A3A));
    // เคาน์เตอร์
    rect(x - 2, 108, w + 4, 6, const Color(0xFF8A5A3A));
    rect(x, 114, w, 22, const Color(0xFFB07A4A));
    for (var i = x + 4; i < x + w; i += 12) {
      rect(i, 116, 1, 18, const Color(0xFF8A5A3A));
    }
    // สินค้าบนเคาน์เตอร์
    switch (kind) {
      case 0: // ผัก ผลไม้
        for (var i = 0; i < 7; i++) {
          final c = const [
            Color(0xFFE05A3A),
            Color(0xFF7CC242),
            Color(0xFFF2C94C),
            Color(0xFF9B5DE5),
          ][i % 4];
          ellipse(x + 10 + i * 11, 102, 5, 5, c);
          rect(x + 10 + i * 11, 96, 1, 3, const Color(0xFF3FA34D));
        }
      case 1: // ปลาบนน้ำแข็ง
        rect(x + 6, 100, w - 12, 8, const Color(0xFFE6F4FB));
        for (var i = 0; i < 4; i++) {
          final fx = x + 10 + i * 18;
          ellipse(fx + 6, 100, 7, 3, const Color(0xFF8FA6B5));
          rect(fx - 2, 98, 3, 5, const Color(0xFF8FA6B5));
          rect(fx + 10, 99, 1, 1, _ink);
        }
      default: // โหลและกระสอบของแห้ง
        for (var i = 0; i < 4; i++) {
          final jx = x + 8 + i * 20;
          rect(jx, 92, 12, 16, const Color(0xFFC9D8EE));
          rect(
            jx + 1,
            97,
            10,
            10,
            Color(const [0xFFE9B949, 0xFFD8453A, 0xFF9BD64B, 0xFFF2E2C2][i]),
          );
          rect(jx, 90, 12, 3, const Color(0xFFC9985E));
        }
    }
    if (closed) {
      // ม่านเหล็กลงปิดร้าน
      rect(x, 68, w, 68, const Color(0xFF8B96A3));
      for (var y = 70; y < 136; y += 5) {
        rect(x, y, w, 1, const Color(0xFF6B7682));
      }
      rect(x + w ~/ 2 - 9, 92, 18, 12, const Color(0xFFD8453A));
      rect(x + w ~/ 2 - 6, 97, 12, 2, Colors.white);
    }
  }
}

/// ครัว: ผนังกระเบื้อง เตาพร้อมหม้อมีไอน้ำ เคาน์เตอร์ และอุปกรณ์ถนอมที่มี
class KitchenPainter extends PixelPainter {
  KitchenPainter(super.tick, {this.equipment = const {}, this.cooking = 0});

  /// จำนวนอุปกรณ์ครัวที่มี (rack, jar, fridge, canner)
  final Map<String, int> equipment;

  /// จำนวนชุดที่กำลังถนอม (ไอน้ำ/ของบนราว)
  final int cooking;

  bool _has(String id) => (equipment[id] ?? 0) > 0;

  @override
  void draw(int t) {
    // ผนังกระเบื้อง (แถวบนลายต่อเนื่อง)
    rect(0, 0, 320, 112, const Color(0xFFF2E6CE));
    for (var y = 0; y < 112; y += 12) {
      rect(0, y, 320, 1, const Color(0xFFDCCBA8));
    }
    for (var x = 0; x < 320; x += 12) {
      rect(x, 0, 1, 112, const Color(0xFFDCCBA8));
    }
    // หน้าต่าง
    rect(232, 18, 64, 48, const Color(0xFF8A5A3A));
    rect(236, 22, 56, 40, const Color(0xFF7DD3FC));
    ellipse(278, 34, 5, 5, const Color(0xFFFFF3B0));
    rect(262, 22, 2, 40, const Color(0xFF8A5A3A));
    rect(236, 41, 56, 2, const Color(0xFF8A5A3A));
    // ราวแขวนอุปกรณ์
    rect(20, 24, 110, 3, const Color(0xFF6B4528));
    for (final u in const [(28, 14), (48, 18), (68, 12), (88, 16), (108, 14)]) {
      rect(u.$1, 27, 1, 4, _ink);
      rect(u.$1 - 3, 31, 7, u.$2, const Color(0xFF9AA5B1));
      rect(u.$1 - 3, 31, 7, 2, const Color(0xFFC7D0D9));
    }
    // ชั้นเครื่องเทศ
    rect(150, 40, 66, 4, const Color(0xFF8A5A3A));
    for (var i = 0; i < 5; i++) {
      final c = const [
        Color(0xFFD8453A),
        Color(0xFFE9B949),
        Color(0xFF5DB857),
        Color(0xFFB0764A),
        Color(0xFFF2E2C2),
      ][i];
      rect(153 + i * 12, 30, 9, 10, const Color(0xFFC9D8EE));
      rect(154 + i * 12, 33, 7, 6, c);
    }
    // เคาน์เตอร์ + ตู้ล่าง
    rect(0, 108, 320, 6, const Color(0xFF8A5A3A));
    rect(0, 114, 320, 26, const Color(0xFFB07A4A));
    for (var x = 0; x < 320; x += 40) {
      rect(x + 2, 116, 36, 22, const Color(0xFFC08A58));
      rect(x + 30, 125, 4, 2, _ink);
    }
    // เตา + หม้อ
    rect(62, 92, 70, 16, const Color(0xFF3A3A44));
    rect(62, 92, 70, 2, const Color(0xFF5A5A66));
    final flame = t % 6 < 3;
    rect(
      76,
      104,
      12,
      3,
      flame ? const Color(0xFFFF8A3A) : const Color(0xFFFFB14A),
    );
    rect(
      104,
      104,
      12,
      3,
      flame ? const Color(0xFFFFB14A) : const Color(0xFFFF8A3A),
    );
    rect(70, 74, 28, 18, const Color(0xFF8E9AA6));
    rect(68, 72, 32, 4, const Color(0xFFB4BEC8));
    rect(100, 80, 22, 12, const Color(0xFF2F2F38)); // กระทะ
    rect(122, 84, 12, 2, const Color(0xFF6B4528));
    // ไอน้ำลอยขึ้น
    for (var i = 0; i < 4; i++) {
      final y = 68 - ((t * .6 + i * 11) % 40);
      final x = 80 + (math.sin((t + i * 9) / 6) * 3).round() + i * 3;
      rect(x, y, 4, 3, Color.fromRGBO(255, 255, 255, .7 - (68 - y) / 60));
    }
    // ราวตากแห้ง (ถ้ามี)
    if (_has('rack')) {
      rect(150, 62, 60, 2, const Color(0xFF6B4528));
      for (var i = 0; i < 4; i++) {
        rect(156 + i * 14, 64, 1, 4, _ink);
        ellipse(157 + i * 14, 74, 3, 6, const Color(0xFFB98A5A));
      }
    }
    // โหลดอง (ถ้ามี)
    if (_has('jar')) {
      for (var i = 0; i < 3; i++) {
        rect(150 + i * 16, 90, 12, 18, const Color(0xFFC9D8EE));
        rect(151 + i * 16, 95, 10, 12, const Color(0xFF9BD64B));
        rect(150 + i * 16, 88, 12, 3, const Color(0xFFC9985E));
      }
    }
    // หม้อบรรจุกระป๋อง (ถ้ามี)
    if (_has('canner')) {
      rect(204, 86, 22, 22, const Color(0xFF6B7682));
      rect(202, 84, 26, 4, const Color(0xFF9AA5B1));
      for (var i = 0; i < 3; i++) {
        rect(206 + i * 7, 100, 5, 7, const Color(0xFFD9DEE4));
      }
    }
    // ตู้เย็น (ถ้ามี)
    if (_has('fridge')) {
      rect(270, 62, 40, 78, const Color(0xFFE8EEF3));
      rect(270, 62, 40, 2, const Color(0xFFFFFFFF));
      rect(270, 92, 40, 2, const Color(0xFFB4BEC8));
      rect(302, 72, 3, 12, const Color(0xFF8E9AA6));
      rect(302, 100, 3, 16, const Color(0xFF8E9AA6));
    }
    // พื้นตาหมากรุก (แถวล่างลายต่อเนื่อง)
    rect(0, 140, 320, 40, const Color(0xFFD9C7A5));
    for (var x = 0; x < 320; x += 16) {
      for (var y = 140; y < 180; y += 16) {
        if (((x + y) ~/ 16).isEven) {
          rect(x, y, 16, 16, const Color(0xFFBFA77E));
        }
      }
    }
  }
}

/// คลังเสบียง: ชั้นวางไม้ 3 ชั้น ของบนชั้นเพิ่มตามอาหารที่มี ลังวัตถุดิบบนพื้น
class StoragePainter extends PixelPainter {
  StoragePainter(
    super.tick, {
    this.meals = 0,
    this.preserved = 0,
    this.raw = 0,
  });

  /// จำนวนจานอาหารสุก / อาหารถนอม / ของสด (ปลา+วัตถุดิบ) — ใช้วาดของบนชั้น
  final int meals;
  final int preserved;
  final int raw;

  @override
  void draw(int t) {
    // ผนังไม้ (แถวบนลายต่อเนื่อง)
    rect(0, 0, 320, 128, const Color(0xFF8B6546));
    for (var x = 0; x < 320; x += 16) {
      rect(x, 0, 2, 128, const Color(0xFF9B7552));
      rect(x + 8, 0, 1, 128, const Color(0xFF7A5638));
    }
    // หลอดไฟ
    rect(160, 0, 2, 18, _ink);
    final f = t % 31 < 2;
    ellipse(161, 24, 14, 12, Color.fromRGBO(255, 236, 160, f ? .12 : .25));
    rect(157, 18, 8, 10, const Color(0xFFFFE9A8));
    // ชั้นวาง 3 ชั้น
    rect(28, 30, 4, 96, const Color(0xFF5E3B26));
    rect(288, 30, 4, 96, const Color(0xFF5E3B26));
    for (final y in const [52, 84, 116]) {
      rect(26, y, 268, 5, const Color(0xFFB07A4A));
      rect(26, y + 5, 268, 2, const Color(0xFF5E3B26));
    }
    // ชั้นบน: อาหารถนอม (โหล/กระป๋อง)
    final p = math.min(preserved, 14);
    for (var i = 0; i < p; i++) {
      final x = 160 - p * 9 + i * 18 + 3;
      final c = const [
        Color(0xFFE9B949),
        Color(0xFFD8453A),
        Color(0xFF9BD64B),
        Color(0xFFB98A5A),
      ][i % 4];
      rect(x, 36, 12, 16, const Color(0xFFC9D8EE));
      rect(x + 1, 40, 10, 11, c);
      rect(x, 34, 12, 3, const Color(0xFFC9985E));
    }
    // ชั้นกลาง: อาหารสุก (จาน/กล่อง) — ของทุกชั้นวางกึ่งกลาง (จอแนวตั้งเห็นแค่ช่วงกลางฉาก)
    final m = math.min(meals, 12);
    for (var i = 0; i < m; i++) {
      final x = 160 - (m * 21) ~/ 2 + i * 21 + 2;
      rect(x, 74, 16, 10, const Color(0xFFF4EBC8));
      rect(x, 74, 16, 2, const Color(0xFFFFFFFF));
      ellipse(x + 8, 73, 5, 2, const Color(0xFFE08A3A));
    }
    // ชั้นล่าง: กระสอบ/ลังของสด
    final r = math.min(raw, 10);
    for (var i = 0; i < r; i++) {
      final x = 160 - (r * 25) ~/ 2 + i * 25 + 2;
      if (i.isEven) {
        ellipse(x + 9, 108, 9, 8, const Color(0xFFD9C08A));
        rect(x + 6, 99, 6, 3, const Color(0xFFB08A5E));
      } else {
        rect(x, 100, 20, 16, const Color(0xFFC9985E));
        rect(x, 100, 20, 2, const Color(0xFF8A5A3A));
        rect(x + 9, 100, 2, 16, const Color(0xFF8A5A3A));
      }
    }
    // ชั้นว่างทั้งหมด: ป้าย "ว่าง" เล็ก ๆ (ฝุ่น)
    if (p == 0 && m == 0 && r == 0) {
      for (var i = 0; i < 6; i++) {
        rect(60 + i * 37, 80 + (i % 2) * 2, 6, 1, const Color(0xFF7A5638));
      }
    }
    // พื้นไม้ (แถวล่างลายต่อเนื่อง)
    rect(0, 128, 320, 52, const Color(0xFF5E3B26));
    for (var y = 128; y < 180; y += 10) {
      rect(0, y, 320, 1, const Color(0xFF3D2616));
    }
    for (var x = 0; x < 320; x += 40) {
      rect(x, 128, 1, 52, const Color(0xFF3D2616));
    }
    rect(0, 126, 320, 4, const Color(0xFF8A5A3A));
    // ลังใหญ่บนพื้น
    rect(10, 138, 30, 22, const Color(0xFFC9985E));
    rect(10, 138, 30, 3, const Color(0xFF8A5A3A));
    rect(24, 138, 2, 22, const Color(0xFF8A5A3A));
    rect(280, 142, 28, 18, const Color(0xFFC9985E));
    rect(280, 142, 28, 3, const Color(0xFF8A5A3A));
  }
}
