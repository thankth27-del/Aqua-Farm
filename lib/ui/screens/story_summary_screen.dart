import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../game/story.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../story_provider.dart';
import '../theme/theme.dart';
import '../widgets/story_talk_layer.dart';

/// บทที่ 7 สรุปเนื้อเรื่อง: เกรด S/A/B + ข้อความตอนจบ → ปลดล็อกโหมดเอาชีวิตรอด
/// ลุงทองเล่าตอนจบตามเกรด แล้วให้การ์ดใบสุดท้ายก่อน (ทับหน้าสรุป)
class StorySummaryScreen extends ConsumerWidget {
  const StorySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final grade = e.overallGrade;
    final stars = kGradePoints[grade] ?? 1;

    Widget row(Widget icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: icon)),
          const SizedBox(width: Gap.s),
          Expanded(child: Bold(label)),
          Bold(value, size: FontSize.label),
        ],
      ),
    );

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
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Responsive.maxPanel,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.l),
                  child: BounceIn(
                    child: WoodPanel(
                      key: const ValueKey('story-summary'),
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(Gap.l),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Bold(
                            'บทที่ $kStoryChapters/$kStoryChapters · สรุป',
                            align: TextAlign.center,
                          ),
                          const SizedBox(height: Gap.xs),
                          const Center(
                            child: OutlinedText('รอดน้ำท่วม!', size: 40),
                          ),
                          const SizedBox(height: Gap.m),
                          Semantics(
                            label: 'เกรดรวม $grade',
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var i = 0; i < 3; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      child: PixelGlyph(
                                        Glyph.star,
                                        size: 34,
                                        color: i < stars
                                            ? AquaColors.gold
                                            : AquaColors.creamDark,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: Gap.s),
                          Center(
                            child: OutlinedText(
                              'เกรด $grade',
                              key: const ValueKey('story-grade'),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: Gap.m),
                          PaperCard(
                            child: Text(
                              kStoryEnding[grade]!,
                              key: const ValueKey('story-ending'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: FontSize.label,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: AquaColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: Gap.s),
                          PaperCard(
                            child: Column(
                              children: [
                                row(
                                  const PixelIcon('cal', size: 22),
                                  'เล่นไป',
                                  '${s.day - 1} วัน',
                                ),
                                row(
                                  const PixelIcon('f_nila', size: 24),
                                  'ปลาในบ่อ',
                                  '${s.pond.length} ตัว',
                                ),
                                row(
                                  const PixelIcon('crate', size: 22),
                                  'เสบียงเหลือ',
                                  '${fmtNum(e.supplyDays)} วัน',
                                ),
                                row(
                                  const PixelIcon('coin', size: 22),
                                  'เงินคงเหลือ',
                                  '${s.money}฿',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Gap.m),
                          const Muted(
                            'ปลดล็อกโหมดเอาชีวิตรอดแล้ว! เลือกเล่น 20 / 30 / 60 วันได้ที่เมนูหลัก',
                            size: FontSize.body,
                            align: TextAlign.center,
                          ),
                          const SizedBox(height: Gap.m),
                          PixelButton(
                            key: const ValueKey('story-finish'),
                            label: 'กลับเมนูหลัก',
                            icon: const PixelIcon('house', size: 24),
                            expand: true,
                            onPressed: () =>
                                ref.read(storyProvider.notifier).finish(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ไม่มีแท็บให้เปิดในบทสรุป
          StoryTalkLayer(onOpenTab: (_) {}),
        ],
      ),
    );
  }
}
