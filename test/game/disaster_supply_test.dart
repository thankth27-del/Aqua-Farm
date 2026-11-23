import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// วันที่ 6 พรุ่งนี้น้ำท่วม (เริ่มวันที่ 7) ปลานิล 8 ตัวในบ่อ อาหารสุก 3 จาน
GameEngine beforeFlood() {
  final e = newEngine();
  final s = e.state;
  s.day = 6;
  s.money = 5000;
  e.buyFish('nila', 8);
  s.stock
    ..clear()
    ..add(StockBatch(food: 'fry', qty: 3))
    ..add(StockBatch(food: 'canned', qty: 4));
  return e;
}

void main() {
  group('น้ำท่วม 4 วัน', () {
    test('ข่าวเตือนล่วงหน้า 5 วัน', () {
      final e = newEngine();
      final seen = <int>[];
      for (var d = 1; d <= 6; d++) {
        seen.add(e.warnDays);
        keepFed(e);
        e.endDay();
      }
      expect(seen, [0, 5, 4, 3, 2, 1]);
      expect(e.state.day, 7);
      expect(e.state.active!.type, DisasterType.flood);
    });

    test('ไม่มีอุปกรณ์: ปลาหาย ไฟดับ/ตลาดปิดวัน 2-3 อาหารเสียหาย มีค่าซ่อม แล้วประกาศภัยถัดไป', () {
      final e = beforeFlood();
      final s = e.state;
      final events = <EventReport>[];
      final power = <bool>[];
      final market = <bool>[];
      for (var i = 0; i < 4; i++) {
        keepFed(e);
        final r = e.endDay();
        events.add(r.event!);
        power.add(s.power);
        market.add(s.marketClosed);
        if (i == 1) {
          expect(
            e.buyFish('nila', 1).message,
            'ตลาดปิดชั่วคราว เส้นทางถูกตัดขาดจากภัยพิบัติ',
          );
          expect(e.buyIngredient('salt').ok, isFalse);
          expect(e.buyEquipment('sand').ok, isFalse);
          expect(e.supplyNeedDays, 2);
        }
      }
      expect(events.map((x) => x.dayIndex), [0, 1, 2, 3]);
      expect(
        events.map((x) => x.text),
        kDisasters[DisasterType.flood]!.dayTexts,
      );
      expect(power, [true, false, false, true]);
      expect(market, [false, true, true, false]);
      expect(events.map((x) => x.protectionPct), everyElement(0));
      expect(events.map((x) => x.cost), everyElement(20)); // 40 × 0.5
      expect(s.repairCost, 80);
      expect(s.damaged, isTrue);
      final lostTotal = events.fold<int>(0, (a, x) => a + x.lost);
      expect(lostTotal, greaterThan(0));
      expect(events.last.cumulativeLost, lostTotal);
      expect(s.pond.length, 8 - lostTotal);
      expect(
        events.last.food,
        0,
        reason: 'วันที่ 4 ตลาดเปิด ไม่มีอาหารเสียหายจากน้ำ',
      );
      expect(events.last.cumulativeFood, greaterThan(0));
      expect(
        s.stock.where((b) => b.food == 'canned').single.qty,
        4,
        reason: 'ปลากระป๋องไม่เสียหายจากน้ำ',
      );
      expect(events.last.last, isTrue);
      expect(events.last.supplyDaysAfter, isNotNull);
      // ภัยถัดไปตามลำดับ: น้ำท่วม → ภัยแล้ง เริ่ม วันที่ 10 + 3 + 3
      expect(s.active, isNull);
      expect(s.upcoming!.type, DisasterType.drought);
      expect(s.upcoming!.startDay, 16);
      expect(s.upcoming!.severity, .55);
    });

    test('อุปกรณ์ครบ (กระสอบทราย 4 เครื่องสูบ ตาข่าย): ป้องกันเต็มทุกวัน ใช้กระสอบวันละใบ', () {
      final e = beforeFlood();
      final s = e.state;
      for (var i = 0; i < 4; i++) {
        e.buyEquipment('sand');
      }
      e.buyEquipment('pump');
      e.buyEquipment('net');
      expect(e.readiness()!.equipmentRatio, 1);
      var lost = 0;
      for (var i = 0; i < 4; i++) {
        keepFed(e);
        final ev = e.endDay().event!;
        expect(ev.protectionPct, 100, reason: 'วันที่ ${i + 1}');
        expect(ev.cost, 8); // round(40 × 0.5 × 0.4)
        expect(ev.food, 0);
        lost += ev.lost;
      }
      expect(lost, 0);
      expect(s.equipmentCount('sand'), 0);
      expect(s.pond.length, 8);
      expect(s.repairCost, 32);
    });

    test('ซ่อมแซมและฟื้นฟูหลังภัย', () {
      final e = beforeFlood();
      for (var i = 0; i < 4; i++) {
        keepFed(e);
        e.endDay();
      }
      final s = e.state..energy = 100;
      final money = s.money;
      final am = s.ammonia;
      final joy = s.joy;
      expect(e.repair().message, 'ซ่อมแซมและฟื้นฟูฟาร์มเรียบร้อย');
      expect(s.money, money - 80);
      expect(s.energy, 85);
      expect(s.damaged, isFalse);
      expect(s.repairCost, 0);
      expect(s.ammonia, closeTo(am * .5, 1e-9));
      expect(s.joy, joy + 10);
      expect(e.repair().ok, isFalse);
    });

    test(
      'ภัยอื่น: แล้งเพิ่มอุณหภูมิ น้ำเสียเพิ่มแอมโมเนีย ร้อนจัดไฟดับวันที่ 2',
      () {
        for (final t in [
          DisasterType.drought,
          DisasterType.poll,
          DisasterType.heat,
        ]) {
          final e = newEngine();
          e.state.upcoming = UpcomingDisaster(
            type: t,
            startDay: 2,
            severity: .5,
          );
          final outs = <bool>[];
          for (var i = 0; i < kDisasters[t]!.duration; i++) {
            keepFed(e);
            final ev = e.endDay().event!;
            expect(ev.type, t);
            outs.add(ev.outage);
          }
          expect(outs, kDisasters[t]!.powerOut);
          expect(e.state.active, isNull);
          expect(
            e.state.upcoming!.type,
            kDisasterOrder[(kDisasterOrder.indexOf(t) + 1) % 4],
          );
        }
      },
    );
  });

  group('เสบียง', () {
    test('คำนวณเสบียงจากความอิ่ม ไม่ใช่นับจาน', () {
      final e = newEngine();
      e.state.stock
        ..clear()
        ..add(StockBatch(food: 'fry', qty: 3)) // 75
        ..add(StockBatch(food: 'salted', qty: 1)); // 22
      expect(e.servings, 4);
      expect(e.supplyHunger, 97);
      expect(e.supplyDays, 4.9);
      // ภัยครั้งถัดไป = น้ำท่วม 4 วัน
      expect(e.supplyNeedDays, 4);
      expect(e.supplyAfterDisaster, .9);
      e.setGoal(10);
      expect(e.goalReached, isFalse);
      expect(e.goalProgressPct, 49);
      expect(e.goalShortfall, 5.1);
      e.setGoal(3);
      expect(e.goalReached, isTrue);
      expect(e.goalProgressPct, 100);
    });

    test('อาหารหมดอายุไม่นับเป็นเสบียง', () {
      final e = newEngine();
      e.state.stock
        ..clear()
        ..add(StockBatch(food: 'fry', qty: 2, age: 3));
      expect(e.supplyDays, 0);
    });

    test('เสบียงไม่พอ: เสบียงขาดก่อนภัย ความพร้อมต่ำ และขาดอาหารจนสุขภาพหมด = Game Over', () {
      final e = newEngine();
      final s = e.state;
      s.stock.clear();
      expect(e.supplyAfterDisaster, -4);

      final hp = <int>[];
      DayReport? last;
      while (!s.over && s.day < 30) {
        last = e.endDay();
        hp.add(s.health);
      }
      // อิ่ม 80→60→40→20→0: วันที่ 3-4 สุขภาพคงที่ แล้วลด 20/วัน เมื่ออิ่มเป็น 0
      expect(hp, [100, 100, 100, 80, 60, 40, 20, 0]);
      expect(s.over, isTrue);
      expect(last!.gameOver, isTrue);
    });

    test('ความหิว < 20 ลดสุขภาพ 5 และ > 50 ฟื้น 5', () {
      final e = newEngine();
      e.state
        ..hunger = 35
        ..health = 50;
      e.endDay();
      expect(e.state.health, 45);
      e.state.hunger = 75;
      e.endDay();
      expect(e.state.health, 50);
    });
  });

  group('เกรด', () {
    test('S เมื่อรายได้สูง น้ำดี เสบียงพอ', () {
      final e = newEngine();
      e.state.earned = 250;
      e.state.stock.add(StockBatch(food: 'canned', qty: 4));
      expect(e.endDay().grade, 'S');
    });

    test('B เมื่อไม่มีรายได้ น้ำแย่ และฟาร์มเสียหาย', () {
      final e = newEngine();
      e.state
        ..ammonia = 5
        ..damaged = true
        ..stock.clear();
      expect(e.endDay().grade, 'B');
    });
  });
}
