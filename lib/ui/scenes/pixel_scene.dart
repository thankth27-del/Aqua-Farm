/// ฉากพิกเซล 320x180 — พอร์ตจากฟังก์ชัน farm(), pond(), fx(), spr() ของ reference/index.html
/// วาดด้วยสี่เหลี่ยมล้วน ไม่ใช้ anti-alias (ภาพไม่เบลอ)
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/fish_data.dart';
import '../../game/game_state.dart';
import '../providers.dart';
import '../layout/responsive.dart';
import 'fish_swim.dart';
import '../design/design_system.dart' show DsColors, DsRadius;
import '../theme/fish_sprite.dart';

const double kSceneW = 320;
const double kSceneH = 180;

int _r(num x) => (x + .5).floor(); // Math.round ของ JS

Color _rgba(int r, int g, int b, double a) =>
    Color.fromRGBO(r, g, b, a.clamp(0, 1).toDouble());

abstract class PixelPainter extends CustomPainter {
  PixelPainter(this.tick) : super(repaint: tick);

  final ValueListenable<int> tick;
  late Canvas _c;
  final Paint _p = Paint()..isAntiAlias = false;

  /// R(x,y,w,h,c)
  void rect(num x, num y, num w, num h, Color c) {
    _p.color = c;
    _c.drawRect(
      Rect.fromLTWH(
        _r(x).toDouble(),
        _r(y).toDouble(),
        w.toDouble(),
        h.toDouble(),
      ),
      _p,
    );
  }

  /// E(x,y,rx,ry,c) วงรีแบบพิกเซล
  void ellipse(num x, num y, int rx, int ry, Color c) {
    _p.color = c;
    for (var j = -ry; j <= ry; j++) {
      final d = _r(rx * math.sqrt(1 - (j / ry) * (j / ry)));
      _c.drawRect(
        Rect.fromLTWH((x - d).toDouble(), (y + j).toDouble(), 2.0 * d, 1),
        _p,
      );
    }
  }

  void draw(int t);

  /// ปลาที่ต้องวาดทับฉาก (ใช้ภาพแถบเฟรมปลาชุดใหม่ ดู [SceneFishLayer])
  bool get hasFish => false;
  List<SceneFish> fishAt(int t) => const [];

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / kSceneW, size.height / kSceneH);
    draw(tick.value);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ข้อมูลที่ฉากฟาร์มต้องใช้
class FarmSceneData {
  const FarmSceneData({
    this.pond = const [],
    this.equipment = const {},
    this.damaged = false,
    this.fxType,
    this.fxLevel = 0,
  });

  factory FarmSceneData.fromState(GameState s, int warnDays) {
    DisasterType? type;
    double lvl = 0;
    final a = s.active;
    if (a != null && a.dayIndex >= 0) {
      type = a.type;
      lvl =
          kDisasters[a.type]!.visualLevel[disasterBaseDay(
            a.type,
            a.duration,
            a.dayIndex,
          )] *
          .85;
    } else if (warnDays > 0 && s.upcoming != null) {
      final lead = s.upcoming!.warnDays;
      type = s.upcoming!.type;
      lvl = (lead + 1 - warnDays) / (lead + 1) * .5;
    }
    return FarmSceneData(
      pond: [for (final f in s.pond) f.type],
      equipment: Map.of(s.equipment),
      damaged: s.damaged,
      fxType: type,
      fxLevel: lvl,
    );
  }

  final List<String> pond;
  final Map<String, int> equipment;
  final bool damaged;
  final DisasterType? fxType;
  final double fxLevel;
}

class FarmPainter extends PixelPainter {
  FarmPainter(super.tick, this.data);

  @override
  bool get hasFish => data.pond.isNotEmpty;

  /// ปลาในบ่อเล็กของฟาร์ม ว่ายไปทางซ้ายวนในบ่อ (สูงสุด 8 ตัว)
  @override
  List<SceneFish> fishAt(int t) {
    final pond = data.pond.take(8).toList();
    return [
      for (var i = 0; i < pond.length; i++)
        SceneFish(
          type: pond[i],
          x: 267 - ((i * 31 + t * .3 * (1 + i % 3)) % 62),
          y: 133.5 + (i % 3) * 7,
          size: 16,
          frame: fishFrameAt(t, i * 3),
          flipX: true,
        ),
    ];
  }

