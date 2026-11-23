import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// แท็บที่ยังไม่ได้ทำหน้าจอ (ตลาด / ครัว / คลัง)
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.title,
    required this.icon,
    required this.note,
  });
  final String title;
  final String icon;
  final String note;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GoldTitle(title),
        const SizedBox(height: 8),
        PixelPanel(
          child: Row(
            children: [
              PixelIcon(icon, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'หน้านี้จะทำในขั้นถัดไป',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Muted(note),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
