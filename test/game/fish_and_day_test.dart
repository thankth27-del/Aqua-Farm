import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/ingredients.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('ข้อมูลปลา', () {
    test('มี 8 ชนิด ตัวเลขตรงต้นแบบ', () {
      expect(kFish.length, 8);
      final n = kFish['nila']!;
      expect(
        [n.buyPrice, n.sellPrice, n.toughness, n.o2Need, n.feed, n.yieldDishes],
        [40, 90, 4, 35, 1, 2],
      );
      final c = kFish['chon']!;
      expect(
        [c.buyPrice, c.sellPrice, c.growthMul, c.o2Need, c.feed],
        [70, 170, .5, 50, 3],
      );
      expect(kFish['nila']!.daysToGrow, 2);
      expect(kFish['chon']!.daysToGrow, 4);
      expect(kFish['tap']!.growthLabel, 'เร็ว');
      expect(kFish['carp']!.growthLabel, 'ช้ามาก');
    });
  });

  group('เกมใหม่', () {
    test('ค่าเริ่มต้นตรงต้นแบบ', () {
      final e = newEngine();
      final s = e.state;
      expect(s.money, 500);
      expect([s.hunger, s.energy, s.health, s.joy], [80, 100, 100, 70]);
      expect(s.water, 96); // round(100 - 0.2*22)
      expect(s.stock.single.food, 'dried');
      expect(s.stock.single.qty, 2);
      expect(s.upcoming!.startDay, 7);
      expect(s.prices, s.prevPrices);
      // random 0.5 → ราคา = round(ฐาน × 1.05)
      expect(s.prices['garlic'], 8);
      expect(s.prices['spice'], 11);
      expect(s.prices['salt'], 4);
    });

    test('ราคาวัตถุดิบสุ่มอยู่ในช่วง 0.6-1.5 เท่าของฐาน และขั้นต่ำ 2', () {
      final e = GameEngine.newGame('x');
      for (var i = 0; i < 200; i++) {
        e.rollPrices();
        for (final ing in kIngredients.values) {
          final p = e.state.prices[ing.id]!;
          expect(p, greaterThanOrEqualTo(2));
          expect(
            p,
            inInclusiveRange(
              (ing.basePrice * .6).round() - 1,
              (ing.basePrice * 1.5).round(),
            ),
          );
        }
      }
    });
  });

  group('ซื้อปลา', () {
    test('ซื้อสำเร็จ หักเงิน ปล่อยลงบ่อ', () {
      final e = newEngine();
      final r = e.buyFish('nila', 3);
      expect(r.ok, isTrue);
      expect(r.message, 'ซื้อปลานิล 3 ตัว ปล่อยลงบ่อแล้ว');
      expect(e.state.money, 500 - 120);
      expect(e.state.pond.length, 3);
      expect(
        e.state.pond.every((f) => f.growth == 0 && f.health == 100),
        isTrue,
      );
      expect(e.state.energy, 100, reason: 'ซื้อปลาไม่ใช้พลังงาน');
    });

    test('บ่อเต็ม 8 ตัวซื้อเพิ่มไม่ได้', () {
      final e = newEngine();
      expect(e.buyFish('tap', 8).ok, isTrue);
      final r = e.buyFish('tap', 1);
      expect(r.ok, isFalse);
      expect(r.message, 'พื้นที่ในบ่อไม่พอ (ว่าง 0 ตัว)');
      expect(e.state.pond.length, kPondCapacity);
    });

    test('เงินไม่พอ', () {
      final e = newEngine();
      e.state.money = 100;
      final r = e.buyFish('chon', 2);
      expect(r.ok, isFalse);
      expect(r.message, 'เงินไม่พอ ต้องใช้ 140 บาท');
      expect(e.state.money, 100);
      expect(e.state.pond, isEmpty);
    });

    test('ตลาดปิดซื้อไม่ได้', () {
      final e = newEngine();
      e.state.marketClosed = true;
      expect(e.buyFish('nila', 1).ok, isFalse);
      expect(e.state.pond, isEmpty);
    });
  });

  group('บ่อและจบวัน', () {
    test('จบวันวันแรก: คุณภาพน้ำ การโต ความอิ่ม เกรด ตรงสูตรต้นแบบ', () {
      final e = newEngine();
      final s = e.state;
      e.buyFish('nila', 2);
      final f = e.feed(2);
      expect(f.message, 'ให้อาหารพอดี ปลาโตดี');
      expect(s.money, 500 - 80 - 4); // feedCost(2) = 2 × feedUnit 2
      expect(s.energy, 97);

      final r = e.endDay();
      // am = .2 + .25 + 2*.05 = .55 → ผ่านไบโอฟิลเตอร์ 10%
      expect(s.ammonia, .52);
      expect(s.nitrite, .03);
      expect(s.nitrate, 0);
      expect(s.bio, 18);
      expect(s.o2, 77); // 90 - 10 - 2*1.5
      expect(s.water, 88);
      expect(s.pond.map((f) => f.growth), [50, 50]);
      expect(s.pond.map((f) => f.health), [100, 100]);
      expect(s.hunger, 60);
      expect(s.energy, 100);
      expect(s.joy, 68);
      expect(s.day, 2);
      expect(s.fed, 0);
      expect(s.stock.single.age, 1);
      expect(r.supplyDays, 2.0);
      expect(r.grade, 'A');
      expect(e.warnDays, 5, reason: 'น้ำท่วมวันที่ 7 แจ้งล่วงหน้า 5 วัน');
      expect(s.prevPrices, isNotEmpty);
    });

    test('ให้อาหารพอดี 2 วัน ปลานิลโตพร้อมจับ แล้วจับและขาย', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      for (var i = 0; i < 2; i++) {
        e.feed(2);
        e.endDay();
      }
      expect(e.matureCount, 1);
      final c = e.catchFish();
      expect(c.message, 'จับปลาได้ 1 ตัว');
      expect(e.state.pond, isEmpty);
      expect(e.state.fishStock['nila'], 1);
      final money = e.state.money;
      expect(e.sellFish('nila').ok, isTrue);
      expect(e.state.money, money + 90);
      expect(e.state.earned, 90);
      expect(e.sellFish('nila').ok, isFalse);
    });

    test('ให้อาหารซ้ำวันเดียวกันไม่ได้ / ไม่มีปลาให้อาหารไม่ได้', () {
      final e = newEngine();
      expect(e.feed(2).message, 'ยังไม่มีปลาในบ่อ');
      e.buyFish('nila', 1);
      expect(e.feed(3).warning, isTrue);
      expect(e.feed(1).message, 'วันนี้ให้อาหารแล้ว');
    });

    test(
      'เงินหมด: ให้อาหาร "น้อย" ฟรี (ลุงทองช่วย) แต่ พอดี/มาก ยังต้องจ่าย',
      () {
        final e = newEngine();
        e.buyFish('nila', 2);
        e.state.money = 0;
        expect(e.freeFeed, isTrue);
        expect(e.feed(2).ok, isFalse);
        final energy = e.state.energy;
        final r = e.feed(1);
        expect(r.ok, isTrue);
        expect(r.message, contains('ลุงทอง'));
        expect(e.state.money, 0);
        expect(e.state.fed, 1);
        expect(e.state.energy, energy - kFeedEnergy);
      },
    );

    test(
      'บ่อว่าง ไม่มีปลาเหลือ เงินไม่พอซื้อปลา → ลุงทองให้ลูกปลานิล 2 ตัวฟรี',
      () {
        final e = newEngine();
        e.state.money = 10;
        expect(e.freeFish, isTrue);
        expect(e.buyFish('nila', 3).ok, isFalse);
        final r = e.buyFish('nila', 2);
        expect(r.ok, isTrue);
        expect(r.message, contains('ลุงทอง'));
        expect(e.state.pond.length, 2);
        expect(e.state.money, 10);
        expect(e.freeFish, isFalse);
        // มีเงินพอซื้อเอง → ไม่ฟรี
        final rich = newEngine();
        expect(rich.freeFish, isFalse);
      },
    );

    test('ให้อาหารมาก: ปลาโตช้าจับได้เร็วขึ้น 1 วัน ปลาโตเร็วเท่าเดิม', () {
      expect(kFish['nila']!.daysToGrowAt(3), kFish['nila']!.daysToGrow);
      expect(kFish['swai']!.daysToGrow, 3);
      expect(kFish['swai']!.daysToGrowAt(3), 2);
      expect(kFish['carp']!.daysToGrowAt(3), 3);
    });

    test('มีเงินพอ "น้อย" → ไม่ฟรี จ่ายตามปกติ', () {
      final e = newEngine();
      e.buyFish('nila', 2);
      e.state.money = e.feedCost(1);
      expect(e.freeFeed, isFalse);
      expect(e.feed(1).ok, isTrue);
      expect(e.state.money, 0);
    });

    test('เตือนเมื่อซื้อแล้วเงินเหลือไม่พอค่าอาหาร "พอดี" 2 วัน', () {
      final e = newEngine();
      e.buyFish('nila', 2);
      final reserve = e.feedReserve();
      expect(reserve, e.feedCost(2) * kFeedReserveDays);
      e.state.money = 100 + reserve;
      expect(e.lowMoneyWarning(100), isNull);
      expect(e.lowMoneyWarning(101), contains('ไม่พอค่าอาหารปลา'));
      // ซื้อปลาเพิ่ม → นับค่าอาหารของปลาใหม่ด้วย
      expect(e.feedReserve(extraUnits: 2), greaterThan(reserve));
      // บ่อว่าง ไม่มีค่าอาหาร → ไม่เตือน
      final empty = newEngine()..state.money = 10;
      expect(empty.lowMoneyWarning(10), isNull);
    });

    test('เปลี่ยนน้ำและเติมอากาศ', () {
      final e = newEngine();
      final s = e.state
        ..ammonia = 1
        ..nitrite = 1
        ..nitrate = 10
        ..o2 = 50;
      e.changeWater();
      expect(s.ammonia, closeTo(.3, 1e-9));
      expect(s.nitrate, closeTo(3, 1e-9));
      expect(s.o2, 65);
      expect(s.money, 480);
      expect(s.energy, 92);
      e.aerate();
      expect(s.o2, 100);
      expect(s.money, 465);
    });

    test('น้ำแย่และออกซิเจนต่ำทำให้ปลาบอบบางตาย', () {
      final e = newEngine();
      e.buyFish('nuan', 1);
      e.buyFish('dook', 1);
      final s = e.state
        ..ammonia = 4
        ..o2 = 20;
      for (var i = 0; i < 3; i++) {
        keepFed(e);
        e.endDay();
      }
      expect(s.pond.map((f) => f.type), [
        'dook',
      ], reason: 'ปลาดุกทนที่สุด ปลานวลจันทร์บอบบาง');
    });

    test('พักผ่อน', () {
      final e = newEngine();
      expect(e.rest().message, 'พลังงานเต็มแล้ว');
      e.state.energy = 50;
      e.rest();
      expect(e.state.energy, 90);
      expect(e.state.hunger, 75);
      expect(e.state.joy, 73);
    });

    test('ตั้งเป้าหมายเสบียงได้เฉพาะ 3/5/7/10', () {
      final e = newEngine();
      for (final g in kSupplyGoals) {
        expect(e.setGoal(g).ok, isTrue);
        expect(e.state.goal, g);
      }
      expect(e.setGoal(4).ok, isFalse);
    });

    test('สถานะคุณภาพน้ำ', () {
      final e = newEngine();
      e.state.water = 80;
      expect(e.waterStatus, WaterStatus.excellent);
      e.state.water = 59;
      expect(e.waterStatus, WaterStatus.warning);
      e.state.water = 39;
      expect(e.waterStatus, WaterStatus.critical);
    });
  });
}
