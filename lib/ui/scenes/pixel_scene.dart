/// ฉากพิกเซล 320x180 — พอร์ตจากฟังก์ชัน farm(), pond(), fx(), spr() ของ reference/index.html
/// วาดด้วยสี่เหลี่ยมล้วน ไม่ใช้ anti-alias (ภาพไม่เบลอ)
///
/// ฉากแบ่งเป็นชั้น: ชั้นที่ไม่ขยับ (ฟ้า ภูเขา พื้น บ้าน) บันทึกเป็นภาพไว้ครั้งเดียว ([PixelPainter.cached])
/// แล้ววาดเฉพาะของที่ขยับทับทุกเฟรม (เมฆ น้ำ ต้นไม้ไหว ฝน ฟ้าแลบ) จึงลื่นบนมือถือ
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
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

/// ผสมชุดสีสองชุด (เช่น ฟ้าใส → ฟ้าพายุ) ตามสัดส่วน [m]
List<Color> _mix(List<int> a, List<int> b, double m) => [
  for (var i = 0; i < a.length; i++) Color.lerp(Color(a[i]), Color(b[i]), m)!,
];

/// เลขสุ่มคงที่จากเลขจำนวนเต็ม (0..1) — ใช้วางของประกอบฉากให้เหมือนเดิมทุกเฟรม
double _hash(int n) {
  final x = math.sin(n * 12.9898 + 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

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

  /// E(x,y,rx,ry,c) วงรีแบบพิกเซล (จุดกลางปัดเป็นพิกเซลเต็ม)
  void ellipse(num x, num y, int rx, int ry, Color c) {
    _p.color = c;
    final cx = _r(x), cy = _r(y);
    if (ry <= 0) {
      _c.drawRect(
        Rect.fromLTWH((cx - rx).toDouble(), cy.toDouble(), 2.0 * rx, 1),
        _p,
      );
      return;
    }
    for (var j = -ry; j <= ry; j++) {
      final d = _r(rx * math.sqrt(1 - (j / ry) * (j / ry)));
      _c.drawRect(
        Rect.fromLTWH((cx - d).toDouble(), (cy + j).toDouble(), 2.0 * d, 1),
        _p,
      );
    }
  }

  /// ลายตารางหมากรุก 1 พิกเซล (ไล่สีแบบพิกเซลอาร์ต) — ใช้ในชั้นที่บันทึกไว้แล้วเท่านั้น
  void dither(int x, int y, int w, int h, Color c) {
    _p.color = c;
    for (var j = 0; j < h; j++) {
      for (var i = (x + y + j) % 2; i < w; i += 2) {
        _c.drawRect(
          Rect.fromLTWH((x + i).toDouble(), (y + j).toDouble(), 1, 1),
          _p,
        );
      }
    }
  }

  /// แถบสีไล่ระดับเป็นขั้น + แถวไล่สีรอยต่อ ([top] ถึง [top] + ความสูงทุกแถบ)
  void bands(List<Color> colors, int top, int bandH, {int x = 0, int w = 320}) {
    for (var i = 0; i < colors.length; i++) {
      rect(x, top + i * bandH, w, bandH, colors[i]);
    }
    for (var i = 1; i < colors.length; i++) {
      dither(x, top + i * bandH - 1, w, 1, colors[i]);
      dither(x, top + i * bandH, w, 1, colors[i - 1]);
      dither(x, top + i * bandH + 1, w, 1, colors[i - 1]);
    }
  }

  static final Map<String, ui.Picture> _cache = {};

  /// ชั้นที่ไม่ขยับ: วาดครั้งแรกแล้วเก็บเป็นภาพ เฟรมต่อไปแค่วางภาพเดิม
  void cached(String key, void Function() body) {
    var pic = _cache[key];
    if (pic == null) {
      final rec = ui.PictureRecorder();
      final saved = _c;
      _c = Canvas(rec);
      body();
      _c = saved;
      pic = rec.endRecording();
      if (_cache.length >= 24) _cache.remove(_cache.keys.first);
      _cache[key] = pic;
    }
    _c.drawPicture(pic);
  }

  void draw(int t);

  /// ชั้นหน้าสุด วาดทับปลา (เช่น ต้นไม้น้ำด้านหน้า) — ดู [hasFront]
  void drawFront(int t) {}
  bool get hasFront => false;

  /// ปลาที่ต้องวาดทับฉาก (ใช้ภาพแถบเฟรมปลาชุดใหม่ ดู [SceneFishLayer])
  bool get hasFish => false;

  /// [t] = เฟรมของฉาก มีเศษได้ (เกลี่ยตำแหน่งระหว่างเฟรมให้ปลาว่ายลื่น)
  List<SceneFish> fishAt(double t) => const [];

  void _run(Canvas canvas, Size size, void Function(int t) body) {
    _c = canvas;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / kSceneW, size.height / kSceneH);
    body(tick.value);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) => _run(canvas, size, draw);

  void paintFront(Canvas canvas, Size size) => _run(canvas, size, drawFront);

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
    this.power = true,
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
      power: s.power,
    );
  }

  final List<String> pond;
  final Map<String, int> equipment;
  final bool damaged;
  final DisasterType? fxType;
  final double fxLevel;

  /// ไฟฟ้าใช้ได้ (ไฟดับ = หน้าต่างบ้านมืด)
  final bool power;
}

// ชุดสีท้องฟ้า (บนสุด → ขอบฟ้า) ตามสภาพอากาศ
const _skyDay = [
  0xFF2F8CE4, 0xFF3F9DEA, 0xFF55AEEF, 0xFF6EBFF2, //
  0xFF8ACEF4, 0xFFA8DCF5, 0xFFC5E8F3, 0xFFDDF1EC,
];
const _skyStorm = [
  0xFF12142E, 0xFF1A1D40, 0xFF232853, 0xFF2D3464, //
  0xFF374073, 0xFF434D80, 0xFF505A89, 0xFF5D678D,
];
const _skyDrought = [
  0xFFD27A2A, 0xFFDA8A35, 0xFFE09B44, 0xFFE6AB56, //
  0xFFEBBB6A, 0xFFEFC981, 0xFFF2D597, 0xFFF4DFAC,
];
const _skyHeat = [
  0xFFDB5E36, 0xFFE2703D, 0xFFE88347, 0xFFEC9654, //
  0xFFF0A863, 0xFFF3B977, 0xFFF5C98E, 0xFFF6D7A5,
];
const _skyPoll = [
  0xFF66775A, 0xFF718260, 0xFF7C8D67, 0xFF889770, //
  0xFF93A17A, 0xFF9EAB85, 0xFFA8B491, 0xFFB2BC9D,
];

class FarmPainter extends PixelPainter {
  FarmPainter(super.tick, this.data);

  @override
  bool get hasFish => data.pond.isNotEmpty;

  /// ปลาในบ่อเล็กของฟาร์ม (สูงสุด 8 ตัว): ว่ายไป-กลับเป็นโค้ง ชะลอและหมุนตัวตอนกลับทาง
  /// ความเร็วต่างกันตามชนิด หันหัวตามทิศที่ว่าย
  @override
  List<SceneFish> fishAt(double t) {
    final pond = data.pond.take(8).toList();
    return [for (var i = 0; i < pond.length; i++) _pondFish(pond[i], i, t)];
  }

  SceneFish _pondFish(String type, int i, double t) {
    final w = .03 * (1 + (i % 3) * .22) * (kSwimSpeedOf[type] ?? 1);
    final a = w * t + i * 1.9;
    final vx = math.cos(a);
    return SceneFish(
      type: type,
      x: 240 + 33 * math.sin(a) + 2 * math.sin(t * .05 + i),
      y: 131 + (i % 4) * 5.5 + 1.2 * math.sin(t * .2 + i),
      size: 16,
      frame: (i * 3 + (t * (.45 + .6 * vx.abs())).floor()) % kFishFrames,
      flipX: vx < 0,
      scaleX: (vx.abs() * 2.6).clamp(.3, 1).toDouble(),
    );
  }

