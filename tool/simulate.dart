// จำลองผู้เล่น 3 แบบ × 3 โหมด × 200 เกม เพื่อดูความสมดุลของความยาก
// รัน: dart run tool/simulate.dart [จำนวนเกม]
//
// ผู้เล่น (ทุกแบบเลี้ยงปลา ให้อาหาร ดูแลน้ำ จับปลา ทำอาหารกิน เหมือนกัน
// ต่างกันที่การเตรียมรับภัย):
// - ไม่เตรียม: เก็บเสบียงพอแค่วันเดียว ไม่ซื้ออุปกรณ์ป้องกัน ไม่ซ่อมฟาร์ม
// - เตรียมครึ่ง: เก็บเสบียงครึ่งหนึ่งของความยาวภัย ซื้ออุปกรณ์อย่างละ 1 ชิ้น
// - เล่นดี: เก็บเสบียงพอทั้งภัย + 2 วัน (ถนอมอาหารเก็บไว้) ซื้ออุปกรณ์ครบ ซ่อมฟาร์ม
import 'dart:io';
import 'dart:math';

import 'package:aqua_farm/data/difficulty.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/game/game_engine.dart';

enum Player { none, half, good }

const playerNames = {
  Player.none: 'ไม่เตรียม',
  Player.half: 'เตรียมครึ่ง',
  Player.good: 'เล่นดี',
};

class Result {
  Result(this.won, this.day, this.grade, this.survived, this.money);
  final bool won;
  final int day;
  final String grade;
  final int survived;
  final int money;
}

/// ภัยที่ต้องรับมือตอนนี้ (กำลังเกิด หรือประกาศเตือนแล้ว)
DisasterType? threat(GameEngine e) {
  final a = e.state.active;
  if (a != null) return a.type;
  if (e.warnDays > 0) return e.state.upcoming!.type;
  return null;
}

int threatDays(GameEngine e) {
  final a = e.state.active;
  if (a != null) return a.duration - a.dayIndex;
  final dz = e.state.upcoming;
  return dz?.duration ?? 0;
}

void eat(GameEngine e) {
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
    if (best < 0 || !e.eatStock(best).ok) return;
  }
}

/// ทำอาหารจากปลาในคลังจนเสบียงถึงเป้า (ซื้อเครื่องปรุงถ้าขาด)
void stockUp(GameEngine e, Player p, double targetDays) {
  final s = e.state;
  var guard = 0;
  while (e.supplyDays < targetDays &&
      e.fishForCooking.isNotEmpty &&
      guard++ < 20) {
    // เล่นดี: ถนอมอาหาร (ตากแห้ง) ถ้ามีแผงตากว่าง เก็บได้นานกว่า
    if (p == Player.good && e.canPreserve('dried')) {
      if (!e.startPreserve('dried').ok) break;
      continue;
    }
    if ((s.inventory['spice'] ?? 0) < 1 && !e.buyIngredient('spice').ok) break;
    if (!e.cook('fry').ok) break;
  }
}

void sellSurplus(GameEngine e, {required int keep}) {
  final s = e.state;
  for (final f in kFish.keys) {
    while ((s.fishStock[f] ?? 0) > keep && e.sellFish(f).ok) {}
  }
}

void prepare(GameEngine e, Player p) {
  final t = threat(e);
  if (t == null || p == Player.none) return;
  final s = e.state;
  for (final id in kDisasters[t]!.equipment.keys) {
    final need = p == Player.good ? e.requiredEquipment(t, id) : 1;
    while (s.equipmentCount(id) < need &&
        s.money >= e.equipmentPrice(id) + 150 &&
        e.buyEquipment(id).ok) {}
  }
}