  final FarmSceneData data;

  int q(String k) => data.equipment[k] ?? 0;

  void sky(int t, double h) {
    const bands = [
      0xFF38BDF8,
      0xFF5CCBF7,
      0xFF86D6F6,
      0xFFAEE2F3,
      0xFFCFEAEA,
      0xFFE8DCC4,
      0xFFF1E3C0,
      0xFFF6E8C6,
    ];
    for (var i = 0; i < 8; i++) {
      rect(0, i * h / 8, 320, h / 8 + 1, Color(bands[i]));
    }
    ellipse(272, 26, 10, 10, const Color(0xFFFFE08A));
    ellipse(272, 26, 7, 7, const Color(0xFFFFF3B0));
    for (var i = 0; i < 4; i++) {
      final x = _r(((t * .15 + i * 95) % 400) - 60), y = 22 + i * 10;
      ellipse(x, y, 20, 5, const Color(0xFFF4FBFF));
      ellipse(x + 12, y - 3, 13, 5, Colors.white);
      ellipse(x - 10, y + 1, 10, 3, const Color(0xFFDFF3FB));
    }
  }

  void tree(int t, int x, int y) {
    final w = _r(math.sin(t / 14 + x) * 1.5);
    rect(x - 3, y - 12, 6, 12, const Color(0xFF5E3B26));
    ellipse(x + w, y - 24, 14, 12, const Color(0xFF1F5A35));
    ellipse(x - 7 + w, y - 17, 9, 8, const Color(0xFF2F7D3A));
    ellipse(x + 8 + w, y - 17, 9, 8, const Color(0xFF2F7D3A));
    ellipse(x - 2 + w, y - 30, 8, 5, const Color(0xFF5DB857));
  }

  void fx(int t, DisasterType? ty, double l) {
    if (ty == null || l <= 0) return;
    switch (ty) {
      case DisasterType.flood:
        final lv = _r(52 * l), y0 = 180 - lv;
        rect(0, y0, 320, lv, _rgba(62, 124, 184, .72));
        for (var x = 0; x < 320; x += 4) {
          rect(
            x,
            y0 + _r(2 * math.sin((x + t) / 6)),
            4,
            3,
            const Color(0xFFA5DDF5),
          );
        }
        rect(0, 0, 320, 180, _rgba(20, 16, 40, .3 * l));
        for (var i = 0; i < _r(46 * l); i++) {
          rect(
            (i * 29 + t * 3) % 320,
            (i * 17 + t * 5) % 180,
            1,
            5,
            const Color(0xFFA5DDF5),
          );
        }
      case DisasterType.drought:
        rect(0, 0, 320, 180, _rgba(240, 150, 60, .25 * l));
        ellipse(70, 26, 14, 14, const Color(0xFFFFE08A));
        for (var a = 0; a < 12; a++) {
          final r = a * math.pi / 6 + t / 40;
          rect(
            70 + math.cos(r) * 20,
            26 + math.sin(r) * 20,
            3,
            3,
            const Color(0xFFE9B949),
          );
        }
        for (var i = 0; i < _r(30 * l); i++) {
          final x = (i * 47) % 320, y = 100 + (i * 29) % 80;
          rect(x, y, 6, 1, const Color(0xFF5E3B26));
          rect(x + 5, y + 1, 1, 4, const Color(0xFF5E3B26));
        }
      case DisasterType.poll:
        ellipse(240, 141, 58, 22, _rgba(90, 120, 30, .55 * l));
        rect(0, 0, 320, 180, _rgba(40, 60, 20, .18 * l));
        for (var i = 0; i < 8; i++) {
          rect(
            205 + (i * 17) % 70,
            128 + (i * 11) % 25 - ((t / 2 + i * 5) % 12),
            3,
            3,
            _rgba(160, 200, 60, .6),
          );
        }
      case DisasterType.heat:
        rect(0, 0, 320, 180, _rgba(255, 140, 50, .28 * l));
        for (var i = 0; i < _r(24 * l); i++) {
          rect(
            (i * 43 + t * 2) % 320,
            86 + (i * 19) % 90 + _r(math.sin((t + i) / 4) * 2),
            8,
            1,
            _rgba(255, 230, 180, .3),
          );
        }
    }
  }

