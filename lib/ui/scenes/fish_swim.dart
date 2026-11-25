/// การว่ายของปลาในฉากบ่อ (Dart ล้วน ทดสอบได้ ไม่ผูกกับ UI)
///
/// ใช้แค่ตอนวาดภาพ ไม่เปลี่ยนกติกาเกม:
/// - ปลาแต่ละตัวจำตำแหน่งของตัวเองไว้ตามตัวตน (ไม่ใช่ลำดับในรายการ)
///   ซื้อ จับ หรือปลาตายไป ปลาตัวอื่นจึงไม่กระโดด
/// - มีเป้าหมายใหม่เป็นระยะ แล้วค่อย ๆ เลี้ยวไปหา (จำกัดมุมเลี้ยวต่อเฟรม)
/// - หันหัวตามทิศที่ว่าย กลับด้านได้ไม่ถี่เกินไป (ไม่กระพริบ)
/// - ความเร็วต่างกัน ช้าลงตอนเลี้ยว แกว่งขึ้นลงเล็กน้อย
/// - อยู่ในน้ำเสมอ ไม่ทะลุผิวน้ำ ขอบบ่อ หรือพื้น
library;

import 'dart:math' as math;

/// พิกัดฉาก (เท่ากับ kSceneW x kSceneH ของฉากพิกเซล)
const double kSwimSceneW = 320;

/// ผิวน้ำ / พื้นบ่อ ในฉาก
const double kSwimSurfaceY = 40;
const double kSwimFloorY = 154;

/// เขตเศษอาหารที่โรยลงบ่อ (ฉากวาดอาหารที่ x 20-146, y 38-108)
const double kFeedMinX = 24, kFeedMaxX = 150, kFeedMaxY = 104;

/// ข้อมูลปลา 1 ตัวที่ฉากต้องใช้
class SwimFish {
  const SwimFish({
    required this.key,
    required this.type,
    required this.growth,
    this.stressed = false,
    this.sick = false,
  });

  /// ตัวตนของปลา (ใช้ object ของปลาในเกมโดยตรง) — ห้ามใช้ลำดับในรายการ
  final Object key;
  final String type;

  /// 0-100
  final int growth;

  /// น้ำเสียหรือออกซิเจนต่ำกว่าที่ปลาชนิดนี้ต้องการ → ว่ายใกล้ผิวน้ำและช้าลง
  final bool stressed;

  /// ป่วย → ว่ายช้าลงอีก
  final bool sick;
}

/// ขนาดเฟรมภาพปลา (เท่าของหน่วยปลา) ในฉากบ่อ
const double kFishFrameUnits = 20;

/// ขนาด 1 พิกเซลของตัวปลาตามการเติบโต (2 ตอนเพิ่งซื้อ → 3 ตอนโตเต็มที่ เหมือนต้นแบบ)
double fishUnit(int growth) => 2 + growth.clamp(0, 100) / 100;

/// ปลา 1 ตัวที่กำลังว่าย (ตำแหน่ง = จุดกลางตัว)
class Swimmer {
  Swimmer._(this.fish, this.x, this.y, this.heading, this.base, this.phase)
    : tx = x,
      ty = y;

  SwimFish fish;
  double x, y;

  /// ทิศที่ว่าย (เรเดียน 0 = ขวา, π = ซ้าย)
  double heading;

  /// ความเร็วปัจจุบัน (พิกเซลฉากต่อเฟรม 100ms)
  double speed = 0;

  /// ความเร็วประจำตัว (สุ่มต่อตัว)
  final double base;

  /// เฟสการแกว่งขึ้นลง
  final double phase;

  /// เฟรมเริ่มของแอนิเมชันว่าย (ปลาแต่ละตัวไม่ขยับครีบพร้อมกัน)
  int frameStart = 0;

  /// เป้าหมาย
  double tx, ty;
  int _retarget = 0;

  /// หันหัวไปทางซ้าย (ภาพปลาต้นฉบับหัวไปทางขวา จึงกลับด้านเมื่อเป็นจริง)
  bool faceLeft = true;
  int _sinceFlip = 99;

  /// ระยะที่เคลื่อนในเฟรมล่าสุด
  double lastDx = 0, lastDy = 0;

  double get unit => fishUnit(fish.growth);

  /// ปลาตัวเล็กเร็วกว่าตัวใหญ่เล็กน้อย / เครียดหรือป่วยช้าลง
  double get cruise {
    var v = base * (1.15 - .2 * fish.growth.clamp(0, 100) / 100);
    // เครียด: รีบขึ้นไปหายใจที่ผิวน้ำ แล้วว่ายช้า ๆ อยู่ตรงนั้น
    if (fish.stressed) v *= y > minY + 22 ? .9 : .55;
    if (fish.sick) v *= .75;
    return v;
  }