  final FarmSceneData data;

  int q(String k) => data.equipment[k] ?? 0;

  /// สัดส่วนสภาพอากาศเลวร้าย 0..1 (ปัด 0.1 เพื่อใช้ชั้นภาพที่บันทึกไว้ซ้ำได้)
  late final double mix = () {
    final l = data.fxType == null ? 0.0 : data.fxLevel;
    final k = data.fxType == DisasterType.poll ? .9 : 1.6;
    return ((l * k).clamp(0, 1) * 10).round() / 10;
  }();

  bool get storm => data.fxType == DisasterType.flood && mix > 0;

  List<Color> get _skyColors => _mix(_skyDay, switch (data.fxType) {
    DisasterType.flood || null => _skyStorm,
    DisasterType.drought => _skyDrought,
    DisasterType.heat => _skyHeat,
    DisasterType.poll => _skyPoll,
  }, mix);

  String get _wx => '${data.fxType?.name}_$mix';

  // ---------- ท้องฟ้า ----------

  void sun(int t) {
    final dim = data.fxType == null || data.fxType == DisasterType.heat
        ? 0.0
        : mix;
    if (dim >= 1) return;
    final a = 1 - dim;
    final pulse = math.sin(t / 9) > 0 ? 1 : 0;
    ellipse(262, 24, 17 + pulse, 17 + pulse, _rgba(255, 236, 160, .16 * a));
    ellipse(262, 24, 13, 13, _rgba(255, 236, 160, .28 * a));
    ellipse(262, 24, 10, 10, _rgba(255, 226, 120, a));
    ellipse(262, 24, 7, 7, _rgba(255, 246, 200, a));
    rect(258, 20, 3, 2, _rgba(255, 255, 240, a));
  }

  void cloud(num x, num y, int s, Color c, Color shade, Color light) {
    ellipse(x, y + 1, 4 * s, s + 1, shade);
    ellipse(x - 2 * s, y, 2 * s + 1, s + 1, c);
    ellipse(x + s, y - s, 2 * s, s + 1, c);
    ellipse(x + 3 * s, y, 2 * s, s, c);
    ellipse(x, y, 3 * s, s, c);
    ellipse(x + s - 1, y - s - 1, s + 2, 1, light);
  }

  void clouds(int t) {
    final m = storm ? mix : mix * .5;
    final far = Color.lerp(
      const Color(0xFFEAF6FC),
      const Color(0xFF454A68),
      m,
    )!;
    final farShade = Color.lerp(
      const Color(0xFFC8E2F0),
      const Color(0xFF34385A),
      m,
    )!;
    // ชั้นไกล: ก้อนเล็ก เลื่อนช้า
    for (var i = 0; i < 5; i++) {
      final x = ((t * .05 + i * 71) % 380) - 30;
      cloud(x, 30 + (i * 7) % 12, 2, far, farShade, far);
    }
    final near = Color.lerp(Colors.white, const Color(0xFF3D4160), m)!;
    final nearShade = Color.lerp(
      const Color(0xFFD5E9F4),
      const Color(0xFF2B2E48),
      m,
    )!;
    final light = Color.lerp(Colors.white, const Color(0xFF5A5F80), m)!;
    // ชั้นใกล้: ก้อนใหญ่ เลื่อนเร็วกว่า (พายุ: มากขึ้นและใหญ่ขึ้น)
    final n = storm ? 4 + (mix * 4).round() : 3;
    for (var i = 0; i < n; i++) {
      final x = ((t * (storm ? .3 : .14) + i * 400 / n) % 420) - 50;
      cloud(
        x,
        14 + (i * 11) % 18,
        storm ? 4 + i % 2 : 3 + i % 2,
        near,
        nearShade,
        light,
      );
    }
  }

  void birds(int t) {
    if (mix > .4) return;
    for (var i = 0; i < 3; i++) {
      final x = ((t * .45 + i * 23) % 400) - 40, y = 40 + i * 4;
      final up = (t + i * 3) % 6 < 3;
      const c = Color(0xFF2B3A4A);
      rect(x - 2, y + (up ? -1 : 0), 2, 1, c);
      rect(x, y, 1, 1, c);
      rect(x + 1, y + (up ? -1 : 0), 2, 1, c);
    }
  }

  // ---------- ฉากไกล: ภูเขา นาข้าว แม่น้ำ ----------

  void farLayer() {
    final m = storm ? mix : mix * .5;
    final c1 = Color.lerp(const Color(0xFF86AECF), const Color(0xFF353F68), m)!;
    final c1l = Color.lerp(
      const Color(0xFFA7C6DE),
      const Color(0xFF465282),
      m,
    )!;
    final c2 = Color.lerp(const Color(0xFF4F8E70), const Color(0xFF22344A), m)!;
    final c2d = Color.lerp(
      const Color(0xFF3E7A5E),
      const Color(0xFF1A2A3E),
      m,
    )!;
    final c2l = Color.lerp(
      const Color(0xFF6AA884),
      const Color(0xFF2E4660),
      m,
    )!;
    for (var x = 0; x < 320; x += 2) {
      final y1 = _r(
        46 +
            9 * math.sin(x / 37) +
            5 * math.sin(x / 13 + 1) +
            2 * math.sin(x / 5),
      );
      rect(x, y1, 2, 80 - y1, c1);
      rect(x, y1, 2, 1, c1l);
    }
    for (var x = 0; x < 320; x += 2) {
      final y2 = _r(58 + 6 * math.sin(x / 29 + 2) + 4 * math.sin(x / 11));
      rect(x, y2, 2, 80 - y2, c2);
      rect(x, y2, 2, 1, c2l);
      if (_hash(x) < .35) rect(x, y2 + 3 + _r(_hash(x + 7) * 8), 2, 2, c2d);
    }
    // นาข้าวและแนวต้นไม้
    final g1 = Color.lerp(const Color(0xFF7DB548), const Color(0xFF3B5A3A), m)!;
    final g2 = Color.lerp(const Color(0xFF94C65A), const Color(0xFF486A44), m)!;
    final w1 = Color.lerp(const Color(0xFF9FD3E6), const Color(0xFF4E6A88), m)!;
    rect(0, 70, 320, 16, g1);
    for (var y = 72; y < 84; y += 3) {
      rect(0, y, 320, 1, g2);
    }
    for (var i = 0; i < 6; i++) {
      final x = 180 + i * 22 + (i % 2) * 5;
      rect(x, 73 + (i % 3) * 3, 14, 1, w1);
    }
    final t1 = Color.lerp(const Color(0xFF2E6E3E), const Color(0xFF1A3328), m)!;
    final t2 = Color.lerp(const Color(0xFF3F8A4A), const Color(0xFF243F30), m)!;
    for (var x = 0; x < 320; x += 4) {
      final h = _r(4 + 7 * _hash(x ~/ 4) * (math.sin(x / 21).abs() + .3));
      rect(x, 76 - h, 4, h + 2, t1);
      rect(x + 1, 76 - h, 2, 1, t2);
    }
    // แม่น้ำ
    final r1 = Color.lerp(const Color(0xFF1C7AA6), const Color(0xFF23415F), m)!;
    final r2 = Color.lerp(const Color(0xFF3399C4), const Color(0xFF2E5274), m)!;
    rect(0, 84, 320, 11, r1);
    rect(0, 84, 320, 2, r2);
    dither(0, 86, 320, 1, r2);
  }

