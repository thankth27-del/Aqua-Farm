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

  /// บทเรียนย่อย (บทคุณภาพน้ำ/ถนอมอาหาร/ปลาป่วย): สอน 1 เรื่อง / ชวนลองทำ
  lesson,

  /// คำถามสั้นหลังบทเรียนย่อย (ตอบผิด = ลุงอธิบาย แล้วถามใหม่)
  quiz,

  /// ทำเป้าหมายบทสำเร็จ
  done,

  /// การ์ดความรู้ "ลุงรู้มา" ท้ายบท
  card,

  /// เงินไม่พอซื้อของที่บทนี้ต้องใช้ → ลุงให้ฟรี (UI ให้ของเมื่อฟังจบ)
  gift,
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
    this.gift,
  });

  final TalkKind kind;

  /// รหัสใน [StoryProgress.heard] (ใช้เป็น key ของกล่องบทสนทนาด้วย)
  final String key;
  final List<ScriptLine> lines;
  final ChoiceScene? choice;
  final KnowledgeCard? card;
  final StoryTarget? target;
  final Quiz? quiz;

  /// ของที่ลุงให้ฟรี (เฉพาะ [TalkKind.gift])
  final Map<String, int>? gift;
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
    if (p.failed) {
      // แพ้: ลุงไม่โทษ ชวนดูว่าครั้งหน้าทำอะไรได้ (พูดครั้งเดียว)
      if (sc.onFail.isNotEmpty && !p.heard.contains('fail')) {
        return TalkCue(TalkKind.done, 'fail', lines: sc.onFail);
      }
      return null;
    }
    if (p.done) {
      // บทสรุป: ตอนจบตามเกรดรวม + ปลดล็อกโหมดเอาชีวิตรอด
      if (p.chapter == kStoryChapters && !p.heard.contains('ending')) {
        final g = kStoryEndingScript.containsKey(e.overallGrade)
            ? e.overallGrade
            : 'B';
        return TalkCue(
          TalkKind.done,
          'ending',
          lines: [...kStoryEndingScript[g]!, ...kStoryUnlockScript],
        );
      }
      if (!p.heard.contains('done')) {
        return TalkCue(TalkKind.done, 'done', lines: sc.onDone);
      }
      if (!p.cards.contains(sc.card.id)) {
        return TalkCue(TalkKind.card, 'card', card: sc.card);
      }
      return null;
    }
    // บทเรียนย่อย: สอนทีละเรื่อง → ถาม → ชวนลอง (ครบทุกเรื่องก่อนให้เลือก)
    for (final l in sc.lessons) {
      final m = l.id;
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
    // บทภัยจริง: เปิดภัยด้วยการดูว่าเตรียมพร้อมแค่ไหน (ไม่ตำหนิ มีทางแก้ให้)
    final prep = Story.prepared(e) ? sc.ready : sc.notReady;
    if (prep.isNotEmpty && !p.heard.contains('prep')) {
      return TalkCue(TalkKind.target, 'prep', lines: prep);
    }
    // บทภัยจริง: ลุงพูดก่อนแต่ละวันของน้ำท่วม
    final day = p.chapter == StoryCh.disaster ? Story.floodDayAhead(e) : null;
    final dayLines = day == null ? null : sc.dayLines[day];
    if (dayLines != null && !p.heard.contains('day:$day')) {
      return TalkCue(TalkKind.target, 'day:$day', lines: dayLines);
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
    // เงินไม่พอซื้อของที่ต้องใช้ → ลุงให้ฟรี ผู้เล่นไม่ค้าง
    final gift = Story.giftNeeded(p, e);
    if (gift != null) {
      return TalkCue(
        TalkKind.gift,
        'gift:${gift.keys.join(',')}',
        lines: [
          ScriptLine(
            UncleMood.smile,
            gift.keys.any(kFoods.containsKey)
                ? 'ของกินจะไม่พอใช่ไหม ลุงมี${Story.itemsText(gift)} จาน แบ่งให้ฟรีเลย ไว้ตั้งตัวได้ค่อยถนอมปลาเก็บเองนะ'
                : 'เงินไม่พอซื้อ${Story.itemsText(gift)} ใช่ไหม ไม่เป็นไร ลุงมีเหลือ แบ่งให้ฟรีเลย',
          ),
        ],
        gift: gift,
      );
    }
    // น้ำแย่ เงินไม่พอเปลี่ยนน้ำ → ลุงช่วยเปลี่ยนให้ (วันละครั้ง)
    if (Story.waterGiftNeeded(p, e)) {
      return TalkCue(
        TalkKind.gift,
        Story.waterGiftKey(e),
        lines: const [
          ScriptLine(
            UncleMood.worry,
            'น้ำเริ่มแย่ แต่เงินไม่พอเปลี่ยนน้ำใช่ไหม ลุงช่วยเปลี่ยนให้ก่อน ขายปลาได้แล้วค่อยเปลี่ยนเองนะ',
          ),
        ],
        gift: const {Story.kWaterGift: 1},
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
    // บทลงบ่อ: ก่อนซื้อปลา (บ่อยังไม่ครบ)
    StoryCh.farm => e.state.pond.length < kStoryPondFish,
    // บทตลาด: จับปลาได้แล้ว ก่อนขาย
    StoryCh.market => e.fishTotal > 0 && e.state.earned == 0,
    // บทถนอมอาหาร: เรียนครบทุกวิธีแล้ว ยังไม่ได้เริ่มถนอม
    StoryCh.preserve => e.state.processing.isEmpty,
    // บทภัยจริง: ไฟดับ และมีทั้งอาหารสุกและของถนอมให้เลือกกิน
    StoryCh.disaster =>
      !e.state.power &&
          _edibleOf(e, FoodKind.meal) >= 0 &&
          _edibleOf(e, FoodKind.preserved) >= 0,
    _ => false,
  };

  /// ช่องในคลังของอาหารประเภท [kind] ที่ยังกินได้ (-1 = ไม่มี)
  static int _edibleOf(GameEngine e, FoodKind kind) {
    final st = e.state.stock;
    for (var i = 0; i < st.length; i++) {
      if (kFoods[st[i].food]!.kind == kind && !e.isExpired(st[i])) return i;
    }
    return -1;
  }

  /// ปุ่ม "ขอคำใบ้จากลุงทอง": บอกว่าต้องทำอะไรต่อ (บรรทัดที่ชี้สิ่งของ → UI พาไปหน้านั้น)
  static List<ScriptLine> hint(StoryProgress p, GameEngine e) {
    const s = UncleMood.smile;
    final t = Story.nextTarget(p, e);
    final m = Story.missing(p, e);
    final need = Story.itemsText(m);
    final method = kPreserveMethods[Story.preserveMethod(p)]!;
    final text = switch (t) {
      StoryTarget.retry => 'ไม่เป็นไรนะ กด "ลองบทนี้ใหม่" แล้วลองอีกครั้ง',
      StoryTarget.next => 'ผ่านแล้ว! กด "บทถัดไป" ด้านบนได้เลย',
      StoryTarget.eat => 'หิวแล้วนะหลาน ไปที่คลัง กินอาหารก่อน',
      StoryTarget.buyFish => 'บ่อยังว่าง ไปหน้าปลา เปิดร้านปลา ซื้อปลาลงบ่อ',
      StoryTarget.feed => 'ไปหน้าปลา กด "ให้อาหาร" ก่อนนะ',
      StoryTarget.water =>
        'น้ำในบ่อเริ่มแย่ ไปหน้าปลา กด "ดูแลน้ำ" ล้างตัวกรองหรือเปลี่ยนน้ำ',
      StoryTarget.catchFish => 'ปลาโตแล้ว ไปหน้าปลา กด "จับปลา"',
      StoryTarget.sellFish => 'ไปตลาด กด "ขาย" แล้วขายปลาในคลัง',
      StoryTarget.buyIngredient =>
        'ไปตลาด ซื้อ${need.isEmpty ? 'เครื่องปรุง' : need} ก่อน',
      StoryTarget.buyTool =>
        'ไปตลาด หมวดอุปกรณ์ครัว ซื้อ${need.isEmpty ? 'อุปกรณ์ถนอม' : need}',
      StoryTarget.cook => 'ของครบแล้ว ไปครัว ทำอาหารจากปลาในคลัง',
      StoryTarget.preserve =>
        'ของครบแล้ว ไปครัว เลือก "ถนอม" แล้วกด${method.name.split(' ').first}',
      StoryTarget.buyMedicine =>
        'ไปตลาด กด "อุปกรณ์และยาปลา" ซื้อ${need.isEmpty ? 'ยาที่ตรงกับโรค' : need}',
      StoryTarget.treat => 'มียาแล้ว ไปหน้าปลา กด "รักษาปลา" เลือกตัวที่ป่วย แล้วเลือกยาที่ตรงอาการ',
      StoryTarget.buyEquipment =>
        'ไปหน้าฟาร์ม ส่วนเตรียมภัย ซื้อ${need.isEmpty ? 'อุปกรณ์กันน้ำท่วม' : need}',
      StoryTarget.endDay => 'ตอนนี้ทำได้ครบแล้ว กด "จบวัน" เพื่อไปวันถัดไป',
      _ => Story.situationHint(p, e) ?? p.spec.hint,
    };
    return [ScriptLine(s, text, point: t)];
  }

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
      // บทลงบ่อ: ซื้อปลาที่เลือกให้ครบบ่อของบท
      case ('fish', final id) when kFish.containsKey(id):
        final n = kStoryPondFish - s.pond.length;
        if (n <= 0) return null;
        final f = kFish[id]!;
        return ChoiceEffect(
          'ซื้อ${f.name} $n ตัว ราคา ${f.buyPrice * n}฿ ปล่อยลงบ่อ?',
          (e) => e.buyFish(id, n),
        );
      // บทตลาด: ขาย 1 ตัว หรือขายทั้งหมด
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
      // บทถนอมอาหาร: วิธีที่เลือก → ซื้ออุปกรณ์ของวิธีนั้น (ถ้ายังไม่มี)
      case ('method', final id) when kPreserveMethods.containsKey(id):
        final tool = kPreserveMethods[id]!.equipment;
        if (s.equipmentCount(tool) > 0) return null;
        final price = e.equipmentPrice(tool);
        return ChoiceEffect(
          'ซื้อ${kEquipment[tool]!.name} ราคา $price฿ ไว้${kFoods[id]!.name}?',
          (e) => e.buyEquipment(tool),
        );
      // บทภัยจริง: กินอาหารประเภทที่เลือก 1 จาน (อิ่มแล้ว = แค่จำคำตอบ)
      case ('eat_order', 'fresh_first' || 'preserved_first'):
        if (s.hunger >= 100) return null;
        final kind = option == 'fresh_first'
            ? FoodKind.meal
            : FoodKind.preserved;
        final i = _edibleOf(e, kind);
        if (i < 0) return null;
        final food = kFoods[s.stock[i].food]!.name;
        return ChoiceEffect('กิน$food 1 จาน?', (e) {
          final j = _edibleOf(e, kind);
          return j < 0
              ? const ActionResult.fail('ไม่มีอาหารให้กิน')
              : e.eatStock(j);
        });
    }
    return null;
  }
}
