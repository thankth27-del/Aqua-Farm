// จำลองผู้เล่น 3 แบบ × 3 โหมด × N เกม เพื่อดูความสมดุลของความยาก
//
// รัน:
//   dart run tool/simulate.dart [จำนวนเกม]          ตารางผล (ค่าเริ่มต้น 200 เกม)
//   dart run tool/simulate.dart ... --fish <ชนิด>   ให้บอทเลี้ยงปลาชนิดนั้นแทนปลานิล
//   dart run tool/simulate.dart ... --no-health     ปิดโรคปลา/ตัวกรอง (เทียบกับสมดุลก่อนมีระบบโรค)
//   dart run tool/simulate.dart --rules             สรุปกติกาการตัดสินใจของบอทแต่ละแบบ
//   dart run tool/simulate.dart --trace <โหมด> <ผู้เล่น> <seed> [วัน]
//                                                   พิมพ์ทุกการกระทำของเกมเดียว ทีละวัน
//
// ทุกแบบเลี้ยงปลาเก่งเท่ากัน (ดูแลบ่อ ขายของหมุนเงิน ซื้อของตอนถูก)
// ต่างกันที่ "การเตรียมรับภัย" อย่างเดียว เพื่อวัดว่าการเตรียมคุ้มไหม
import 'dart:io';
import 'dart:math';

import 'package:aqua_farm/data/difficulty.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/data/ingredients.dart';
import 'package:aqua_farm/game/game_engine.dart';

enum Player { none, half, good }

/// เปิดระบบโรคปลา (ปิดด้วย `--no-health`)
var health = true;

/// ชนิดปลาที่บอทเลี้ยง (เปลี่ยนด้วย `--fish <id>` เพื่อเทียบความคุ้มของแต่ละชนิด)
var fishType = 'nila';

const playerNames = {
  Player.none: 'ไม่เตรียม',
  Player.half: 'เตรียมครึ่ง',
  Player.good: 'เล่นดี',
};

