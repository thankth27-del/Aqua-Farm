import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/game_engine.dart';
import '../../game/story.dart';
import '../providers.dart';
import '../story_provider.dart';
import '../theme/theme.dart';

/// เนื้อเรื่องที่กำลังเล่น (null = ไม่ใช่โหมดเนื้อเรื่อง)
(StoryProgress, GameEngine)? watchStory(WidgetRef ref) {
  final p = ref.watch(storyProvider);
  final g = ref.watch(gameProvider);
  if (p == null || g == null || g.slot != kStorySlot) return null;
  return (p, g.engine);
}

/// ครอบปุ่ม/ส่วนของจอในโหมดเนื้อเรื่อง:
/// - ปุ่มที่ต้องกดต่อไป → กรอบกะพริบ
/// - ปุ่มที่บทนี้ยังไม่เปิด → จางและกดไม่ได้ (หรือซ่อนเมื่อ [hide])
/// นอกโหมดเนื้อเรื่องแสดง [child] ตามปกติ
class StoryGate extends ConsumerWidget {
  const StoryGate({
    super.key,
    required this.target,
    required this.child,
    this.hide = false,
    this.pad = 4,
    this.point = true,
  });

  final StoryTarget target;
  final Widget child;

  /// ซ่อนทั้งส่วนเมื่อบทนี้ไม่เกี่ยว (ไม่ต้องเลื่อนจอผ่านของที่ยังไม่ใช้)
  final bool hide;

  /// ระยะกรอบกะพริบ
  final double pad;

  /// false = ล็อกอย่างเดียว ไม่กะพริบชี้ (เช่น ปุ่มสลับหน้าที่มีกรอบชี้ของตัวเอง)
  final bool point;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = watchStory(ref);
    if (story == null) return child;
    final (p, e) = story;
    if (!Story.allows(p, e, target)) {
      if (hide) return const SizedBox.shrink();
      return Semantics(
        enabled: false,
        child: IgnorePointer(
          child: Opacity(
            key: ValueKey('story-locked-${target.name}'),
            opacity: .35,
            child: child,
          ),
        ),
      );
    }
    return Spotlight(
      key: ValueKey('story-gate-${target.name}'),
      on: point && Story.nextTarget(p, e) == target,
      pad: pad,
      child: child,
    );
  }
}

/// แถบ "เป้าหมายบทนี้" ติดบนจอเสมอ: บท n/7 เป้าหมาย คำอธิบายสั้น ๆ
/// และปุ่มบทถัดไป / ลองบทนี้ใหม่
class StoryGoalBar extends ConsumerWidget {
  const StoryGoalBar({super.key, this.onChapterChanged});

  /// หลังเปลี่ยนบท (ให้หน้าเกมเปิดแท็บที่บทใหม่ใช้)
  final VoidCallback? onChapterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = watchStory(ref);
    if (story == null) return const SizedBox.shrink();
    final (p, e) = story;
    final ctl = ref.read(storyProvider.notifier);
    final spec = p.spec;
    final block = p.done || p.failed ? null : Story.endDayBlock(p, e);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, 0),
      child: PixelBox(
        key: const ValueKey('story-goal'),
        fill: p.failed
            ? AquaColors.redPale
            : (p.done ? AquaColors.leafLight : AquaColors.goldPale),
        depth: 4,
        depthColor: AquaColors.goldDark,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const PixelIcon('scroll', size: 22),
                const SizedBox(width: Gap.xs),
                Expanded(
                  child: Bold(
                    'บทที่ ${p.chapter}/$kStoryChapters · ${spec.title}',
                    size: FontSize.body,
                    maxLines: 1,
                  ),
                ),
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 1; i <= kStoryChapters; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: i < p.chapter
                                ? AquaColors.grass
                                : i == p.chapter
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
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 6),
                    child: PixelGlyph(
                      p.done ? Glyph.check : Glyph.arrowRight,
                      size: 14,
                      color: p.done ? AquaColors.grass : AquaColors.ink,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'เป้าหมาย: ${spec.goal}',
                      key: const ValueKey('story-goal-text'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AquaColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              p.failed
                  ? 'แพ้บทนี้: ${p.failReason}'
                  : p.done
                  ? 'ผ่านบทนี้แล้ว! กด "บทถัดไป"'
                  : (block ?? spec.hint),
              key: const ValueKey('story-hint'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: FontSize.small,
                height: 1.3,
                fontWeight: p.failed ? FontWeight.w700 : FontWeight.w500,
                color: p.failed ? AquaColors.red : AquaColors.textSoft,
              ),
            ),
            if (p.failed || (p.done && !p.finished)) ...[
              const SizedBox(height: Gap.xs),
              Spotlight(
                on: true,
                pad: 3,
                child: PixelButton(
                  key: ValueKey(p.failed ? 'story-retry' : 'story-next'),
                  label: p.failed ? 'ลองบทนี้ใหม่' : 'บทถัดไป',
                  style: p.failed
                      ? PixelButtonStyle.wood
                      : PixelButtonStyle.green,
                  expand: true,
                  trailing: const PixelGlyph(
                    Glyph.arrowRight,
                    size: 14,
                    color: AquaColors.paper,
                  ),
                  onPressed: () async {
                    await (p.failed ? ctl.retry() : ctl.next());
                    onChapterChanged?.call();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
