import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/game/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'story_script.dart';

/// เล่นเนื้อเรื่องด้วยตรรกะล้วน (ไม่ผ่าน Riverpod)
class PureDriver implements StoryDriver {
  PureDriver() : engine = Story.newEngine(random: FixedRandom()) {
    progress = Story.start(engine);
  }

  @override
  GameEngine engine;
  @override
  late StoryProgress progress;

  @override
  Future<void> act(void Function(GameEngine e) action) async {
    action(engine);
    Story.check(progress, engine);
  }

  @override
  Future<void> endDay() async {
    final r = engine.endDay();
    Story.afterDay(progress, engine, r);
  }

  @override
  Future<void> next() async => Story.next(progress, engine);

  void retry() => engine = Story.retry(progress, random: FixedRandom());
}

void main() {
  test('เกมเนื้อเรื่อง: ไม่มีภัยสุ่ม ไม่ใช้บทเรียนเดิม เริ่มบท 1', () {
    final d = PureDriver();
    expect(d.engine.state.upcoming, isNull);
    expect(d.engine.tutorialActive, isFalse);
    expect(d.progress.chapter, 1);
    expect(d.progress.spec.tabs, {1});
  });

  test('ผ่านบท 1-7 ตามลำดับ และข้ามบทไม่ได้', () async {
    final d = PureDriver();
    // ยังไม่ผ่านเป้าหมาย → ไปบทถัดไปไม่ได้
    expect(Story.next(d.progress, d.engine), isFalse);
    expect(d.progress.chapter, 1);

    final seen = <int>[];
    while (!d.progress.finished) {
      seen.add(d.progress.chapter);
      await clearChapter(d);
      expect(d.progress.failed, isFalse);
    }
    expect(seen, [1, 2, 3, 4, 5, 6]);
    expect(d.progress.chapter, kStoryChapters);
    expect(d.progress.done, isTrue);
    expect(kStoryEnding.keys, contains(d.engine.overallGrade));
    // เนื้อเรื่องไม่จบเกมแบบ Game Over/ชนะ
    expect(d.engine.state.finished, isFalse);
  });

  test('บท 1: จบวันไม่ได้จนกว่าจะซื้อปลาครบและให้อาหาร', () async {
    final d = PureDriver();
    expect(Story.endDayBlock(d.progress, d.engine), contains('ซื้อปลา'));
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.buyFish);
    await d.act((e) => e.buyFish('nila', kStoryPondFish));
    expect(Story.endDayBlock(d.progress, d.engine), contains('ให้อาหาร'));
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.feed);
    await d.act((e) => e.feed(2));
    expect(Story.canEndDay(d.progress, d.engine), isTrue);
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.endDay);
    // ปุ่มของบทหลัง ๆ ยังกดไม่ได้
    expect(Story.allows(d.progress, d.engine, StoryTarget.cook), isFalse);
    expect(Story.allows(d.progress, d.engine, StoryTarget.tabMarket), isFalse);
  });

  test('ผ่านบทแล้วต้องกด "บทถัดไป" ก่อนจบวัน', () async {
    final d = PureDriver();
    await clearChapter(d); // → บท 2
    await d.act((e) {
      e.state.pond.first.growth = 100;
      e.catchFish();
      e.sellFish('nila');
    });
    expect(d.progress.done, isTrue);
    expect(Story.canEndDay(d.progress, d.engine), isFalse);
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.next);
  });

  test('บท 5 ประกาศน้ำท่วมล่วงหน้า และต้องมีอุปกรณ์ + อาหารพอ 4 วัน', () async {
    final d = PureDriver();
    for (var i = 0; i < 4; i++) {
      await clearChapter(d);
    }
    expect(d.progress.chapter, 5);
    final dz = d.engine.state.upcoming!;
    expect(dz.type, DisasterType.flood);
    expect(dz.duration, kStorySupplyDays);
    expect(d.engine.warnDays, kDisasters[DisasterType.flood]!.leadDays);
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.buyEquipment);
    // อาหารไม่พอ 4 วัน → ยังไม่ผ่าน
    await d.act((e) {
      e.state.stock.clear();
      e.buyEquipment('sand');
    });
    expect(d.progress.done, isFalse);
  });

  test('บท 6 แพ้เพราะอาหารไม่พอ แล้วลองใหม่เฉพาะบท 6', () async {
    final d = PureDriver();
    for (var i = 0; i < 5; i++) {
      await clearChapter(d);
    }
    expect(d.progress.chapter, 6);
    final startDay = d.engine.state.day;
    // รอจนน้ำท่วมเริ่ม แล้วไม่กินอะไรเลย
    while (d.engine.state.active == null) {
      await fedDay(d);
    }
    d.engine.state.hunger = 0;
    await d.endDay();
    expect(d.progress.failed, isTrue);
    expect(d.progress.failReason, contains('อาหารไม่พอ'));
    expect(Story.canEndDay(d.progress, d.engine), isFalse);
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.retry);

    d.retry();
    expect(d.progress.chapter, 6);
    expect(d.progress.failed, isFalse);
    expect(d.engine.state.day, startDay);
    expect(d.engine.state.upcoming, isNotNull);
    await clearChapter(d);
    expect(d.progress.finished, isTrue);
  });

  test(
    'น้ำท่วมมาถึงตอนบท 5 ยังเตรียมไม่ครบ → บท 6 และลองใหม่กลับไปบท 5',
    () async {
      final d = PureDriver();
      for (var i = 0; i < 4; i++) {
        await clearChapter(d);
      }
      final day5 = d.engine.state.day;
      while (d.progress.chapter == 5) {
        await fedDay(d);
      }
      expect(d.progress.chapter, 6);
      expect(d.progress.retryChapter, 5);
      d.engine.state.hunger = 0;
      await d.endDay();
      expect(d.progress.failed, isTrue);
      d.retry();
      expect(d.progress.chapter, 5);
      expect(d.engine.state.day, day5);
    },
  );

  test('Game Over ในเนื้อเรื่อง = แพ้บทนั้น (ไม่จบเกม)', () async {
    final d = PureDriver();
    await d.act((e) => e.buyFish('nila', kStoryPondFish));
    await d.act((e) {
      e.feed(2);
      e.state
        ..hunger = 0
        ..health = 10;
    });
    await d.endDay();
    expect(d.engine.state.over, isFalse);
    expect(d.progress.failed, isTrue);
    d.retry();
    expect(d.progress.chapter, 1);
    expect(d.engine.state.pond, isEmpty);
  });

  test('ความคืบหน้าบทแปลงเป็น JSON แล้วกลับมาได้ครบ', () async {
    final d = PureDriver();
    await clearChapter(d);
    d.progress.failReason = 'x';
    final back = StoryProgress.fromJson(d.progress.toJson());
    expect(back.chapter, 2);
    expect(back.startDay, d.progress.startDay);
    expect(back.failReason, 'x');
    expect(back.retryChapter, 2);
    expect(back.snapshot!['day'], d.progress.snapshot!['day']);
  });
}