  @override
  void draw(int t) {
    sky(t, 90);
    rect(0, 76, 320, 16, const Color(0xFF4F7D2E));
    for (var x = 0; x < 320; x += 4) {
      rect(
        x,
        70 + _r(7 * math.sin(x / 21) + 3 * math.sin(x / 7)),
        4,
        22,
        const Color(0xFF6A9A3A),
      );
    }
    rect(0, 84, 320, 12, const Color(0xFF0E7490));
    for (var x = 0; x < 320; x += 6) {
      rect(
        (x + t * .6) % 320,
        86 + ((x ~/ 6) % 3) * 3,
        5,
        1,
        const Color(0xFF38BDF8),
      );
    }
    rect(0, 94, 320, 2, const Color(0xFF8B6546));
    rect(0, 96, 320, 84, const Color(0xFF65A30D));
    for (var i = 0; i < 220; i++) {
      rect(
        (i * 37) % 320,
        98 + (i * 13) % 80,
        2,
        1,
        i.isOdd ? const Color(0xFF7CBD1E) : const Color(0xFF4D7C0F),
      );
    }
    const path = Color(0xFFB08A5A);
    rect(108, 128, 22, 52, path);
    rect(104, 150, 26, 30, path);
    rect(104, 148, 96, 12, path);
    for (var i = 0; i < 40; i++) {
      rect(
        106 + (i * 17) % 90,
        130 + (i * 7) % 48,
        2,
        1,
        const Color(0xFF8A6A3E),
      );
    }
    tree(t, 36, 120);
    tree(t, 312, 100);
    tree(t, 24, 156);
    tree(t, 268, 92);
    // บ้าน
    rect(86, 98, 64, 30, const Color(0xFFC9985E));
    for (var i = 0; i < 6; i++) {
      rect(86, 102 + i * 5, 64, 1, const Color(0xFFB5702A));
    }
    rect(86, 98, 64, 2, const Color(0xFF6B4226));
    for (var i = 0; i < 22; i++) {
      final w = 76 - i * 3;
      rect(
        118 - w / 2,
        96 - i,
        w,
        1,
        i % 6 != 0 ? const Color(0xFF8B4A2B) : const Color(0xFFE8DCC4),
      );
    }
    rect(134, 72, 9, 20, const Color(0xFF8A5A3A));
    rect(133, 70, 11, 3, const Color(0xFF5E3B26));
    rect(112, 108, 13, 20, const Color(0xFF5E3B26));
    rect(122, 118, 2, 2, const Color(0xFFE9B949));
    final fl = (t % 37 < 2) ? const Color(0xFFC9A030) : const Color(0xFFE9B949);
    for (final p in const [(92, 104), (132, 104)]) {
      rect(p.$1 - 1, p.$2 - 1, 14, 14, const Color(0xFF5E3B26));
      rect(p.$1, p.$2, 12, 12, fl);
      rect(p.$1 + 5, p.$2, 2, 12, const Color(0xFFB98A25));
      rect(p.$1, p.$2 + 5, 12, 2, const Color(0xFFB98A25));
    }
    // คลังสินค้า (ลังไม้)
    rect(56, 120, 12, 10, const Color(0xFFC9985E));
    rect(56, 124, 12, 1, const Color(0xFF6B4226));
    rect(68, 124, 12, 8, const Color(0xFFC9985E));
    rect(68, 127, 12, 1, const Color(0xFF6B4226));
    rect(60, 113, 10, 8, const Color(0xFFC9985E));
    // ร้านค้า
    rect(166, 104, 2, 24, const Color(0xFF5E3B26));
    rect(194, 104, 2, 24, const Color(0xFF5E3B26));
    for (var i = 0; i < 8; i++) {
      rect(
        166 + i * 4,
        104,
        4,
        8,
        i.isOdd ? Colors.white : const Color(0xFF0E7490),
      );
    }
    rect(166, 112, 30, 2, const Color(0xFF2D7F8F));
    rect(168, 118, 28, 10, const Color(0xFFC9985E));
    for (final g in const [
      (0xFFD8453A, 170),
      (0xFF9BD64B, 176),
      (0xFFE9B949, 182),
      (0xFFFFFFFF, 188),
    ]) {
      rect(g.$2, 114, 4, 4, Color(g.$1));
    }
    // ครัว (เตา)
    rect(150, 118, 14, 10, const Color(0xFF4B4A5C));
    rect(148, 116, 18, 3, const Color(0xFF8F86A8));
    rect(152, 111, 10, 6, const Color(0xFF0E7490));
    rect(151, 111, 12, 1, const Color(0xFFE8DCC4));
    rect(
      156 + math.sin(t / 5) * 3,
      108 - ((t * .7) % 14),
      2,
      2,
      _rgba(240, 235, 255, .6),
    );
    // รั้ว
    for (var x = 56; x <= 100; x += 8) {
      rect(x, 160, 3, 12, const Color(0xFFC9985E));
    }
    rect(56, 163, 47, 2, const Color(0xFFC9985E));
    rect(56, 168, 47, 2, const Color(0xFFC9985E));
    for (var x = 140; x <= 184; x += 8) {
      rect(x, 166, 3, 12, const Color(0xFFC9985E));
    }
    rect(140, 169, 47, 2, const Color(0xFFC9985E));
    rect(140, 174, 47, 2, const Color(0xFFC9985E));
    // บ่อ
    ellipse(240, 141, 62, 25, const Color(0xFF6B4226));
    ellipse(240, 141, 58, 22, const Color(0xFF3E7CB8));
    ellipse(240, 140, 52, 18, const Color(0xFF4C93CC));
    for (var i = 0; i < 5; i++) {
      rect(
        200 + ((t * .5 + i * 27) % 76),
        128 + i * 5,
        7,
        1,
        const Color(0xFFA5DDF5),
      );
    }
    rect(186, 136, 18, 10, const Color(0xFF8A5A3A));
    for (var i = 0; i < 4; i++) {
      rect(187 + i * 4, 136, 1, 10, const Color(0xFF5E3B26));
    }
    const flowers = [
      (70, 140),
      (88, 150),
      (160, 134),
      (60, 172),
      (196, 172),
      (150, 150),
      (34, 130),
      (290, 168),
    ];
    const fc = [Color(0xFFE9B949), Colors.white, Color(0xFFF2B8A8)];
    for (var i = 0; i < flowers.length; i++) {
      rect(flowers[i].$1, flowers[i].$2, 2, 2, fc[i % 3]);
      rect(flowers[i].$1, flowers[i].$2 + 2, 1, 3, const Color(0xFF2F7D3A));
    }
    // อุปกรณ์ที่ซื้อแล้ว
    for (var i = 0; i < math.min(q('sand'), 8); i++) {
      rect(86 + i * 8, 132 + (i % 2) * 3, 8, 5, const Color(0xFFC9985E));
      rect(86 + i * 8, 136 + (i % 2) * 3, 8, 1, const Color(0xFF6B4226));
    }
    if (q('pump') > 0) {
      rect(136, 134, 12, 9, const Color(0xFF8F86A8));
      rect(140, 130, 4, 5, const Color(0xFF4B4A5C));
      rect(133, 138, 4, 2, const Color(0xFF3E7CB8));
    }
    if (q('tank') > 0) {
      rect(200, 150, 12, 16, const Color(0xFF3E7CB8));
      rect(200, 150, 12, 3, const Color(0xFFA5DDF5));
      rect(200, 164, 12, 2, const Color(0xFF23467A));
    }
    if (q('filter') > 0) {
      rect(186, 150, 10, 10, const Color(0xFF8B4A2B));
      rect(188, 152, 6, 3, const Color(0xFFA5DDF5));
    }
    if (q('net') > 0) {
      for (var x = 184; x < 298; x += 4) {
        rect(x, 118 + _r(math.sin(x / 9).abs() * 2), 2, 1, Colors.white);
      }
    }
    if (q('shade') > 0) {
      rect(206, 98, 40, 3, const Color(0xFF0E7490));
      rect(208, 101, 2, 12, const Color(0xFF5E3B26));
      rect(242, 101, 2, 12, const Color(0xFF5E3B26));
    }
    if (q('air') > 0) {
      for (var i = 0; i < 4; i++) {
        rect(
          232 + i * 3,
          150 - ((t * 1.1 + i * 9) % 22),
          2,
          2,
          const Color(0xFFA5DDF5),
        );
      }
    }
    if (q('rack') > 0) {
      rect(44, 134, 20, 2, const Color(0xFF8B6546));
      rect(46, 134, 2, 10, const Color(0xFF8B6546));
      rect(60, 134, 2, 10, const Color(0xFF8B6546));
      for (var i = 0; i < 3; i++) {
        rect(49 + i * 5, 136, 3, 6, const Color(0xFFE8DCC4));
      }
    }
    if (q('jar') > 0) {
      rect(74, 121, 5, 7, const Color(0xFFA5DDF5));
      rect(74, 119, 5, 2, const Color(0xFFC9985E));
      rect(80, 123, 5, 5, const Color(0xFFA5DDF5));
    }
    // ควันปล่องไฟ
    for (var i = 0; i < 4; i++) {
      final y = 66 - ((t * .5 + i * 9) % 32);
      rect(
        138 + math.sin((t + i * 11) / 8) * 4,
        y,
        3 + i,
        3 + i,
        _rgba(220, 210, 240, .55 - ((66 - y) / 60)),
      );
    }
    if (data.damaged) rect(0, 96, 320, 84, _rgba(94, 59, 38, .35));
    fx(t, data.fxType, data.fxLevel);
  }
}

