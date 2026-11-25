import 'dart:ui' show PointMode;

import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart';
import 'colors.dart';

/// เส้นขอบ "ปกติ" ของการ์ด (ขอบเข้มเดิมของธีมพิกเซล) → เส้นบางสีอ่อน
/// สีขอบอื่น (เน้น/เตือน/เลือกอยู่) ยังแสดงเป็นขอบหนาสีนั้น
Color _edge(Color border) =>
    border == AquaColors.ink || border == AquaColors.woodDark
    ? DsColors.border
    : border;

double _edgeWidth(Color border) =>
    border == AquaColors.ink || border == AquaColors.woodDark ? 1 : 2;

/// วาดกล่องมุมมนของระบบดีไซน์: พื้น ขอบบาง และเงาบางเมื่อมี [depth]
/// (ชื่อเดิมคงไว้ให้หน้าเดิมใช้ต่อได้ — ไม่มีลายไม้/มุมบากแล้ว)
class PixelBoxPainter extends CustomPainter {
  const PixelBoxPainter({
    required this.fill,
    this.border = AquaColors.ink,
    this.px = 3,
    this.depth = 0,
    this.depthColor = AquaColors.ink,
    this.bevel = true,
    this.grain,
  });

  final Color fill;
  final Color border;

  /// ขนาดขอบเดิม: 2 = ป้ายเล็ก (มุมมนเล็ก) / 3 = การ์ด
  final double px;

  /// มีเงา (การ์ดลอย)
  final double depth;
  final Color depthColor;
  final bool bevel;
  final Color? grain;

  double get radius => px <= 2 ? DsRadius.small : DsRadius.small + 2;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    if (depth > 0) {
      canvas.drawRRect(
        r.shift(const Offset(0, 2)),
        Paint()
          ..color = const Color(0x1A0F3D36)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawRRect(r, Paint()..color = fill);
    final w = _edgeWidth(border);
    canvas.drawRRect(
      r.deflate(w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = _edge(border),
    );
  }

  @override
  bool shouldRepaint(PixelBoxPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.depth != depth ||
      old.px != px;
}

/// กล่องมุมมนทั่วไป
class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.fill = AquaColors.cream,
    this.border = AquaColors.ink,
    this.padding = const EdgeInsets.all(12),
    this.px = 3,
    this.depth = 0,
    this.depthColor = AquaColors.ink,
    this.bevel = true,
    this.grain,
  });

  final Widget child;
  final Color fill;
  final Color border;
  final EdgeInsetsGeometry padding;
  final double px;
  final double depth;
  final Color depthColor;
  final bool bevel;
  final Color? grain;

  @override
  Widget build(BuildContext context) {
    final radius = px <= 2 ? DsRadius.small : DsRadius.small + 2;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _edge(border), width: _edgeWidth(border)),
        boxShadow: depth > 0 ? DsShadow.card : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// การ์ดหลักของเกม: พื้นขาว มุมมน เงาบาง (เดิมเป็นกรอบไม้)
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpace.m),
    this.margin = const EdgeInsets.only(bottom: DsSpace.m),
    this.inner = AquaColors.cream,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color inner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inner,
          borderRadius: BorderRadius.circular(DsRadius.card),
          border: Border.all(color: DsColors.border),
          boxShadow: DsShadow.card,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// การ์ดย่อย (ซ้อนในการ์ดหลัก หรือเป็นช่องไอคอน)
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.fill = AquaColors.paper,
    this.border = AquaColors.woodDark,
    this.padding = const EdgeInsets.all(10),
  });

  final Widget child;
  final Color fill;
  final Color border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => PixelBox(
    fill: fill == AquaColors.paper ? DsColors.surfaceAlt : fill,
    border: border,
    px: 3,
    padding: padding,
    child: child,
  );
}

/// แถบหลักสีเข้ม (แถบบน / เมนู) — ตัวอักษรบนแถบใช้ [AquaColors.paper]
class WoodPlank extends StatelessWidget {
  const WoodPlank({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DsColors.primaryDark,
        boxShadow: DsShadow.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// พื้นหลังของทุกหน้า: ใต้น้ำของบ่อแบบพิกเซล (น้ำไล่สีเป็นขั้น ระลอกน้ำ ฟองอากาศ
/// เงาปลาไกล ๆ และพื้นทรายกับสาหร่ายด้านล่าง) — สีอ่อน ไม่แย่งสายตาจากการ์ด
/// [deep] = โทนเข้มกว่า ใช้นอกพื้นที่เนื้อหาบนจอกว้าง
class GrassBackground extends StatelessWidget {
  const GrassBackground({super.key, required this.child, this.deep = false});
  final Widget child;
  final bool deep;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: PondBackdropPainter(deep: deep)),
          ),
        ),
        child,
      ],
    );
  }
}

