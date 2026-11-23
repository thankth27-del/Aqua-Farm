import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/mode_dialog.dart';

/// หน้าชนะ — รอดครบวันเป้าหมายของโหมด พร้อมคะแนนสรุป
/// (เกมที่จบไม่ถูกบันทึกทับเซฟเดิม)
class WinScreen extends ConsumerWidget {
  const WinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final sum = session.engine.summary;
    final spec = kDifficulties[sum.mode]!;
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
                        Center(
                          child: Tag(
                            'โหมด${spec.name}',
                            color: modeColor(sum.mode),
                            textColor: AquaColors.paper,
                          ),
                        ),
                        const SizedBox(height: Gap.m),
                        _GradeBadge(grade: sum.grade),
                        const SizedBox(height: Gap.m),
                        PaperCard(
                          child: Column(
                            children: [
                              _Row(
                                icon: const PixelGlyph(
                                  Glyph.star,
                                  size: 22,
                                  color: AquaColors.gold,
                                ),
                                label: 'เกรดรวม',
                                value: sum.grade,
                              ),
                              _Row(
                                icon: const PixelIcon('warn', size: 24),
                                label: 'ภัยที่รอด',
                                value: '${sum.disastersSurvived} ครั้ง',
                              ),
                              _Row(
                                icon: const PixelIcon('coin', size: 24),
                                label: 'เงินคงเหลือ',
                                value: '${sum.money}฿',
                              ),
                              _Row(
                                icon: const PixelIcon('cal', size: 24),
                                label: 'จำนวนวัน',
                                value: '${sum.days}/${sum.targetDays} วัน',
                              ),
                            ],
                          ),
                        ),
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

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'เกรดรวม $grade',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: PixelGlyph(
                  Glyph.star,
                  size: 34,
                  color: i < (kGradePoints[grade] ?? 1)
                      ? AquaColors.gold
                      : AquaColors.creamDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 30, child: Center(child: icon)),
          const SizedBox(width: Gap.s),
          Expanded(child: Muted(label, size: FontSize.body)),
          Bold(value, size: FontSize.label),
        ],
      ),
    );
  }
}
