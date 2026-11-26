// บอทเล่นเนื้อเรื่องทุกบท ทุกทางเลือก โดยทำตาม "คำแนะนำของเกม" เท่านั้น
// (บทพูดลุงทอง + Story.nextTarget + StoryTalk.hint) ต้องจบเนื้อเรื่องได้ทุกเส้นทาง ไม่ค้าง
//
// ครบ 9 บท: ลงบ่อ → คุณภาพน้ำ → ตลาด → ครัว → ถนอม → ปลาป่วย → คำเตือน → ภัยจริง → สรุป
// เส้นทาง = ตัวเลือกปลา × ขาย 1/หมด × วิธีถนอม × ลำดับกินตอนไฟดับ
// และอีกชุด "หมดตัว": เงินเหลือ 0 ทุกครั้งที่เริ่มบทใหม่ (ต้องมีทางไปต่อเสมอ)
import 'dart:math';

import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/data/story_script.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/game/story_talk.dart';
import 'package:flutter_test/flutter_test.dart';

class _Path {
  const _Path(this.picks, {this.broke = false});
  final Map<String, String> picks;
  final bool broke;
  @override
  String toString() => '${picks.values.join('/')}${broke ? ' (หมดตัว)' : ''}';
}

/// เล่นจนจบเนื้อเรื่อง คืนบันทึกการเล่น (โยน StateError ถ้าค้าง)
List<String> _playStory(_Path path, {int seed = 1, Set<int>? seen}) {
  var e = Story.newEngine(random: Random(seed));
  final p = Story.start(e);
  final log = <String>[];
  seen?.add(p.chapter);
  var lastChapter = 0;
  var idle = 0;
  String sig() =>
      '${p.chapter}|${p.done}|${p.failed}|${e.state.day}|${e.state.money}|'
      '${e.fishTotal}|${e.state.pond.length}|${e.state.stock.length}|'
      '${e.state.processing.length}|${e.state.inventory}|${e.state.equipment}|'
      '${p.heard.length}|${p.choices.length}|${p.cards.length}|${p.talked}|'
      '${e.state.filterDirt}|${e.sickCount}|${e.state.meds}|'
      '${[for (final f in e.state.pond) f.treatDays]}';
  var last = '';

  for (var step = 0; step < 3000; step++) {
    if (p.chapter != lastChapter) {
      lastChapter = p.chapter;
      seen?.add(p.chapter);
      if (path.broke && p.chapter < kStoryChapters) e.state.money = 0;
    }
    if (p.finished && p.done) {
      // บทสรุป: ฟังลุงให้ครบ แล้วจบ
      final cue = StoryTalk.next(p, e);
      if (cue == null) return log;
      if (cue.kind == TalkKind.card) {
        StoryTalk.keepCard(p, cue.card!);
      } else {
        StoryTalk.hear(p, cue);
      }
      continue;
    }

    final cue = StoryTalk.next(p, e);
    if (cue != null) {
      switch (cue.kind) {
        case TalkKind.card:
          StoryTalk.keepCard(p, cue.card!);
        case TalkKind.quiz:
          // ตอบผิดก่อน 1 ครั้ง (ต้องไม่ค้าง) แล้วตอบถูก
          final opts = cue.quiz!.options;
          final wrong = opts.indexWhere((o) => !o.correct);
          if (!p.heard.contains('wrong:${cue.key}') && wrong >= 0) {
            StoryTalk.answer(p, cue, wrong);
            p.heard.add('wrong:${cue.key}');
          } else {
            StoryTalk.answer(p, cue, opts.indexWhere((o) => o.correct));
          }
        case TalkKind.choice:
          final c = cue.choice!;
          final id = path.picks[c.id] ?? c.options.first.id;
          final effect = StoryTalk.effect(c.id, id, e);
          StoryTalk.choose(p, c, id);
          if (effect != null) log.add('เลือก $id: ${effect.apply(e).message}');
        case TalkKind.gift:
          StoryTalk.hear(p, cue);
          log.add(Story.giveGift(e, cue.gift!).message);
        case _:
          StoryTalk.hear(p, cue);
      }
      Story.check(p, e);
      continue;
    }

    if (p.failed) {
      log.add('แพ้บท ${p.chapter}: ${p.failReason} → ลองใหม่');
      e = Story.retry(p, random: Random(seed + step));
      continue;
    }
    if (p.done) {
      Story.next(p, e);
      continue;
    }

    // ทำตามสิ่งที่เกมชี้ (ไม่มีคำชี้ = ถามคำใบ้ลุงทอง)
    final t = Story.nextTarget(p, e);
    final hint = StoryTalk.hint(p, e).first;
    expect(hint.text, isNotEmpty);
    // สิ่งที่เกมชี้ต้องกดได้จริงในบทนี้ (แท็บเปิด ปุ่มไม่ถูกล็อก)
    if (t != null && t != StoryTarget.endDay) {
      expect(Story.allows(p, e, t), isTrue, reason: 'บท ${p.chapter} ชี้ $t');
      expect(Story.tabOpen(p, storyTabOf(t)!), isTrue);
    }
    final r = _act(t, p, e, log);
    if (r == 'endDay') {
      final rep = e.endDay();
      Story.afterDay(p, e, rep);
    }
    Story.check(p, e);

    final now = sig();
    if (now == last) {
      idle++;
      if (idle > 3) {
        throw StateError(
          'ค้างที่บท ${p.chapter} เป้าหมาย=$t คำใบ้="${hint.text}" '
          'เงิน=${e.state.money} ปลาคลัง=${e.fishTotal} บ่อ=${e.state.pond.length} '
          'ของ=${e.state.inventory} อุปกรณ์=${e.state.equipment}\n${log.join('\n')}',
        );
      }
    } else {
      idle = 0;
      last = now;
    }
  }
  throw StateError('เล่นไม่จบใน 3000 ขั้น บท ${p.chapter}\n${log.join('\n')}');
}