/// วาดฉากใต้น้ำ (ภาพนิ่ง ไม่มีแอนิเมชัน) — ตำแหน่งสุ่มแบบคงที่ตามพิกัด
class PondBackdropPainter extends CustomPainter {
  const PondBackdropPainter({this.deep = false});
  final bool deep;

  /// ขนาด 1 พิกเซลของภาพ (หน่วย logical)
  static const double u = 3;

  static const _light = [
    Color(0xFFE3F4F0),
    Color(0xFFD8EFEA),
    Color(0xFFCDE9E3),
    Color(0xFFC2E3DC),
    Color(0xFFB7DCD4),
    Color(0xFFACD5CC),
  ];
  static const _dark = [
    Color(0xFF9CCBC2),
    Color(0xFF8DC2B8),
    Color(0xFF7FB8AE),
    Color(0xFF71AEA4),
    Color(0xFF64A49A),
    Color(0xFF589A90),
  ];

  static const _fish = [
    '..##....',
    '.#####.#',
    '########',
    '.#####.#',
    '..##....',
  ];

  static int _h(int a, int b) =>
      ((a * 73856093) ^ (b * 19349663) ^ 0x5bd1e995) & 0x7fffffff;

  static double _snap(double v) => (v / u).floorToDouble() * u;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final p = Paint()..isAntiAlias = false;
    final w = size.width, h = size.height;
    final bands = deep ? _dark : _light;

    // 1) น้ำไล่สีเป็นขั้น + จุดสลับตรงรอยต่อ (แบบเกมพิกเซล)
    final bh = _snap(h / bands.length) + u;
    for (var i = 0; i < bands.length; i++) {
      p.color = bands[i];
      canvas.drawRect(Rect.fromLTWH(0, i * bh, w, bh + u), p);
    }
    final dots = Paint()
      ..isAntiAlias = false
      ..strokeWidth = u
      ..strokeCap = StrokeCap.square;
    for (var i = 1; i < bands.length; i++) {
      final y0 = i * bh;
      dots.color = bands[i];
      final pts = <Offset>[];
      for (var x = 0.0; x < w; x += u * 2) {
        pts
          ..add(Offset(x + u / 2, y0 - u * 1.5))
          ..add(Offset(x + u * 1.5, y0 - u * 2.5));
      }
      canvas.drawPoints(PointMode.points, pts, dots);
    }

    // 2) ระลอกน้ำ: เส้นคลื่นสั้น ๆ กระจายเป็นแถว
    p.color = deep ? const Color(0x33FFFFFF) : const Color(0x8CFFFFFF);
    for (var row = 0, y = 30.0; y < h * .8; row++, y += 84) {
      for (var col = 0, x = -40.0; x < w; col++) {
        final k = _h(row, col);
        x += 70 + (k % 90);
        if (k % 3 == 0) continue;
        final cx = _snap(x), cy = _snap(y + (k >> 4) % 30);
        final len = (3 + (k >> 8) % 4) * u;
        canvas
          ..drawRect(Rect.fromLTWH(cx, cy, len, u), p)
          ..drawRect(Rect.fromLTWH(cx + len, cy - u, _snap(len * .7), u), p)
          ..drawRect(
            Rect.fromLTWH(cx + len + _snap(len * .7), cy, u * 2, u),
            p,
          );
      }
    }

    // 3) เงาปลาไกล ๆ (สีจาง)
    p.color = deep ? const Color(0x22000000) : const Color(0x2E0F766E);
    for (var gy = 0; gy * 230.0 < h * .78; gy++) {
      for (var gx = 0; gx * 260.0 < w; gx++) {
        final k = _h(gx + 101, gy + 37);
        if (k % 100 > 38) continue;
        final ox = _snap(gx * 260.0 + 30 + k % 180);
        final oy = _snap(gy * 230.0 + 50 + (k >> 6) % 140);
        final flip = (k >> 3).isOdd;
        final s = (k >> 9).isOdd ? u : u * 2;
        for (var r = 0; r < _fish.length; r++) {
          final line = _fish[r];
          for (var c = 0; c < line.length; c++) {
            if (line[c] != '#') continue;
            final cc = flip ? line.length - 1 - c : c;
            canvas.drawRect(Rect.fromLTWH(ox + cc * s, oy + r * s, s, s), p);
          }
        }
      }
    }