  /// ความเร็วสูงสุดที่เป็นไปได้ (ใช้ตรวจว่าไม่วาร์ป)
  double get maxSpeed => base * 1.15 * 1.3;

  // ขอบเขตตามภาพปลาชุดใหม่ (เฟรม [kFishFrameUnits] หน่วย ตัวปลากินพื้นที่ x 6-107, y 24-101 จาก 128)
  // ห่างจากจุดกลาง: หาง/หัว ≤ 45% ของเฟรม, บน 31%, ล่าง 29%
  double get frame => kFishFrameUnits * unit;
  double get minX => .46 * frame + 1;
  double get maxX => kSwimSceneW - .46 * frame - 1;
  double get minY => kSwimSurfaceY + 1 + .32 * frame;
  double get maxY => kSwimFloorY - .3 * frame;

  /// ตำแหน่ง y ที่ใช้วาด (รวมการแกว่งขึ้นลง) — ยังอยู่ในน้ำเสมอ
  double drawY(int t) =>
      (y + 1.2 * math.sin(t * .22 + phase)).clamp(minY, maxY).toDouble();
}

/// สภาพบ่อทั้งหมดที่ส่งผลต่อการว่าย
class PondSwim {
  PondSwim({int seed = 7}) : _rng = math.Random(seed);

  final math.Random _rng;
  final Map<Object, Swimmer> _byKey = {};
  List<Swimmer> _order = [];
  int _t = -1;
  bool _fed = false;

  /// เฟรมที่เพิ่งโรยอาหาร (ปลารุมเข้าหาอาหารช่วงแรก)
  int _rushUntil = -1;

  List<Swimmer> get swimmers => _order;

  Swimmer? of(Object key) => _byKey[key];

  /// อัปเดตรายชื่อปลา: ตัวที่มีอยู่แล้วคงตำแหน่งเดิม ตัวใหม่เกิดในน้ำ ตัวที่หายไปถูกลบ
  void sync(List<SwimFish> fish, {required bool fed}) {
    final first = _byKey.isEmpty;
    final keep = <Object>{};
    final next = <Swimmer>[];
    for (var i = 0; i < fish.length; i++) {
      final f = fish[i];
      keep.add(f.key);
      var s = _byKey[f.key];
      if (s == null) {
        s = _spawn(f, first ? i : -1, fish.length);
        _byKey[f.key] = s;
      } else {
        // น้ำเพิ่งเสีย/กลับมาดี: เปลี่ยนเป้าหมายทันที
        if (s.fish.stressed != f.stressed) s._retarget = 0;
        s.fish = f;
      }
      next.add(s);
    }
    _byKey.removeWhere((k, _) => !keep.contains(k));
    _order = next;
    if (fed && !_fed && !first) _rushUntil = math.max(_t, 0) + 150;
    if (fed && !_fed) {
      // เป้าหมายใหม่ทันทีเพื่อเข้าหาอาหาร
      for (final s in _order) {
        s._retarget = 0;
      }
    }
    _fed = fed;
  }

  Swimmer _spawn(SwimFish f, int slot, int count) {
    final base = .9 + _rng.nextDouble() * .7;
    final s = Swimmer._(f, 0, 0, 0, base, _rng.nextDouble() * 6.28);
    if (slot >= 0) {
      // เปิดฉาก: กระจายปลาทั่วบ่อ ไม่ซ้อนกัน
      final lane = (slot + .5) / count;
      s.x = s.minX + (s.maxX - s.minX) * lane + (_rng.nextDouble() - .5) * 20;
      final hiY = f.stressed ? s.minY + 22 : s.maxY;
      s.y = s.minY + (hiY - s.minY) * _rng.nextDouble();
    } else {
      // ปลาที่เพิ่งปล่อยลงบ่อ: ลงจากผิวน้ำ
      s.x = s.minX + (s.maxX - s.minX) * _rng.nextDouble();
      s.y = s.minY;
    }
    s.x = s.x.clamp(s.minX, s.maxX).toDouble();
    s.heading = _rng.nextBool() ? 0 : math.pi;
    s.faceLeft = math.cos(s.heading) < 0;
    s.speed = s.cruise * .5;
    _pickTarget(s);
    s.frameStart = _rng.nextInt(8);
    return s;
  }