const rules = '''
กติกาการตัดสินใจของบอท (ทำตามลำดับนี้ทุกวัน ก่อนกดจบวัน)

ส่วนที่ทุกแบบทำเหมือนกัน (เลี้ยงปลาเป็น):
  1. พลังงาน < 40 → พักผ่อน
  2. ความอิ่ม ≤ 75 → กินอาหารที่ใกล้หมดอายุที่สุดก่อน จนอิ่มเกิน 75
  3. จับปลาที่โตเต็มที่ทั้งหมด
  4. ดูแลบ่อตามค่าน้ำ: ตัวกรองสกปรกถึงเกณฑ์ → ล้าง, คุณภาพน้ำ < 70 → เปลี่ยนน้ำ,
     ออกซิเจน < 50 → เติมอากาศ · ปลาป่วย → ซื้อยาที่ตรงโรคแล้วรักษา
  5. ให้อาหารปลา "พอดี" (เงินไม่พอ → "น้อย")
  6. เครื่องปรุง: ราคาวันนี้ถูกกว่าราคากลาง 10% ขึ้นไป → ตุนให้ถึง 6 ชิ้น (ถ้ามีเงิน 150 ขึ้นไป)
     ไม่ถูก → ซื้อแค่ให้มี 2 ชิ้น (ไว้ทำอาหารตอนตลาดปิด)
  7. ปลาในคลังทั้งหมด → ทำปลาทอด (1 ตัว = 2 จาน ขายได้รวม ~130 คุ้มกว่าขายปลาดิบ ~90)
     ไม่มีเครื่องปรุงและซื้อไม่ได้ → ขายปลาดิบแทน
  8. ขายอาหารปรุงสุกส่วนเกิน เก็บไว้กินพอ 2 วัน (ไม่เตรียม/เตรียมครึ่ง เก็บเพิ่มตามเป้าเสบียงถ้ามีภัย
     เล่นดี ไม่ตุนอาหารสุก เพราะเสียใน 3 วัน ใช้อาหารถนอมรับภัยแทน)
     อาหารถนอมเกินเป้าเกิน 3 วัน และไม่มีภัย → ขายส่วนเกิน
  9. (เริ่มซื้อปลาวันที่ 1-2 สุ่มต่อเกม) เติมปลานิลลงบ่อจนเต็ม 8 ตัว โดยเหลือเงินไว้ค่าอาหารปลา (บ่อมีปลาแล้ว: เหลือค่าอาหาร 3 วัน + ค่าเปลี่ยนน้ำ)
     บ่อว่างและเงินหมด → รับลูกปลาฟรี 2 ตัวจากลุงทอง (บ่อว่างต้องซื้อก่อนเสมอ เพราะเป็นรายได้ทางเดียว)

ส่วนที่ต่างกัน (เมื่อมีข่าวเตือนหรือภัยกำลังเกิด):
  ไม่เตรียม:
    - ไม่ซื้ออุปกรณ์ป้องกัน ไม่ถนอมอาหาร
    - ซ่อมฟาร์มหลังภัยจบ เมื่อเงินเหลือเกินค่าซ่อม + 300 (เหมือนผู้เล่นทั่วไป)
    - เสบียงเท่าวันปกติ
  (เตรียมครึ่ง/เล่นดี ซื้ออุปกรณ์เมื่อมีปลาในบ่อแล้วเท่านั้น)
  เตรียมครึ่ง:
    - ซื้ออุปกรณ์ป้องกันของภัยนั้นชนิดละ 1 ชิ้น (กระสอบทราย 1 ใบจาก 4)
    - เก็บอาหารปรุงสุกไว้ครึ่งหนึ่งของความยาวภัย (ไม่ถนอม อาหารสุกเสียใน 3 วัน)
    - ซ่อมฟาร์มหลังภัยจบ เมื่อเงินเหลือเกินค่าซ่อม + 300
  เล่นดี:
    - ซื้ออุปกรณ์ป้องกันของภัยนั้นครบจำนวน เรียงจากชิ้นที่ได้ความพร้อมต่อบาทสูงสุด
    - ซื้อแผงตากปลา + โหลดองค์ (ถ้ายังไม่มี) แล้วถนอมอาหาร (ตากแห้ง/หมักเกลือ)
      ให้เสบียงถึงความยาวภัยที่เหลือ + 1 วัน
    - ซ่อมฟาร์มทันทีที่ภัยจบ ก่อนซื้อของอื่น เหลือเงินไว้แค่ค่าอาหารปลา (ซ่อมระหว่างภัยเสียเปล่า เพราะเสียหายซ้ำทุกวัน)
''';

class Result {
  Result(this.won, this.day, this.grade, this.survived, this.money);
  final bool won;
  final int day;
  final String grade;
  final int survived;
  final int money;
}

class Bot {
  Bot(this.e, this.p, {this.log, this.startDay = 1});

  /// วันแรกที่เริ่มซื้อปลา (สุ่มต่อเกม ให้จังหวะปลาโตไม่ตรงกันทุกเกม เหมือนผู้เล่นจริง)
  final int startDay;
  final GameEngine e;
  final Player p;
  final List<String>? log;

  void act(String what, ActionResult r) {
    if (r.ok) log?.add(what);
  }

  /// ภัยที่ต้องรับมือตอนนี้ (กำลังเกิด หรือประกาศเตือนแล้ว)
  DisasterType? get threat {
    final a = e.state.active;
    if (a != null) return a.type;
    if (e.warnDays > 0) return e.state.upcoming!.type;
    return null;
  }

  /// วันที่ภัยยังเหลือ (รวมวันที่ยังไม่มา)
  int get threatDays {
    final a = e.state.active;
    if (a != null) return a.duration - a.dayIndex;
    return e.state.upcoming?.duration ?? 0;
  }

  /// เงินสำรองที่ไม่ใช้ซื้ออุปกรณ์: ค่าอาหารปลา 3 วัน + ค่าเปลี่ยนน้ำ
  /// + ค่าปลาใหม่ 4 ตัวไว้เติมบ่อหลังภัย
  /// (ใช้เงินหมดแล้วปลาไม่โต จะไม่มีรายได้อีกเลย)
  int get reserve => e.feedCost(2) * 3 + 40 + 4 * kFish[fishType]!.buyPrice;