/// ข้อมูลที่ฉากบ่อต้องใช้
class PondSceneData {
  const PondSceneData({
    required this.fish,
    required this.water,
    required this.o2,
    required this.fed,
  });

  factory PondSceneData.fromState(GameState s) => PondSceneData(
    fish: [
      for (final f in s.pond)
        SwimFish(
          key: f,
          type: f.type,
          growth: f.growth,
          stressed: s.water < 60 || s.o2 < kFish[f.type]!.o2Need,
          sick: fishSick(f),
        ),
    ],
    water: s.water,
    o2: s.o2,
    fed: s.fed > 0,
  );

  final List<SwimFish> fish;
  final int water;
  final double o2;
  final bool fed;
}

/// ปลาป่วย: สุขภาพต่ำกว่าครึ่ง (ใช้แสดงผลเท่านั้น)
bool fishSick(PondFish f) => f.health < 50;

class PondPainter extends PixelPainter {
  /// [swim] ต้องเป็นตัวเดิมตลอดอายุหน้าจอ (ปลาจำตำแหน่งของตัวเองไว้ในนั้น)
  PondPainter(super.tick, this.data, [PondSwim? swim])
    : swim = swim ?? PondSwim() {
    this.swim.sync(data.fish, fed: data.fed);
  }
  final PondSceneData data;
  final PondSwim swim;

