/// ชั้นบทสนทนาลุงทองบนหน้าเกม (โหมดเนื้อเรื่อง)
///
/// แสดงตาม [StoryTalk.next]: เปิดบท → (บท 4: สอน/ถาม/ชวนลอง ทีละวิธี) → ถามให้เลือก
/// → พูดก่อนทำสิ่งใหม่ → จบบท → การ์ดความรู้
/// บรรทัดที่ลุงพูดถึงสิ่งไหน → เปิดหน้านั้นให้ (เนื้อเรื่องไม่มีเมนูล่าง ลุงพาไปเอง)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/story_script.dart';
import '../../game/story.dart';
import '../../game/story_talk.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../story_provider.dart';
import '../theme/theme.dart';
import 'knowledge_card.dart';
import 'story_gate.dart';
import 'uncle_dialog.dart';

class StoryTalkLayer extends ConsumerStatefulWidget {
  const StoryTalkLayer({super.key, required this.onOpenTab});

  /// เปิดแท็บของสิ่งที่ลุงพูดถึง
  final ValueChanged<int> onOpenTab;

  @override
  ConsumerState<StoryTalkLayer> createState() => _StoryTalkLayerState();
}

class _StoryTalkLayerState extends ConsumerState<StoryTalkLayer> {
  /// ลุงตอบหลังผู้เล่นเลือก (แสดงก่อนทำผลของตัวเลือก)
  List<ScriptLine>? _reply;
  ChoiceEffect? _effect;

  /// กำลังรอหน้ายืนยันของผลตัวเลือก → ลุงยังไม่พูดเรื่องถัดไป
  bool _confirming = false;

  /// คำตอบที่กำลังแสดงมาจากปุ่ม "ขอคำใบ้" (ผู้เล่นขอเอง → ลุงพาไปหน้านั้นได้)
  bool _hint = false;

  /// ลุงพาไปหน้าที่พูดถึง — เฉพาะตอนผู้เล่นขอคำใบ้เอง
  /// บทพูดอื่นแค่ทำให้แท็บนั้นกะพริบ ไม่ดึงผู้เล่นไปหน้าอื่น
  void _point(ScriptLine l) {
    final t = l.point;
    final tab = t == null ? null : storyTabOf(t);
    if (tab != null) widget.onOpenTab(tab);
  }

  Future<void> _afterReply() async {
    final effect = _effect;
    setState(() {
      _reply = null;
      _effect = null;
      _hint = false;
      _confirming = effect != null;
    });
    if (effect == null) return;
    // ซื้อ/ขายต้องยืนยันก่อนเสมอ
    final ok = await confirmDialog(context, effect.confirm);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (!ok) return;
    final r = ref.read(gameProvider.notifier).run(effect.apply);
    if (mounted) showResult(context, r);
  }

  @override
  Widget build(BuildContext context) {
    // ปุ่มขอคำใบ้ → ลุงบอกสิ่งที่ต้องทำต่อ แล้วพาไปหน้านั้น
    ref.listen<int>(storyHintProvider, (_, _) {
      final p = ref.read(storyProvider);
      final g = ref.read(gameProvider);
      if (p == null || g == null) return;
      setState(() {
        _reply = StoryTalk.hint(p, g.engine);
        _effect = null;
        _hint = true;
      });
    });
    final story = watchStory(ref);
    if (story == null || _confirming) return const SizedBox.shrink();
    // มีแผ่นรายละเอียด/หน้าอื่นเปิดทับอยู่ → รอปิดก่อนแล้วลุงค่อยพูด (ไม่ให้กล่องถูกบัง)
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      return const SizedBox.shrink();
    }
    final (p, e) = story;
    final ctl = ref.read(storyProvider.notifier);

    final reply = _reply;
    if (reply != null) {
      return UncleTalkLayer(
        talk: UncleTalk(
          key: const ValueKey('talk-reply'),
          lines: reply,
          onLine: _hint ? _point : null,
          onDone: _afterReply,
        ),
      );
    }

    final cue = StoryTalk.next(p, e);
    if (cue == null) return const SizedBox.shrink();
    switch (cue.kind) {
      case TalkKind.card:
        return _CardLayer(
          card: cue.card!,
          chapter: p.chapter,
          onKeep: () => ctl.keepCard(cue.card!),
        );
      case TalkKind.choice:
        final c = cue.choice!;
        return UncleTalkLayer(
          talk: UncleTalk(
            key: ValueKey('talk-${p.chapter}-${cue.key}'),
            lines: cue.lines,
            options: [
              for (final o in c.options) UncleOption(o.label, detail: o.detail),
            ],
            onOption: (i) {
              final id = c.options[i].id;
              final effect = StoryTalk.effect(c.id, id, e);
              final lines = ctl.choose(c, id);
              setState(() {
                _reply = lines;
                _effect = effect;
              });
            },
          ),
        );
      case TalkKind.quiz:
        // ตอบผิด: ลุงอธิบาย แล้วถามข้อเดิมอีกครั้ง (ยังไม่ผ่าน next จึงคืนคำถามเดิม)
        return UncleTalkLayer(
          talk: UncleTalk(
            key: ValueKey('talk-${p.chapter}-${cue.key}'),
            lines: cue.lines,
            options: [for (final o in cue.quiz!.options) UncleOption(o.text)],
            onOption: (i) {
              final a = ctl.answer(cue, i);
              setState(() {
                _reply = a.explain;
                _effect = null;
              });
            },
          ),
        );
      case TalkKind.gift:
        return UncleTalkLayer(
          talk: UncleTalk(
            key: ValueKey('talk-${p.chapter}-${cue.key}'),
            lines: cue.lines,
            onDone: () {
              // จำว่าให้แล้ว (ของขวัญเปลี่ยนน้ำให้วันละครั้ง)
              ctl.hear(cue);
              final r = ref
                  .read(gameProvider.notifier)
                  .run((e) => Story.giveGift(e, cue.gift!));
              showResult(context, r);
            },
          ),
        );
      case TalkKind.intro ||
          TalkKind.target ||
          TalkKind.lesson ||
          TalkKind.done:
        return UncleTalkLayer(
          talk: UncleTalk(
            key: ValueKey('talk-${p.chapter}-${cue.key}'),
            lines: cue.lines,
            onDone: () => ctl.hear(cue),
          ),
        );
    }
  }
}

/// การ์ด "ลุงรู้มา" ท้ายบท + ปุ่มเก็บลงสมุดบันทึก
class _CardLayer extends StatelessWidget {
  const _CardLayer({
    required this.card,
    required this.chapter,
    required this.onKeep,
  });

  final KnowledgeCard card;
  final int chapter;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(dismissible: false, color: Color(0x990B2623)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              // การ์ดยาว (จอเตี้ย) เลื่อนดูได้ ปุ่มเก็บอยู่ใต้การ์ดบนจอเสมอ
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        child: BounceIn(
                          from: .6,
                          duration: const Duration(milliseconds: 400),
                          child: KnowledgeCardView(
                            card: card,
                            chapter: chapter,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    PixelButton(
                      key: const ValueKey('card-keep'),
                      label: 'เก็บลงสมุดบันทึกลุงทอง',
                      icon: const PixelIcon('scroll', size: 24),
                      size: PixelButtonSize.large,
                      expand: true,
                      onPressed: onKeep,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
