import 'package:material_ui/material_ui.dart';

import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';

/// แท็บที่ยังไม่ได้ทำหน้าจอ (ตลาด / ครัว / คลัง) — ฉากห้องไม้ + ป้าย "เร็ว ๆ นี้"
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
    required this.note,
    this.items = const [],
  });
  final String title;
  final String icon;
  final String note;

  /// ไอคอนตัวอย่างของที่จะมีในหน้านี้
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        PageHeader(
          scene: PixelScene(painterBuilder: RoomPainter.new),
          title: title,
          icon: PixelIcon(icon, size: 30),
        ),
        WoodPanel(
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: Gap.m,
                runSpacing: Gap.s,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Bob(
                      phase: i / items.length,
                      dy: 2,
                      child: PaperCard(child: PixelIcon(items[i], size: 44)),
                    ),
                ],
              ),
              const SizedBox(height: Gap.m),
              const Bold('หน้านี้จะทำในขั้นถัดไป', size: FontSize.label),
              const SizedBox(height: Gap.xs),
              Muted(note, size: FontSize.body, align: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}
