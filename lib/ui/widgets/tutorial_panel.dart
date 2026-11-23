import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/tutorial.dart';
import '../providers.dart';
import '../theme/theme.dart';

/// กล่องบทเรียน (div.tut ในต้นแบบ): บทเรียน n/9 จุดความคืบหน้า ข้อความ
/// และปุ่ม ย้อนกลับ / ถัดไป / ข้าม — ไม่แสดงเมื่อจบบทเรียนแล้ว
class TutorialPanel extends ConsumerWidget {
  const TutorialPanel({super.key, required this.screen});

  /// หน้าที่ผู้เล่นเปิดอยู่ ใช้ตรวจเงื่อนไขของขั้น
  final GameScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(gameProvider)!.engine;
    final step = e.tutorialStep;
    if (step == null) return const SizedBox.shrink();
    final ctl = ref.read(gameProvider.notifier);
    final s = e.state;

    // ต้นแบบตรวจเงื่อนไขทุกครั้งที่วาดจอ — ที่นี่ตรวจหลังวาดเสร็จ เพื่อไม่แก้สถานะระหว่าง build
    if (step.done != null && s.tutOk != s.tut && step.done!(e, screen)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ctl.update((e) => e.tutorialCheck(screen)),
      );
    }
    final canNext = e.tutorialCanNext || (step.done?.call(e, screen) ?? false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 0),
      child: PixelBox(
        key: const ValueKey('tutorial'),
        fill: AquaColors.goldPale,
        depth: 4,
        depthColor: AquaColors.goldDark,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PixelIcon('scroll', size: 24),
                const SizedBox(width: Gap.xs),
                Bold(
                  'บทเรียน ${s.tut + 1}/$kTutorialSteps',
                  size: FontSize.label,
                ),
                const Spacer(),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < kTutorialSteps; i++)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: i < s.tut
                                ? AquaColors.grass
                                : i == s.tut
                                ? AquaColors.gold
                                : AquaColors.paper,
                            border: Border.all(color: AquaColors.ink, width: 2),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                step.text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AquaColors.text,
                ),
              ),
            ),
            const SizedBox(height: Gap.s),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'ย้อนกลับ',
                    style: PixelButtonStyle.wood,
                    onPressed: s.tut > 0
                        ? () => ctl.update((e) => e.tutorialBack())
                        : null,
                  ),
                ),
                const SizedBox(width: Gap.xs),
                Expanded(
                  child: PixelButton(
                    label: 'ถัดไป',
                    style: PixelButtonStyle.green,
                    trailing: const PixelGlyph(
                      Glyph.arrowRight,
                      size: 14,
                      color: AquaColors.paper,
                    ),
                    onPressed: canNext
                        ? () => ctl.update((e) {
                            e.tutorialCheck(screen);
                            e.tutorialNext();
                          })
                        : null,
                  ),
                ),
                const SizedBox(width: Gap.xs),
                Expanded(
                  child: PixelButton(
                    label: 'ข้าม',
                    style: PixelButtonStyle.wood,
                    tooltip: 'ข้ามบทเรียน',
                    onPressed: () => ctl.update((e) => e.tutorialSkip()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