  /// เป้าเสบียง (วัน)

  double get supplyTarget {
    if (threat == null) return 2;
    return switch (p) {
      Player.none => 2,
      Player.half => max(2.0, threatDays / 2),
      Player.good => threatDays + 1.0,
    };
  }

  double get mealDays =>
      e.edible
          .where((b) => kFoods[b.food]!.kind == FoodKind.meal)
          .fold(0, (a, b) => a + kFoods[b.food]!.hunger * b.qty) /
      20;
  double get preservedDays => e.supplyDays - mealDays;

  void eat() {
    final s = e.state;
    while (s.hunger <= 75) {
      var best = -1;
      var left = 1e9;
      for (var i = 0; i < s.stock.length; i++) {
        final b = s.stock[i];
        if (e.isExpired(b)) continue;
        final l = e.ageLeft(b);
        if (l < left) {
          left = l;
          best = i;
        }
      }
      if (best < 0) return;
      final name = kFoods[s.stock[best].food]!.name;
      final r = e.eatStock(best);
      act('กิน$name', r);
      if (!r.ok) return;
    }
  }

  void needEnergy(int n) {
    if (e.state.energy < n) act('พักผ่อน (พลังงานไม่พอ)', e.rest());
  }

  bool get cheapSpice =>
      e.state.prices['spice']! <=
      kIngredients['spice']!.basePrice * e.buyMultiplier * .9;

  void buySpice() {
    final s = e.state;
    final want = cheapSpice && s.money >= 150 ? 6 : 2;
    var n = 0;
    while ((s.inventory['spice'] ?? 0) < want && e.buyIngredient('spice').ok) {
      n++;
    }
    if (n > 0) {
      log?.add(
        'ซื้อเครื่องปรุง $n ชิ้น @${s.prices['spice']} (${cheapSpice ? 'ถูก ตุนไว้' : 'ซื้อพอใช้'})',
      );
    }
  }

  /// เล่นดี: ถนอมอาหารให้เสบียงถึงเป้า
  void preserve() {
    final s = e.state;
    var guard = 0;
    while (preservedDays + _processingDays < supplyTarget &&
        e.fishForCooking.isNotEmpty &&
        guard++ < 10) {
      needEnergy(8);
      if (e.canPreserve('dried')) {
        act('ตากปลาแห้ง', e.startPreserve('dried'));
        continue;
      }
      if (e.freeCapacity('jar') > 0) {
        while ((s.inventory['salt'] ?? 0) < 2 && e.buyIngredient('salt').ok) {}
        if (e.canPreserve('salted')) {
          act('หมักปลาเค็ม', e.startPreserve('salted'));
          continue;
        }
      }
      break;
    }
  }

  double get _processingDays => e.state.processing.fold(
    0.0,
    (a, j) => a + kFoods[j.method]!.hunger * j.qty / 20,
  );

  void cookAll() {
    final s = e.state;
    while (e.fishForCooking.isNotEmpty) {
      needEnergy(8);
      if ((s.inventory['spice'] ?? 0) < 1) {
        act('ซื้อเครื่องปรุง 1 ชิ้น (ขาด)', e.buyIngredient('spice'));
      }
      if (e.canCook('fry') && s.energy >= 8) {
        act('ทำปลาทอด', e.cook('fry'));
        continue;
      }
      // ทำอาหารไม่ได้: ขายปลาดิบแทน (ถ้าตลาดเปิด)
      final f = e.fishForCooking;
      final r = e.sellFish(f);
      act('ขาย${kFish[f]!.name}ดิบ', r);
      if (!r.ok) break;
    }
  }

