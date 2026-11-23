import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';

/// Game Over — สุขภาพหมด (เกมที่จบไม่ถูกบันทึก จึงโหลดเซฟล่าสุดได้)
class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(gameProvider.notifier);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PixelScene(
            painterBuilder: (t) => FarmPainter(
              t,
              const FarmSceneData(damaged: true),
            ),
            cover: true,
            framed: false,
            alignment: const Alignment(-.12, 0),
          ),
          const ColoredBox(color: Color(0x991B120B)),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: BounceIn(
                  child: WoodPanel(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(Gap.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OutlinedText(
                          'Game Over',
                          size: 44,
                          color: AquaColors.red,
                        ),
                        const SizedBox(height: Gap.s),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PixelIcon('face', size: 56),
                            SizedBox(width: Gap.s),
                            PixelGlyph(
                              Glyph.heart,
                              size: 30,
                              color: AquaColors.creamDark,
                              outline: AquaColors.textSoft,
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.m),
                        const Bold(
                          'สุขภาพหมดเพราะขาดอาหารเป็นเวลานาน',
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: Gap.s),
                        const PaperCard(
                          child: Row(
                            children: [
                              PixelIcon('crate', size: 32),
                              SizedBox(width: Gap.s),
                              Expanded(
                                child: Text(
                                  'บทเรียน: เตรียมเสบียงถนอมอาหารไว้ก่อนภัยพิบัติ',
                                  style: TextStyle(
                                    fontSize: FontSize.body,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gap.l),
                        PixelButton(
                          label: 'โหลดเซฟล่าสุด',
                          icon: const PixelIcon('scroll', size: 24),
                          expand: true,
                          onPressed: () {
                            try {
                              if (!ctl.continueLatest()) {
                                toast(context, 'ยังไม่มีเซฟ', bad: true);
                              }
                            } on SaveException catch (e) {
                              toast(context, e.message, bad: true);
                            }
                          },
                        ),
                        const SizedBox(height: Gap.s),
                        PixelButton(
                          label: 'กลับเมนูหลัก',
                          icon: const PixelIcon('house', size: 24),
                          style: PixelButtonStyle.wood,
                          expand: true,
                          onPressed: ctl.close,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
