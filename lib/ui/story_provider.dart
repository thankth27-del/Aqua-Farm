/// Riverpod: ควบคุมโหมดเนื้อเรื่อง (บทปัจจุบัน เงื่อนไขผ่านบท เซฟ/โหลด ปลดล็อก)
///
/// ตรรกะบทอยู่ใน lib/game/story.dart ที่นี่แค่เชื่อมกับ [gameProvider] และเซฟ
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_engine.dart';
import '../game/game_state.dart';
import '../data/story_script.dart';
import '../game/story.dart';
import '../game/story_talk.dart';
import 'providers.dart';

/// Random ของเนื้อเรื่อง (override ในเทสต์ให้ผลแน่นอน)
final storyRandomProvider = Provider<Random?>((ref) => null);

/// โหมดเอาชีวิตรอดปลดล็อกแล้วหรือยัง (เล่นเนื้อเรื่องจบ)
final survivalUnlockedProvider = Provider<bool>((ref) {
  ref.watch(storyProvider);
  return ref.read(saveRepositoryProvider).survivalUnlocked;
});

/// มีเนื้อเรื่องเล่นค้างอยู่ไหม
final storySavedProvider = Provider<bool>((ref) {
  ref.watch(storyProvider);
  return ref.read(saveRepositoryProvider).hasStory;
});

class StoryController extends Notifier<StoryProgress?> {
  @override
  StoryProgress? build() {
    // ทุกการกระทำในเกม → ตรวจเป้าหมายบทแล้วเซฟ
    ref.listen<GameSession?>(gameProvider, (prev, next) {
      final p = state;
      if (p == null || next == null || next.slot != kStorySlot) return;
      if (Story.check(p, next.engine)) state = p.copy();
      _save();
    });
    return null;
  }

  GameController get _game => ref.read(gameProvider.notifier);

  GameEngine? get _engine {
    final s = ref.read(gameProvider);
    return s != null && s.slot == kStorySlot ? s.engine : null;
  }

  void _attach(GameEngine e) =>
      _game.attachStory(e, afterDay: afterDay, onExit: exit);

  Future<void> _save() async {
    final p = state;
    final e = _engine;
    if (p == null || e == null) return;
    await ref.read(saveRepositoryProvider).saveStory(p, e.state);
  }

  /// เริ่มเนื้อเรื่องใหม่ตั้งแต่บท 1 (ทับของเดิม)
  Future<void> startNew() async {
    final e = Story.newEngine(random: ref.read(storyRandomProvider));
    state = Story.start(e);
    _attach(e);
    await _save();
  }

  /// เล่นเนื้อเรื่องต่อจากเซฟ — false ถ้าไม่มีเซฟ
  bool resume() {
    final saved = ref.read(saveRepositoryProvider).loadStory();
    if (saved == null) return false;
    final (p, s) = saved;
    final e = GameEngine(s, random: ref.read(storyRandomProvider))..calcWater();
    // เซฟรุ่นเก่า: เปิด/ปิดโรคปลาตามบท
    Story.check(p, e);
    state = p;
    _attach(e);
    return true;
  }

  /// หลังจบวัน (GameController เรียกก่อนวาดหน้าใหม่)
  Future<void> afterDay(DayReport r) async {
    final p = state;
    final e = _engine;
    if (p == null || e == null) return;
    Story.afterDay(p, e, r);
    state = p.copy();
    await _save();
  }

  /// ลุงพูดชุดนี้จบแล้ว
  Future<void> hear(TalkCue cue) async {
    final p = state;
    if (p == null) return;
    StoryTalk.hear(p, cue);
    state = p.copy();
    await _save();
  }

  /// ผู้เล่นเลือกตัวเลือก → คืนบทที่ลุงตอบ
  List<ScriptLine> choose(ChoiceScene c, String id) {
    final p = state;
    if (p == null) return const [];
    final reply = StoryTalk.choose(p, c, id);
    state = p.copy();
    _save();
    return reply;
  }

  /// ตอบคำถามบทเรียนย่อย → คืนคำอธิบายของลุง (ผิดก็ไม่มีโทษ ถามข้อเดิมใหม่)
  QuizAnswer answer(TalkCue cue, int index) {
    final p = state;
    final a = StoryTalk.answer(p!, cue, index);
    state = p.copy();
    _save();
    return a;
  }

  /// เก็บการ์ดความรู้ลงสมุดบันทึก
  Future<void> keepCard(KnowledgeCard card) async {
    final p = state;
    if (p == null) return;
    StoryTalk.keepCard(p, card);
    state = p.copy();
    await _save();
  }

  /// ไปบทถัดไป
  Future<void> next() async {
    final p = state;
    final e = _engine;
    if (p == null || e == null || !Story.next(p, e)) return;
    state = p.copy();
    _game.update((_) {});
    await _save();
  }

  /// ลองบทนี้ใหม่ (คืนสถานะตอนเริ่มบท)
  Future<void> retry() async {
    final p = state;
    if (p == null || !p.failed) return;
    final e = Story.retry(p, random: ref.read(storyRandomProvider));
    state = p.copy();
    _attach(e);
    await _save();
  }

  /// จบเนื้อเรื่อง: ปลดล็อกโหมดเอาชีวิตรอด ลบเซฟเนื้อเรื่อง กลับเมนู
  Future<void> finish() async {
    final p = state;
    if (p == null || !p.finished) return;
    final repo = ref.read(saveRepositoryProvider);
    await repo.setSurvivalUnlocked(true);
    await repo.deleteStory();
    _game.close();
    state = null;
  }

  /// ออกไปเมนูหลัก (เซฟไว้เล่นต่อ)
  Future<void> exit() async {
    await _save();
    _game.close();
    state = null;
  }
}

final storyProvider = NotifierProvider<StoryController, StoryProgress?>(
  StoryController.new,
);

/// ปุ่ม "ขอคำใบ้จากลุงทอง" — เพิ่มค่าทุกครั้งที่กด ชั้นบทสนทนาฟังแล้วให้ลุงพูดคำใบ้
class StoryHintRequest extends Notifier<int> {
  @override
  int build() => 0;

  void ask() => state++;
}

final storyHintProvider = NotifierProvider<StoryHintRequest, int>(
  StoryHintRequest.new,
);
