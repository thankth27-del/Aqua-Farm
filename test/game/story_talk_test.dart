import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/equipment_data.dart';
import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/story_script.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/game/story_talk.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late StoryProgress p;
  late GameEngine e;

  setUp(() {
    e = Story.newEngine(random: FixedRandom());
    p = Story.start(e);
  });

  TalkCue cue() => StoryTalk.next(p, e)!;

  test('บท 1: เล่าเปิดบท → ถามเลือกปลา → ลุงสอนก่อนทำสิ่งใหม่ทีละอย่าง', () {
    expect(cue().kind, TalkKind.intro);
    expect(cue().lines, scriptOf(1).intro);
    StoryTalk.hear(p, cue());
    expect(p.needsIntro, isFalse);

    final c = cue();
    expect(c.kind, TalkKind.choice);
    expect(c.choice!.id, 'fish');
    final reply = StoryTalk.choose(p, c.choice!, 'nila');
    expect(reply, isNotEmpty);
    expect(p.choices, {'fish': 'nila'});

    // ผลจริง: ซื้อปลาที่เลือกให้ครบบ่อของบท (ต้องยืนยันก่อน)
    final fx = StoryTalk.effect('fish', 'nila', e)!;
    expect(fx.confirm, contains('ปลานิล 3 ตัว'));
    final money = e.state.money;
    expect(fx.apply(e).ok, isTrue);
    expect(e.state.pond.length, kStoryPondFish);
    expect(e.state.money, money - kFish['nila']!.buyPrice * kStoryPondFish);

    // ถัดไป: สอนให้อาหาร (ไฮไลต์ปุ่มให้อาหาร) แล้วไม่พูดซ้ำ
    final feed = cue();
    expect(feed.kind, TalkKind.target);
    expect(feed.target, StoryTarget.feed);
    expect(feed.lines.first.point, StoryTarget.feed);
    StoryTalk.hear(p, feed);
    e.feed(2);
    final end = cue();
    expect(end.target, StoryTarget.endDay);
    StoryTalk.hear(p, end);
    expect(StoryTalk.next(p, e), isNull);
  });

  test('บท 1: ซื้อปลาเองครบแล้ว → ไม่ถามเลือกปลา', () {
    StoryTalk.hear(p, cue());
    e.buyFish('dook', 3);
    expect(cue().kind, TalkKind.target);
    expect(StoryTalk.effect('fish', 'nila', e), isNull);
  });

  test(
    'จบบท: ลุงชม → การ์ดความรู้ → เก็บลงสมุด แล้วเงียบ · บทใหม่เริ่มฟังใหม่',
    () {
      StoryTalk.hear(p, cue());
      e.buyFish('nila', 3);
      e.state.day = p.startDay + kStoryCareDays;
      expect(Story.check(p, e), isTrue);
      expect(cue().kind, TalkKind.done);
      StoryTalk.hear(p, cue());
      final card = cue();
      expect(card.kind, TalkKind.card);
      expect(card.card!.id, 'fish');
      StoryTalk.keepCard(p, card.card!);
      expect(p.cards, ['fish']);
      expect(StoryTalk.next(p, e), isNull);

      Story.next(p, e);
      expect(p.chapter, 2);
      expect(p.heard, isEmpty);
      expect(cue().kind, TalkKind.intro);
      expect(p.cards, ['fish'], reason: 'สมุดบันทึกเก็บข้ามบท');
    },
  );

  test('บทตลาด: จับปลาได้แล้วถามขาย 1 ตัว/ขายหมด ผลขายจริงตามที่เลือก', () {
    p
      ..chapter = StoryCh.market
      ..talked = StoryCh.market;
    e.state.fishStock['nila'] = 2;
    e.state.fishStock['dook'] = 1;
    final c = cue();
    expect(c.kind, TalkKind.choice);
    expect(c.choice!.id, 'sell');

    final one = StoryTalk.effect('sell', 'sell_one', e)!;
    expect(one.confirm, contains('1 ตัว'));
    final all = StoryTalk.effect('sell', 'sell_all', e)!;
    expect(all.confirm, contains('ทั้งหมด 3 ตัว'));

    final money = e.state.money;
    expect(all.apply(e).ok, isTrue);
    expect(e.fishTotal, 0);
    expect(e.state.money, greaterThan(money));
    expect(e.state.earned, e.state.money - money);
  });

  test('บทถนอมอาหาร: สอน→ถาม→ชวนลอง ทีละวิธี · ตอบผิดไม่ผ่านแต่ถามซ้ำ · ครบแล้วถามวิธีแรก', () {
    p
      ..chapter = StoryCh.preserve
      ..talked = StoryCh.preserve;
    final lessons = scriptOf(StoryCh.preserve).lessons;
    expect(lessons.map((l) => l.id), kPreserveMethods.keys.toList());
    for (final l in lessons) {
      final teach = cue();
      expect(teach.kind, TalkKind.lesson);
      expect(teach.lines, l.teach);
      StoryTalk.hear(p, teach);

      final q = cue();
      expect(q.kind, TalkKind.quiz);
      expect(q.lines.single.text, l.quiz.question);
      final right = l.quiz.options.indexWhere((o) => o.correct);
      final wrong = l.quiz.options.indexWhere((o) => !o.correct);
      final miss = StoryTalk.answer(p, q, wrong);
      expect(miss.correct, isFalse);
      expect(miss.explain.single.mood, UncleMood.think);
      expect(cue().key, q.key, reason: 'ตอบผิด → ถามข้อเดิมใหม่');
      final money = e.state.money;
      final hit = StoryTalk.answer(p, q, right);
      expect(hit.correct, isTrue);
      expect(e.state.money, money, reason: 'ไม่มีโทษ/รางวัลเป็นเงิน');

      final tryIt = cue();
      expect(tryIt.kind, TalkKind.lesson);
      expect(tryIt.lines, l.tryIt);
      StoryTalk.hear(p, tryIt);
    }
    final c = cue();
    expect(c.kind, TalkKind.choice);
    expect(c.choice!.id, 'method');
  });

  test('บท 4: เลือกวิธี = ซื้ออุปกรณ์ของวิธีนั้น (มีแล้วไม่ซื้อซ้ำ)', () {
    for (final id in kPreserveMethods.keys) {
      final tool = kPreserveMethods[id]!.equipment;
      final fx = StoryTalk.effect('method', id, e)!;
      expect(fx.confirm, contains(kEquipment[tool]!.name));
      expect(fx.confirm, contains(kFoods[id]!.name));
    }
    e.state.money = 100000;
    final tool = kPreserveMethods['dried']!.equipment;
    expect(StoryTalk.effect('method', 'dried', e)!.apply(e).ok, isTrue);
    expect(e.state.equipmentCount(tool), 1);
    expect(StoryTalk.effect('method', 'dried', e), isNull);
  });

  /// เข้าบทภัยจริงตามทางปกติ (บทคำเตือนประกาศน้ำท่วมล่วงหน้า) แล้วฟังเปิดบท
  void toDisaster() {
    p
      ..chapter = StoryCh.sick
      ..done = true;
    Story.next(p, e);
    p.done = true;
    Story.next(p, e);
    expect(p.chapter, StoryCh.disaster);
    StoryTalk.hear(p, cue());
  }

  test('บทภัยจริง: เตรียมไม่พอ → ลุงไม่ตำหนิ ให้ทางแก้ · ลุงพูดก่อนแต่ละวันน้ำท่วม', () {
    toDisaster();
    final prep = cue();
    expect(prep.key, 'prep');
    expect(prep.lines, scriptOf(StoryCh.disaster).notReady);
    StoryTalk.hear(p, prep);

    // คืนก่อนน้ำมา: ลุงพูดเรื่องวันแรก
    final up = e.state.upcoming!;
    e.state.day = up.startDay - 1;
    expect(Story.floodDayAhead(e), 0);
    final d0 = cue();
    expect(d0.key, 'day:0');
    expect(d0.lines, scriptOf(StoryCh.disaster).dayLines[0]);
    StoryTalk.hear(p, d0);

    // ระหว่างน้ำท่วม: วันที่ i ผ่านแล้ว → ลุงพูดเรื่องวันถัดไป
    e.state.active = ActiveDisaster(
      type: up.type,
      duration: 4,
      severity: up.severity,
      fishBefore: 3,
      dayIndex: 1,
    );
    expect(Story.floodDayAhead(e), 2);
    expect(cue().key, 'day:2');
    e.state.active!.dayIndex = 3;
    expect(Story.floodDayAhead(e), isNull, reason: 'น้ำลดแล้ว');
  });

  test('บทภัยจริง: เตรียมพร้อม → ลุงพูดชุด "พร้อมดี"', () {
    final tool = kDisasters[kStoryDisaster]!.equipment.keys.first;
    e.state.equipment[tool] = 1;
    e.state.stock.add(StockBatch(food: 'canned', qty: 20));
    toDisaster();
    expect(Story.prepared(e), isTrue);
    expect(cue().lines, scriptOf(StoryCh.disaster).ready);
  });

  test(
    'บทภัยจริง: ไฟดับ มีทั้งอาหารสุกและของถนอม → ถามกินอะไรก่อน ผลคือกินจริง',
    () {
      toDisaster();
      StoryTalk.hear(p, cue()); // prep
      e.state
        ..power = false
        ..hunger = 50
        ..stock.addAll([
          StockBatch(food: 'salted', qty: 1),
          StockBatch(food: 'fry', qty: 1),
        ]);
      final c = cue();
      expect(c.kind, TalkKind.choice);
      expect(c.choice!.id, 'eat_order');
      final fx = StoryTalk.effect('eat_order', 'fresh_first', e)!;
      expect(fx.confirm, contains(kFoods['fry']!.name));
      expect(fx.apply(e).ok, isTrue);
      expect(e.state.stock.map((b) => b.food), isNot(contains('fry')));
      expect(e.state.hunger, greaterThan(50));
      // อิ่มแล้ว: เลือกได้ แต่ไม่มีผลกิน
      e.state.hunger = 100;
      expect(StoryTalk.effect('eat_order', 'preserved_first', e), isNull);
    },
  );

  test('บทภัยจริง แพ้: ลุงพูดให้กำลังใจครั้งเดียว แล้วรอผู้เล่นลองใหม่', () {
    toDisaster();
    p.failReason = 'อาหารไม่พอ';
    final f = cue();
    expect(f.key, 'fail');
    expect(f.lines, scriptOf(StoryCh.disaster).onFail);
    StoryTalk.hear(p, f);
    expect(StoryTalk.next(p, e), isNull);
  });

  for (final (g, points) in [('S', 3), ('A', 2), ('B', 1)]) {
    test('บทสรุป: ตอนจบเกรด $g → ปลดล็อก → ลุงฝากท้าย → การ์ดสุดท้าย', () {
      e.state
        ..gradeDays = 4
        ..gradePoints = points * 4;
      expect(e.overallGrade, g);
      p
        ..chapter = StoryCh.disaster
        ..done = true;
      Story.next(p, e);
      expect(p.finished, isTrue);
      StoryTalk.hear(p, cue()); // เปิดบทสรุป
      final end = cue();
      expect(end.key, 'ending');
      expect(end.lines, [...kStoryEndingScript[g]!, ...kStoryUnlockScript]);
      StoryTalk.hear(p, end);
      expect(cue().key, 'done');
      StoryTalk.hear(p, cue());
      expect(cue().card!.id, 'summary');
    });
  }

  test('เซฟ/โหลด: จำบทพูดที่ฟังแล้ว ตัวเลือก และการ์ดในสมุด', () {
    p
      ..talked = 1
      ..heard.add('t:feed')
      ..choices['fish'] = 'tap'
      ..cards.add('fish');
    final back = StoryProgress.fromJson(p.toJson());
    expect(back.talked, 1);
    expect(back.heard, {'t:feed'});
    expect(back.choices, {'fish': 'tap'});
    expect(back.cards, ['fish']);
    // เซฟเก่าที่ยังไม่มีข้อมูลลุงทอง: ลุงเล่าเปิดบทปัจจุบันใหม่
    final old = StoryProgress.fromJson({'ch': 3});
    expect(old.needsIntro, isTrue);
    expect(old.cards, isEmpty);
  });

  test('บรรทัดที่ชี้สิ่งของ: ชี้เฉพาะสิ่งที่กดได้ในบทนั้น', () {
    for (final s in kStoryScript) {
      if (s.chapter == kStoryChapters) continue;
      final spec = kStory[s.chapter - 1];
      for (final entry in s.onTarget.entries) {
        expect(
          spec.allowed.contains(entry.key) || entry.key == StoryTarget.endDay,
          isTrue,
          reason: 'บท ${s.chapter}: ${entry.key}',
        );
      }
    }
  });
}
