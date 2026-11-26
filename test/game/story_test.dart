import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/data/story_script.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/game/story_talk.dart';
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

  test('ผ่านบท 1-9 ตามลำดับ และข้ามบทไม่ได้', () async {
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
    expect(seen, [1, 2, 3, 4, 5, 6, 7, 8]);
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
    await clearChapter(d); // → บทคุณภาพน้ำ
    await clearChapter(d); // → บทตลาด
    await d.act((e) {
      e.state.pond.first.growth = 100;
      e.catchFish();
      e.sellFish('nila');
    });
    expect(d.progress.done, isTrue);
    expect(Story.canEndDay(d.progress, d.engine), isFalse);
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.next);
  });

  test(
    'บทคำเตือน ประกาศน้ำท่วมล่วงหน้า และต้องมีอุปกรณ์ + อาหารพอ 4 วัน',
    () async {
      final d = PureDriver();
      while (d.progress.chapter < StoryCh.warning) {
        await clearChapter(d);
      }
      expect(d.progress.chapter, StoryCh.warning);
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
    },
  );

  test('บทภัยจริง ก่อนน้ำมาถึง: คำแนะนำบอกจำนวนวันที่เหลือ', () async {
    final d = PureDriver();
    while (d.progress.chapter < StoryCh.disaster) {
      await clearChapter(d);
    }
    expect(d.progress.chapter, StoryCh.disaster);
    final up = d.engine.state.upcoming!;
    expect(
      Story.situationHint(d.progress, d.engine),
      contains('น้ำท่วมมาในอีก ${up.startDay - d.engine.state.day} วัน'),
    );
    while (d.engine.state.active == null) {
      await fedDay(d);
    }
    // น้ำมาแล้ว: กลับไปใช้คำแนะนำประจำบท
    expect(Story.situationHint(d.progress, d.engine), isNull);
  });

  test('บทภัยจริง แพ้เพราะอาหารไม่พอ แล้วลองใหม่เฉพาะบทนี้', () async {
    final d = PureDriver();
    while (d.progress.chapter < StoryCh.disaster) {
      await clearChapter(d);
    }
    expect(d.progress.chapter, StoryCh.disaster);
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
    expect(d.progress.chapter, StoryCh.disaster);
    expect(d.progress.failed, isFalse);
    expect(d.engine.state.day, startDay);
    expect(d.engine.state.upcoming, isNotNull);
    await clearChapter(d);
    expect(d.progress.finished, isTrue);
  });

  test('น้ำท่วมมาถึงตอนบทคำเตือนยังเตรียมไม่ครบ → บทภัยจริง และลองใหม่กลับไปบทคำเตือน', () async {
    final d = PureDriver();
    while (d.progress.chapter < StoryCh.warning) {
      await clearChapter(d);
    }
    final day5 = d.engine.state.day;
    while (d.progress.chapter == StoryCh.warning) {
      await fedDay(d);
    }
    expect(d.progress.chapter, StoryCh.disaster);
    expect(d.progress.retryChapter, StoryCh.warning);
    d.engine.state.hunger = 0;
    await d.endDay();
    expect(d.progress.failed, isTrue);
    d.retry();
    expect(d.progress.chapter, StoryCh.warning);
    expect(d.engine.state.day, day5);
  });

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

  test('เซฟรุ่น 7 บท: เลื่อนเลขบทไปบทเดียวกันในชุด 9 บท', () {
    const old = [1, 2, 3, 4, 5, 6, 7];
    const now = [
      StoryCh.farm,
      StoryCh.market,
      StoryCh.kitchen,
      StoryCh.preserve,
      StoryCh.warning,
      StoryCh.disaster,
      StoryCh.summary,
    ];
    for (var i = 0; i < old.length; i++) {
      final p = StoryProgress.fromJson({
        'ch': old[i],
        'retry': old[i],
        'talk': old[i],
      });
      expect(p.chapter, now[i], reason: 'บทเก่า ${old[i]}');
      expect(p.retryChapter, now[i]);
      expect(p.talked, now[i]);
      expect(p.needsIntro, isFalse);
    }
    // บทเก่า 5 ยังไม่ได้ฟังลุงเปิดบท → ฟังบทคำเตือน
    final p = StoryProgress.fromJson({'ch': 5, 'talk': 4});
    expect(p.chapter, StoryCh.warning);
    expect(p.needsIntro, isTrue);
    // เซฟรุ่นใหม่ไม่เลื่อนซ้ำ
    final back = StoryProgress.fromJson(p.toJson());
    expect(back.chapter, StoryCh.warning);
  });

  test('โรคปลาเปิดตั้งแต่บทปลาป่วย (เซฟเก่าก็ปรับตามบท)', () async {
    final d = PureDriver();
    expect(d.engine.state.diseaseOn, isFalse);
    while (d.progress.chapter < StoryCh.sick) {
      await clearChapter(d);
      expect(d.engine.state.diseaseOn, d.progress.chapter >= StoryCh.sick);
    }
    final p = StoryProgress(chapter: StoryCh.kitchen);
    d.engine.state.diseaseOn = true;
    Story.check(p, d.engine);
    expect(d.engine.state.diseaseOn, isFalse);
  });

  test('บทคุณภาพน้ำ: ล้างตัวกรองแล้วน้ำดี = ผ่าน', () async {
    final d = PureDriver();
    await clearChapter(d);
    expect(d.progress.chapter, StoryCh.water);
    final s = d.engine.state;
    expect(Story.allows(d.progress, d.engine, StoryTarget.tabMarket), isFalse);
    expect(s.filterDirt, greaterThanOrEqualTo(kCleanFilterMin));
    expect(Story.nextTarget(d.progress, d.engine), StoryTarget.water);
    expect(d.progress.done, isFalse);
    await d.act((e) => e.cleanFilter());
    if (s.water < kWaterGoodLine) await d.act((e) => e.changeWater());
    expect(d.progress.done, isTrue);
  });

  test('บทปลาป่วย: ลุงพบปลาจุดขาว ชี้ไปซื้อยา รักษา แล้วรอจนหาย', () async {
    final d = PureDriver();
    while (d.progress.chapter < StoryCh.sick) {
      await clearChapter(d);
    }
    final e = d.engine;
    final s = e.state;
    expect(s.diseaseOn, isTrue);
    final i = s.pond.indexWhere((f) => f.sick);
    expect(i, greaterThanOrEqualTo(0));
    expect(s.pond[i].disease, 'ich');
    expect(Story.nextTarget(d.progress, e), StoryTarget.buyMedicine);
    expect(Story.missing(d.progress, e), {'salt': kMedicines['salt']!.dose});
    expect(StoryTalk.hint(d.progress, e).first.text, contains('เกลือ'));
    // ลองใหม่ = ปลาตัวเดิมป่วยอีกครั้ง
    final snap = StoryProgress.fromJson(d.progress.toJson());
    await d.act((e) {
      e.buyMedicine('salt');
      e.buyMedicine('salt');
    });
    expect(Story.nextTarget(d.progress, e), StoryTarget.treat);
    await d.act((e) => e.treat(i, 'salt'));
    expect(Story.nextTarget(d.progress, e), isNot(StoryTarget.treat));
    expect(d.progress.done, isFalse);
    while (!d.progress.done) {
      await fedDay(d);
    }
    expect(e.sickCount, 0);
    snap.failReason = 'x';
    final again = Story.retry(snap);
    expect(again.state.pond.where((f) => f.sick), hasLength(1));
  });

  test(
    'บทปลาป่วย: ให้ยาผิด → ลุงอธิบาย แล้วชี้ให้เลือกใหม่ (เสียแค่ยา)',
    () async {
      final d = PureDriver();
      while (d.progress.chapter < StoryCh.sick) {
        await clearChapter(d);
      }
      final e = d.engine;
      final p = d.progress;
      // ฟังบทเรียนให้ครบก่อน ลุงจะได้พูดเรื่องยาผิดต่อ
      p.talked = p.chapter;
      for (final l in scriptOfLessons(p)) {
        p.heard.addAll(['l:$l', 'q:$l', 'try:$l']);
      }
      final i = e.state.pond.indexWhere((f) => f.sick);
      e.state.meds['kmno4'] = 1;
      final health = e.state.pond[i].health;
      final r = e.treat(i, 'kmno4');
      expect(r.warning, isTrue);
      expect(e.state.meds['kmno4'], 0);
      expect(e.state.pond[i].sick, isTrue);
      expect(e.state.pond[i].health, health);
      final cue = StoryTalk.next(p, e)!;
      expect(cue.key, startsWith('wrong:'));
      expect(cue.lines.first.text, contains('ด่างทับทิม'));
      expect(cue.lines.last.text, contains('เกลือ'));
      StoryTalk.hear(p, cue);
      expect(StoryTalk.next(p, e)?.key, isNot(startsWith('wrong:')));
      // เลือกใหม่: ยังชี้ไปซื้อยาที่ถูก
      expect(Story.nextTarget(p, e), StoryTarget.buyMedicine);
      // ให้ยาถูก → ล้างสถานะยาผิด
      e.state.inventory['salt'] = 2;
      expect(e.treat(i, 'salt').ok, isTrue);
      expect(e.state.wrongMed, isNull);
    },
  );

  test('บทปลาป่วย: ปลาตายเพราะโรค = ลองบทนี้ใหม่', () async {
    final d = PureDriver();
    while (d.progress.chapter < StoryCh.sick) {
      await clearChapter(d);
    }
    final f = d.engine.state.pond.firstWhere((f) => f.sick);
    f.health = 1;
    await fedDay(d);
    expect(d.progress.failed, isTrue);
    expect(d.progress.failReason, contains('รักษาไม่ทัน'));
    d.retry();
    expect(d.progress.chapter, StoryCh.sick);
    expect(d.engine.state.pond.where((f) => f.sick), hasLength(1));
  });
}

/// รหัสบทเรียนย่อยของบทปัจจุบัน
Iterable<String> scriptOfLessons(StoryProgress p) =>
    scriptOf(p.chapter).lessons.map((l) => l.id);