  void sellSurplus() {
    final s = e.state;
    if (s.marketClosed) return;
    // อาหารสุก: เก็บไว้กิน 2 วัน (+ เป้าเสบียงที่ยังไม่มีอาหารถนอมรองรับ)
    final keepMeal = p == Player.good
        ? 2.0
        : 2 + max(0.0, supplyTarget - preservedDays - 2);
    var sold = 0;
    var money = 0;
    while (mealDays > keepMeal + .01) {
      final i = _oldest(FoodKind.meal);
      if (i < 0) break;
      final b = s.stock[i];
      final left = mealDays - kFoods[b.food]!.hunger / 20;
      if (left < keepMeal) break;
      final r = e.sellStock(i);
      if (!r.ok) break;
      sold++;
      money += e.foodSellPrice(b.food);
    }
    // อาหารถนอมส่วนเกินตอนไม่มีภัย
    if (threat == null) {
      while (preservedDays > supplyTarget + 3) {
        final i = _oldest(FoodKind.preserved);
        if (i < 0) break;
        final f = s.stock[i].food;
        if (!e.sellStock(i).ok) break;
        sold++;
        money += e.foodSellPrice(f);
      }
    }
    if (sold > 0) log?.add('ขายอาหารส่วนเกิน $sold จาน +$money');
  }

  int _oldest(FoodKind kind) {
    final s = e.state;
    var best = -1;
    var left = 1e9;
    for (var i = 0; i < s.stock.length; i++) {
      final b = s.stock[i];
      if (e.isExpired(b) || kFoods[b.food]!.kind != kind) continue;
      final l = e.ageLeft(b);
      if (l < left) {
        left = l;
        best = i;
      }
    }
    return best;
  }

  /// ซื้ออุปกรณ์ป้องกันของภัย
  void prepareEquipment() {
    final t = threat;
    final s = e.state;
    // ยังไม่มีปลา = ยังไม่มีรายได้ → เลี้ยงปลาก่อน ค่อยซื้ออุปกรณ์
    if (t == null || p == Player.none || s.pond.isEmpty) return;
    final spec = kDisasters[t]!;
    final ids = spec.equipment.keys.toList();
    while (true) {
      // ชิ้นถัดไปที่คุ้มที่สุด (ความพร้อมที่เพิ่ม ÷ ราคา)
      String? pick;
      var bestVal = 0.0;
      for (final id in ids) {
        final need = p == Player.good ? e.requiredEquipment(t, id) : 1;
        final have = s.equipmentCount(id);
        if (have >= need) continue;
        final gain = 1 / ids.length / e.requiredEquipment(t, id);
        final v = gain / e.equipmentPrice(id);
        if (v > bestVal) {
          bestVal = v;
          pick = id;
        }
      }
      if (pick == null) return;
      final price = e.equipmentPrice(pick);
      if (s.money < price + reserve) return;
      needEnergy(3);
      final r = e.buyEquipment(pick);
      act('ซื้อ$pick @$price (ป้องกัน${spec.name})', r);
      if (!r.ok) return;
    }
  }