/// ทำสิ่งที่เกมชี้ 1 อย่าง ('endDay' = ให้ผู้เรียกจบวัน)
String? _act(StoryTarget? t, StoryProgress p, GameEngine e, List<String> log) {
  final s = e.state;
  void run(String what, ActionResult r) {
    if (r.ok) log.add('$what: ${r.message}');
  }

  switch (t) {
    case StoryTarget.buyFish:
      // ซื้อเท่าที่เงินพอ (อย่างน้อย 1 ตัว) · เงินไม่พอเลย = ลุงให้ลูกปลาฟรี
      final price = kFish['nila']!.buyPrice;
      final n = min(kStoryPondFish, max(1, s.money ~/ price));
      final r = e.buyFish('nila', n);
      if (!r.ok) run('รับปลาฟรี', e.buyFish('nila', 2));
      run('ซื้อปลา', r);
    case StoryTarget.feed:
      final r = e.feed(2);
      run('ให้อาหาร', r.ok ? r : e.feed(1));
    case StoryTarget.water:
      // ออกซิเจนต่ำ → เติมอากาศ · ตัวกรองสกปรก → ล้าง · น้ำยังแย่ → เปลี่ยนน้ำ
      if (s.o2 < e.pondO2Need) run('เติมอากาศ', e.aerate());
      if (s.filterDirt >= kCleanFilterMin) run('ล้างตัวกรอง', e.cleanFilter());
      if (s.water < 60) run('เปลี่ยนน้ำ', e.changeWater());
    case StoryTarget.buyMedicine:
      for (final x in Story.missing(p, e).entries) {
        for (var i = 0; i < x.value; i++) {
          run('ซื้อยา${x.key}', e.buyMedicine(x.key));
        }
      }
    case StoryTarget.treat:
      // ดูอาการแล้วเลือกยาที่ตรงโรค (ตามที่ลุงสอน)
      final i = s.pond.indexWhere(
        (f) => f.sick && f.treatDays == 0 && f.health > 0,
      );
      final med = kDiseases[s.pond[i].disease]!.medicine;
      final r = e.treat(i, med);
      if (!r.ok && s.energy < 30) e.rest();
      run('รักษา', r);
    case StoryTarget.catchFish:
      run('จับปลา', e.catchFish());
    case StoryTarget.sellFish:
      final k = s.fishStock.entries.firstWhere((x) => x.value > 0).key;
      run('ขายปลา', e.sellFish(k));
    case StoryTarget.buyIngredient:
      final m = Story.missing(p, e);
      for (final x in (m.isEmpty ? {'spice': 1} : m).entries) {
        for (var i = 0; i < x.value; i++) {
          run('ซื้อ${x.key}', e.buyIngredient(x.key));
        }
      }
    case StoryTarget.buyTool || StoryTarget.buyEquipment:
      for (final id in Story.missing(p, e).keys) {
        run('ซื้อ$id', e.buyEquipment(id));
      }
    case StoryTarget.cook:
      run('ทำอาหาร', e.cook(kRecipes.keys.firstWhere(e.canCook)));
    case StoryTarget.preserve:
      final m = e.canPreserve(Story.preserveMethod(p))
          ? Story.preserveMethod(p)
          : kPreserveMethods.keys.firstWhere(e.canPreserve);
      run('ถนอม', e.startPreserve(m));
    case StoryTarget.eat:
      final i = s.stock.indexWhere((b) => !e.isExpired(b));
      run('กิน', e.eatStock(i));
    case StoryTarget.endDay || null:
      // ระหว่างรอ: ดูแลบ่อและท้องก่อนจบวัน (ทำตามแถบคำแนะนำของเกมเหมือนผู้เล่น)
      if (s.pond.isNotEmpty && s.fed == 0) {
        final r = e.feed(2);
        if (!r.ok) e.feed(1);
      }
      if (s.water < 60 && s.money >= 20) e.changeWater();
      while (s.hunger < 60) {
        final i = s.stock.indexWhere((b) => !e.isExpired(b));
        if (i < 0 || !e.eatStock(i).ok) break;
      }
      if (s.energy < 30) e.rest();
      if (!Story.canEndDay(p, e)) return null;
      if (p.chapter >= StoryCh.sick) {
        log.add(
          'จบวัน ${s.day} บท ${p.chapter}: อิ่ม ${s.hunger} เสบียง ${e.supplyDays} '
          'อาหาร ${[for (final b in s.stock) '${b.food}x${b.qty}(อายุ${b.age})']} '
          'กำลังถนอม ${s.processing.length} เงิน ${s.money} '
          'ภัย ${s.active?.dayIndex}/${s.upcoming?.startDay} น้ำ ${s.water} am ${s.ammonia} ni ${s.nitrite} na ${s.nitrate} t ${s.temp} bio ${s.bio} dirt ${s.filterDirt} o2 ${s.o2} fed ${s.fed} ปลา ${[for (final f in s.pond) '${f.type}g${f.growth}h${f.health}']}',
        );
      }
      return 'endDay';
    default:
      return null;
  }
  return null;
}

