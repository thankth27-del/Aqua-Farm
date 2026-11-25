import 'package:material_ui/material_ui.dart';

import '../theme/theme.dart';
import 'guide_bars.dart';

/// แท็บย่อยในหน้า (เช่น ตลาด: ซื้อ | ขาย) — ปุ่มที่เลือกเป็นสีทอง
/// แทนการเรียงทุกส่วนต่อกันเป็นหน้ายาว
class SubTabs extends StatelessWidget {
  const SubTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  /// (คีย์, ชื่อ, ไอคอน, ตัวเลขบนป้าย หรือ null)
  final List<(String key, String label, String icon, int? count)> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: Gap.s),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Semantics(
                    selected: i == selected,
                    child: PixelButton(
                      key: ValueKey(items[i].$1),
                      label: items[i].$2,
                      icon: PixelIcon(items[i].$3, size: 24),
                      expand: true,
                      style: i == selected
                          ? PixelButtonStyle.green
                          : PixelButtonStyle.wood,
                      onPressed: () => onSelect(i),
                    ),
                  ),
                  // จำนวนของที่รออยู่ในแท็บย่อยนี้
                  if (items[i].$4 != null && i != selected)
                    Positioned(
                      top: -6,
                      right: -4,
                      child: NavBadge(
                        key: ValueKey('${items[i].$1}-badge'),
                        count: items[i].$4!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