  void dayStep() {
    final s = e.state;
    if (s.energy < 40) act('พักผ่อน', e.rest());
    eat();
    needEnergy(10);
    final caught = e.matureCount;
    act('จับปลา $caught ตัว', e.catchFish());

    // ดูแลบ่อตามค่าน้ำ
    // ล้างเมื่อสกปรกมาก (ล้างบ่อยเกินแบคทีเรียดีหาย น้ำยิ่งแย่)
    if (s.filterDirt >= 40 && s.pond.isNotEmpty) {
      needEnergy(kCleanFilterEnergy);
      act('ล้างตัวกรอง', e.cleanFilter());
    }
    // ปลาป่วย: ซื้อยาที่ตรงโรค (ตลาดเปิด) แล้วรักษา
    for (var i = 0; i < s.pond.length; i++) {
      final f = s.pond[i];
      if (!f.sick || f.treatDays > 0 || f.health <= 0) continue;
      final med = kDiseases[f.disease]!.medicine;
      while (e.medCount(med) < kMedicines[med]!.dose &&
          s.money >= e.medicinePrice(med) &&
          e.buyMedicine(med).ok) {}
      needEnergy(kTreatEnergy);
      act('รักษา${kDiseases[f.disease]!.name}', e.treat(i, med));
    }
    if (s.pond.isNotEmpty || s.water < 50) {
      if (s.water < 70) act('เปลี่ยนน้ำ (น้ำ ${s.water})', e.changeWater());
      if (s.o2 < 50) {
        act('เติมอากาศ (O2 ${s.o2.round()})', e.aerate());
      }
    }
    if (s.pond.isNotEmpty) {
      final r = e.feed(2);
      if (r.ok) {
        log?.add('ให้อาหารปลา พอดี');
      } else {
        act('ให้อาหารปลา น้อย (เงินไม่พอ)', e.feed(1));
      }
    }

    // ซ่อมฟาร์มก่อนจับจ่าย (ฟาร์มพังปลาโตช้า)
    final int repairBuffer = switch (p) {
      Player.none || Player.half => 300,
      Player.good => e.feedCost(2) * 2 + 20,
    };
    if (s.damaged &&
        s.active == null &&
        s.money >= s.repairCost + repairBuffer) {
      needEnergy(15);
      act('ซ่อมฟาร์ม ${s.repairCost}', e.repair());
    }

    // บ่อว่าง: ซื้อปลาก่อนของอื่น (เป็นรายได้ทางเดียว)
    if (s.pond.isEmpty && s.day >= startDay) {
      if (e.freeFish) act('รับลูกปลาฟรีจากลุงทอง', e.buyFish('nila', 2));
      while (s.pond.length < 8 &&
          s.money >= kFish[fishType]!.buyPrice + 2 * (s.pond.length + 1) + 10 &&
          e.buyFish(fishType, 1).ok) {}
    }

    buySpice();

    // เตรียมรับภัย
    prepareEquipment();
    if (p == Player.good && threat != null) {
      for (final id in ['rack', 'jar']) {
        if (s.equipmentCount(id) == 0 &&
            s.money >= e.equipmentPrice(id) + reserve) {
          act('ซื้อ$id ไว้ถนอมอาหาร', e.buyEquipment(id));
        }
      }
      preserve();
    }

    cookAll();
    eat(); // กินมื้อเย็นก่อน แล้วค่อยขายส่วนที่เกิน
    sellSurplus();

    if (s.day < startDay) return;
    // เติมปลาในบ่อ (ติดตาย → รับลูกปลาฟรีจากลุงทอง)
    if (e.freeFish) act('รับลูกปลาฟรีจากลุงทอง', e.buyFish('nila', 2));
    var bought = 0;
    // เก็บเงินสำรอง (ค่าอาหาร 3 วัน + เปลี่ยนน้ำ) ไม่ทุ่มซื้อปลาจนหมดตัว
    final keep = s.pond.isNotEmpty
        ? reserve - 4 * kFish[fishType]!.buyPrice
        : 10;
    while (s.pond.length < 8 &&
        s.money >= kFish[fishType]!.buyPrice + 2 * (s.pond.length + 1) + keep &&
        e.buyFish(fishType, 1).ok) {
      bought++;
    }
    if (bought > 0) log?.add('ซื้อปลานิล $bought ตัว');
    eat();
  }
}

Result playGame(
  Difficulty mode,
  Player p,
  int seed, {
  bool trace = false,
  int maxDays = 1000,
}) {
  final e = GameEngine.newGame('sim', random: Random(seed), mode: mode);
  final s = e.state..diseaseOn = health;
  final startDay = 1 + Random(seed * 31 + 7).nextInt(2);
  while (!s.finished && s.day <= maxDays) {
    final log = trace ? <String>[] : null;
    final before = trace
        ? 'วัน ${s.day} | เงิน ${s.money} อิ่ม ${s.hunger} สุขภาพ ${s.health} '
              'พลังงาน ${s.energy} | บ่อ ${s.pond.length} ตัว น้ำ ${s.water} '
              'O2 ${s.o2.round()} | เสบียง ${e.supplyDays} วัน | '
              '${s.active != null
                  ? '${kDisasters[s.active!.type]!.name} วันที่ ${s.active!.dayIndex + 1}/${s.active!.duration}${s.marketClosed ? ' (ตลาดปิด)' : ''}'
                  : e.warnDays > 0
                  ? 'เตือน${kDisasters[s.upcoming!.type]!.name}อีก ${e.warnDays} วัน'
                  : 'ปกติ'}'
        : '';
    if (!health) s.filterDirt = 0;
    Bot(e, p, log: log, startDay: startDay).dayStep();
    if (trace) {
      stdout.writeln(before);
      stdout.writeln('   → ${log!.join(' · ')}');
    }
    final r = e.endDay();
    if (trace && r.event != null) {
      final ev = r.event!;
      stdout.writeln(
        '   ภัย: ปลาตาย ${ev.lost} ความพร้อม ${ev.protectionPct}% '
        'เสียหาย ${ev.cost} อาหารเสีย ${ev.food}',
      );
    }
  }
  return Result(s.won, e.summary.days, e.overallGrade, s.survived, s.money);
}

