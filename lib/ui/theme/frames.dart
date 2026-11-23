import 'package:material_ui/material_ui.dart';

import 'colors.dart';

/// วาดกล่องพิกเซล: มุมบาก, ขอบเข้ม, เส้นไฮไลต์บน/ซ้าย, เงาล่าง/ขวา และ "ความหนา" ด้านล่าง
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

  /// ความหนาเส้นขอบ (พิกเซลจอ)
  final double px;

  /// ความหนาส่วนล่าง (ทำให้ดูนูน กดแล้วยุบ)
  final double depth;
  final Color depthColor;

  /// วาดไฮไลต์/เงาด้านใน
  final bool bevel;

  /// ลายไม้ (เส้นแนวนอนสีเข้มกว่า) — null = ไม่มี
  final Color? grain;

  static void notched(Canvas c, Rect r, double n, Paint p) {
    if (r.width <= 2 * n || r.height <= 2 * n) {
      c.drawRect(r, p);
      return;
    }
    c
      ..drawRect(Rect.fromLTRB(r.left + n, r.top, r.right - n, r.bottom), p)
      ..drawRect(Rect.fromLTRB(r.left, r.top + n, r.right, r.bottom - n), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    final body = Rect.fromLTWH(0, 0, size.width, size.height - depth);
    if (depth > 0) {
      p.color = depthColor;
      notched(
        canvas,
        Rect.fromLTWH(0, depth, size.width, size.height - depth),
        px,
        p,
      );
    }
    p.color = border;
    notched(canvas, body, px, p);
    final inner = body.deflate(px);
    if (inner.isEmpty) return;
    p.color = fill;
    canvas.drawRect(inner, p);
    if (grain != null) {
      p.color = grain!;
      var i = 0;
      for (var y = inner.top + 9; y < inner.bottom - 2; y += 10) {
        canvas.drawRect(Rect.fromLTWH(inner.left, y, inner.width, 2), p);
        // รอยต่อแผ่นไม้สลับตำแหน่ง
        final x = inner.left + (i * 67) % inner.width;
        canvas.drawRect(Rect.fromLTWH(x, y - 8, 2, 8), p);
        i++;
      }
    }
    if (bevel) {
      final b = (px * .7).roundToDouble().clamp(2.0, 4.0);
      p.color = Color.lerp(fill, Colors.white, .32)!;
      canvas
        ..drawRect(Rect.fromLTWH(inner.left, inner.top, inner.width, b), p)
        ..drawRect(Rect.fromLTWH(inner.left, inner.top, b, inner.height), p);
      p.color = Color.lerp(fill, AquaColors.ink, .25)!;
      canvas
        ..drawRect(
          Rect.fromLTWH(inner.left, inner.bottom - b, inner.width, b),
          p,
        )
        ..drawRect(
          Rect.fromLTWH(inner.right - b, inner.top, b, inner.height),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(PixelBoxPainter old) =>
      old.fill != fill ||
      old.border != border ||
      old.depth != depth ||
      old.px != px ||
      old.grain != grain ||
      old.bevel != bevel;
}

/// กล่องพิกเซลทั่วไป
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
    return CustomPaint(
      painter: PixelBoxPainter(
        fill: fill,
        border: border,
        px: px,
        depth: depth,
        depthColor: depthColor,
        bevel: bevel,
        grain: grain,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: depth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// แผงกรอบไม้ ตอกตะปูที่มุม ข้างในเป็นกระดาษครีม — การ์ดหลักของเกม
class WoodPanel extends StatelessWidget {
  const WoodPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 16),
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
      child: CustomPaint(
        foregroundPainter: const _NailsPainter(),
        child: PixelBox(
          fill: AquaColors.wood,
          grain: AquaColors.woodDark,
          depth: 5,
          padding: const EdgeInsets.all(7),
          child: PixelBox(
            fill: inner,
            border: AquaColors.woodDark,
            px: 3,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NailsPainter extends CustomPainter {
  const _NailsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    final h = size.height - 5;
    for (final o in [
      const Offset(6, 6),
      Offset(size.width - 10, 6),
      Offset(6, h - 10),
      Offset(size.width - 10, h - 10),
    ]) {
      p.color = AquaColors.woodHi;
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 4, 4), p);
      p.color = AquaColors.goldPale;
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 2, 2), p);
    }
  }

  @override
  bool shouldRepaint(_NailsPainter old) => false;
}

/// การ์ดกระดาษเรียบ (ใช้ซ้อนในแผงไม้ หรือเป็นช่องไอคอน)
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
    fill: fill,
    border: border,
    px: 3,
    depth: 3,
    padding: padding,
    child: child,
  );
}

/// แผ่นไม้ยาว (แถบบน / เมนูล่าง)
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
    return CustomPaint(
      painter: const _PlankPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PlankPainter extends CustomPainter {
  const _PlankPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    p.color = AquaColors.wood;
    canvas.drawRect(Offset.zero & size, p);
    p.color = AquaColors.woodDark;
    var i = 0;
    for (var y = 12.0; y < size.height; y += 14) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), p);
      for (var x = (i * 53) % 90 + 20.0; x < size.width; x += 140) {
        canvas.drawRect(Rect.fromLTWH(x, y - 12, 2, 12), p);
      }
      i++;
    }
    p.color = AquaColors.woodHi;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 3), p);
    p.color = AquaColors.ink;
    canvas.drawRect(Rect.fromLTWH(0, size.height - 3, size.width, 3), p);
  }

  @override
  bool shouldRepaint(_PlankPainter old) => false;
}

/// พื้นหลังหญ้าลายจุดพิกเซล (พื้นของทุกหน้าในเกม)
class GrassBackground extends StatelessWidget {
  const GrassBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _GrassPainter(), child: child);
  }
}

class _GrassPainter extends CustomPainter {
  const _GrassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    p.color = AquaColors.bgGreen;
    canvas.drawRect(Offset.zero & size, p);
    for (var y = 0.0, row = 0; y < size.height; y += 18, row++) {
      for (var x = (row.isOdd ? 9.0 : 0.0); x < size.width; x += 18) {
        p.color = AquaColors.bgGreenDot;
        canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), p);
        if ((x ~/ 18 + row) % 7 == 0) {
          p.color = AquaColors.grassDark;
          canvas
            ..drawRect(Rect.fromLTWH(x + 6, y + 8, 2, 4), p)
            ..drawRect(Rect.fromLTWH(x + 9, y + 6, 2, 6), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GrassPainter old) => false;
}
