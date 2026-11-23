import 'dart:convert';

import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/difficulty.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/equipment_data.dart';
import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/ingredients.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/game/js_math.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

GameEngine engineFor(Difficulty mode) =>
    GameEngine.newGame('ทดสอบ', random: FixedRandom(), mode: mode);

/// วันแรกของขั้นความยาก [stage]
int firstDayOf(int stage, int target) {
  for (var d = 1; d <= target; d++) {
    if (difficultyStage(d, target) == stage) return d;
  }
  throw StateError('ไม่มีขั้น $stage');
}

/// ภัยที่จะจบในวันนี้ (จบวันแล้วประกาศภัยถัดไปตามขั้นของวันถัดไป)
void endDisasterToday(GameEngine e) {
  final s = e.state;
  s.upcoming = null;
  s.active = ActiveDisaster(
    type: DisasterType.flood,
    duration: 4,
    severity: .5,
    fishBefore: 0,
    dayIndex: 2,
  );
}

void main() {
  group('ปานกลาง วันแรกเท่าต้นแบบ', () {
    test('ตัวคูณทุกตัวเป็น 1 และราคา/ภัยเท่าข้อมูลต้นแบบ', () {
      final e = newEngine();
      final s = e.state;
      expect(s.mode, Difficulty.normal);
      expect(e.targetDays, 30);
      expect(e.stage, 0);
      expect(e.buyMultiplier, 1);
      expect(e.sellMultiplier, 1);
      expect(e.severityMultiplier, 1);
      expect(e.waterMultiplier, 1);
      // ราคาวัตถุดิบ: สูตรเดียวกับต้นแบบ (FixedRandom = .5)
      for (final ing in kIngredients.values) {
        expect(
          s.prices[ing.id],
          jsRound(ing.basePrice * (0.6 + .5 * 0.9)) < 2
              ? 2
              : jsRound(ing.basePrice * (0.6 + .5 * 0.9)),
        );
      }
      for (final eq in kEquipment.values) {
        expect(e.equipmentPrice(eq.id), eq.price);
      }
      for (final f in kFish.values) {
        expect(e.fishSellPrice(f.id), f.sellPrice);
      }
      for (final f in kFoods.values) {
        expect(e.foodSellPrice(f.id), f.value);
      }
      e.buyFish('nila', 2);
      for (final lv in [1, 2, 3]) {
        expect(e.feedCost(lv), kFeedCostMultiplier[lv] * e.feedUnit);
      }
      // ภัยแรก: น้ำท่วม วันที่ 7 ความรุนแรง .5 เตือน 5 วัน นาน 4 วัน
      final dz = s.upcoming!;
      expect(dz.type, DisasterType.flood);
      expect(dz.startDay, 7);
      expect(dz.severity, .5);
      expect(dz.warnDays, 5);
      expect(dz.duration, 4);
      // เซฟของวันแรกไม่มีค่าภัยที่ปรับแต่ง (เหมือนต้นแบบ)
      expect(dz.toJson().containsKey('dur'), isFalse);
      expect(dz.toJson().containsKey('warn'), isFalse);
    });

    test('โหมดง่าย/ยาก วันแรกเบากว่า/หนักกว่าปานกลาง', () {
      final easy = engineFor(Difficulty.easy);
      final hard = engineFor(Difficulty.hard);
      final normal = newEngine();
      expect(
        easy.equipmentPrice('pump'),
        lessThan(normal.equipmentPrice('pump')),
      );
      expect(
        hard.equipmentPrice('pump'),
        greaterThan(normal.equipmentPrice('pump')),
      );
      expect(
        easy.fishSellPrice('nila'),
        greaterThan(normal.fishSellPrice('nila')),
      );
      expect(
        hard.fishSellPrice('nila'),
        lessThan(normal.fishSellPrice('nila')),
      );
      expect(easy.state.upcoming!.severity, lessThan(.5));
      expect(hard.state.upcoming!.severity, greaterThan(.5));
    });
  });

  group('ความยากเพิ่มตามขั้น', () {
    for (final mode in Difficulty.values) {
      test(
        '${kDifficulties[mode]!.name}: 6 ขั้น ราคาซื้อขึ้น ราคาขายขึ้นช้ากว่า',
        () {
          final e = engineFor(mode);
          final target = e.targetDays;
          final seen = <int>{};
          double? lastBuy, lastSell;
          for (var stage = 0; stage < kDifficultyStages; stage++) {
            e.state.day = firstDayOf(stage, target);
            seen.add(e.stage);
            // ขั้นคงที่ภายในช่วง (ขึ้นเป็นขั้น ไม่ต่อเนื่อง)
            expect(e.stage, stage);
            if (lastBuy != null) {
              expect(e.buyMultiplier, greaterThan(lastBuy));
              expect(e.sellMultiplier, greaterThan(lastSell!));
              // ราคาขายขึ้นช้ากว่าราคาซื้อ
              expect(
                e.sellMultiplier / kDifficulties[mode]!.sell,
                lessThan(e.buyMultiplier / kDifficulties[mode]!.buy),
              );
            }
            lastBuy = e.buyMultiplier;
            lastSell = e.sellMultiplier;
          }
          expect(seen, {0, 1, 2, 3, 4, 5});
          // วันสุดท้ายอยู่ขั้นสุดท้าย
          e.state.day = target;
          expect(e.stage, kDifficultyStages - 1);
          expect(
            e.equipmentPrice('pump'),
            greaterThan(engineFor(mode).equipmentPrice('pump')),
          );
        },
      );
    }

    test('ภัยที่ประกาศช่วงท้ายเกม: รุนแรงกว่า นานกว่า เตือนสั้นกว่า (ไม่ต่ำกว่า 1 วัน)', () {
      final early = newEngine();
      final late = newEngine();
      early.state.day = 2;
      late.state.day = 28;
      endDisasterToday(early);
      endDisasterToday(late);
      keepFed(early);
      keepFed(late);
      early.endDay();
      late.endDay();
      final a = early.state.upcoming!;
      final b = late.state.upcoming!;
      expect(a.type, b.type);
      expect(b.severity, greaterThan(a.severity));
      expect(b.duration, greaterThan(a.duration));
      expect(b.warnDays, lessThan(a.warnDays));
      // ทุกโหมด ทุกขั้น ทุกภัย เตือนอย่างน้อย 1 วัน
      for (final mode in Difficulty.values) {
        final e = engineFor(mode);
        for (var d = 1; d <= e.targetDays; d++) {
          e.state.day = d;
          for (final t in DisasterType.values) {
            expect(e.disasterWarnDays(t), greaterThanOrEqualTo(kMinWarnDays));
          }
        }
      }
    });

    test('ข่าวเตือนนับตามวันเตือนที่ประกาศไว้', () {
      final e = newEngine();
      e.state.upcoming = UpcomingDisaster(
        type: DisasterType.flood,
        startDay: 10,
        severity: .5,
        customWarnDays: 2,
      );
      final seen = <int>[];
      for (var d = 1; d <= 9; d++) {
        e.state.day = d;
        seen.add(e.warnDays);
      }
      expect(seen, [0, 0, 0, 0, 0, 0, 0, 2, 1]);
    });

    test('น้ำเสียเร็วขึ้นในขั้นท้าย', () {
      double ammoniaAfterDay(int day) {
        final e = newEngine();
        final s = e.state
          ..day = day
          ..money = 9999
          ..bio = 0
          ..upcoming = null;
        e.buyFish('nila', 4);
        e.feed(2);
        keepFed(e);
        final before = s.ammonia;
        e.endDay();
        return s.ammonia - before;
      }

      expect(ammoniaAfterDay(28), greaterThan(ammoniaAfterDay(2)));
    });

    test('ภัยที่ถูกยืด: เล่นครบทุกวันได้ ข้อความเลขวันถูกต้อง แล้วประกาศภัยถัดไป', () {
      final e = newEngine();
      final s = e.state
        ..day = 20
        ..money = 9999;
      e.buyFish('nila', 6);
      s.upcoming = UpcomingDisaster(
        type: DisasterType.flood,
        startDay: 21,
        severity: .6,
        customDuration: 6,
      );
      final texts = <String>[];
      final market = <bool>[];
      for (var i = 0; i < 6; i++) {
        keepFed(e);
        final ev = e.endDay().event!;
        texts.add(ev.text);
        market.add(ev.marketClosed);
        expect(ev.duration, 6);
        expect(ev.last, i == 5);
      }
      for (var i = 0; i < 6; i++) {
        expect(texts[i], startsWith('วันที่ ${i + 1} '));
      }
      // น้ำท่วมช่วงหนักสุด (วันที่ 3 ของต้นแบบ) ยาวขึ้น 2 วัน ตลาดปิดต่อเนื่อง
      expect(market, [false, true, true, true, true, false]);
      expect(s.active, isNull);
      expect(s.upcoming, isNotNull);
      expect(s.survived, 1);
    });
  });

  group('ชนะเมื่อรอดถึงวันสุดท้าย', () {
    for (final mode in Difficulty.values) {
      test(
        '${kDifficulties[mode]!.name}: รอดครบ ${kDifficulties[mode]!.targetDays} วัน',
        () async {
          final e = engineFor(mode);
          final s = e.state..upcoming = null;
          final target = e.targetDays;
          s.day = target - 1;
          keepFed(e);
          final r1 = e.endDay();
          expect(r1.won, isFalse);
          expect(s.won, isFalse);
          expect(s.finished, isFalse);

          keepFed(e);
          final r2 = e.endDay();
          expect(r2.day, target);
          expect(r2.won, isTrue);
          expect(r2.gameOver, isFalse);
          expect(s.won, isTrue);
          expect(s.finished, isTrue);

          final sum = e.summary;
          expect(sum.won, isTrue);
          expect(sum.mode, mode);
          expect(sum.days, target);
          expect(sum.money, s.money);
          expect(['S', 'A', 'B'], contains(sum.grade));

          // เกมที่ชนะแล้วไม่ถูกเซฟทับ
          SharedPreferences.setMockInitialValues({});
          final repo = SaveRepository(await SharedPreferences.getInstance());
          expect(await repo.save(1, s), isFalse);
        },
      );
    }

    test('ตายวันสุดท้าย = แพ้ ไม่ใช่ชนะ', () {
      final e = engineFor(Difficulty.easy);
      final s = e.state
        ..upcoming = null
        ..day = 15
        ..hunger = 0
        ..health = 10;
      final r = e.endDay();
      expect(r.gameOver, isTrue);
      expect(r.won, isFalse);
      expect(s.over, isTrue);
      expect(s.won, isFalse);
    });

    test('คะแนนสรุป: เกรดรวมจากเกรดรายวัน และนับภัยที่รอด', () {
      final e = newEngine();
      final s = e.state
        ..gradePoints = 3 * 10
        ..gradeDays = 10
        ..survived = 3;
      expect(e.overallGrade, 'S');
      s
        ..gradePoints = 20
        ..gradeDays = 10;
      expect(e.overallGrade, 'A');
      s
        ..gradePoints = 15
        ..gradeDays = 10;
      expect(e.overallGrade, 'B');
      expect(e.summary.disastersSurvived, 3);
      keepFed(e);
      e.endDay();
      expect(s.gradeDays, 11);
    });
  });

  group('เซฟ/โหลด', () {
    test('เซฟแล้วโหลดได้โหมด ความคืบหน้า และภัยที่ปรับแต่งตรงเดิม', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = SaveRepository(await SharedPreferences.getInstance());
      for (final mode in Difficulty.values) {
        final e = engineFor(mode);
        final s = e.state
          ..day = 12
          ..gradePoints = 20
          ..gradeDays = 11
          ..survived = 2
          ..upcoming = UpcomingDisaster(
            type: DisasterType.heat,
            startDay: 15,
            severity: .7,
            customDuration: 4,
            customWarnDays: 2,
          );
        expect(await repo.save(2, s), isTrue);
        final l = repo.load(2);
        expect(l.mode, mode);
        expect(l.day, 12);
        expect(l.gradePoints, 20);
        expect(l.gradeDays, 11);
        expect(l.survived, 2);
        expect(l.upcoming!.duration, 4);
        expect(l.upcoming!.warnDays, 2);
        expect(GameEngine(l).stage, e.stage);
        expect(jsonEncode(l.toJson()), jsonEncode(s.toJson()));
      }
    });

    test('เซฟเก่าที่ไม่มีโหมด ถือเป็นปานกลาง', () {
      final j = newEngine().state.toJson()
        ..remove('mode')
        ..remove('won')
        ..remove('gp')
        ..remove('gd')
        ..remove('surv');
      final s = GameState.fromJson(j);
      expect(s.mode, Difficulty.normal);
      expect(s.won, isFalse);
      expect(GameEngine(s).targetDays, 30);
    });
  });
}