void main(List<String> argv) {
  final args = [...argv];
  health = !args.remove('--no-health');
  final fi = args.indexOf('--fish');
  if (fi >= 0) {
    fishType = args[fi + 1];
    args.removeRange(fi, fi + 2);
  }
  if (args.isNotEmpty && args.first == '--rules') {
    stdout.write(rules);
    return;
  }
  if (args.isNotEmpty && args.first == '--trace') {
    final r = playGame(
      Difficulty.values.byName(args[1]),
      Player.values.byName(args[2]),
      int.parse(args[3]),
      trace: true,
      maxDays: args.length > 4 ? int.parse(args[4]) : 1000,
    );
    stdout.writeln('ชนะ=${r.won} วัน=${r.day} เงิน=${r.money} เกรด=${r.grade}');
    return;
  }
  // --losses <โหมด> <ผู้เล่น>: seed ของเกมที่แพ้ (ไว้ใช้กับ --trace)
  if (args.isNotEmpty && args.first == '--losses') {
    for (var i = 0; i < 200; i++) {
      final seed = i * 7919 + 1;
      final r = playGame(
        Difficulty.values.byName(args[1]),
        Player.values.byName(args[2]),
        seed,
      );
      if (!r.won) stdout.writeln('seed $seed แพ้วันที่ ${r.day}');
    }
    return;
  }
  final games = args.isEmpty ? 200 : int.parse(args.first);
  final out = StringBuffer()
    ..writeln(
      'จำลอง $games เกมต่อช่อง (โหมด × ผู้เล่น) · โรคปลา${health ? 'เปิด' : 'ปิด'}',
    )
    ..writeln()
    ..writeln(
      '| โหมด (เป้า) | ผู้เล่น | อัตราชนะ | วันที่ล้มเฉลี่ย | เงินเฉลี่ยตอนจบ | เงินเฉลี่ยตอนชนะ | ภัยที่รอดเฉลี่ย | เกรดตอนชนะ S/A/B |',
    )
    ..writeln('|---|---|---|---|---|---|---|---|');
  for (final mode in Difficulty.values) {
    final spec = kDifficulties[mode]!;
    for (final p in Player.values) {
      final rs = [
        for (var i = 0; i < games; i++) playGame(mode, p, i * 7919 + 1),
      ];
      final wins = rs.where((r) => r.won).toList();
      final losses = rs.where((r) => !r.won).toList();
      String avg(Iterable<int> xs) => xs.isEmpty
          ? '-'
          : (xs.reduce((a, b) => a + b) / xs.length).toStringAsFixed(1);
      String g(String x) => '${wins.where((r) => r.grade == x).length}';
      out.writeln(
        '| ${spec.name} (${spec.targetDays}) | ${playerNames[p]} | '
        '${(wins.length * 100 / games).toStringAsFixed(0)}% | '
        '${avg(losses.map((r) => r.day))} | '
        '${avg(rs.map((r) => r.money))} | ${avg(wins.map((r) => r.money))} | '
        '${avg(rs.map((r) => r.survived))} | '
        '${g('S')}/${g('A')}/${g('B')} |',
      );
    }
  }
  stdout.write(out);
}