  @override
  void draw(int t) {
    rect(0, 0, 320, 30, const Color(0xFF38BDF8));
    ellipse(280, 14, 12, 12, const Color(0xFFF4EBC8));
    rect(0, 26, 320, 10, const Color(0xFF2F6B45));
    for (var x = 0; x < 320; x += 6) {
      rect(x, 22, 2, 5, const Color(0xFF3D8A55));
    }
    rect(0, 36, 320, 144, const Color(0xFF0E7490));
    for (var y = 44; y < 180; y += 10) {
      for (var i = 0; i < 320; i += 26) {
        rect(
          i + (y % 20) + _r(2 * math.sin((t + i) / 9)),
          y,
          8,
          1,
          const Color(0xFF4C93CC),
        );
      }
    }
    for (var k = 0; k < 5; k++) {
      rect(
        40 + k * 60 + _r(4 * math.sin(t / 20 + k)),
        36,
        16,
        144,
        _rgba(165, 221, 245, .07),
      );
    }
    for (var x = 0; x < 320; x += 4) {
      rect(
        x,
        36 + _r(2 * math.sin((x + t * 1.5) / 7)),
        4,
        3,
        const Color(0xFFA5DDF5),
      );
    }
    rect(0, 156, 320, 24, const Color(0xFF23467A));
    for (var i = 0; i < 60; i++) {
      rect((i * 53) % 320, 158 + (i * 7) % 20, 3, 1, const Color(0xFF2A5C94));
    }
    for (var i = 0; i < 8; i++) {
      final x = 10 + i * 36;
      for (var j = 0; j < 5; j++) {
        rect(
          x + _r(2 * math.sin((t + i * 5 + j * 4) / 10)),
          156 - j * 6,
          2,
          6,
          const Color(0xFF2F7D3A),
        );
      }
    }
    // น้ำขุ่นตามคุณภาพน้ำ
    rect(0, 36, 320, 144, _rgba(94, 70, 30, (100 - data.water) / 230));
    // ฟองอากาศตามออกซิเจน
    for (var i = 0; i < _r(data.o2 / 10); i++) {
      final bx = (i * 31 + 9) % 300, by = 156 - ((t * 1.3 + i * 19) % 118);
      rect(bx, by, 4, 4, const Color(0xFFA5DDF5));
      rect(bx + 1, by + 1, 1, 1, Colors.white);
    }
    if (data.fed) {
      for (var i = 0; i < 10; i++) {
        rect(
          20 + i * 14,
          38 + (t * .8 + i * 11) % 70,
          2,
          2,
          const Color(0xFFC9985E),
        );
      }
    }
    // ปลาแต่ละตัวว่ายตามเป้าหมายของตัวเอง (ดู fish_swim.dart)
    swim.advanceTo(t);
  }