    // 4) ฟองอากาศ
    final ring = Paint()
      ..isAntiAlias = false
      ..color = deep ? const Color(0x40FFFFFF) : const Color(0xB3FFFFFF);
    final shine = Paint()
      ..isAntiAlias = false
      ..color = deep ? const Color(0x66FFFFFF) : const Color(0xFFFFFFFF);
    for (var gy = 0; gy * 96.0 < h * .85; gy++) {
      for (var gx = 0; gx * 96.0 < w; gx++) {
        final k = _h(gx + 7, gy + 913);
        if (k % 100 > 34) continue;
        final x = _snap(gx * 96.0 + k % 80);
        final y = _snap(gy * 96.0 + (k >> 7) % 80);
        if ((k >> 5) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, u * 2, u * 2), ring);
        } else {
          canvas
            ..drawRect(Rect.fromLTWH(x + u, y, u * 2, u), ring)
            ..drawRect(Rect.fromLTWH(x, y + u, u, u * 2), ring)
            ..drawRect(Rect.fromLTWH(x + u * 3, y + u, u, u * 2), ring)
            ..drawRect(Rect.fromLTWH(x + u, y + u * 3, u * 2, u), ring)
            ..drawRect(Rect.fromLTWH(x + u, y + u, u, u), shine)
            // ฟองเล็กลอยตามขึ้นไป
            ..drawRect(Rect.fromLTWH(x + u * 4, y - u * 3, u, u), ring);
        }
      }
    }

    // 5) พื้นทราย สาหร่าย และก้อนหิน (เฉพาะจอที่สูงพอ)
    if (h < 320) return;
    final sandTop = _snap(h - 30);
    final weed = deep ? const Color(0xFF3F8A68) : const Color(0xFF6DB58C);
    final weedDark = deep ? const Color(0xFF2F7056) : const Color(0xFF4E9A70);
    for (var i = 0, x = 6.0; x < w; i++) {
      final k = _h(i, 4242);
      x += 34 + k % 70;
      final bx = _snap(x);
      final tall = (12 + k % 18) * u;
      for (var s = 0.0; s < tall; s += u) {
        final step = (s / u).round();
        final sway = (step ~/ 4).isOdd ? u : 0.0;
        p.color = s < tall * .5 ? weedDark : weed;
        canvas.drawRect(Rect.fromLTWH(bx + sway, sandTop - s - u, u * 2, u), p);
        // ใบแตกข้าง
        if (step % 7 == 3) {
          p.color = weed;
          canvas.drawRect(
            Rect.fromLTWH(bx + sway + u * 2, sandTop - s - u * 2, u * 2, u),
            p,
          );
        }
      }
    }
    final sand = deep ? const Color(0xFFB8A57A) : const Color(0xFFEADBAF);
    final sandDot = deep ? const Color(0xFF9C8A62) : const Color(0xFFD8C48E);
    final sandHi = deep ? const Color(0xFFC8B68C) : const Color(0xFFF4E9C8);
    final rock = deep ? const Color(0xFF6E7F7A) : const Color(0xFF9FB2AC);
    for (var x = 0.0, i = 0; x < w; x += u * 4, i++) {
      final bump = (_h(i, 77) % 3) * u;
      p.color = sand;
      canvas.drawRect(Rect.fromLTWH(x, sandTop - bump, u * 4, h), p);
      p.color = sandHi;
      canvas.drawRect(Rect.fromLTWH(x, sandTop - bump, u * 4, u), p);
      final k = _h(i, 78);
      if (k % 3 == 0) {
        p.color = sandDot;
        canvas.drawRect(
          Rect.fromLTWH(x + (k >> 3) % 3 * u, sandTop + u * (2 + k % 5), u, u),
          p,
        );
      }
      if (k % 23 == 0) {
        p.color = rock;
        canvas
          ..drawRect(Rect.fromLTWH(x, sandTop - bump - u * 2, u * 4, u * 3), p)
          ..drawRect(Rect.fromLTWH(x + u, sandTop - bump - u * 3, u * 2, u), p);
      }
    }
  }

  @override
  bool shouldRepaint(PondBackdropPainter old) => old.deep != deep;
}
