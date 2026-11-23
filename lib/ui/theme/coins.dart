import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'colors.dart';
import 'frames.dart';
import 'pixel_icon.dart';

/// ป้ายราคาเหรียญ: เหรียญ + จำนวนเงิน
class CoinTag extends StatelessWidget {
  const CoinTag(
    this.amount, {
    super.key,
    this.size = FontSize.body,
    this.color = AquaColors.text,
    this.boxed = false,
  });

  final int amount;
  final double size;
  final Color color;

  /// วางบนป้ายครีมเล็ก ๆ (ใช้บนปุ่ม/การ์ดสินค้า)
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: '$amount บาท',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelIcon('coin', size: size * 1.1),
            const SizedBox(width: 4),
            Text(
              '$amount',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w700,
                color: boxed ? AquaColors.text : color,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
    if (!boxed) return row;
    return PixelBox(
      fill: AquaColors.goldPale,
      px: 2,
      bevel: false,
      padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
      child: row,
    );
  }
}