  @override
  bool get hasFish => true;

  /// ขนาดเฟรมตาม [Swimmer.frame]: ขอบเขตการว่ายคิดจากขนาดเดียวกัน ปลาจึงไม่ล้นบ่อ
  @override
  List<SceneFish> fishAt(int t) {
    swim.advanceTo(t);
    return [
      for (final s in swim.swimmers)
        SceneFish(
          type: s.fish.type,
          x: s.x,
          y: s.drawY(t),
          size: s.frame.roundToDouble(),
          frame: fishFrameAt(t, s.frameStart),
          flipX: s.faceLeft,
        ),
    ];
  }
}

/// ฉากห้องไม้ (ร้าน ตลาด ครัว คลัง รายงาน) — พอร์ตจาก room() ของต้นแบบ
class RoomPainter extends PixelPainter {
  RoomPainter(super.tick);

  @override
  void draw(int t) {
    rect(0, 0, 320, 180, const Color(0xFF8B6546));
    for (var x = 0; x < 320; x += 16) {
      rect(x, 0, 2, 130, const Color(0xFF9B7552));
      rect(x + 8, 0, 1, 130, const Color(0xFF7A5638));
    }
    rect(0, 128, 320, 52, const Color(0xFF5E3B26));
    for (var y = 128; y < 180; y += 10) {
      rect(0, y, 320, 1, const Color(0xFF3D2616));
    }
    for (var x = 0; x < 320; x += 40) {
      rect(x + (x % 80 != 0 ? 0 : 20), 128, 1, 52, const Color(0xFF3D2616));
    }
    rect(0, 126, 320, 4, const Color(0xFF8A5A3A));
    // หน้าต่าง
    rect(212, 28, 70, 56, const Color(0xFF8A5A3A));
    rect(216, 32, 62, 48, const Color(0xFF38BDF8));
    for (var i = 0; i < 9; i++) {
      rect(220 + (i * 17) % 54, 36 + (i * 11) % 40, 1, 1, Colors.white);
    }
    ellipse(262, 48, 5, 5, const Color(0xFFF4EBC8));
    rect(246, 32, 2, 48, const Color(0xFF8A5A3A));
    rect(216, 56, 62, 2, const Color(0xFF8A5A3A));
    // ชั้นวางและโหล
    rect(30, 60, 100, 5, const Color(0xFF8A5A3A));
    rect(30, 100, 100, 5, const Color(0xFF8A5A3A));
    for (final j in const [
      (0xFFD8453A, 34),
      (0xFFE9B949, 52),
      (0xFF5DB857, 70),
      (0xFFF2E2C2, 88),
      (0xFF9BD64B, 106),
    ]) {
      rect(j.$2, 42, 13, 18, const Color(0xFFC9D8EE));
      rect(j.$2 + 1, 46, 11, 13, Color(j.$1));
      rect(j.$2, 40, 13, 3, const Color(0xFFC9985E));
    }
    rect(36, 82, 28, 18, const Color(0xFFC9985E));
    rect(70, 82, 28, 18, const Color(0xFFC9985E));
    rect(104, 86, 20, 14, const Color(0xFFC9985E));
    // โคมไฟ
    rect(160, 0, 2, 34, const Color(0xFF161022));
    final f = t % 23 < 2;
    ellipse(
      161,
      42,
      12,
      12,
      f ? _rgba(233, 185, 73, .2) : _rgba(233, 185, 73, .32),
    );
    rect(155, 34, 12, 16, const Color(0xFFE9B949));
    rect(158, 37, 6, 10, const Color(0xFFFFF3C4));
  }
}