  void riverShimmer(int t) {
    for (var x = 0; x < 320; x += 7) {
      rect(
        (x + t * .6) % 320,
        87 + ((x ~/ 7) % 3) * 3,
        4,
        1,
        storm ? const Color(0xFF6E8FB0) : const Color(0xFF8FD8F2),
      );
    }
  }

  // ---------- ฉากใกล้ (ไม่ขยับ) ----------

  void ground() {
    rect(0, 94, 320, 3, const Color(0xFF7A5634));
    for (var x = 0; x < 320; x += 3) {
      rect(x, 93 + (_hash(x) < .5 ? 0 : 1), 2, 1, const Color(0xFF6AA83A));
    }
    rect(0, 97, 320, 83, const Color(0xFF5FA42E));
    rect(0, 97, 320, 6, const Color(0xFF57982B));
    dither(0, 103, 320, 2, const Color(0xFF57982B));
    // ลายหญ้า (ไม่วาดแถวล่างสุด เพราะแถวนั้นถูกยืดเติมจอ)
    for (var i = 0; i < 420; i++) {
      final x = (i * 37 + (i ~/ 9) * 5) % 320, y = 100 + (i * 13) % 78;
      rect(
        x,
        y,
        1,
        2,
        i.isOdd ? const Color(0xFF7CC23A) : const Color(0xFF4C8A24),
      );
    }
    for (var i = 0; i < 60; i++) {
      final x = (i * 53) % 316, y = 104 + (i * 29) % 72;
      rect(x, y, 1, 1, const Color(0xFF9AD65A));
      rect(x + 2, y + 1, 1, 1, const Color(0xFF9AD65A));
    }
  }

  void path() {
    const p = Color(0xFFCBA672), e = Color(0xFFA98352), s = Color(0xFFE0C08E);
    rect(107, 131, 24, 49, e);
    rect(108, 131, 22, 49, p);
    rect(103, 149, 98, 13, e);
    rect(104, 150, 96, 11, p);
    for (var i = 0; i < 44; i++) {
      final x = 106 + (i * 17) % 92, y = 132 + (i * 7) % 46;
      if (x > 130 && y > 160) continue;
      rect(x, y, 2, 1, i.isOdd ? e : s);
    }
    // แผ่นหินทางเดิน
    for (var i = 0; i < 5; i++) {
      rect(112 + (i % 2) * 6, 135 + i * 8, 7, 4, const Color(0xFFB9B2A0));
      rect(112 + (i % 2) * 6, 138 + i * 8, 7, 1, const Color(0xFF8E887A));
    }
  }

  void crate(int x, int y, int w, int h) {
    rect(x, y, w, h, const Color(0xFF7A4E2A));
    rect(x + 1, y + 1, w - 2, h - 2, const Color(0xFFC9935A));
    for (var j = y + 3; j < y + h - 1; j += 3) {
      rect(x + 1, j, w - 2, 1, const Color(0xFFA9763F));
    }
    rect(x + 1, y + 1, w - 2, 1, const Color(0xFFE2B27A));
  }

  void house() {
    // เงาบ้าน
    ellipse(118, 131, 40, 4, _rgba(30, 70, 20, .35));
    // ผนังไม้ซุงกรอบไม้ (สีครีม)
    rect(86, 100, 64, 28, const Color(0xFFF0DAA8));
    for (var y = 104; y < 127; y += 5) {
      rect(86, y, 64, 1, const Color(0xFFDDC08A));
    }
    for (final x in const [86, 109, 127, 148]) {
      rect(x, 100, 2, 28, const Color(0xFF7A4A2A));
    }
    rect(86, 100, 64, 2, const Color(0xFF5E3820));
    rect(86, 126, 64, 2, const Color(0xFF5E3820));
    // ประตูและกันสาด
    rect(112, 107, 13, 21, const Color(0xFF5A3420));
    rect(113, 108, 11, 20, const Color(0xFF7E4C2A));
    rect(114, 110, 4, 7, const Color(0xFF6A3E22));
    rect(119, 110, 4, 7, const Color(0xFF6A3E22));
    rect(114, 119, 4, 7, const Color(0xFF6A3E22));
    rect(119, 119, 4, 7, const Color(0xFF6A3E22));
    rect(121, 117, 2, 2, const Color(0xFFE9B949));
    rect(109, 103, 19, 3, const Color(0xFF9A3520));
    rect(109, 105, 19, 1, const Color(0xFF5A2A1A));
    // กระบะดอกไม้ใต้หน้าต่าง
    for (final wx in const [91, 131]) {
      rect(wx, 118, 16, 3, const Color(0xFF7A4A2A));
      for (var i = 0; i < 7; i++) {
        rect(
          wx + 1 + i * 2,
          116 + (i % 2),
          2,
          2,
          const [Color(0xFFE2463A), Color(0xFFF29BC0), Color(0xFFFFD84A)][i %
              3],
        );
      }
      rect(wx + 1, 118, 14, 1, const Color(0xFF3E8A3A));
    }
    // หลังคากระเบื้องแดงทรงปั้นหยา
    for (var i = 0; i < 22; i++) {
      final y = 99 - i;
      final hw = _r(39 - i * 1.05);
      final x0 = 118 - hw;
      final line = i % 4 == 0;
      rect(
        x0,
        y,
        2 * hw,
        1,
        line
            ? const Color(0xFF8E2C1E)
            : i >= 18
            ? const Color(0xFFDC6446)
            : const Color(0xFFC5482F),
      );
      if (!line) {
        for (var x = x0 + 2 + ((i ~/ 4) % 2) * 3; x < x0 + 2 * hw - 2; x += 6) {
          rect(x, y, 1, 1, const Color(0xFFA23822));
        }
      }
      rect(x0 + 2 * hw - 5, y, 5, 1, const Color(0x55601A10));
      rect(x0, y, 1, 1, const Color(0xFFE8805E));
    }
    rect(100, 77, 36, 2, const Color(0xFF7A2418));
    rect(78, 100, 80, 2, const Color(0xFF4E2A18));
    // ปล่องไฟหิน
    rect(133, 70, 11, 3, const Color(0xFF4E4E58));
    rect(134, 73, 9, 16, const Color(0xFF8E8C96));
    for (var y = 75; y < 89; y += 3) {
      rect(134 + (y % 2) * 3, y, 4, 1, const Color(0xFF6E6C78));
    }
    rect(141, 73, 2, 16, const Color(0xFF6E6C78));
    // ระเบียงหน้าบ้าน
    rect(82, 127, 72, 4, const Color(0xFF9A6A3A));
    for (var x = 84; x < 154; x += 6) {
      rect(x, 127, 1, 4, const Color(0xFF7A4E2A));
    }
    rect(82, 127, 72, 1, const Color(0xFFB98A55));
    rect(110, 131, 17, 2, const Color(0xFF8A5A30));
    // พุ่มไม้ข้างบ้าน
    ellipse(83, 126, 6, 4, const Color(0xFF256B37));
    ellipse(82, 124, 4, 2, const Color(0xFF3E9A45));
  }

