/// ลำดับการพูดของลุงทองในเนื้อเรื่อง — ตรรกะล้วน ไม่ผูกกับ UI
///
/// [StoryTalk.next] บอกว่าตอนนี้ลุงควรพูดอะไร (null = ไม่ต้องพูด ให้ผู้เล่นทำต่อ)
/// UI แสดงตามนั้น แล้วบอกกลับผ่าน [StoryTalk.hear] / [StoryTalk.choose] / [StoryTalk.keepCard]
/// ผลของตัวเลือกใช้การกระทำที่มีอยู่ในเกม ([ChoiceEffect]) ไม่เพิ่มตัวเลขใหม่
library;

import '../data/equipment_data.dart';
import '../data/fish_data.dart';
import '../data/food_data.dart';
import '../data/story_script.dart';
import 'game_engine.dart';
import 'story.dart';

enum TalkKind {
  /// เปิดบท: เล่า "ทำไม"
  intro,

  /// ให้ผู้เล่นเลือก
  choice,

  /// ก่อนทำสิ่งหนึ่งครั้งแรกในบท (ไฮไลต์สิ่งนั้น)
  target,

  /// บท 4: สอน 1 วิธี / ชวนลองทำวิธีนั้น
  lesson,

  /// บท 4: คำถามสั้นหลังสอนแต่ละวิธี (ตอบผิด = ลุงอธิบาย แล้วถามใหม่)
  quiz,

  /// ทำเป้าหมายบทสำเร็จ
  done,

  /// การ์ดความรู้ "ลุงรู้มา" ท้ายบท
  card,
}

/// สิ่งที่ลุงจะพูด 1 ชุด
class TalkCue {
  const TalkCue(
    this.kind,
    this.key, {
    this.lines = const [],
    this.choice,
    this.card,
    this.target,
    this.quiz,
  });

  final TalkKind kind;

  /// รหัสใน [StoryProgress.heard] (ใช้เป็น key ของกล่องบทสนทนาด้วย)
  final String key;
  final List<ScriptLine> lines;
  final ChoiceScene? choice;
  final KnowledgeCard? card;
  final StoryTarget? target;
  final Quiz? quiz;
}

/// ผลการตอบคำถาม: ถูกไหม + ลุงอธิบาย (ถูก = ยิ้ม · ผิด = คิด ไม่ตำหนิ)
class QuizAnswer {
  const QuizAnswer(this.correct, this.explain);

  final bool correct;
  final List<ScriptLine> explain;
}

/// ผลจริงของตัวเลือก: ข้อความยืนยัน (ซื้อ/ขายต้องยืนยัน) + การกระทำในเกม
class ChoiceEffect {
  const ChoiceEffect(this.confirm, this.apply);

  final String confirm;
  final ActionResult Function(GameEngine e) apply;
}

abstract final class StoryTalk {
  /// ตอนนี้ลุงควรพูดอะไร
  static TalkCue? next(StoryProgress p, GameEngine e) {
    final sc = scriptOf(p.chapter);
    if (p.needsIntro) {
      return TalkCue(TalkKind.intro, 'intro', lines: sc.intro);
    }
    if (p.failed) return null;
    if (p.done) {
      if (!p.heard.contains('done')) {
        return TalkCue(TalkKind.done, 'done', lines: sc.onDone);
      }
      if (!p.cards.contains(sc.card.id)) {
        return TalkCue(TalkKind.card, 'card', card: sc.card);
      }
      return null;
    }
    // บท 4: สอนทีละวิธี → ถาม → ชวนลอง (ครบทุกวิธีก่อนให้เลือกวิธีแรก)
    for (final l in sc.lessons) {
      final m = l.method;
      if (!p.heard.contains('l:$m')) {
        return TalkCue(TalkKind.lesson, 'l:$m', lines: l.teach);
      }
      if (!p.heard.contains('q:$m')) {
        return TalkCue(
          TalkKind.quiz,
          'q:$m',
          lines: [ScriptLine(UncleMood.think, l.quiz.question)],
          quiz: l.quiz,
        );
      }
      if (!p.heard.contains('try:$m')) {
        return TalkCue(TalkKind.lesson, 'try:$m', lines: l.tryIt);
      }
    }
    final ch = sc.choice;
    if (ch != null && !p.choices.containsKey(ch.id) && _choiceDue(p, e)) {
      return TalkCue(
        TalkKind.choice,
        'choice:${ch.id}',
        lines: ch.ask,
        choice: ch,
      );
    }
    final t = Story.nextTarget(p, e);
    final lines = t == null ? null : sc.onTarget[t];
    if (t != null && lines != null && !p.heard.contains('t:${t.name}')) {
      return TalkCue(TalkKind.target, 't:${t.name}', lines: lines, target: t);
    }
    return null;
  }