/// วิดเจ็ตฉาก — เดินเฟรมทุก 100ms เหมือนต้นแบบ (ปิดได้ผ่าน sceneAnimationProvider)
class PixelScene extends ConsumerStatefulWidget {
  const PixelScene({
    super.key,
    required this.painterBuilder,
    this.overlay,
    this.cover = false,
    this.alignment = Alignment.center,
    this.framed = true,
    this.backdrop = false,
    this.focus = const Offset(.5, .6),
  });

  final PixelPainter Function(ValueListenable<int> tick) painterBuilder;
  final Widget? overlay;

  /// เต็มพื้นที่ (ครอปขอบ) แทนการคงสัดส่วน 16:9 — ใช้เป็นพื้นหลังหน้าเริ่มเกม
  final bool cover;

  /// จุดที่ให้อยู่กลางภาพเมื่อ cover
  final Alignment alignment;

  /// มีกรอบเข้มรอบฉาก
  final bool framed;

  /// ฉากเต็มจอเป็นพื้นหลังของหน้า (จำนวนเต็มเท่า ไม่เบลอ ไม่มีกรอบ)
  /// จอแนวตั้งต่อท้องฟ้า/พื้นด้านบน-ล่างจากแถวขอบของฉากจนเต็มจอ
  final bool backdrop;

  /// จุดในฉาก (0..1) ที่ให้อยู่กลางจอเมื่อฉากใหญ่กว่าจอ
  final Offset focus;

  @override
  ConsumerState<PixelScene> createState() => _PixelSceneState();
}

