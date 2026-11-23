import 'dart:math' as math;

import 'package:aqua_farm/ui/scenes/fish_swim.dart';
import 'package:flutter_test/flutter_test.dart';

class _K {
  _K(this.n);
  final int n;
  @override
  String toString() => 'fish$n';
}

List<SwimFish> _fish(
  List<_K> keys, {
  int growth = 30,
  bool stressed = false,
  bool sick = false,
}) => [
  for (final k in keys)
    SwimFish(
      key: k,
      type: 'nila',
      growth: growth,
      stressed: stressed,
      sick: sick,
    ),
];

void main() {
  final keys = List.generate(8, _K.new);

  test('ปลาอยู่ในน้ำเสมอ ไม่ทะลุผิวน้ำ ขอบ หรือพื้น และไม่วาร์ป', () {
    for (final growth in [0, 50, 100]) {
      for (final fed in [false, true]) {
        final p = PondSwim(seed: growth + (fed ? 1 : 0))
          ..sync(_fish(keys, growth: growth), fed: fed);
        for (var t = 0; t < 3000; t++) {
          p.step();
          for (final s in p.swimmers) {
            final u = s.unit;
            expect(s.x - 6 * u, greaterThanOrEqualTo(0));
            expect(s.x + 6 * u, lessThanOrEqualTo(kSwimSceneW));
            expect(s.drawY(t) - 3.5 * u, greaterThanOrEqualTo(kSwimSurfaceY));
            expect(s.drawY(t) + 2.5 * u, lessThanOrEqualTo(kSwimFloorY));
            final moved = math.sqrt(s.lastDx * s.lastDx + s.lastDy * s.lastDy);
            expect(moved, lessThanOrEqualTo(s.maxSpeed + 1e-9));
          }
        }
      }
    }
  });

  test('หันหัวตามทิศที่ว่าย และไม่กลับด้านถี่จนกระพริบ', () {
    final p = PondSwim(seed: 3)..sync(_fish(keys), fed: false);
    final last = <Swimmer, int>{};
    final face = <Swimmer, bool>{};
    var agree = 0, moving = 0;
    for (var t = 0; t < 2000; t++) {
      p.step();
      for (final s in p.swimmers) {
        if (face[s] != null && face[s] != s.faceLeft) {
          // กลับด้านห่างกันอย่างน้อย 0.8 วินาที
          if (last[s] != null) expect(t - last[s]!, greaterThanOrEqualTo(8));
          last[s] = t;
        }
        face[s] = s.faceLeft;
        if (s.lastDx.abs() > .3) {
          moving++;
          if ((s.lastDx < 0) == s.faceLeft) agree++;
        }
      }
    }
    expect(moving, greaterThan(1000));
    expect(agree / moving, greaterThan(.95));
  });

  test('ปลาเลี้ยวนุ่มนวล: ทิศเปลี่ยนไม่เกินกำหนดต่อเฟรม', () {
    final p = PondSwim(seed: 5)..sync(_fish(keys.take(3).toList()), fed: false);
    final prev = <Swimmer, double>{};
    for (var t = 0; t < 1500; t++) {
      p.step();
      for (final s in p.swimmers) {
        if (prev[s] != null) {
          var d = (s.heading - prev[s]!).abs() % (2 * math.pi);
          if (d > math.pi) d = 2 * math.pi - d;
          expect(d, lessThanOrEqualTo(.16 + 1e-9));
        }
        prev[s] = s.heading;
      }
    }
  });

  test('ซื้อ/จับ/ปลาหาย ปลาตัวอื่นไม่กระโดด', () {
    final p = PondSwim()..sync(_fish(keys.take(5).toList()), fed: false);
    for (var t = 0; t < 50; t++) {
      p.step();
    }
    Map<Object, (double, double)> pos() => {
      for (final s in p.swimmers) s.fish.key: (s.x, s.y),
    };
    final before = pos();
    // จับตัวที่ 0 และ 2 ออก แล้วซื้อตัวใหม่ 2 ตัว
    p.sync(_fish([keys[1], keys[3], keys[4], keys[5], keys[6]]), fed: false);
    final after = pos();
    for (final k in [keys[1], keys[3], keys[4]]) {
      expect(after[k], before[k]);
    }
    expect(p.swimmers.length, 5);
    expect(p.of(keys[0]), isNull);
    // ปลาใหม่ลงมาจากผิวน้ำ
    expect(p.of(keys[5])!.y, p.of(keys[5])!.minY);
  });

  test('ความเร็วต่างกันแต่ละตัว และตัวเล็กเร็วกว่าตัวใหญ่', () {
    final p = PondSwim()..sync(_fish(keys), fed: false);
    final speeds = {for (final s in p.swimmers) s.base};
    expect(speeds.length, keys.length);
    final s = p.swimmers.first;
    final small = SwimFish(key: s.fish.key, type: 'nila', growth: 0);
    final big = SwimFish(key: s.fish.key, type: 'nila', growth: 100);
    s.fish = small;
    final vs = s.cruise;
    s.fish = big;
    expect(vs, greaterThan(s.cruise));
    expect(fishUnit(0), lessThan(fishUnit(100)));
  });

  test('ตอนให้อาหาร ปลาว่ายเข้าหาอาหาร', () {
    final p = PondSwim(seed: 11)..sync(_fish(keys), fed: false);
    for (var t = 0; t < 30; t++) {
      p.step();
    }
    p.sync(_fish(keys), fed: true);
    var inZone = 0, n = 0;
    for (var t = 0; t < 140; t++) {
      p.step();
      if (t > 60) {
        for (final s in p.swimmers) {
          n++;
          if (s.x < kFeedMaxX + 20 && s.y < kFeedMaxY + 6) inZone++;
        }
      }
    }
    expect(inZone / n, greaterThan(.7));
  });

  test('น้ำเสีย/ออกซิเจนต่ำ ปลาว่ายใกล้ผิวน้ำและช้าลง', () {
    double avg(bool stressed, bool wantY) {
      final p = PondSwim(seed: 2)
        ..sync(_fish(keys, stressed: stressed), fed: false);
      var sum = 0.0, n = 0;
      for (var t = 0; t < 600; t++) {
        p.step();
        if (t > 100) {
          for (final s in p.swimmers) {
            sum += wantY
                ? s.y - s.minY
                : math.sqrt(s.lastDx * s.lastDx + s.lastDy * s.lastDy);
            n++;
          }
        }
      }
      return sum / n;
    }

    expect(avg(true, true), lessThan(20));
    expect(avg(true, true), lessThan(avg(false, true)));
    expect(avg(true, false), lessThan(avg(false, false) * .75));
  });

  test('น้ำเพิ่งเสีย: ปลาขึ้นมาใกล้ผิวน้ำภายในไม่กี่วินาที', () {
    final p = PondSwim(seed: 9)..sync(_fish(keys), fed: false);
    for (var t = 0; t < 100; t++) {
      p.step();
    }
    p.sync(_fish(keys, stressed: true), fed: false);
    for (var t = 0; t < 80; t++) {
      p.step();
    }
    for (final s in p.swimmers) {
      expect(s.y - s.minY, lessThan(30));
    }
    // เปิดจอตอนน้ำเสียอยู่แล้ว: ปลาเริ่มใกล้ผิวน้ำเลย
    final q = PondSwim()..sync(_fish(keys, stressed: true), fed: false);
    for (final s in q.swimmers) {
      expect(s.y - s.minY, lessThanOrEqualTo(22));
    }
  });

  test('เรียก advanceTo ซ้ำด้วยเฟรมเดิมไม่ขยับซ้ำ', () {
    final p = PondSwim()..sync(_fish(keys.take(2).toList()), fed: false);
    p.advanceTo(0);
    p.advanceTo(10);
    final x = p.swimmers.first.x;
    p.advanceTo(10);
    expect(p.swimmers.first.x, x);
  });
}