  /// ถึงเวลาถามของแต่ละบทหรือยัง
  static bool _choiceDue(StoryProgress p, GameEngine e) => switch (p.chapter) {
    // บท 1: ก่อนซื้อปลา (บ่อยังไม่ครบ)
    1 => e.state.pond.length < kStoryPondFish,
    // บท 2: จับปลาได้แล้ว ก่อนขาย
    2 => e.fishTotal > 0 && e.state.earned == 0,
    // บท 4: เรียนครบทุกวิธีแล้ว ยังไม่ได้เริ่มถนอม
    4 => e.state.processing.isEmpty,
    _ => false,
  };

  /// ลุงพูดชุดนี้จบแล้ว
  static void hear(StoryProgress p, TalkCue cue) {
    if (cue.kind == TalkKind.intro) {
      p.talked = p.chapter;
    } else {
      p.heard.add(cue.key);
    }
  }

  /// ผู้เล่นเลือกแล้ว → จำไว้ คืนบทพูดที่ลุงตอบ
  static List<ScriptLine> choose(StoryProgress p, ChoiceScene c, String id) {
    p.choices[c.id] = id;
    return c.options.firstWhere((o) => o.id == id).reply;
  }

  /// ตอบคำถามข้อ [index]: ถูก → ผ่านคำถามนี้ · ผิด → ยังไม่ผ่าน (ถามใหม่ได้ ไม่มีโทษ)
  static QuizAnswer answer(StoryProgress p, TalkCue cue, int index) {
    final o = cue.quiz!.options[index];
    if (o.correct) p.heard.add(cue.key);
    return QuizAnswer(o.correct, [
      ScriptLine(o.correct ? UncleMood.smile : UncleMood.think, o.explain),
    ]);
  }

  /// เก็บการ์ดลงสมุดบันทึกลุงทอง
  static void keepCard(StoryProgress p, KnowledgeCard card) {
    if (!p.cards.contains(card.id)) p.cards.add(card.id);
  }

  /// ผลจริงของตัวเลือก (null = ไม่มีผลทันที หรือทำไม่ได้ตอนนี้)
  static ChoiceEffect? effect(String choice, String option, GameEngine e) {
    final s = e.state;
    switch ((choice, option)) {
      // บท 1: ซื้อปลาที่เลือกให้ครบบ่อของบท
      case ('fish', final id) when kFish.containsKey(id):
        final n = kStoryPondFish - s.pond.length;
        if (n <= 0) return null;
        final f = kFish[id]!;
        return ChoiceEffect(
          'ซื้อ${f.name} $n ตัว ราคา ${f.buyPrice * n}฿ ปล่อยลงบ่อ?',
          (e) => e.buyFish(id, n),
        );
      // บท 2: ขาย 1 ตัว หรือขายทั้งหมด
      case ('sell', 'sell_one' || 'sell_all'):
        final all = option == 'sell_all';
        final types = [
          for (final k in kFish.keys)
            for (var i = 0; i < (s.fishStock[k] ?? 0); i++) k,
        ];
        if (types.isEmpty) return null;
        final sold = all ? types : [types.first];
        final total = sold.fold(0, (a, k) => a + e.fishSellPrice(k));
        return ChoiceEffect(
          all
              ? 'ขายปลาทั้งหมด ${sold.length} ตัว ได้ $total฿?'
              : 'ขาย${kFish[sold.first]!.name} 1 ตัว ได้ $total฿?',
          (e) {
            ActionResult r = const ActionResult.fail('ไม่มีปลาให้ขาย');
            var got = 0;
            for (final k in sold) {
              final price = e.fishSellPrice(k);
              r = e.sellFish(k);
              if (!r.ok) return r;
              got += price;
            }
            return sold.length == 1
                ? r
                : ActionResult.ok('ขายปลา ${sold.length} ตัว +$got บาท');
          },
        );
      // บท 4: วิธีที่เลือก → ซื้ออุปกรณ์ของวิธีนั้น (ถ้ายังไม่มี)
      case ('method', final id) when kPreserveMethods.containsKey(id):
        final tool = kPreserveMethods[id]!.equipment;
        if (s.equipmentCount(tool) > 0) return null;
        final price = e.equipmentPrice(tool);
        return ChoiceEffect(
          'ซื้อ${kEquipment[tool]!.name} ราคา $price฿ ไว้${kFoods[id]!.name}?',
          (e) => e.buyEquipment(tool),
        );
    }
    return null;
  }
}
