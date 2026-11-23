import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

GameEngine kitchen() {
  final e = newEngine();
  e.state.fishStock['nila'] = 5;
  e.state.fishStock['carp'] = 2;
  for (final k in e.state.inventory.keys) {
    e.state.inventory[k] = 10;
  }
  e.state.stock.clear();
  return e;
}

void main() {
  group('ครัว 5 เมนู', () {
    test('มี 5 เมนู ทำได้ทุกเมนู ได้จานตาม yield ของปลา', () {
      expect(kRecipes.length, 5);
      for (final r in kRecipes.keys) {
        final e = kitchen();
        final before = Map.of(e.state.inventory);
        final res = e.cook(r);
        expect(res.ok, isTrue, reason: r);
        expect(e.state.fishStock['nila'], 4);
        expect(e.state.energy, 92);
        kRecipes[r]!.need.forEach(
          (k, v) => expect(e.state.inventory[k], before[k]! - v),
        );
        expect(e.state.stock.single.food, r);
        expect(e.state.stock.single.qty, 2);
      }
    });

    test('ปลาทอดด้วยปลานิล: ข้อความตรงต้นแบบ', () {
      final e = kitchen();
      expect(e.cook('fry').message, 'ทำปลาทอดได้ 2 จาน (ใช้ปลานิล)');
    });

    test('เลือกปลาคาร์พได้ 3 จาน และรวมล็อตอายุ 0', () {
      final e = kitchen();
      e.setCookFish('carp');
      e.cook('tomyum');
      e.cook('tomyum');
      expect(e.state.stock.single.qty, 6);
      expect(e.state.fishStock['carp'], 0);
      e.cook('tomyum'); // ปลาคาร์พหมด กลับไปใช้ปลาตัวแรกที่มี
      expect(e.state.fishStock['nila'], 4);
    });

    test('วัตถุดิบไม่พอ / ไม่มีปลา / พลังงานไม่พอ', () {
      final e = kitchen();
      e.state.inventory['spice'] = 0;
      expect(e.cook('fry').message, 'วัตถุดิบไม่พอ');
      e.state.fishStock.updateAll((k, v) => 0);
      expect(e.canCook('tomyum'), isFalse);
      final e2 = kitchen()..state.energy = 5;
      expect(e2.cook('fry').message, 'พลังงานไม่พอ ไปพักผ่อนที่บ้านก่อน');
    });

    test('กินอาหาร เพิ่มความอิ่ม พลังงาน ความสุข และอิ่มแล้วกินไม่ได้', () {
      final e = kitchen();
      e.cook('tomyum');
      e.state
        ..hunger = 50
        ..energy = 50;
      final r = e.eatStock(0);
      expect(r.message, 'กินต้มยำปลา อิ่ม +32 พลังงาน +15');
      expect(e.state.hunger, 82);
      expect(e.state.energy, 65);
      expect(e.state.joy, 74);
      expect(e.state.stock.single.qty, 1);
      e.state.hunger = 100;
      expect(e.eatStock(0).message, 'อิ่มแล้ว');
    });

    test('ขายและทิ้งอาหาร', () {
      final e = kitchen();
      e.cook('bake');
      // ราคาขายอาหาร ×0.6 จากต้นแบบ (140 → 84)
      expect(e.sellStock(0).message, 'ขายปลาอบ +84 บาท');
      expect(e.state.earned, 84);
      expect(e.discardStock(0).ok, isTrue);
      expect(e.state.stock, isEmpty);
    });
  });

  group('ถนอมอาหาร 4 วิธี', () {
    test('ตากแห้งต้องมีแผงตาก เสร็จใน 2 วัน', () {
      final e = kitchen();
      expect(
        e.startPreserve('dried').message,
        'ต้องมีแผงตากปลาว่างอยู่ (ซื้อที่ตลาด)',
      );
      expect(e.buyEquipment('rack').ok, isTrue);
      expect(e.state.money, 440);
      final r = e.startPreserve('dried');
      expect(r.message, 'เริ่มตากแห้ง (Drying) ใช้เวลา 2 วัน');
      expect(e.state.processing.single.qty, 2);
      // แผงเดียวทำได้ทีละงาน
      expect(e.canPreserve('dried'), isFalse);

      keepFed(e);
      final d1 = e.endDay();
      expect(d1.done, isEmpty);
      keepFed(e);
      final d2 = e.endDay();
      expect(d2.done.single.food, 'dried');
      expect(d2.done.single.qty, 2);
      expect(e.state.processing, isEmpty);
      final b = e.state.stock.single;
      expect(b.food, 'dried');
      expect(b.age, 1, reason: 'ของที่เสร็จคืนนั้นถูกนับอายุทันทีเหมือนต้นแบบ');
    });

    test('หมักเกลือใช้เกลือ 2 + โหล 3 วัน / ดองใช้โหลร่วมกัน / กระป๋องต้องมีเครื่องบรรจุ', () {
      final e = kitchen();
      e.buyEquipment('jar');
      expect(e.startPreserve('salted').ok, isTrue);
      expect(e.state.inventory['salt'], 8);
      expect(
        e.startPreserve('pickled').ok,
        isFalse,
        reason: 'โหลเดียวถูกใช้แล้ว',
      );
      e.buyEquipment('jar');
      expect(e.startPreserve('pickled').ok, isTrue);
      expect(e.state.inventory['vin'], 9);
      expect(e.startPreserve('canned').ok, isFalse);
      e.buyEquipment('canner');
      expect(e.startPreserve('canned').ok, isTrue);
      expect(e.state.inventory['cans'], 9);
      expect(e.state.processing.map((p) => p.daysLeft), [3, 2, 2]);
    });

    test('วันหมดอายุ: อาหารสุก 3 วัน หมดอายุแล้วกินไม่ได้ และนับจานเสีย', () {
      final e = kitchen();
      e.cook('fry');
      for (var i = 0; i < 2; i++) {
        keepFed(e);
        e.endDay();
      }
      expect(e.freshness(e.state.stock.single), Freshness.near);
      keepFed(e);
      final r = e.endDay();
      expect(r.spoiled, 2);
      expect(e.isExpired(e.state.stock.single), isTrue);
      expect(e.eatStock(0).message, 'อาหารหมดอายุ กินไม่ได้');
      expect(e.servings, 0);
    });

    test('ตู้เย็น: อาหารสุกเสื่อม 0.5/วัน ต้องมีไฟ / ไฟดับเสื่อม 1.5/วัน / อาหารถนอม 1/วัน', () {
      final e = kitchen();
      e.state.money = 2000;
      e.buyEquipment('fridge');
      e.cook('fry');
      e.state.stock.add(StockBatch(food: 'canned', qty: 1));
      keepFed(e);
      e.endDay();
      expect(e.state.stock[0].age, .5);
      expect(e.state.stock[1].age, 1);

      e.state.power = false; // ไฟดับ (เช่น ระหว่างภัย)
      expect(e.fridgeWorking, isFalse);
      keepFed(e);
      e.endDay();
      expect(e.state.stock[0].age, 2);
    });
  });
}