class _PixelSceneState extends ConsumerState<PixelScene> {
  final _tick = ValueNotifier<int>(0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (ref.read(sceneAnimationProvider)) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _tick.value++,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = widget.painterBuilder(_tick);
    Widget paint = RepaintBoundary(child: CustomPaint(painter: painter));
    if (widget.backdrop) return _backdrop(painter, paint);
    if (painter.hasFish) {
      paint = Stack(
        fit: StackFit.expand,
        children: [
          paint,
          SceneFishLayer(tick: _tick, fishAt: painter.fishAt),
        ],
      );
    }
    if (widget.cover) {
      paint = ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: widget.alignment,
          child: SizedBox(width: kSceneW, height: kSceneH, child: paint),
        ),
      );
    }
    Widget scene = Stack(
      fit: StackFit.expand,
      children: [paint, ?widget.overlay],
    );
    if (widget.framed) {
      // ภาพฉากมุมมนเข้ากับการ์ด ขอบบางสีอ่อน
      scene = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DsRadius.card),
          border: Border.all(color: DsColors.border, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DsRadius.card),
          child: scene,
        ),
      );
    }
    scene = ExcludeSemantics(child: scene);
    if (widget.cover) return scene;
    // ระบบเลย์เอาต์กลาง: ขยายฉากเป็นจำนวนเต็มเท่าของพิกเซลจริง (คม ไม่เบลอ)
    // ที่เหลือด้านข้างเติมด้วยฉากเดียวกันแบบหรี่ ไม่ใช่แถบดำ
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final ppl = context.rs.physicalPerLogical(
          MediaQuery.devicePixelRatioOf(context),
        );
        final fit = integerSceneSize(
          Size(w, w * kSceneH / kSceneW),
          ppl,
          const Size(kSceneW, kSceneH),
        );
        final inner = SizedBox.fromSize(size: fit, child: scene);
        if (w - fit.width < 1) return inner;
        return SizedBox(
          width: w,
          height: fit.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: kSceneW,
                      height: kSceneH,
                      child: CustomPaint(painter: widget.painterBuilder(_tick)),
                    ),
                  ),
                ),
              ),
              const ColoredBox(color: Color(0x8C0B1A12)),
              Center(child: inner),
            ],
          ),
        );
      },
    );
  }

  Widget _backdrop(PixelPainter painter, Widget paint) {
    if (painter.hasFish) {
      paint = Stack(
        fit: StackFit.expand,
        children: [
          paint,
          SceneFishLayer(tick: _tick, fishAt: painter.fishAt),
        ],
      );
    }
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, box) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final ppl = context.rs.physicalPerLogical(dpr);
          final w = box.maxWidth, h = box.maxHeight;
          final s = integerBackdropSize(
            Size(w, h),
            ppl,
            const Size(kSceneW, kSceneH),
          );
          double snap(double v) => (v * ppl).roundToDouble() / ppl;
          double place(double view, double size, double f) => size <= view
              ? (view - size) / 2
              : (view / 2 - f * size).clamp(view - size, 0).toDouble();
          final left = snap(place(w, s.width, widget.focus.dx));
          final top = snap(place(h, s.height, widget.focus.dy));
          final bottom = top + s.height;
          return ClipRect(
            child: Stack(
              children: [
                if (top > 0)
                  Positioned(
                    left: left,
                    top: 0,
                    width: s.width,
                    height: top + 1,
                    child: CustomPaint(
                      painter: _RowStretchPainter(
                        widget.painterBuilder(_tick),
                        0,
                        s.width,
                      ),
                    ),
                  ),
                if (bottom < h)
                  Positioned(
                    left: left,
                    top: bottom - 1,
                    width: s.width,
                    height: h - bottom + 1,
                    child: CustomPaint(
                      painter: _RowStretchPainter(
                        widget.painterBuilder(_tick),
                        kSceneH.toInt() - 1,
                        s.width,
                      ),
                    ),
                  ),
                Positioned(
                  left: left,
                  top: top,
                  width: s.width,
                  height: s.height,
                  child: paint,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// วาดแถวพิกเซลเดียวของฉาก ([row]) ยืดเต็มกล่อง — ต่อท้องฟ้า/พื้นให้ฉากเต็มจอแนวตั้ง
class _RowStretchPainter extends CustomPainter {
  _RowStretchPainter(this.base, this.row, this.sceneWidth)
    : super(repaint: base.tick);
  final PixelPainter base;
  final int row;
  final double sceneWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(0, -row * size.height);
    base.paint(canvas, Size(sceneWidth, kSceneH * size.height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ปลา 1 ตัวในฉาก (พิกัดฉาก 320x180, จุดกลางเฟรม)
class SceneFish {
  const SceneFish({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.frame,
    required this.flipX,
  });
  final String type;
  final double x, y;

  /// ขนาดเฟรม (พิกเซลฉาก)
  final double size;
  final int frame;

  /// หัวไปทางซ้าย
  final bool flipX;
}

/// ชั้นปลาทับฉากพิกเซล: ใช้ [FishSprite] (ภาพแถบเฟรม) ตามตำแหน่งที่ฉากคำนวณ
/// ตำแหน่งและขนาดปัดเป็นพิกเซลจริงทุกครั้ง ภาพจึงคม
class SceneFishLayer extends StatelessWidget {
  const SceneFishLayer({super.key, required this.tick, required this.fishAt});
  final ValueListenable<int> tick;
  final List<SceneFish> Function(int t) fishAt;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    double snap(double v) => (v * dpr).roundToDouble() / dpr;
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final k = box.maxWidth / kSceneW;
            return ValueListenableBuilder<int>(
              valueListenable: tick,
              builder: (context, t, _) {
                final fish = fishAt(t);
                return Stack(
                  children: [
                    for (var i = 0; i < fish.length; i++)
                      Positioned(
                        key: ValueKey(i),
                        left: snap((fish[i].x - fish[i].size / 2) * k),
                        top: snap((fish[i].y - fish[i].size / 2) * k),
                        child: FishSprite(
                          fish[i].type,
                          size: snap(fish[i].size * k),
                          frame: fish[i].frame,
                          flipX: fish[i].flipX,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
