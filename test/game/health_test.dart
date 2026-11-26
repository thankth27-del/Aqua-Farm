// ดูแลน้ำ (เครื่องเติมอากาศ ตัวกรอง ชุดตรวจน้ำ) และโรคปลา (ป่วย รักษา แยกบ่อ ระบาด)
import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// สุ่มได้ 0 เสมอ = โอกาสมากกว่า 0 เกิดแน่นอน
GameEngine unlucky() => GameEngine.newGame('ทดสอบ', random: FixedRandom(0));

/// น้ำใสสะอาด ออกซิเจนเต็ม (ไม่ให้ค่าน้ำรบกวนการทดสอบโรค)
void cleanWater(GameEngine e) {
  e.state
    ..ammonia = 0
    ..nitrite = 0
    ..nitrate = 0
    ..o2 = 100
    ..temp = 28;
  e.calcWater();
}

void main() {
  group('ตัวกรอง', () {
    test('ให้อาหารแล้วตัวกรองสกปรกขึ้น ตามปริมาณอาหาร', () {
      final e = newEngine();
      e.buyFish('nila', 2);
      e.feed(2);
      keepFed(e);
      e.endDay();
      expect(e.state.filterDirt, kFilterDirtPerDay[2]);
      e.feed(3);
      keepFed(e);
      e.endDay();
      expect(e.state.filterDirt, kFilterDirtPerDay[2] + kFilterDirtPerDay[3]);
    });

    test('ตัวกรองสกปรก กรองแอมโมเนียได้น้อยลง', () {
      double ammoniaAfter(int dirt) {
        final e = newEngine();
        e.buyFish('nila', 2);
        e.state
          ..bio = 80
          ..filterDirt = dirt;
        e.feed(2);
        e.endDay();
        return e.state.ammonia;
      }

      expect(ammoniaAfter(100), greaterThan(ammoniaAfter(0)));
    });

    test('ล้างตัวกรอง: สกปรกเป็น 0 แบคทีเรียลด 10 · ยังสะอาดล้างไม่ได้', () {
      final e = newEngine();
      final s = e.state
        ..filterDirt = 5
        ..bio = 50;
      expect(e.cleanFilter().ok, isFalse);
      s.filterDirt = 60;
      final energy = s.energy;
      expect(e.cleanFilter().ok, isTrue);
      expect(s.filterDirt, 0);
      expect(s.bio, 40);
      expect(s.energy, energy - kCleanFilterEnergy);
      expect(s.money, 500, reason: 'ล้างตัวกรองฟรี');
    });
  });

  group('เครื่องเติมอากาศ', () {
    test('ไม่มีเครื่อง เปิดไม่ได้', () {
      final e = newEngine();
      expect(e.toggleAerator().ok, isFalse);
      expect(e.state.aeratorOn, isFalse);
    });

    test('เปิดไว้: ออกซิเจนตอนเช้าไม่ต่ำกว่า 80 เสียค่าไฟคืนละ 5', () {
      final e = newEngine();
      e.buyFish('nila', 4);
      e.buyEquipment('air');
      final s = e.state..o2 = 20;
      expect(e.toggleAerator().ok, isTrue);
      final money = s.money;
      keepFed(e);
      final r = e.endDay();
      expect(s.o2, kAeratorO2Floor);
      expect(r.aeratorCost, kAeratorPowerCost);
      expect(s.money, money - kAeratorPowerCost);
      // ปิดแล้วออกซิเจนลดตามปกติ ไม่เสียค่าไฟ
      e.toggleAerator();
      keepFed(e);
      expect(e.endDay().aeratorCost, 0);
      expect(s.o2, lessThan(kAeratorO2Floor));
    });

    test('ไฟดับ = ไม่ทำงาน · เงินไม่พอค่าไฟ = ปิดเอง', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      e.buyEquipment('air');
      e.toggleAerator();
      final s = e.state
        ..power = false
        ..o2 = 30;
      keepFed(e);
      expect(e.endDay().aeratorCost, 0);
      expect(s.o2, lessThan(30));
      s.money = 2;
      keepFed(e);
      final r = e.endDay();
      expect(r.aeratorOff, isTrue);
      expect(s.aeratorOn, isFalse);
      expect(s.money, 2);
    });

    test('เนื้อเรื่อง: เงินไม่พอเติมอากาศ ปลาขาดออกซิเจน → ลุงทองให้ยืมเครื่องฟรี', () {
      final e = newEngine();
      e.state.storyMode = true;
      e.buyFish('nila', 1);
      final s = e.state
        ..money = 3
        ..o2 = 10;
      expect(e.freeAerate, isTrue);
      final r = e.aerate();
      expect(r.ok, isTrue);
      expect(r.message, contains('ลุงทอง'));
      expect(s.o2, 100);
      expect(s.money, 3);
      // มีเงินพอ จ่ายเองตามปกติ
      final rich = newEngine()..buyFish('nila', 1);
      rich.state
        ..storyMode = true
        ..o2 = 10;
      expect(rich.freeAerate, isFalse);
    });

    test('โหมดเอาชีวิตรอด: ไม่มีเครื่องเติมอากาศฟรี', () {
      final e = newEngine()..buyFish('nila', 1);
      e.state
        ..money = 3
        ..o2 = 10;
      expect(e.freeAerate, isFalse);
      expect(e.aerate().ok, isFalse);
      // เซฟ/โหลดจำโหมดได้
      e.state.storyMode = true;
      expect(GameState.fromJson(e.state.toJson()).storyMode, isTrue);
    });
  });

  group('ชุดตรวจน้ำ', () {
    test('ต้องมีชุดตรวจ · ตรวจได้วันละครั้ง', () {
      final e = newEngine();
      expect(e.testWater().ok, isFalse);
      e.buyEquipment('kit');
      expect(e.state.testedToday, isFalse);
      expect(e.testWater().ok, isTrue);
      expect(e.state.testedToday, isTrue);
      expect(e.testWater().ok, isFalse);
      keepFed(e);
      e.endDay();
      expect(e.state.testedToday, isFalse, reason: 'วันใหม่ต้องตรวจใหม่');
    });
  });

  group('โรคปลา', () {
    test('น้ำแย่ติดกัน 2 วัน → ปลาเริ่มป่วยเป็นโรคตัวด่าง', () {
      final e = unlucky();
      e.buyFish('nila', 2);
      final s = e.state;
      for (var i = 0; i < 2; i++) {
        s
          ..ammonia = 2
          ..o2 = 100;
        e.calcWater();
        keepFed(e);
        e.endDay();
      }
      expect(s.badWaterDays, greaterThanOrEqualTo(kSickBadWaterDays));
      expect(s.pond.where((f) => f.disease == 'spot'), isNotEmpty);
    });

    test('น้ำดี ไม่มีภัย ไม่ป่วย', () {
      final e = unlucky();
      e.buyFish('nila', 3);
      for (var i = 0; i < 3; i++) {
        cleanWater(e);
        keepFed(e);
        e.feed(2);
        e.endDay();
      }
      expect(e.sickCount, 0);
    });

    test('ปิดระบบโรค (เนื้อเรื่องก่อนบทปลาป่วย) ไม่ติดเชื้อใหม่', () {
      final e = unlucky();
      e.buyFish('nila', 2);
      e.state
        ..diseaseOn = false
        ..badWaterDays = 5
        ..ammonia = 3;
      e.calcWater();
      keepFed(e);
      e.endDay();
      expect(e.sickCount, 0);
    });

    test(
      'ป่วยไม่รักษา: ไม่โต สุขภาพลดวันละ 15 ตายใน 3 วัน (ปลาทนอยู่ได้ 4 วัน)',
      () {
        final e = newEngine();
        e.buyFish('tap', 1); // ทน 3
        e.buyFish('nila', 1); // ทน 4
        final s = e.state;
        for (final f in s.pond) {
          f.disease = 'spot';
        }
        final alive = <int>[];
        for (var i = 0; i < 4; i++) {
          cleanWater(e);
          keepFed(e);
          e.feed(2);
          final r = e.endDay();
          if (i == 0) {
            expect(s.pond.map((f) => f.growth), everyElement(0));
            expect(
              s.pond.map((f) => f.health),
              everyElement(100 - kSickDamage),
            );
          }
          alive.add(s.pond.length);
          if (i == 2) expect(r.diseaseDied, 1);
        }
        expect(alive, [2, 2, 1, 0]);
      },
    );

    test('ยาถูกโรค + น้ำดี: หายใน 2 วัน ไม่ทรุดระหว่างรักษา', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      final s = e.state;
      final f = s.pond.single..disease = 'spot';
      expect(e.treat(0, 'kmno4').ok, isFalse, reason: 'ยังไม่มียา');
      expect(e.buyMedicine('kmno4').ok, isTrue);
      expect(s.money, 500 - 40 - e.medicinePrice('kmno4'));
      final r = e.treat(0, 'kmno4');
      expect(r.ok, isTrue);
      expect(r.warning, isFalse);
      expect(e.medCount('kmno4'), 0);
      expect(f.treatDays, kTreatDays);
      cleanWater(e);
      keepFed(e);
      e.endDay();
      expect(f.sick, isTrue);
      expect(f.health, 100);
      cleanWater(e);
      keepFed(e);
      expect(e.endDay().cured, 1);
      expect(f.sick, isFalse);
    });

    test('ยาผิดโรค: เสียยา อาการไม่ดีขึ้น (เตือน)', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      final f = e.state.pond.single..disease = 'ich';
      e.buyMedicine('antibio');
      final r = e.treat(0, 'antibio');
      expect(r.ok, isTrue);
      expect(r.warning, isTrue);
      expect(r.message, contains('ไม่ตรง'));
      expect(e.medCount('antibio'), 0);
      expect(f.treatDays, 0);
    });

    test('จุดขาวรักษาด้วยเกลือ 2 ถุง', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      e.state.pond.single.disease = 'ich';
      e.buyMedicine('salt');
      expect(e.treat(0, 'salt').ok, isFalse, reason: 'ต้องใช้เกลือ 2 ถุง');
      e.buyMedicine('salt');
      expect(e.medCount('salt'), 2);
      expect(e.treat(0, 'salt').ok, isTrue);
      expect(e.state.inventory['salt'], 0);
    });

    test('ไม่แก้ต้นเหตุ: น้ำต่ำกว่าเส้นอันตราย ยาไม่ได้ผล', () {
      final e = newEngine();
      e.buyFish('dook', 1);
      final f = e.state.pond.single..disease = 'spot';
      e.buyMedicine('kmno4');
      e.state.ammonia = 4;
      e.calcWater();
      expect(e.state.water, lessThan(kWaterDangerLine));
      expect(e.treat(0, 'kmno4').warning, isTrue);
      keepFed(e);
      final r = e.endDay();
      expect(r.treatFailed, 1);
      expect(f.treatDays, 0);
      expect(f.sick, isTrue);
    });

    test('ปลาป่วยแพร่เชื้อ · แยกไปบ่อพักแล้วไม่แพร่', () {
      GameEngine pond({required bool isolate}) {
        final e = unlucky();
        e.buyFish('nila', 3);
        e.state.pond.first.disease = 'ich';
        if (isolate) {
          expect(e.toggleQuarantine(0).ok, isFalse, reason: 'ยังไม่มีบ่อพัก');
          e.buyEquipment('qtank');
          expect(e.toggleQuarantine(0).ok, isTrue);
        }
        cleanWater(e);
        keepFed(e);
        e.endDay();
        return e;
      }

      expect(pond(isolate: false).sickCount, 3);
      expect(pond(isolate: true).sickCount, 1);
    });

    test('บ่อพัก 1 บ่อ จุ 2 ตัว', () {
      final e = newEngine();
      e.buyFish('nila', 3);
      e.buyEquipment('qtank');
      expect(e.quarantineFree, kQuarantineSlots);
      expect(e.toggleQuarantine(0).ok, isTrue);
      expect(e.toggleQuarantine(1).ok, isTrue);
      expect(e.toggleQuarantine(2).ok, isFalse);
      expect(e.toggleQuarantine(0).ok, isTrue, reason: 'ย้ายกลับบ่อใหญ่');
      expect(e.quarantineFree, 1);
    });

    test('หลังน้ำท่วม 2 วัน มีโอกาสระบาดโรคจุดขาว', () {
      final e = unlucky();
      e.buyFish('dook', 2);
      final s = e.state
        ..upcoming = null
        ..active = ActiveDisaster(
          type: DisasterType.flood,
          duration: 1,
          severity: 0,
          fishBefore: 2,
        );
      for (final f in s.pond) {
        f.quarantine = true; // ไม่ให้ติดระหว่างวันน้ำท่วม
      }
      cleanWater(e);
      keepFed(e);
      e.endDay();
      expect(s.outbreak, 'ich');
      expect(s.outbreakDays, kOutbreakDays);
      for (final f in s.pond) {
        f.quarantine = false;
      }
      cleanWater(e);
      keepFed(e);
      e.endDay();
      expect(s.pond.map((f) => f.disease), everyElement('ich'));
      cleanWater(e);
      keepFed(e);
      e.endDay();
      expect(s.outbreak, isNull, reason: 'ระบาดแค่ 2 วัน');
    });

    test('เซฟและโหลด: ค่าดูแลน้ำ ยา และสถานะปลาป่วยไม่หาย', () {
      final e = newEngine();
      e.buyFish('nila', 1);
      e.buyEquipment('air');
      e.buyMedicine('antibio');
      final s = e.state
        ..aeratorOn = true
        ..filterDirt = 33
        ..testedDay = 4
        ..badWaterDays = 2
        ..outbreak = 'bleed'
        ..outbreakDays = 1
        ..diseaseOn = false;
      s.pond.single
        ..disease = 'bleed'
        ..sickDays = 1
        ..treatDays = 2
        ..quarantine = true;
      final l = GameState.fromJson(s.toJson());
      expect(
        [l.aeratorOn, l.filterDirt, l.testedDay, l.badWaterDays, l.outbreak],
        [true, 33, 4, 2, 'bleed'],
      );
      expect([l.outbreakDays, l.diseaseOn, l.meds['antibio']], [1, false, 1]);
      final f = l.pond.single;
      expect(
        [f.disease, f.sickDays, f.treatDays, f.quarantine],
        ['bleed', 1, 2, true],
      );
      // เซฟเก่าไม่มีค่าเหล่านี้ → ค่าเริ่มต้น (ระบบโรคเปิด)
      final old = GameState.fromJson({'money': 100});
      expect([old.aeratorOn, old.filterDirt, old.diseaseOn], [false, 0, true]);
      expect(old.water, greaterThanOrEqualTo(kWaterGoodLine));
    });
  });
}
