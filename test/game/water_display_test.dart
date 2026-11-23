import 'package:aqua_farm/game/game_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'disaster_supply_test.dart' show beforeFlood;
import 'helpers.dart';

/// ค่าที่ใช้แสดงผลอย่างเดียว (สีค่าน้ำ ป้ายสถานะ คะแนนความพร้อม) — ไม่เปลี่ยนกติกา
void main() {
  group('ป้ายสถานะน้ำเป็นภาษาไทย', () {
    test('ชื่อสถานะ 4 ระดับ', () {
      expect(WaterStatus.values.map((w) => w.label), [
        'ดีมาก',
        'ดี',
        'เฝ้าระวัง',
        'อันตราย',
      ]);
    });
  });

  group('ระดับค่าน้ำรายตัว', () {
    test('เกมใหม่: ทุกค่าปกติ สถานะบ่อดีมาก ไม่มีคำแนะนำ', () {
      final e = newEngine();
      expect(e.ammoniaLevel, ValueLevel.good);
      expect(e.o2Level, ValueLevel.good);
      expect(e.pondStatus, WaterStatus.excellent);
      expect(e.waterAdvice, isNull);
    });

    test('แอมโมเนีย: ต่ำกว่า 0.5 ปกติ · 0.5 เริ่มสูง · 1.5 อันตราย', () {
      final e = newEngine();
      e.state.ammonia = .49;
      expect(e.ammoniaLevel, ValueLevel.good);
      e.state.ammonia = .83;
      expect(e.ammoniaLevel, ValueLevel.watch);
      e.state.ammonia = 1.5;
      expect(e.ammoniaLevel, ValueLevel.bad);
    });

    test('ออกซิเจนเทียบกับปลาในบ่อ (ปลานิลต้องการ 35)', () {
      final e = newEngine();
      e.state.money = 1000;
      e.buyFish('nila', 2);
      expect(e.pondO2Need, 35);
      e.state.o2 = 58;
      expect(e.o2Level, ValueLevel.good);
      e.state.o2 = 40;
      expect(e.o2Level, ValueLevel.watch);
      e.state.o2 = 30;
      expect(e.o2Level, ValueLevel.bad);
    });

    test('ป้ายบ่อไม่ดีกว่าค่าที่แย่ที่สุด (กรณีวันที่ 3: น้ำ 80% แต่แอมโมเนีย 0.83)', () {
      final e = newEngine();
      e.state
        ..ammonia = .83
        ..water = 80;
      expect(e.waterStatus, WaterStatus.excellent);
      expect(e.pondStatus, WaterStatus.good);
      expect(e.waterAdvice, contains('เปลี่ยนน้ำ'));
    });

    test('ออกซิเจนต่ำกว่าที่ปลาต้องการ = อันตราย และแนะนำเติมอากาศ', () {
      final e = newEngine();
      e.state.money = 1000;
      e.buyFish('nila', 2);
      e.state.o2 = 20;
      expect(e.pondStatus, WaterStatus.critical);
      expect(e.waterAdvice, contains('เติมอากาศ'));
    });

    test('ค่าแสดงผลไม่เปลี่ยนคะแนนน้ำ', () {
      final e = newEngine();
      e.state
        ..ammonia = .83
        ..nitrite = .12;
      e.calcWater();
      final before = e.state.water;
      e.pondStatus;
      e.waterAdvice;
      expect(e.state.water, before);
    });
  });

  group('คะแนนความพร้อมแยกส่วน', () {
    test('ผลรวมส่วนย่อยเท่ากับเปอร์เซ็นต์รวม', () {
      final e = beforeFlood();
      e.buyEquipment('sand');
      final r = e.readiness()!;
      expect(r.equipmentPts + r.supplyPts + r.waterPts + r.moneyPts, r.pct);
      expect(r.waterPts, 10);
      expect(r.moneyPts, 10);
    });

    test('ยังไม่มีอุปกรณ์: อุปกรณ์ 0/50 แต่เสบียง/น้ำ/เงินยังได้คะแนน', () {
      final e = beforeFlood();
      final r = e.readiness()!;
      expect(r.equipmentPts, 0);
      expect(r.pct, r.supplyPts + 20);
    });
  });
}