void main() {
  final paths = <_Path>[
    for (final fish in ['nila', 'dook', 'tap'])
      for (final sell in ['sell_one', 'sell_all'])
        for (final method in ['dried', 'salted', 'pickled', 'canned'])
          for (final eat in ['fresh_first', 'preserved_first'])
            _Path({
              'fish': fish,
              'sell': sell,
              'method': method,
              'eat_order': eat,
            }),
  ];
  final broke = [
    for (final method in ['dried', 'salted', 'pickled', 'canned'])
      for (final sell in ['sell_one', 'sell_all'])
        _Path({'fish': 'nila', 'sell': sell, 'method': method}, broke: true),
  ];

  test('มีตัวเลือกครบทุกจุดตัดสินใจในบท', () {
    final ids = {
      for (var c = 1; c <= kStoryChapters; c++)
        if (scriptOf(c).choice != null) scriptOf(c).choice!.id,
    };
    expect(ids, {'fish', 'sell', 'method', 'eat_order'});
  });

  for (final path in [...paths, ...broke]) {
    test('บอทเล่นจนจบ ไม่ค้าง: $path', () {
      final seen = <int>{};
      final log = _playStory(path, seen: seen);
      expect(log, isNotEmpty);
      // ผ่านครบทุกบท
      expect(seen, {for (var c = 1; c <= kStoryChapters; c++) c});
      // บทคุณภาพน้ำได้ล้างตัวกรอง · บทปลาป่วยได้รักษา
      expect(log.where((l) => l.startsWith('ล้างตัวกรอง')), isNotEmpty);
      expect(log.where((l) => l.startsWith('รักษา')), isNotEmpty);
    });
  }

  test('บอทหลาย seed: โรคสุ่มช่วงหลังก็ไม่ทำให้ค้าง', () {
    for (var seed = 2; seed < 12; seed++) {
      final seen = <int>{};
      _playStory(
        const _Path({'fish': 'tap', 'sell': 'sell_all', 'method': 'dried'}),
        seed: seed,
        seen: seen,
      );
      expect(seen, hasLength(kStoryChapters), reason: 'seed $seed');
    }
  });

  test(
    'บทถนอมอาหาร หมักเกลือ ไม่มีเกลือ: เกมชี้ไปซื้อเกลือที่ตลาด ไม่ใช่ครัว',
    () {
      final e = Story.newEngine(random: Random(1));
      final p = Story.start(e)
        ..chapter = StoryCh.preserve
        ..talked = StoryCh.preserve;
      p.choices['method'] = 'salted';
      for (final l in scriptOf(StoryCh.preserve).lessons) {
        p.heard.addAll(['l:${l.id}', 'q:${l.id}', 'try:${l.id}']);
      }
      e.buyFish('nila', 1);
      e.state.fishStock['nila'] = 1;
      e.buyEquipment('jar');
      expect(Story.missing(p, e), {'salt': 2});
      expect(Story.nextTarget(p, e), StoryTarget.buyIngredient);
      expect(storyTabOf(Story.nextTarget(p, e)!), 2);
      expect(StoryTalk.hint(p, e).first.text, contains('เกลือ'));
      // เงินหมด → ลุงให้เกลือฟรี แล้วชี้กลับไปถนอม
      e.state.money = 0;
      final cue = StoryTalk.next(p, e);
      expect(cue!.kind, TalkKind.gift);
      Story.giveGift(e, cue.gift!);
      expect(Story.nextTarget(p, e), StoryTarget.preserve);
      expect(e.startPreserve('salted').ok, isTrue);
    },
  );

  test(
    'บทภัยจริง ก่อนน้ำมา: ปลาทอดเสียก่อนน้ำลด → ชี้ให้ถนอม ไม่ใช่รอเฉยๆ',
    () {
      final e = Story.newEngine(random: Random(1));
      final p = Story.start(e)
        ..chapter = StoryCh.sick
        ..done = true;
      Story.next(p, e); // บทคำเตือน ประกาศน้ำท่วม
      p.chapter = StoryCh.disaster;
      final s = e.state;
      s.stock
        ..clear()
        ..add(StockBatch(food: 'fry', qty: 6));
      expect(e.supplyDays, greaterThanOrEqualTo(kStorySupplyDays));
      expect(
        Story.floodSupply(e),
        0,
        reason: 'ปลาทอดเก็บได้ 3 วัน เสียก่อนน้ำลด',
      );
      s.fishStock['nila'] = 1;
      s.equipment['rack'] = 1;
      expect(Story.nextTarget(p, e), StoryTarget.preserve);
    },
  );

  test('หิว ไม่มีของกิน ไม่มีปลา ไม่มีเงิน → ลุงแบ่งปลาแห้งให้', () {
    final e = Story.newEngine(random: Random(1));
    final p = Story.start(e)
      ..chapter = StoryCh.preserve
      ..talked = StoryCh.preserve;
    p.choices['method'] = 'dried';
    for (final l in scriptOf(StoryCh.preserve).lessons) {
      p.heard.addAll(['l:${l.id}', 'q:${l.id}', 'try:${l.id}']);
    }
    final s = e.state
      ..money = 0
      ..hunger = 30;
    s.stock.clear();
    final g = Story.giftNeeded(p, e);
    expect(g, {'dried': 2});
    expect(StoryTalk.next(p, e)!.kind, TalkKind.gift);
    Story.giveGift(e, g!);
    expect(e.servings, 2);
    expect(Story.giftNeeded(p, e), isNull);
  });

  test('บทปลาป่วย เงินไม่พอซื้อยา → ลุงให้ยาที่ตรงโรคฟรี', () {
    final e = Story.newEngine(random: Random(1));
    final p = Story.start(e)
      ..chapter = StoryCh.preserve
      ..done = true;
    e.buyFish('nila', 2);
    Story.next(p, e);
    expect(p.chapter, StoryCh.sick);
    expect(e.sickCount, 1);
    p.talked = p.chapter;
    for (final l in scriptOf(StoryCh.sick).lessons) {
      p.heard.addAll(['l:${l.id}', 'q:${l.id}', 'try:${l.id}']);
    }
    e.state.money = 0;
    final cue = StoryTalk.next(p, e)!;
    expect(cue.kind, TalkKind.gift);
    expect(cue.gift, {'salt': kMedicines['salt']!.dose});
    Story.giveGift(e, cue.gift!);
    expect(Story.nextTarget(p, e), StoryTarget.treat);
    // ยาที่ไม่ใช่วัตถุดิบไปอยู่ในช่องยา
    Story.giveGift(e, {'kmno4': 1});
    expect(e.state.meds['kmno4'], 1);
    expect(Story.itemsText({'kmno4': 1}), kMedicines['kmno4']!.name);
  });
}
