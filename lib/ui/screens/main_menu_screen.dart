import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import 'slots_screen.dart';

/// โลโก้เกม AQUA FARM (ใช้หน้าเมนูหลักและช่องบันทึก)
class AquaLogo extends StatelessWidget {
  const AquaLogo({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BounceIn(
            child: Bob(
              dy: 3,
              period: const Duration(milliseconds: 2400),
              child: OutlinedText(
                'AQUA FARM',
                size: size,
                stroke: size / 5,
              ),
            ),
          ),
          const SizedBox(height: Gap.xs),
          BounceIn(
            delay: const Duration(milliseconds: 180),
            child: PixelBox(
              fill: AquaColors.leaf,
              depth: 4,
              depthColor: AquaColors.grassDark,
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
              child: const Text(
                'From Farm to Food',
                style: TextStyle(
                  color: AquaColors.paper,
                  fontWeight: FontWeight.w700,
                  fontSize: FontSize.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ฉากฟาร์มเต็มพื้นที่ + โลโก้ลอยบนท้องฟ้า (หน้าเริ่มเกม)
class TitleBackdrop extends StatelessWidget {
  const TitleBackdrop({super.key, this.logoSize = 54});
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PixelScene(
          painterBuilder: (t) => FarmPainter(t, const FarmSceneData()),
          cover: true,
          framed: false,
          // ให้เห็นบ้าน ลังไม้ และร้านค้าเต็ม ๆ บนจอแนวตั้ง
          alignment: const Alignment(-.42, 0),
        ),
        Align(
          alignment: const Alignment(0, -.78),
          child: AquaLogo(size: logoSize),
        ),
      ],
    );
  }
}

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
    void openSlots() => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SlotsScreen()));
    return Scaffold(
      body: GrassBackground(
        child: Column(
          children: [
            const Expanded(child: TitleBackdrop()),
            Transform.translate(
              offset: const Offset(0, -26),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                child: WoodPanel(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(Gap.m),
                  child: Column(
                    children: [
                      PixelButton(
                        label: 'เกมใหม่',
                        icon: const PixelGlyph(
                          Glyph.plus,
                          size: 22,
                          color: AquaColors.paper,
                        ),
                        size: PixelButtonSize.large,
                        expand: true,
                        onPressed: openSlots,
                      ),
                      const SizedBox(height: Gap.m),
                      Row(
                        children: [
                          Expanded(
                            child: PixelButton(
                              label: 'เล่นต่อ',
                              icon: const PixelGlyph(
                                Glyph.arrowRight,
                                size: 20,
                                color: AquaColors.paper,
                              ),
                              style: PixelButtonStyle.green,
                              onPressed: () => _continue(context, ref),
                            ),
                          ),
                          const SizedBox(width: Gap.m),
                          Expanded(
                            child: PixelButton(
                              label: 'โหลดเกม',
                              icon: const PixelIcon('scroll', size: 24),
                              style: PixelButtonStyle.water,
                              onPressed: openSlots,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Gap.m),
                      PixelButton(
                        label: 'เครดิต',
                        icon: const PixelGlyph(
                          Glyph.star,
                          size: 20,
                          color: AquaColors.gold,
                        ),
                        style: PixelButtonStyle.wood,
                        expand: true,
                        onPressed: () => infoDialog(
                          context,
                          'Credits',
                          const [
                            'AQUA FARM: From Farm to Food',
                            'โปรเจกต์ต้นแบบเกมจำลองฟาร์มปลา',
                            'ค่าน้ำ ปลา และโภชนาการเป็นแบบจำลองเพื่อการเรียนรู้',
                            'ฟอนต์ Mali (SIL Open Font License)',
                          ],
                          icon: const PixelIcon('f_nila', size: 72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
