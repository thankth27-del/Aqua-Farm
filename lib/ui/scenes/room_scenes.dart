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
    // ท้องฟ้าไล่สีเป็นขั้น (แถวบนสีเรียบ)
    cached(
      'market_sky',
      () => bands(
        const [
          Color(0xFF3F9DEA),
          Color(0xFF55AEEF),
          Color(0xFF6EBFF2),
          Color(0xFF8ACEF4),
          Color(0xFFA8DCF5),
          Color(0xFFC5E8F3),
          Color(0xFFDDF1EC),
        ],
        0,
        10,
      ),
    );
    // ดวงอาทิตย์
    ellipse(292, 16, 15, 15, const Color(0x29FFECA0));
    ellipse(292, 16, 11, 11, const Color(0x47FFECA0));
    ellipse(292, 16, 8, 8, const Color(0xFFFFE278));
    ellipse(292, 16, 6, 6, const Color(0xFFFFF6C8));
    // เมฆ 2 ชั้น (ไกลช้า ใกล้เร็ว)
    for (var i = 0; i < 4; i++) {
      final x = ((t * .06 + i * 97) % 380) - 30;
      ellipse(x, 30 + (i * 5) % 10, 9, 2, const Color(0xFFE4F3FB));
      ellipse(x + 5, 28 + (i * 5) % 10, 5, 2, const Color(0xFFF4FBFF));
    }
    for (var i = 0; i < 3; i++) {
      final x = ((t * .2 + i * 120) % 380) - 40;
      ellipse(x, 19 + i * 9, 16, 4, const Color(0xFFD3E9F5));
      ellipse(x, 18 + i * 9, 16, 4, const Color(0xFFF4FBFF));
      ellipse(x + 10, 15 + i * 9, 9, 4, Colors.white);
    }
    // นกบินผ่าน
    for (var i = 0; i < 3; i++) {
      final x = ((t * .5 + i * 19) % 400) - 40, y = 12 + i * 5;
      final up = (t + i * 2) % 6 < 3 ? 1 : 0;
      rect(x - 2, y - up, 2, 1, const Color(0xFF2B3A4A));
      rect(x, y, 1, 1, const Color(0xFF2B3A4A));
      rect(x + 1, y - up, 2, 1, const Color(0xFF2B3A4A));
    }
    // ตึกแถวด้านหลัง: เงาด้านข้าง หน้าต่างมีบานเกล็ด กระถางต้นไม้
    for (final b in const [
      (0, 34, 60, 0xFFE8C9A0),
      (58, 26, 70, 0xFFD9B48A),
      (126, 38, 64, 0xFFEAD2AE),
      (188, 22, 72, 0xFFD2A97C),
      (258, 32, 62, 0xFFE3C196),
    ]) {
      final c = Color(b.$4);
      rect(b.$1, b.$2, b.$3, 100 - b.$2, c);
      rect(
        b.$1 + b.$3 - 4,
        b.$2,
        4,
        100 - b.$2,
        Color.lerp(c, const Color(0xFF5E3B26), .25)!,
      );
      for (var y = b.$2 + 6; y < 100; y += 6) {
        rect(b.$1, y, b.$3 - 4, 1, Color.lerp(c, Colors.white, .12)!);
      }
      var k = 0;
      for (var wx = b.$1 + 8; wx < b.$1 + b.$3 - 10; wx += 16) {
        for (var wy = b.$2 + 8; wy < 84; wy += 16) {
          final lit = (wx * 7 + wy) % 5 == 0;
          rect(wx - 1, wy - 1, 10, 10, const Color(0xFF7A5232));
          rect(
            wx,
            wy,
            8,
            8,
            lit ? const Color(0xFFFFD98A) : const Color(0xFF5B8FB0),
          );
          rect(
            wx,
            wy,
            8,
            2,
            lit ? const Color(0xFFFFF0C0) : const Color(0xFF9CC9E0),
          );
          rect(wx + 3, wy, 2, 8, const Color(0xFF7A5232));
          rect(wx - 1, wy + 9, 10, 1, const Color(0xFFF4EBD8));
          if (k++ % 3 == 1) {
            rect(wx + 1, wy + 6, 6, 3, const Color(0xFFB0603A));
            rect(wx, wy + 4, 3, 2, const Color(0xFF3FA34D));
            rect(wx + 4, wy + 3, 3, 3, const Color(0xFF5DB857));
            rect(wx + 3, wy + 3, 1, 1, const Color(0xFFE2463A));
          }
        }
      }
      rect(b.$1, b.$2, b.$3, 3, const Color(0xFF8A5A3A));
      rect(b.$1, b.$2, b.$3, 1, const Color(0xFFB57E46));
      rect(b.$1, b.$2 + 3, b.$3, 1, const Color(0x335E3B26));
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
    // ก้อนหินทางเดิน (ไม่วาดแถวล่างสุด)
    for (var i = 0; i < 90; i++) {
      final x = (i * 41 + (i ~/ 8) * 13) % 316, y = 103 + (i * 17) % 74;
      rect(x, y, 3, 1, const Color(0xFFDCBB90));
      rect(x, y + 1, 3, 1, const Color(0xFFB08A5E));
    }
    // เงาใต้แผงและแสงแดดส่องเฉียง
    for (final x in const [14, 116, 218]) {
      rect(x - 2, 136, 92, 4, const Color(0x335E3B26));
      rect(x, 140, 88, 2, const Color(0x1F5E3B26));
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
    // นกพิราบเดินจิกพื้น (ตลาดปิด: ไม่มี)
    if (!closed) {
      for (var i = 0; i < 2; i++) {
        final x = 60 + i * 150 + 10 * math.sin(t / 30 + i * 2);
        final peck = (t + i * 7) % 18 < 3 ? 1 : 0;
        rect(x, 160, 6, 3, const Color(0xFF9AA5B1));
        rect(x + 1, 159, 4, 1, const Color(0xFFB4BEC8));
        rect(x + 5, 158 + peck, 2, 2, const Color(0xFF6B7682));
        rect(x + 7, 159 + peck, 1, 1, const Color(0xFFE9B949));
        rect(x + 2, 163, 1, 2, const Color(0xFFD8453A));
        rect(x + 4, 163, 1, 2, const Color(0xFFD8453A));
      }
    }
    // ใบไม้ปลิวผ่าน
    for (var i = 0; i < 3; i++) {
      final k = (t * .9 + i * 120) % 360;
      rect(
        k - 20,
        60 + i * 30 + 6 * math.sin(t / 7 + i),
        2,
        1,
        i.isOdd ? const Color(0xFF7CC242) : const Color(0xFFE0B24A),
      );
    }
    // ตลาดปิด: ทั้งฉากหม่นลง
    if (closed) rect(0, 0, 320, 180, const Color(0x2E1E2430));
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
    rect(x, 55, w, 1, const Color(0x40FFFFFF));
    // เงาใต้กันสาด
    rect(x + 6, 71, w - 12, 3, const Color(0x2A2A1C12));
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
    // ผนังกระเบื้อง (แถวบนลายต่อเนื่อง) + เงาใต้ตู้แขวน
    cached('kitchen_wall', () {
      rect(0, 0, 320, 112, const Color(0xFFF2E6CE));
      for (var y = 0; y < 112; y += 12) {
        rect(0, y, 320, 1, const Color(0xFFDCCBA8));
        if (y > 0) rect(0, y + 1, 320, 1, const Color(0xFFFBF3E2));
      }
      for (var x = 0; x < 320; x += 12) {
        rect(x, 0, 1, 112, const Color(0xFFDCCBA8));
      }
      // ลายกระเบื้องคาดฟ้าแถวกลาง
      for (var x = 0; x < 320; x += 12) {
        rect(x + 1, 61, 11, 11, const Color(0xFFBFE3EC));
        rect(x + 5, 65, 3, 3, const Color(0xFF5BA8C0));
      }
      // ผนังมืดลงใกล้เคาน์เตอร์
      dither(0, 100, 320, 8, const Color(0x22000000));
    });
    // หน้าต่าง: วิวนอกบ้าน (ฟ้า เมฆ ทุ่ง ต้นไม้ไหว)
    rect(232, 18, 64, 48, const Color(0xFF8A5A3A));
    rect(236, 22, 56, 14, const Color(0xFF6EBFF2));
    rect(236, 36, 56, 12, const Color(0xFF9AD3F5));
    rect(236, 48, 56, 14, const Color(0xFF7DB548));
    rect(236, 48, 56, 2, const Color(0xFF5E9A3A));
    ellipse(280, 30, 5, 5, const Color(0xFFFFF3B0));
    final cx = 236 + ((t * .15) % 70) - 10;
    if (cx > 238 && cx < 284) {
      ellipse(cx, 32, 6, 2, Colors.white);
      ellipse(cx + 3, 30, 3, 2, Colors.white);
    }
    final sw = (math.sin(t / 12) * 1.2).round();
    rect(252, 44, 2, 10, const Color(0xFF6B4226));
    ellipse(253 + sw, 41, 6, 5, const Color(0xFF2E7D3A));
    ellipse(252 + sw, 39, 3, 2, const Color(0xFF5DB857));
    rect(262, 22, 2, 40, const Color(0xFF8A5A3A));
    rect(236, 41, 56, 2, const Color(0xFF8A5A3A));
    rect(237, 23, 6, 1, const Color(0x80FFFFFF));
    // ผ้าม่านลายตาราง + ขอบหน้าต่างและกระถางสมุนไพร
    for (final x in const [226, 292]) {
      for (var y = 16; y < 64; y += 4) {
        rect(x, y, 8, 4, const Color(0xFFD8453A));
        rect(x + ((y ~/ 4).isEven ? 0 : 4), y, 4, 4, const Color(0xFFF6EEDC));
      }
      rect(x, 40, 8, 2, const Color(0xFF8A5A3A));
    }
    rect(224, 14, 80, 3, const Color(0xFF6B4528));
    rect(230, 66, 68, 3, const Color(0xFFB07A4A));
    rect(246, 60, 8, 6, const Color(0xFFB0603A));
    rect(245, 56, 4, 4, const Color(0xFF5DB857));
    rect(249, 54, 4, 6, const Color(0xFF3FA34D));
    // ลำแสงแดดจากหน้าต่างทอดเฉียงลงพื้น + ฝุ่นลอย
    for (var j = 0; j < 20; j++) {
      rect(238 - j * 3, 69 + j * 4, 52, 4, const Color(0x12FFF2C0));
    }
    for (var i = 0; i < 8; i++) {
      final k = (t * .2 + i * 13) % 70;
      rect(
        200 - k * .6 + 18 * math.sin(i * 2.3),
        74 + k,
        1,
        1,
        const Color(0x66FFF6D8),
      );
    }
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
    // แสงไฟจากเตา (วูบวาบ)
    ellipse(97, 100, 44 + t % 3, 14, const Color(0x1AFF9A40));
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
    rect(70, 74, 4, 18, const Color(0xFFA9B4BF));
    rect(94, 74, 4, 18, const Color(0xFF75818D));
    // ฝาหม้อกระดกเมื่อกำลังถนอมอาหาร
    final lid = cooking > 0 && t % 8 < 2 ? 1 : 0;
    rect(68, 72 - lid, 32, 4, const Color(0xFFB4BEC8));
    rect(82, 69 - lid, 4, 3, const Color(0xFF5A5A66));
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
    // พื้นตาหมากรุก (แถวล่างลายต่อเนื่อง) + เงาใต้เคาน์เตอร์ + แสงสะท้อน
    rect(0, 140, 320, 40, const Color(0xFFD9C7A5));
    for (var x = 0; x < 320; x += 16) {
      for (var y = 140; y < 180; y += 16) {
        if (((x + y) ~/ 16).isEven) {
          rect(x, y, 16, 16, const Color(0xFFBFA77E));
        } else if (y < 170) {
          rect(x + 2, y + 2, 4, 1, const Color(0x66FFFFFF));
        }
      }
    }
    rect(0, 140, 320, 4, const Color(0x335E3B26));
    rect(0, 144, 320, 2, const Color(0x1A5E3B26));
    // แสงแดดตกกระทบพื้น
    rect(166, 148, 58, 10, const Color(0x1AFFF2C0));
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
    // ผนังไม้ลายเสี้ยนและปุ่มไม้ (แถวบนลายต่อเนื่อง)
    cached('storage_wall', () {
      rect(0, 0, 320, 128, const Color(0xFF8B6546));
      for (var x = 0; x < 320; x += 16) {
        rect(x, 0, 2, 128, const Color(0xFF9B7552));
        rect(x + 8, 0, 1, 128, const Color(0xFF7A5638));
      }
      for (var i = 0; i < 60; i++) {
        final x = (i * 37 + (i ~/ 9) * 7) % 316 + 3, y = 4 + (i * 23) % 120;
        rect(x, y, 1, 6 + i % 5, const Color(0xFF805C3E));
      }
      for (var i = 0; i < 9; i++) {
        final x = 12 + i * 35 + (i % 2) * 6, y = 14 + (i * 41) % 100;
        ellipse(x, y, 2, 1, const Color(0xFF6E4C30));
        rect(x, y, 1, 1, const Color(0xFF5A3C24));
      }
      // หยากไย่มุมซ้ายบน
      for (var i = 0; i < 12; i++) {
        rect(2 + i, 2 + i, 1, 1, const Color(0x66E8E0D0));
        rect(2 + i * 2, 2, 1, 1, const Color(0x55E8E0D0));
        rect(2, 2 + i * 2, 1, 1, const Color(0x55E8E0D0));
      }
    });
    // หลอดไฟ: แสงเป็นกรวยลงมาถึงพื้น (แกว่งเล็กน้อย)
    final f = t % 31 < 2;
    final sway = (math.sin(t / 15) * 1.5).round();
    rect(160, 0, 2, 18, _ink);
    for (var j = 0; j < 25; j++) {
      final w = 20 + j * 7;
      rect(
        161 + sway * (1 - j / 25) - w / 2,
        28 + j * 4,
        w,
        4,
        Color.fromRGBO(255, 230, 150, (f ? .03 : .06) * (1 - j / 40)),
      );
    }
    ellipse(
      161 + sway,
      24,
      14,
      12,
      Color.fromRGBO(255, 236, 160, f ? .12 : .25),
    );
    rect(157 + sway, 17, 8, 2, const Color(0xFF4A4A52));
    rect(157 + sway, 19, 8, 9, const Color(0xFFFFE9A8));
    rect(158 + sway, 20, 3, 4, const Color(0xFFFFFBE0));
    // ชั้นวาง 3 ชั้น + เงาใต้ชั้น
    rect(28, 30, 4, 96, const Color(0xFF5E3B26));
    rect(288, 30, 4, 96, const Color(0xFF5E3B26));
    for (final y in const [52, 84, 116]) {
      rect(26, y + 7, 268, 4, const Color(0x332A1C12));
      rect(26, y, 268, 5, const Color(0xFFB07A4A));
      rect(26, y, 268, 1, const Color(0xFFD09A62));
      rect(26, y + 5, 268, 2, const Color(0xFF5E3B26));
    }
    // ฝุ่นลอยในแสงไฟ
    for (var i = 0; i < 10; i++) {
      final k = (t * .12 + i * 11) % 90;
      rect(
        150 + 30 * math.sin(i * 1.7) + 4 * math.sin(t / 20 + i),
        30 + k,
        1,
        1,
        const Color(0x66FFF0C8),
      );
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
    rect(10, 138, 30, 1, const Color(0xFFE2B27A));
    rect(280, 142, 28, 1, const Color(0xFFE2B27A));
    // แสงไฟตกกระทบพื้นไม้ + เงาใต้ลัง
    ellipse(161, 150, 60, 10, const Color(0x1FFFE6A0));
    rect(10, 160, 32, 3, const Color(0x402A1C12));
    rect(280, 160, 30, 3, const Color(0x402A1C12));
    for (var y = 129; y < 178; y += 10) {
      rect(0, y, 320, 1, const Color(0x1AFFE0B0));
    }
    // มุมห้องมืดลง (คงที่ทุกแถว ยืดเติมจอได้)
    rect(0, 0, 18, 180, const Color(0x262A1C12));
    rect(0, 0, 8, 180, const Color(0x262A1C12));
    rect(302, 0, 18, 180, const Color(0x262A1C12));
    rect(312, 0, 8, 180, const Color(0x262A1C12));
  }
}
