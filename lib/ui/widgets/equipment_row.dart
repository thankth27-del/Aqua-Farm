import 'package:material_ui/material_ui.dart';

import '../../data/equipment_data.dart';
import '../theme/theme.dart';

/// แถวอุปกรณ์ 1 ชนิด (eqRow ในต้นแบบ): ไอคอน ชื่อ จำนวนที่มี คำอธิบาย ปุ่มซื้อพร้อมราคา
/// ใช้ทั้งอุปกรณ์ครัว (ตลาด) และอุปกรณ์ป้องกันภัย (เตรียมภัย)
class EquipmentRow extends StatelessWidget {
  const EquipmentRow({
    super.key,
    required this.spec,
    required this.price,
    required this.owned,
    required this.closed,
    required this.onBuy,
    this.usage,
    this.badge,
    this.badgeOk = false,
  });

  final EquipmentSpec spec;

  /// ราคาวันนี้ (ตามความยาก)
  final int price;
  final int owned;

  /// ตลาดปิด: ปุ่มเป็น "ปิด" (กดแล้วบอกเหตุผล)
  final bool closed;
  final VoidCallback onBuy;

  /// บรรทัดประโยชน์ / ใช้กับภัยอะไร (ถ้ามี)
  final String? usage;

  /// ป้ายเด่นบนสุด เช่น "น้ำท่วม: ยังขาด 3" (ถ้ามี)
  final String? badge;

  /// ป้ายเป็นสีผ่าน (ครบแล้ว) แทนสีแดง
  final bool badgeOk;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          PixelIcon(spec.icon, size: 44),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Tag(
                      badge!,
                      size: 13,
                      color: badgeOk ? AquaColors.creamDark : AquaColors.red,
                      textColor: badgeOk ? AquaColors.ok : Colors.white,
                    ),
                  ),
                Row(
                  children: [
                    Flexible(child: Bold(spec.name, maxLines: 2)),
                    const SizedBox(width: Gap.xs),
                    Tag(
                      'x$owned',
                      size: 13,
                      color: owned > 0 ? AquaColors.gold : AquaColors.creamDark,
                    ),
                  ],
                ),
                Muted(spec.description, size: 13),
                if (usage != null) Muted(usage!, size: 13),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          PixelButton(
            label: closed ? 'ปิด' : 'ซื้อ',
            style: closed ? PixelButtonStyle.wood : PixelButtonStyle.green,
            below: CoinTag(price, boxed: true, size: FontSize.small),
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}