/// การกระทำ 1 วันของผู้เล่น (ก่อนกดจบวัน)
void dayStep(GameEngine e, Player p) {
  final s = e.state;
  if (s.energy < 35) e.rest();
  eat(e);
  e.catchFish();
  if (s.water < 60) e.changeWater();
  if (s.o2 < 40) e.aerate();

  // 1) เลี้ยงปลาก่อนเสมอ (ไม่มีเงินพอให้พอดี ก็ให้น้อย)
  if (s.pond.isNotEmpty && s.fed == 0 && !e.feed(2).ok) e.feed(1);

  // เงินหมด: ขายปลาในคลังมาหมุน (เหลือไว้ 1 ตัวทำอาหาร)
  for (final f in kFish.keys) {
    while (s.money < 120 && e.fishTotal > 1 && (s.fishStock[f] ?? 0) > 0) {
      if (!e.sellFish(f).ok) break;
    }
  }
  // ทิ้งอาหารหมดอายุ
  for (var i = s.stock.length - 1; i >= 0; i--) {
    if (e.isExpired(s.stock[i])) e.discardStock(i);
  }

  // 2) เครื่องปรุงติดบ้านไว้ทำอาหารตอนตลาดปิด
  while ((s.inventory['spice'] ?? 0) < 3 && e.buyIngredient('spice').ok) {}

  // 3) เสบียงตามแบบผู้เล่น
  final dur = threatDays(e).toDouble();
  // ไม่มีภัย: ทุกแบบเก็บเสบียงพอวันสองวัน / มีภัย: ต่างกันตามแบบผู้เล่น
  final warned = threat(e) != null;
  final target = switch (p) {
    Player.none => 1.0,
    Player.half => warned ? max(2.0, dur / 2) : 1.5,
    Player.good => warned ? dur + 2 : 1.5,
  };
  stockUp(e, p, target);

  // 4) ขายปลาที่เหลือ (ปลาสดในคลังไม่เสีย ผู้เล่นที่เตรียมเก็บไว้บ้าง)
  sellSurplus(
    e,
    keep: !warned
        ? 0
        : switch (p) {
            Player.none => 0,
            Player.half => 1,
            Player.good => 3,
          },
  );

  // 5) เติมปลาในบ่อ เหลือเงินสำรองไว้ค่าอาหารปลา
  while (s.pond.length < 8 && s.money >= 40 + 60 && e.buyFish('nila', 1).ok) {}

  // 6) เตรียมภัยด้วยเงินที่เหลือ
  if (p != Player.none) {
    prepare(e, p);
    if (s.damaged && s.money >= s.repairCost + 120) e.repair();
  }
  if (p == Player.good && s.equipmentCount('rack') == 0 && s.money >= 300) {
    e.buyEquipment('rack');
  }
  eat(e);
}

Result playGame(Difficulty mode, Player p, int seed, {bool trace = false}) {
  final e = GameEngine.newGame('sim', random: Random(seed), mode: mode);
  final s = e.state;
  while (!s.finished) {
    if (trace) {
      stdout.writeln(
        'd${s.day} money${s.money} hun${s.hunger} hp${s.health} en${s.energy} '
        'pond${s.pond.length} fish${e.fishTotal} sup${e.supplyDays} '
        'stock${s.stock.map((b) => "${b.food}x${b.qty}").join(",")} '
        'proc${s.processing.length} w${s.water} '
        'act${s.active?.type.name ?? "-"} warn${e.warnDays} '
        'dmg${s.repairCost} eq${s.equipment}',
      );
    }
    dayStep(e, p);
    e.endDay();
  }
  final sum = e.summary;
  return Result(
    s.won,
    s.won ? e.targetDays : s.day,
    sum.grade,
    s.survived,
    s.money,
  );
}

void main(List<String> args) {
  // --trace <โหมด> <ผู้เล่น> <seed>: พิมพ์สถานะทุกวันของเกมเดียว
  if (args.isNotEmpty && args.first == '--trace') {
    final r = playGame(
      Difficulty.values.byName(args[1]),
      Player.values.byName(args[2]),
      int.parse(args[3]),
      trace: true,
    );
    stdout.writeln('won=${r.won} day=${r.day}');
    return;
  }
  final games = args.isEmpty ? 200 : int.parse(args.first);
  final out = StringBuffer()
    ..writeln('จำลอง $games เกมต่อช่อง (โหมด × ผู้เล่น)')
    ..writeln()
    ..writeln(
      '| โหมด (เป้า) | ผู้เล่น | อัตราชนะ | วันที่ล้มเฉลี่ย | ภัยที่รอดเฉลี่ย | เกรดรวมตอนชนะ (S/A/B) |',
    )
    ..writeln('|---|---|---|---|---|---|');
  for (final mode in Difficulty.values) {
    final spec = kDifficulties[mode]!;
    for (final p in Player.values) {
      final rs = [
        for (var i = 0; i < games; i++) playGame(mode, p, i * 7919 + 1),
      ];
      final wins = rs.where((r) => r.won).toList();
      final losses = rs.where((r) => !r.won).toList();
      final lossDay = losses.isEmpty
          ? '-'
          : (losses.map((r) => r.day).reduce((a, b) => a + b) / losses.length)
                .toStringAsFixed(1);
      final surv =
          (rs.map((r) => r.survived).reduce((a, b) => a + b) / rs.length)
              .toStringAsFixed(1);
      String g(String x) => '${wins.where((r) => r.grade == x).length}';
      out.writeln(
        '| ${spec.name} (${spec.targetDays}) | ${playerNames[p]} | '
        '${(wins.length * 100 / games).toStringAsFixed(0)}% | $lossDay | $surv | '
        '${g('S')}/${g('A')}/${g('B')} |',
      );
    }
  }
  stdout.write(out);
}
