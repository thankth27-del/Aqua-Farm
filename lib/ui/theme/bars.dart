import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'colors.dart';

/// แถบสถานะพิกเซล: แบ่งเป็นช่อง ๆ มีไฮไลต์ด้านบน เลื่อนค่าแบบนุ่ม
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 18,
  });

  /// 0-100
  final num value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0, 100).toDouble()),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => CustomPaint(
          size: Size.infinite,
          painter: _BarPainter(v / 100, color),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.f, this.color);
  final double f;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    const b = 3.0;
    // ขอบมุมบาก
    p.color = AquaColors.ink;
    canvas
      ..drawRect(Rect.fromLTRB(b, 0, size.width - b, size.height), p)
      ..drawRect(Rect.fromLTRB(0, b, size.width, size.height - b), p);
    final inner = Rect.fromLTRB(b, b, size.width - b, size.height - b);
    p.color = AquaColors.inkSoft;
    canvas.drawRect(inner, p);
    final w = (inner.width * f).floorToDouble();
    if (w <= 0) return;
    final fill = Rect.fromLTWH(inner.left, inner.top, w, inner.height);
    p.color = color;
    canvas.drawRect(fill, p);
    p.color = Color.lerp(color, Colors.white, .45)!;
    canvas.drawRect(
      Rect.fromLTWH(
        fill.left,
        fill.top,
        fill.width,
        (inner.height / 4).ceilToDouble(),
      ),
      p,
    );
    // ช่องแบ่ง (แบบ .bar ของต้นแบบ)
    p.color = Color.lerp(color, AquaColors.ink, .35)!;
    for (var x = inner.left + 10; x < fill.right - 1; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, fill.top, 2, fill.height), p);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.f != f || old.color != color;
}

/// ค่าสถานะแบบไอคอน + แถบ + ตัวเลข (ไม่มีชื่อ มี tooltip บอกแทน)
class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    this.suffix = '',
  });

  final Widget icon;
  final int value;
  final Color color;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label $value$suffix',
      child: Semantics(
        label: label,
        value: '$value$suffix',
        child: ExcludeSemantics(
          child: Row(
            children: [
              SizedBox(width: 26, child: Center(child: icon)),
              const SizedBox(width: Gap.s),
              Expanded(
                child: PixelBar(value: value, color: color),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '$value',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: FontSize.body,
                    color: AquaColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