  void _pickTarget(Swimmer s) {
    final feeding = _fed && (_t < _rushUntil || _rng.nextDouble() < .5);
    final dir = _rng.nextBool() ? 1 : -1;
    var tx = s.x + dir * (40 + _rng.nextDouble() * 120);
    var ty = s.y + (_rng.nextDouble() - .5) * 60;
    var loY = s.minY, hiY = s.maxY;
    if (s.fish.stressed) {
      // น้ำเสีย/ออกซิเจนต่ำ: ลอยหายใจใกล้ผิวน้ำ
      hiY = math.min(hiY, s.minY + 22);
      tx = s.x + dir * (20 + _rng.nextDouble() * 50);
    } else if (feeding) {
      tx = kFeedMinX + _rng.nextDouble() * (kFeedMaxX - kFeedMinX);
      hiY = math.min(hiY, kFeedMaxY);
      ty = loY + _rng.nextDouble() * (hiY - loY);
    }
    if (tx < s.minX || tx > s.maxX) {
      tx = s.x - dir * (40 + _rng.nextDouble() * 80);
    }
    s.tx = tx.clamp(s.minX, s.maxX).toDouble();
    s.ty = ty.clamp(loY, hiY).toDouble();
    s._retarget = 40 + _rng.nextInt(60);
  }

  /// เดินการว่ายไปถึงเฟรม t (เรียกซ้ำด้วย t เดิมได้ ไม่ขยับซ้ำ)
  void advanceTo(int t) {
    if (_t < 0 || t < _t) {
      _t = t;
      return;
    }
    final n = math.min(t - _t, 30);
    for (var i = 0; i < n; i++) {
      _t++;
      step();
    }
    _t = t;
  }

  /// 1 เฟรม (100ms)
  void step() {
    for (final s in _order) {
      if (--s._retarget <= 0 || (s.tx - s.x).abs() + (s.ty - s.y).abs() < 8) {
        _pickTarget(s);
      }
      // ทิศที่อยากไป + ผลักออกจากปลาที่อยู่ใกล้เกินไป (ไม่ว่ายซ้อนกัน)
      var dx = s.tx - s.x, dy = s.ty - s.y;
      final d = math.sqrt(dx * dx + dy * dy) + 1e-6;
      dx /= d;
      dy /= d;
      for (final o in _order) {
        if (identical(o, s)) continue;
        final ox = s.x - o.x, oy = (s.y - o.y) * 1.6;
        final od = math.sqrt(ox * ox + oy * oy);
        final near = 9 * (s.unit + o.unit) / 2;
        if (od > 0 && od < near) {
          final w = (near - od) / near * .9;
          dx += ox / od * w;
          dy += oy / od * w;
        }
      }
      // ปลาว่ายแนวนอนเป็นหลัก: ลดองค์ประกอบแนวตั้ง
      // ยกเว้นปลาที่กำลังขึ้นไปหายใจที่ผิวน้ำ
      final rising = s.fish.stressed && s.y > s.minY + 22;
      final want = math.atan2(dy * (rising ? 1.4 : .6), dx);
      var diff = want - s.heading;
      while (diff > math.pi) {
        diff -= 2 * math.pi;
      }
      while (diff < -math.pi) {
        diff += 2 * math.pi;
      }
      // เลี้ยวนุ่มนวล: จำกัดมุมเลี้ยวต่อเฟรม
      const maxTurn = .16;
      s.heading += diff.clamp(-maxTurn, maxTurn);
      // ช้าลงตอนเลี้ยวและตอนใกล้ถึงเป้า
      final turning = 1 - .55 * (diff.abs() / math.pi);
      final arrive = (d / 25).clamp(.45, 1.0);
      final target = s.cruise * turning * arrive;
      s.speed += (target - s.speed) * .18;
      final px = s.x, py = s.y;
      s.x = (s.x + math.cos(s.heading) * s.speed).clamp(s.minX, s.maxX);
      s.y = (s.y + math.sin(s.heading) * s.speed).clamp(s.minY, s.maxY);
      s.lastDx = s.x - px;
      s.lastDy = s.y - py;
      // ชนขอบ: หันกลับเข้าหาเป้า
      if (s.x <= s.minX || s.x >= s.maxX) _pickTarget(s);
      // หันหัว: กลับด้านเมื่อว่ายสวนทางชัดเจน และไม่ถี่เกิน 0.8 วินาที
      s._sinceFlip++;
      final vx = math.cos(s.heading) * s.speed;
      if (s._sinceFlip >= 8 &&
          ((s.faceLeft && vx > .12) || (!s.faceLeft && vx < -.12))) {
        s.faceLeft = !s.faceLeft;
        s._sinceFlip = 0;
      }
    }
  }
}