  void stall() {
    for (final x in const [166, 194]) {
      rect(x, 100, 2, 28, const Color(0xFF5E3B26));
    }
    rect(164, 98, 34, 2, const Color(0xFF0B5F6B));
    for (var i = 0; i < 8; i++) {
      final c = i.isOdd ? const Color(0xFFF4EBD8) : const Color(0xFF14889A);
      rect(165 + i * 4, 100, 4, 8, c);
      rect(166 + i * 4, 108, 2, 2, c);
    }
    rect(165, 100, 32, 1, const Color(0xFF9ADCE4));
    // ตะกร้าผักผลไม้บนแผง
    for (final g in const [
      (0xFFD8453A, 169),
      (0xFF9BD64B, 175),
      (0xFFE9B949, 181),
      (0xFFF6F0E0, 187),
    ]) {
      rect(g.$2, 113, 5, 3, Color(g.$1));
      rect(g.$2 + 1, 112, 3, 1, Color(g.$1));
      rect(g.$2, 115, 5, 2, const Color(0xFF9A6A3A));
    }
    rect(166, 117, 32, 2, const Color(0xFF8A5A30));
    rect(168, 119, 28, 9, const Color(0xFFB57A42));
    for (var x = 172; x < 196; x += 6) {
      rect(x, 119, 1, 9, const Color(0xFF8A5A30));
    }
  }

  void stove() {
    rect(150, 116, 15, 2, const Color(0xFF7A4226));
    rect(151, 118, 13, 10, const Color(0xFF9C5B36));
    rect(151, 118, 2, 10, const Color(0xFFB87048));
    rect(154, 122, 7, 5, const Color(0xFF2A1A12));
    rect(152, 110, 11, 6, const Color(0xFF3A3A48));
    rect(151, 110, 13, 1, const Color(0xFF6A6A7A));
    rect(153, 111, 2, 4, const Color(0xFF55556A));
  }

  void post(int x, int y) {
    rect(x, y, 3, 12, const Color(0xFFB57E46));
    rect(x, y, 3, 1, const Color(0xFFDDA668));
    rect(x + 2, y + 1, 1, 11, const Color(0xFF8A5A30));
  }

  void rail(int x, int y, int w) {
    rect(x, y, w, 2, const Color(0xFFC8925A));
    rect(x, y + 2, w, 1, const Color(0xFF8A5A30));
  }

  void fences() {
    rail(56, 163, 47);
    rail(56, 168, 47);
    for (var x = 56; x <= 100; x += 8) {
      post(x, 160);
    }
    rail(140, 169, 47);
    rail(140, 174, 47);
    for (var x = 140; x <= 184; x += 8) {
      post(x, 166);
    }
  }

  void pondBase() {
    // ขอบหินรอบบ่อ
    ellipse(240, 142, 65, 27, _rgba(30, 60, 20, .35));
    ellipse(240, 141, 64, 26, const Color(0xFF5E5A52));
    ellipse(240, 141, 62, 24, const Color(0xFF8E897D));
    for (var k = 0; k < 56; k++) {
      final a = k / 56 * 2 * math.pi;
      final x = 240 + 61 * math.cos(a), y = 141 + 23.5 * math.sin(a);
      rect(
        x - 2,
        y - 1,
        4,
        3,
        k.isOdd ? const Color(0xFFB9B3A4) : const Color(0xFFA29C8E),
      );
      rect(x - 2, y + 1, 4, 1, const Color(0xFF6E6A60));
    }
    // น้ำ: ขอบลึก → กลางสว่าง
    ellipse(240, 141, 57, 21, const Color(0xFF1C6F9E));
    ellipse(240, 140, 54, 18, const Color(0xFF2A8DBE));
    ellipse(240, 139, 47, 14, const Color(0xFF39A2CF));
    ellipse(240, 138, 38, 9, const Color(0xFF45AED8));
    ellipse(226, 128, 24, 2, _rgba(255, 255, 255, .16));
  }

