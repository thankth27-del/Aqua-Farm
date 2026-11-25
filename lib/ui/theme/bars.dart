import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import '../design/design_system.dart';
import 'colors.dart';

/// แถบสถานะพิกเซล: แบ่งเป็นช่อง ๆ มีไฮไลต์ด้านบน เลื่อนค่าแบบนุ่ม
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 12,
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
    // แถบมุมมน: รางสีอ่อน + ส่วนที่เต็มเป็นสีของค่านั้น
    final r = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = DsColors.border,
    );
    final w = size.width * f;
    if (w <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w.clamp(size.height, size.width), size.height),
        r,
      ),
      Paint()..color = color,
    );
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
