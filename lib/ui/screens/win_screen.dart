import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/summary_card.dart';

/// หน้าชนะ — รอดครบวันเป้าหมายของโหมด พร้อมคะแนนสรุป
/// (เกมที่จบไม่ถูกบันทึกทับเซฟเดิม)
class WinScreen extends ConsumerWidget {
  const WinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final sum = session.engine.summary;
    final ctl = ref.read(gameProvider.notifier);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PixelScene(
            painterBuilder: (t) => FarmPainter(t, const FarmSceneData()),
            cover: true,
            framed: false,
            alignment: const Alignment(-.12, 0),
          ),
          const ColoredBox(color: Color(0x661B120B)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.l),
                child: BounceIn(
                  child: WoodPanel(
                    key: const ValueKey('win'),
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(Gap.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: OutlinedText('ชนะ!', size: 48)),
                        const SizedBox(height: Gap.xs),
                        Bold(
                          'รอดครบ ${sum.targetDays} วัน',
                          size: FontSize.label + 2,
                          align: TextAlign.center,
                        ),
                        const SizedBox(height: Gap.s),
                        SummaryCard(summary: sum),
                        const SizedBox(height: Gap.l),
                        PixelButton(
                          label: 'กลับเมนูหลัก',
                          icon: const PixelIcon('house', size: 24),
                          style: PixelButtonStyle.green,
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