  void vegBed() {
    rect(272, 165, 46, 14, const Color(0xFF8A5A3A));
    rect(273, 166, 44, 12, const Color(0xFF5E3B26));
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 7; i++) {
        final x = 277 + i * 6 + r * 3, y = 169 + r * 5;
        ellipse(x, y, 3, 2, const Color(0xFF2F7D3A));
        ellipse(x, y - 1, 2, 1, const Color(0xFF5DB857));
        rect(x - 1, y - 2, 1, 1, const Color(0xFF9BD64B));
      }
    }
  }

  void dock() {
    rect(185, 135, 20, 12, const Color(0xFF5E3B26));
    rect(186, 136, 18, 10, const Color(0xFF9A6A3A));
    for (var i = 0; i < 5; i++) {
      rect(187 + i * 4, 136, 1, 10, const Color(0xFF6B4226));
    }
    rect(186, 136, 18, 1, const Color(0xFFC08A55));
    rect(186, 146, 2, 3, const Color(0xFF4E2E1A));
    rect(202, 146, 2, 3, const Color(0xFF4E2E1A));
  }

  void flowers() {
    const spots = [
      (70, 140), (88, 150), (160, 134), (60, 176), (196, 172), //
      (150, 152), (34, 130), (44, 148), (230, 172), (250, 104),
    ];
    const fc = [
      Color(0xFFFFD84A),
      Colors.white,
      Color(0xFFF29BC0),
      Color(0xFFE2463A),
    ];
    for (var i = 0; i < spots.length; i++) {
      final (x, y) = spots[i];
      rect(x, y + 2, 1, 3, const Color(0xFF2F7D3A));
      rect(x - 1, y, 3, 2, fc[i % 4]);
      rect(x, y, 1, 1, const Color(0xFFFFF3B0));
    }
  }

  void nearLayer() {
    ground();
    path();
    crate(56, 120, 12, 10);
    crate(68, 123, 12, 9);
    crate(59, 112, 11, 9);
    house();
    stall();
    stove();
    pondBase();
    dock();
    vegBed();
    flowers();
    fences();
  }

  // ---------- ของที่ขยับ ----------

  void lushTree(int t, int x, int y) {
    final w = _r(math.sin(t / 14 + x) * 1.2);
    ellipse(x + 2, y, 13, 3, _rgba(20, 60, 20, .35));
    rect(x - 2, y - 14, 5, 14, const Color(0xFF6B4226));
    rect(x + 1, y - 14, 2, 14, const Color(0xFF4E2E1A));
    rect(x - 4, y - 1, 9, 1, const Color(0xFF4E2E1A));
    ellipse(x + w, y - 24, 15, 12, const Color(0xFF1E5631));
    ellipse(x - 8 + w, y - 17, 9, 7, const Color(0xFF235F35));
    ellipse(x + 8 + w, y - 18, 9, 7, const Color(0xFF235F35));
    ellipse(x - 3 + w, y - 27, 11, 8, const Color(0xFF2E8540));
    ellipse(x + 6 + w, y - 22, 7, 5, const Color(0xFF2E8540));
    ellipse(x - 6 + w, y - 30, 6, 4, const Color(0xFF4FA845));
    ellipse(x + 2 + w, y - 32, 5, 3, const Color(0xFF6CC052));
    rect(x - 7 + w, y - 32, 3, 1, const Color(0xFF9ADB6A));
    for (var i = 0; i < 6; i++) {
      rect(
        x - 10 + w + (i * 7) % 20,
        y - 20 + (i * 5) % 9,
        2,
        1,
        const Color(0xFF184A2A),
      );
    }
  }

  void leaf(
    num x0,
    num y0,
    double a,
    int len,
    double droop,
    Color c,
    Color rib,
  ) {
    for (var k = 2; k < len; k++) {
      final x = x0 + math.cos(a) * k, y = y0 + math.sin(a) * k + droop * k * k;
      final wd = _r(2.6 * math.sin(math.pi * k / len));
      rect(x, y - wd, 1, 2 * wd + 1, c);
      rect(x, y, 1, 1, rib);
    }
  }

  void papaya(int t) {
    const x = 306, top = 66;
    rect(x - 1, top, 3, 100 - top, const Color(0xFF9C8C6C));
    for (var y = top + 3; y < 100; y += 4) {
      rect(x - 1, y, 3, 1, const Color(0xFF7E6E52));
    }
    ellipse(x + 1, 100, 6, 2, _rgba(20, 60, 20, .3));
    final s = .06 * math.sin(t / 11);
    for (var i = 0; i < 7; i++) {
      final a = -math.pi + .25 + i * (math.pi - .5) / 6 + s;
      leaf(
        x,
        top,
        a,
        15,
        .03,
        i.isOdd ? const Color(0xFF3E9A45) : const Color(0xFF2E7D3A),
        const Color(0xFF8FD06A),
      );
    }
    for (final f in const [
      (-3, 4, 0xFFE9A23B),
      (2, 5, 0xFF9BC43E),
      (-1, 8, 0xFFF0B84A),
    ]) {
      ellipse(x + f.$1, top + f.$2, 2, 3, Color(f.$3));
    }
  }

  void banana(int t) {
    const x = 18, top = 142;
    rect(x - 2, top, 5, 38, const Color(0xFF7FA34A));
    rect(x + 1, top, 2, 38, const Color(0xFF5E8034));
    for (var i = 0; i < 5; i++) {
      final a = -math.pi * (.15 + i * .17) + .07 * math.sin(t / 12 + i);
      leaf(
        x,
        top,
        a,
        22 - (i % 2) * 4,
        .028,
        i.isOdd ? const Color(0xFF4FAE3E) : const Color(0xFF3A9233),
        const Color(0xFFB4E27A),
      );
    }
  }

  void tufts(int t) {
    for (var i = 0; i < 22; i++) {
      final x = (i * 61 + 13) % 316, y = 104 + (i * 23) % 70;
      if (x > 100 && x < 205 && y < 132) continue; // หลังบ้าน/ร้าน
      if ((x - 240).abs() < 66 && (y - 141).abs() < 28) continue; // บ่อ
      final sw = math.sin(t / 8 + i) > .3 ? 1 : 0;
      rect(x, y, 1, 3, const Color(0xFF3E8A2A));
      rect(x + 1 + sw, y - 2, 1, 4, const Color(0xFF7CC23A));
      rect(x + 3, y, 1, 3, const Color(0xFF4C9A2E));
    }
  }

  void butterflies(int t) {
    if (mix > .3) return;
    for (var i = 0; i < 2; i++) {
      final cx = i == 0 ? 78 : 168, cy = i == 0 ? 146 : 152;
      final x = cx + 14 * math.sin(t / 23 + i * 2),
          y = cy + 6 * math.sin(t / 11 + i);
      final c = i == 0 ? const Color(0xFFFFE17A) : const Color(0xFFF7F2FF);
      if ((t + i) % 4 < 2) {
        rect(x - 2, y, 2, 2, c);
        rect(x + 1, y, 2, 2, c);
      } else {
        rect(x - 1, y - 1, 1, 2, c);
        rect(x + 1, y - 1, 1, 2, c);
      }
      rect(x, y, 1, 2, const Color(0xFF3A2A1A));
    }
  }

  void fallingLeaves(int t) {
    for (var i = 0; i < 2; i++) {
      final k = (t * .35 + i * 37) % 60;
      rect(
        30 + 8 * math.sin(t / 9 + i) + k * .4,
        96 + k * .6,
        2,
        1,
        i == 0 ? const Color(0xFF9ADB6A) : const Color(0xFFE0B24A),
      );
    }
  }

  void pondLife(int t) {
    // แสงระยิบบนผิวน้ำ
    for (var i = 0; i < 5; i++) {
      rect(
        200 + ((t * .5 + i * 27) % 76),
        128 + i * 5,
        6,
        1,
        const Color(0xFFA5E4F7),
      );
    }
    for (var i = 0; i < 3; i++) {
      final cyc = (t + i * 9) % 26;
      if (cyc < 4) {
        final n = (t + i * 9) ~/ 26 * 3 + i;
        final x = 205 + _hash(n) * 70, y = 128 + _hash(n + 50) * 22;
        rect(x - 1, y, 3, 1, Colors.white);
        if (cyc < 2) rect(x, y - 1, 1, 3, Colors.white);
      }
    }
    // ใบบัว (ลอยขึ้นลงเล็กน้อย)
    const pads = [
      (197, 141, true),
      (284, 139, false),
      (229, 157, false),
      (252, 124, true),
      (276, 152, false),
    ];
    for (var i = 0; i < pads.length; i++) {
      final (x, y, flower) = pads[i];
      final b = math.sin(t / 13 + i) > .6 ? 1 : 0;
      ellipse(x, y + b, 5, 2, const Color(0xFF2E7D32));
      ellipse(x, y - 1 + b, 4, 1, const Color(0xFF55B24A));
      rect(x + 1, y - 2 + b, 2, 2, const Color(0xFF2A8DBE));
      if (flower) {
        rect(x - 2, y - 3 + b, 3, 2, const Color(0xFFF29BC0));
        rect(x - 1, y - 4 + b, 1, 1, const Color(0xFFFFD0E2));
        rect(x - 1, y - 3 + b, 1, 1, const Color(0xFFFFE17A));
      }
    }
    // วงน้ำกระเพื่อม
    final rc = t % 40;
    if (rc < 12) {
      final rx = 3 + rc ~/ 2;
      final x = 222 + _hash(t ~/ 40) * 36;
      final c = _rgba(200, 240, 255, .5 - rc / 26);
      rect(x - rx, 145, 2 * rx, 1, c);
      rect(x - rx + 2, 143, 2 * rx - 4, 1, c);
    }
  }

  void stoveFire(int t) {
    final f = (t % 5) < 2;
    rect(155, 123, 5, 4, f ? const Color(0xFFFFB13B) : const Color(0xFFE8642A));
    rect(156, 124, 3, 2, const Color(0xFFFFE17A));
    rect(
      156 + math.sin(t / 5) * 3,
      107 - ((t * .7) % 14),
      2,
      2,
      _rgba(240, 235, 255, .6),
    );
  }

  void smoke(int t) {
    for (var i = 0; i < 4; i++) {
      final y = 67 - ((t * .5 + i * 9) % 32);
      rect(
        137 + math.sin((t + i * 11) / 8) * 4,
        y,
        3 + i,
        3 + i,
        _rgba(220, 215, 235, .55 - ((67 - y) / 60)),
      );
    }
  }

  void windows(int t) {
    final dark = storm ? mix : 0.0;
    for (final wx in const [92, 131]) {
      if (data.power) {
        ellipse(wx + 7, 110, 12, 9, _rgba(255, 210, 110, .06 + .22 * dark));
      }
      rect(wx - 1, 104, 16, 13, const Color(0xFF5A3A22));
      if (data.power) {
        final dim = (t + wx) % 53 < 2;
        rect(
          wx,
          105,
          14,
          11,
          dim ? const Color(0xFFF0BE52) : const Color(0xFFFFCF5E),
        );
        rect(wx + 1, 106, 5, 4, const Color(0xFFFFEDA6));
        rect(wx + 6, 105, 2, 11, const Color(0xFFB5802A));
        rect(wx, 110, 14, 1, const Color(0xFFB5802A));
      } else {
        rect(wx, 105, 14, 11, const Color(0xFF243049));
        rect(wx + 2, 106, 2, 4, const Color(0xFF3E4C72));
        rect(wx + 6, 105, 2, 11, const Color(0xFF3A2818));
        rect(wx, 110, 14, 1, const Color(0xFF3A2818));
      }
    }
  }

  void equipment(int t) {
    for (var i = 0; i < math.min(q('sand'), 8); i++) {
      final x = 86 + i * 8, y = 132 + (i % 2) * 3;
      rect(x, y, 8, 5, const Color(0xFFD2A86A));
      rect(x, y, 8, 1, const Color(0xFFE6C48E));
      rect(x, y + 4, 8, 1, const Color(0xFF6B4226));
    }
    if (q('pump') > 0) {
      rect(136, 134, 12, 9, const Color(0xFF8F86A8));
      rect(136, 134, 12, 1, const Color(0xFFB5ADCC));
      rect(140, 130, 4, 5, const Color(0xFF4B4A5C));
      rect(133, 138, 4, 2, const Color(0xFF3E7CB8));
    }
    if (q('tank') > 0) {
      rect(200, 150, 12, 16, const Color(0xFF3E7CB8));
      rect(200, 150, 12, 3, const Color(0xFFA5DDF5));
      rect(202, 153, 2, 11, const Color(0xFF6AA6DA));
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
      rect(206, 101, 40, 1, const Color(0xFF0A5568));
      rect(208, 101, 2, 12, const Color(0xFF5E3B26));
      rect(242, 101, 2, 12, const Color(0xFF5E3B26));
    }
    if (q('air') > 0) {
      for (var i = 0; i < 4; i++) {
        rect(
          232 + i * 3 + _r(math.sin((t + i * 5) / 3)),
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
  }

  // ---------- ภัยพิบัติ ----------

  void lightning(int t, double l) {
    if (!storm || l < .2) return;
    final cyc = t % 61;
    if (cyc >= 4) return;
    final n = t ~/ 61;
    var x = 30 + _hash(n) * 200;
    var y = 14.0;
    final glow = _rgba(180, 170, 255, cyc < 2 ? .5 : .25);
    final core = cyc < 2 ? const Color(0xFFF6F2FF) : const Color(0xFFC8C0F0);
    var k = 0;
    while (y < 64) {
      final nx = x + (_hash(n * 7 + k) - .5) * 10;
      final steps = 6;
      for (var s = 0; s < steps; s++) {
        final px = x + (nx - x) * s / steps;
        rect(px - 1, y + s, 4, 1, glow);
        rect(px, y + s, 2, 1, core);
      }
      if (k == 2) {
        // กิ่งฟ้าแลบ
        for (var s = 0; s < 8; s++) {
          rect(nx + s, y + 6 + s, 1, 1, core);
        }
      }
      x = nx;
      y += steps;
      k++;
    }
  }

  void rain(int t, double l) {
    final far = _r(60 * l), near = _r(80 * l);
    for (var i = 0; i < far; i++) {
      final x = (_hash(i) * 330 + t * 2) % 330 - 5,
          y = (_hash(i + 300) * 184 + t * 6) % 184 - 2;
      if (y < 1 || y > 175) continue;
      rect(x, y, 1, 3, _rgba(190, 210, 240, .35));
    }
    for (var i = 0; i < near; i++) {
      final x = (_hash(i + 600) * 340 + t * 4) % 340 - 10,
          y = (_hash(i + 900) * 190 + t * 10) % 190 - 6;
      if (y < 1 || y > 172) continue;
      rect(x, y, 1, 3, _rgba(210, 228, 250, .7));
      rect(x - 1, y + 3, 1, 3, _rgba(210, 228, 250, .7));
    }
  }

  void floodWater(int t, double l) {
    final lv = _r(52 * l), y0 = 180 - lv;
    rect(0, y0, 320, lv, _rgba(64, 112, 138, .78));
    rect(0, y0 + 8, 320, lv, _rgba(40, 76, 100, .35));
    for (var i = 0; i < 10; i++) {
      rect(
        (i * 47 + t * 1.2) % 340 - 10,
        y0 + 5 + (i * 7) % math.max(1, lv - 6),
        12,
        1,
        _rgba(150, 120, 80, .35),
      );
    }
    for (var x = 0; x < 320; x += 4) {
      final wy =
          y0 + _r(2 * math.sin((x + t * 2) / 7) + math.sin((x - t) / 13));
      rect(x, wy - 1, 4, 2, const Color(0xFFD5F1F8));
      rect(x, wy + 1, 4, 1, const Color(0xFF8FC6DD));
    }
    // ของลอยน้ำ
    for (var i = 0; i < 4; i++) {
      final x = (i * 97 + t * .8) % 360 - 20;
      final y = y0 + 2 + _r(math.sin(t / 6 + i));
      switch (i % 3) {
        case 0:
          rect(x, y, 10, 2, const Color(0xFF8A5A30));
          rect(x, y, 10, 1, const Color(0xFFB57E46));
        case 1:
          rect(x, y, 3, 2, const Color(0xFF3E9A45));
          rect(x + 2, y - 1, 2, 2, const Color(0xFF55B24A));
        default:
          rect(x, y - 1, 2, 4, const Color(0xFFDDEBF5));
          rect(x, y - 2, 2, 1, const Color(0xFF3E7CB8));
      }
    }
    // ฝนกระทบผิวน้ำ
    for (var i = 0; i < _r(16 * l); i++) {
      if ((t + i * 3) % 5 > 1) continue;
      final x = _hash(i * 13 + t ~/ 5) * 318;
      rect(x, y0 - 2, 1, 1, Colors.white);
      rect(x - 1, y0 - 1, 3, 1, _rgba(255, 255, 255, .6));
    }
  }

  void fx(int t, DisasterType? ty, double l) {
    if (ty == null || l <= 0) return;
    switch (ty) {
      case DisasterType.flood:
        rect(0, 0, 320, 180, _rgba(14, 14, 40, .3 * l));
        floodWater(t, l);
      case DisasterType.drought:
        rect(0, 90, 320, 90, _rgba(240, 150, 60, .18 * l));
        ellipse(70, 26, 18, 18, _rgba(255, 220, 120, .3));
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
          final x = (i * 47) % 320, y = 100 + (i * 29) % 78;
          rect(x, y, 6, 1, const Color(0xFF7A5634));
          rect(x + 5, y + 1, 1, 4, const Color(0xFF7A5634));
          rect(x + 1, y - 2, 1, 2, const Color(0xFF7A5634));
        }
      case DisasterType.poll:
        ellipse(240, 141, 56, 21, _rgba(90, 120, 30, .6 * l));
        rect(0, 0, 320, 180, _rgba(40, 60, 20, .16 * l));
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
        rect(0, 90, 320, 90, _rgba(255, 140, 50, .2 * l));
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
    final l = data.fxType == null ? 0.0 : data.fxLevel;
    cached('farm_sky_$_wx', () => bands(_skyColors, 0, 10));
    sun(t);
    clouds(t);
    birds(t);
    cached('farm_far_${storm ? mix : mix / 2}', farLayer);
    lightning(t, l);
    riverShimmer(t);
    cached('farm_near', nearLayer);
    lushTree(t, 268, 94);
    papaya(t);
    stoveFire(t);
    pondLife(t);
    equipment(t);
    smoke(t);
    lushTree(t, 36, 120);
    tufts(t);
    butterflies(t);
    fallingLeaves(t);
    banana(t);
    if (data.damaged) rect(0, 96, 320, 84, _rgba(94, 59, 38, .35));
    fx(t, data.fxType, l);
    windows(t);
    if (storm) {
      rain(t, l);
      final cyc = t % 61;
      if (l >= .2 && cyc < 2) {
        rect(0, 0, 320, 180, _rgba(220, 220, 255, cyc == 0 ? .22 : .1));
      }
    }
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

// น้ำในบ่อ: ผิวน้ำ → ก้นบ่อ
const _waterBands = [
  0xFF3CAED0, 0xFF2F9DC3, 0xFF2689B3, 0xFF1F77A3, //
  0xFF1A6693, 0xFF165884, 0xFF134B75, 0xFF104066,
];

class PondPainter extends PixelPainter {
  /// [swim] ต้องเป็นตัวเดิมตลอดอายุหน้าจอ (ปลาจำตำแหน่งของตัวเองไว้ในนั้น)
  PondPainter(super.tick, this.data, [PondSwim? swim])
    : swim = swim ?? PondSwim() {
    this.swim.sync(data.fish, fed: data.fed);
  }
  final PondSceneData data;
  final PondSwim swim;

  void backLayer() {
    // ฟ้าและฝั่งบ่อ
    bands(
      [
        const Color(0xFF3F9DEA),
        const Color(0xFF5DB4F0),
        const Color(0xFF86CBF3),
        const Color(0xFFB4E0F2),
      ],
      0,
      6,
    );
    for (var i = 0; i < 9; i++) {
      final x = i * 38 + (i % 2) * 9;
      ellipse(x, 22, 14 + (i % 3) * 3, 9, const Color(0xFF2B6440));
      ellipse(x - 3, 18, 8, 5, const Color(0xFF3A7E4E));
      rect(x - 6, 15, 4, 1, const Color(0xFF5BA06A));
    }
    rect(0, 26, 320, 10, const Color(0xFF4A9440));
    rect(0, 26, 320, 1, const Color(0xFF6CB458));
    dither(0, 30, 320, 2, const Color(0xFF3B7E35));
    rect(0, 32, 320, 4, const Color(0xFF6B5034));
    // น้ำไล่สีตามความลึก
    bands([for (final c in _waterBands) Color(c)], 36, 15);
    // ชั้นลึก: เงาหินและสาหร่ายไกล ๆ (สีจางกลืนน้ำ)
    const deep = Color(0xFF16577E), deep2 = Color(0xFF134C70);
    for (var i = 0; i < 7; i++) {
      final x = 20 + i * 47 + (i % 2) * 11;
      ellipse(x, 150, 16 + (i % 3) * 4, 10 + (i % 2) * 4, deep);
      ellipse(x - 4, 146, 6, 4, deep2);
    }
    for (var i = 0; i < 14; i++) {
      final x = 8 + i * 23, h = 18 + (i * 7) % 22;
      for (var j = 0; j < h; j += 3) {
        rect(x + _r(2 * math.sin(j / 6 + i)), 156 - j, 2, 3, deep2);
      }
    }
    // พื้นทรายก้นบ่อ
    for (var x = 0; x < 320; x += 2) {
      final y = _r(153 + 2 * math.sin(x / 17) + math.sin(x / 6));
      rect(x, y, 2, 180 - y, const Color(0xFFB09160));
      rect(x, y, 2, 1, const Color(0xFFCBAE7A));
    }
    rect(0, 162, 320, 18, const Color(0xFF9C7F52));
    dither(0, 161, 320, 2, const Color(0xFF9C7F52));
    rect(0, 171, 320, 9, const Color(0xFF876D45));
    dither(0, 170, 320, 1, const Color(0xFF876D45));
    for (var i = 0; i < 70; i++) {
      final x = (i * 53 + (i ~/ 6) * 19) % 318, y = 157 + (i * 7) % 20;
      rect(
        x,
        y,
        2 + i % 2,
        1,
        i % 3 == 0 ? const Color(0xFF6E5A3A) : const Color(0xFFC9AE80),
      );
    }
    // ก้อนหิน ขอนไม้ เปลือกหอย
    ellipse(34, 156, 14, 7, const Color(0xFF4E5A68));
    ellipse(32, 153, 11, 5, const Color(0xFF66727F));
    ellipse(28, 151, 5, 2, const Color(0xFF8A96A2));
    ellipse(52, 160, 7, 4, const Color(0xFF5A6674));
    rect(236, 158, 46, 6, const Color(0xFF5E4028));
    rect(236, 158, 46, 2, const Color(0xFF7E5A38));
    ellipse(236, 161, 3, 3, const Color(0xFF8A6A48));
    ellipse(236, 161, 1, 1, const Color(0xFF5E4028));
    for (final s in const [(120, 166), (178, 172), (300, 168)]) {
      rect(s.$1, s.$2, 3, 2, const Color(0xFFF2D8C8));
      rect(s.$1 + 1, s.$2, 1, 1, const Color(0xFFD9A898));
    }
    // ก้นบ่ออยู่ใต้น้ำ: เติมสีน้ำทับเล็กน้อย
    rect(0, 150, 320, 30, _rgba(20, 80, 120, .22));
  }

  void lightRays(int t) {
    for (var k = 0; k < 5; k++) {
      final x0 = 18 + k * 66 + 6 * math.sin(t / 25 + k);
      for (var j = 0; j < 26; j++) {
        rect(
          x0 + j * 4 * .35,
          38 + j * 4,
          9 + (j * .35).floor(),
          4,
          _rgba(200, 240, 255, .1 * (1 - j / 26)),
        );
      }
    }
  }

  void caustics(int t) {
    for (var i = 0; i < 28; i++) {
      final x = (i * 41 + t * (i % 3 + 1) * .5) % 330 - 5;
      final y = 40 + (i * 7) % 18 + _r(math.sin(t / 7 + i));
      rect(x, y, 3 + i % 4, 1, _rgba(210, 245, 255, .28 - (y - 40) / 90));
    }
  }

  void surface(int t) {
    for (var x = 0; x < 320; x += 4) {
      final y = 36 + _r(1.5 * math.sin((x + t * 1.5) / 7));
      rect(x, y, 4, 2, const Color(0xFFBDEBF7));
      rect(x, y + 2, 4, 1, const Color(0xFF6FCBE6));
    }
  }

  void reeds(int t) {
    for (var i = 0; i < 9; i++) {
      final x = 14 + i * 36 + (i % 3) * 5;
      final sw = _r(1.5 * math.sin(t / 10 + i));
      for (var j = 0; j < 4; j++) {
        rect(x + (j > 1 ? sw : 0), 34 - j * 3, 1, 3, const Color(0xFF3E7A2E));
      }
      rect(x - 1 + sw, 21, 3, 4, const Color(0xFF7A4E2A));
      rect(x + 3, 30, 1, 5, const Color(0xFF5A9A3A));
    }
  }

  /// สาหร่ายใบยาว แกว่งมากขึ้นตามความสูง
  void weed(int t, int x, int h, double ph, Color c, Color hi) {
    for (var b = -1; b <= 1; b++) {
      final bh = h - b.abs() * (h ~/ 4);
      for (var j = 0; j < bh; j += 3) {
        final k = j / bh;
        final off = 4 * k * k * math.sin(t / 12 + ph + b) + b * 2 * k;
        rect(x + b * 2 + off, 158 - j, 2, 3, c);
        if (j % 6 == 0) rect(x + b * 2 + off, 158 - j, 1, 2, hi);
      }
    }
  }

  void plants(int t) {
    const spots = [
      (46, 40),
      (96, 58),
      (150, 32),
      (198, 64),
      (262, 46),
      (300, 30),
      (128, 22),
    ];
    for (var i = 0; i < spots.length; i++) {
      weed(
        t,
        spots[i].$1,
        spots[i].$2,
        i * 1.3,
        i.isOdd ? const Color(0xFF2F8A4A) : const Color(0xFF3A9A42),
        const Color(0xFF6CC86A),
      );
    }
  }

  void bubbles(int t) {
    for (var i = 0; i < _r(data.o2 / 10); i++) {
      final by = 156 - ((t * 1.3 + i * 19) % 118);
      final bx = (i * 31 + 9) % 300 + _r(2 * math.sin((t + i * 7) / 4));
      final big = i % 3 == 0;
      if (big) {
        rect(bx, by, 4, 4, const Color(0xFFA5DDF5));
        rect(bx + 1, by + 1, 2, 2, const Color(0xFF5CB8DA));
        rect(bx + 1, by, 1, 1, Colors.white);
      } else {
        rect(bx, by, 2, 2, const Color(0xFFBFE8F7));
        rect(bx, by, 1, 1, Colors.white);
      }
    }
    // สายฟองจากซอกหิน
    for (var i = 0; i < 4; i++) {
      final by = 150 - ((t * 1.6 + i * 9) % 40);
      rect(
        36 + _r(math.sin((t + i * 4) / 3)),
        by,
        2,
        2,
        const Color(0xFFBFE8F7),
      );
    }
  }

  void motes(int t) {
    for (var i = 0; i < 24; i++) {
      final x = (i * 53 + t * .15 * (1 + i % 3)) % 320;
      final y = 46 + (i * 37) % 104 + 2 * math.sin(t / 15 + i);
      rect(x, y, 1, 1, _rgba(220, 250, 255, .35));
    }
  }

  @override
  void draw(int t) {
    cached('pond_back', backLayer);
    reeds(t);
    lightRays(t);
    caustics(t);
    surface(t);
    plants(t);
    motes(t);
    // น้ำขุ่นตามคุณภาพน้ำ
    rect(0, 36, 320, 144, _rgba(94, 70, 30, (100 - data.water) / 230));
    // ฟองอากาศตามออกซิเจน
    bubbles(t);
    if (data.fed) {
      for (var i = 0; i < 10; i++) {
        rect(
          20 + i * 14 + _r(1.5 * math.sin((t + i * 5) / 5)),
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

  /// ชั้นหน้าสุด: กอสาหร่ายมุมล่างซ้าย-ขวา (ปลาว่ายลอดหลังได้ ให้ความลึก)
  @override
  void drawFront(int t) {
    for (final (x0, dir) in const [(4, 1), (316, -1)]) {
      for (var b = 0; b < 4; b++) {
        final h = 26 + b * 7;
        for (var j = 0; j < h; j += 3) {
          final k = j / h;
          final off = dir * b * 3 * k + 3 * k * k * math.sin(t / 11 + b);
          rect(x0 + dir * b * 2 + off, 178 - j, 3, 3, const Color(0xFF1F6E3A));
          if (j % 6 == 0) {
            rect(
              x0 + dir * b * 2 + off,
              178 - j,
              1,
              2,
              const Color(0xFF3E9A55),
            );
          }
        }
      }
    }
  }

  @override
  bool get hasFront => true;

  @override
  bool get hasFish => true;

  /// ขนาดเฟรมตาม [Swimmer.frame]: ขอบเขตการว่ายคิดจากขนาดเดียวกัน ปลาจึงไม่ล้นบ่อ
  @override
  List<SceneFish> fishAt(double t) {
    swim.advanceTo(t.floor());
    final a = (t - t.floor()).clamp(0.0, 1.0);
    double lerp(double p, double q) => p + (q - p) * a;
    return [
      for (final s in swim.swimmers)
        SceneFish(
          type: s.fish.type,
          x: lerp(s.px, s.x),
          y: s.drawY(t, lerp(s.py, s.y)),
          size: s.frame.roundToDouble(),
          frame: s.tailFrame,
          flipX: s.faceLeft,
          scaleX: lerp(s.prevTurnScale, s.turnScale),
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

  /// ฉาก + ปลา + ชั้นหน้าสุด
  Widget _layers(PixelPainter painter, Widget paint) {
    if (!painter.hasFish && !painter.hasFront) return paint;
    return Stack(
      fit: StackFit.expand,
      children: [
        paint,
        if (painter.hasFish)
          SceneFishLayer(
            tick: _tick,
            fishAt: painter.fishAt,
            smooth: _timer != null,
          ),
        if (painter.hasFront)
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _FrontPainter(painter)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final painter = widget.painterBuilder(_tick);
    Widget paint = RepaintBoundary(child: CustomPaint(painter: painter));
    if (widget.backdrop) return _backdrop(painter, paint);
    paint = _layers(painter, paint);
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
    paint = _layers(painter, paint);
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

/// ชั้นหน้าสุดของฉาก (วาดทับปลา)
class _FrontPainter extends CustomPainter {
  _FrontPainter(this.base) : super(repaint: base.tick);
  final PixelPainter base;

  @override
  void paint(Canvas canvas, Size size) => base.paintFront(canvas, size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
    this.scaleX = 1,
  });
  final String type;
  final double x, y;

  /// ขนาดเฟรม (พิกเซลฉาก)
  final double size;
  final int frame;

  /// หัวไปทางซ้าย
  final bool flipX;

  /// ความกว้างตามแนวนอน (<1 ตอนหมุนตัวกลับด้าน)
  final double scaleX;
}

/// ชั้นปลาทับฉากพิกเซล: ใช้ [FishSprite] (ภาพแถบเฟรม) ตามตำแหน่งที่ฉากคำนวณ
/// ตำแหน่งและขนาดปัดเป็นพิกเซลจริงทุกครั้ง ภาพจึงคม
///
/// [smooth]: เกลี่ยตำแหน่งระหว่างเฟรมฉาก (100ms) ด้วยนาฬิกาจอ ~30 ครั้ง/วินาที
/// ให้ปลาว่ายลื่น (ปิดในเทสต์ผ่าน sceneAnimationProvider)
class SceneFishLayer extends StatefulWidget {
  const SceneFishLayer({
    super.key,
    required this.tick,
    required this.fishAt,
    this.smooth = false,
  });
  final ValueListenable<int> tick;
  final List<SceneFish> Function(double t) fishAt;
  final bool smooth;

  @override
  State<SceneFishLayer> createState() => _SceneFishLayerState();
}

class _SceneFishLayerState extends State<SceneFishLayer>
    with SingleTickerProviderStateMixin {
  static const _step = Duration(milliseconds: 100);
  static const _minGap = Duration(milliseconds: 30);
  final _frac = ValueNotifier<double>(0);
  Ticker? _ticker;
  Duration _now = Duration.zero, _at = Duration.zero, _drawn = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.tick.addListener(_onTick);
    if (widget.smooth) {
      _ticker = createTicker(_onFrame)..start();
    }
  }

  void _onTick() {
    _at = _now;
    _frac.value = 0;
  }

  void _onFrame(Duration now) {
    _now = now;
    if (now - _drawn < _minGap) return;
    _drawn = now;
    _frac.value = ((now - _at).inMicroseconds / _step.inMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  @override
  void didUpdateWidget(SceneFishLayer old) {
    super.didUpdateWidget(old);
    if (old.tick != widget.tick) {
      old.tick.removeListener(_onTick);
      widget.tick.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.tick.removeListener(_onTick);
    _ticker?.dispose();
    _frac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    double snap(double v) => (v * dpr).roundToDouble() / dpr;
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final k = box.maxWidth / kSceneW;
            return ListenableBuilder(
              listenable: Listenable.merge([widget.tick, _frac]),
              builder: (context, _) {
                final fish = widget.fishAt(widget.tick.value + _frac.value);
                return Stack(
                  children: [
                    for (var i = 0; i < fish.length; i++)
                      Positioned(
                        key: ValueKey(i),
                        left: snap((fish[i].x - fish[i].size / 2) * k),
                        top: snap((fish[i].y - fish[i].size / 2) * k),
                        child: _turn(
                          fish[i].scaleX,
                          FishSprite(
                            fish[i].type,
                            size: snap(fish[i].size * k),
                            frame: fish[i].frame,
                            flipX: fish[i].flipX,
                          ),
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

  /// หมุนตัว: บีบภาพตามแนวนอนรอบจุดกลาง (ยังวาดแบบพิกเซลไม่กรองภาพ)
  Widget _turn(double sx, Widget child) {
    if (sx >= .999) return child;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(sx, 1, 1),
      child: child,
    );
  }
}
