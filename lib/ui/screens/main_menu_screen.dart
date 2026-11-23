import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme.dart';
import 'slots_screen.dart';

/// เมนูหลัก: เกมใหม่ / เล่นต่อ / โหลดเกม / เครดิต
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  void _continue(BuildContext context, WidgetRef ref) {
    try {
      if (!ref.read(gameProvider.notifier).continueLatest()) {
        toast(context, 'ยังไม่มีเซฟ', bad: true);
      }
    } on SaveException catch (e) {
      toast(context, e.message, bad: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openSlots() =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const SlotsScreen()));
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PixelScene(
              painterBuilder: (t) => FarmPainter(t, const FarmSceneData()),
            ),
            const SizedBox(height: 20),
            const Center(child: GoldTitle('AQUA FARM', size: 44)),
            const Center(child: Muted('From Farm to Food', size: 15)),
            const SizedBox(height: 24),
            PixelButton(
              label: 'เกมใหม่',
              style: PixelButtonStyle.gold,
              expand: true,
              onPressed: openSlots,
            ),
            const SizedBox(height: 10),
            PixelButton(
              label: 'เล่นต่อ',
              expand: true,
              onPressed: () => _continue(context, ref),
            ),
            const SizedBox(height: 10),
            PixelButton(label: 'โหลดเกม', expand: true, onPressed: openSlots),
            const SizedBox(height: 10),
            PixelButton(
              label: 'เครดิต',
              style: PixelButtonStyle.dark,
              expand: true,
              onPressed: () => infoDialog(context, 'Credits', const [
                'AQUA FARM: From Farm to Food',
                'โปรเจกต์ต้นแบบเกมจำลองฟาร์มปลา',
                'ค่าน้ำ ปลา และโภชนาการเป็นแบบจำลองเพื่อการเรียนรู้',
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
