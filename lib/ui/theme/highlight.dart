import 'package:material_ui/material_ui.dart';

import 'colors.dart';
import 'motion.dart';

/// กรอบกะพริบชี้จุดที่บทเรียนให้กด (.hl ในต้นแบบ) — ไม่บังการกด
class Spotlight extends StatelessWidget {
  const Spotlight({
    super.key,
    required this.on,
    required this.child,
    this.pad = 4,
  });

  final bool on;
  final Widget child;

  /// ระยะกรอบที่ยื่นออกนอกตัวลูก
  final double pad;

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -pad,
          top: -pad,
          right: -pad,
          bottom: -pad,
          child: IgnorePointer(
            child: Blink(
              low: .1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AquaColors.ink, width: 2),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AquaColors.goldLight, width: 3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
