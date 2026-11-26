import 'dart:io';

import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/data/story_script.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:flutter_test/flutter_test.dart';

Iterable<ScriptLine> _all(ChapterScript c) sync* {
  yield* c.intro;
  yield* c.onDone;
  for (final l in c.onTarget.values) {
    yield* l;
  }
  final ch = c.choice;
  if (ch != null) {
    yield* ch.ask;
    for (final o in ch.options) {
      yield* o.reply;
    }
  }
  for (final l in c.lessons) {
    yield* l.teach;
    yield* l.tryIt;
  }
  for (final l in c.dayLines.values) {
    yield* l;
  }
  yield* c.ready;
  yield* c.notReady;
  yield* c.onFail;
}

void main() {
  test('บทพูดครบ 9 บท เรียงตามบท และทุกบทเปิดด้วยการเล่า "ทำไม"', () {
    expect(kStoryScript, hasLength(kStoryChapters));
    for (var i = 0; i < kStoryChapters; i++) {
      final c = kStoryScript[i];
      expect(c.chapter, i + 1);
      expect(c.title, kStory[i].title);
      expect(c.intro, isNotEmpty, reason: 'บท ${c.chapter}');
      expect(c.onDone, isNotEmpty, reason: 'บท ${c.chapter}');
    }
  });

  test('ทุกบรรทัดสั้น 1-2 ประโยค (ไม่เกิน 110 ตัวอักษร)', () {
    for (final c in kStoryScript) {
      for (final l in _all(c)) {
        expect(l.text.trim(), isNotEmpty);
        expect(l.text.length, lessThanOrEqualTo(110), reason: l.text);
      }
    }
  });

  test(
    'ตัวเลือกอยู่ในบทลงบ่อ ตลาด ถนอมอาหาร ภัยจริง และอ้างของที่มีในเกมจริง',
    () {
      final withChoice = [
        for (final c in kStoryScript)
          if (c.choice != null) c.chapter,
      ];
      expect(withChoice, [
        StoryCh.farm,
        StoryCh.market,
        StoryCh.preserve,
        StoryCh.disaster,
      ]);
      for (final c in kStoryScript.where((c) => c.choice != null)) {
        final opts = c.choice!.options;
        expect(opts.length, inInclusiveRange(2, 4));
        expect(opts.map((o) => o.id).toSet(), hasLength(opts.length));
        for (final o in opts) {
          expect(o.reply, isNotEmpty);
        }
      }
      for (final o in scriptOf(1).choice!.options) {
        expect(kFish, contains(o.id));
      }
      for (final o in scriptOf(StoryCh.preserve).choice!.options) {
        expect(kPreserveMethods, contains(o.id));
      }
    },
  );

  test('บทถนอมอาหาร: สอนครบ 4 วิธี', () {
    final lessons = scriptOf(StoryCh.preserve).lessons;
    expect(lessons.map((l) => l.id).toSet(), kPreserveMethods.keys.toSet());
  });

  test(
    'บทเรียนย่อยมีเฉพาะบทน้ำ ถนอม ปลาป่วย · ถาม 2-3 ตัวเลือก ถูกข้อเดียว',
    () {
      expect(
        [
          for (final c in kStoryScript)
            if (c.lessons.isNotEmpty) c.chapter,
        ],
        [StoryCh.water, StoryCh.preserve, StoryCh.sick],
      );
      final all = [for (final c in kStoryScript) ...c.lessons];
      expect(all.map((l) => l.id).toSet(), hasLength(all.length));
      for (final l in all) {
        expect(l.teach, isNotEmpty);
        expect(l.quiz.options.length, inInclusiveRange(2, 3));
        expect(l.quiz.options.where((o) => o.correct), hasLength(1));
        for (final o in l.quiz.options) {
          expect(o.explain, isNotEmpty);
        }
      }
    },
  );

  test('บทปลาป่วย: คำถามยาจุดขาวตรงกับข้อมูลโรค และลุงอธิบายเมื่อให้ยาผิด', () {
    final q = scriptOf(StoryCh.sick).lessons.first.quiz;
    final right = q.options.firstWhere((o) => o.correct).text;
    expect(right, kMedicines[kDiseases['ich']!.medicine]!.name);
    expect(scriptOf(StoryCh.sick).onFail, isNotEmpty);
    for (final d in kDiseases.values) {
      for (final m in kMedicines.keys) {
        if (m == d.medicine) continue;
        final lines = wrongMedicineLines(m, d.id);
        expect(lines.last.text, contains(kMedicines[d.medicine]!.name));
        for (final l in lines) {
          expect(l.text.length, lessThanOrEqualTo(110), reason: l.text);
        }
      }
    }
  });

  test('การ์ดบทใหม่ใช้ค่าในเกม', () {
    for (final ch in [StoryCh.water, StoryCh.sick]) {
      final facts = scriptOf(ch).card.facts();
      expect(facts, isNotEmpty);
      expect(facts.where((f) => f.inGame), isNotEmpty);
    }
  });

  test('บทภัยจริง: พูดคั่นทุกวันของน้ำท่วม และมีทางออกเมื่อเตรียมไม่พอ', () {
    final c = scriptOf(StoryCh.disaster);
    final days = c.dayLines.keys.toList()..sort();
    expect(days, List.generate(kStorySupplyDays, (i) => i));
    expect(c.ready, isNotEmpty);
    expect(c.notReady, isNotEmpty);
    expect(c.onFail, isNotEmpty);
  });

  test('ตอนจบต่างกันตามเกรด S/A/B', () {
    expect(kStoryEndingScript.keys.toSet(), {'S', 'A', 'B'});
    final texts = kStoryEndingScript.values.map((l) => l.first.text).toSet();
    expect(texts, hasLength(3));
    expect(kStoryUnlockScript, isNotEmpty);
  });

  test('การ์ดความรู้ 1 ใบต่อบท มีตัวเลขจากเกมติดป้าย "ค่าในเกม"', () {
    expect(kKnowledgeCards.map((c) => c.id).toSet(), hasLength(kStoryChapters));
    for (final card in kKnowledgeCards) {
      final facts = card.facts();
      expect(facts, isNotEmpty, reason: card.id);
      expect(facts.any((f) => f.inGame), isTrue, reason: card.id);
    }
    // การ์ดถนอมอาหาร: อายุเก็บรักษาและเวลาทำตรงกับข้อมูลเกม
    final facts = kKnowledgeCards.firstWhere((c) => c.id == 'preserve').facts();
    for (final m in kPreserveMethods.values) {
      final f = facts.firstWhere((f) => f.label == kFoods[m.id]!.name);
      expect(f.inGame, isTrue);
      expect(f.value, contains('${kFoods[m.id]!.shelfDays} วัน'));
      expect(f.value, contains('${m.days} วัน'));
    }
  });

  test('มีภาพลุงทองครบทุกอารมณ์', () {
    for (final m in UncleMood.values) {
      expect(File(Uncle.asset(m)).existsSync(), isTrue, reason: m.name);
    }
  });
}
