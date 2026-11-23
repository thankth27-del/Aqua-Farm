import 'dart:convert';

import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/helpers.dart';

/// เล่นหลายระบบเพื่อให้สถานะมีข้อมูลครบทุกส่วน
GameEngine playedGame() {
  final e = newEngine();
  final s = e.state..money = 3000;
  e.buyFish('nila', 3);
  e.buyFish('chon', 1);
  e.feed(2);
  s.fishStock['carp'] = 2;
  for (final k in s.inventory.keys) {
    s.inventory[k] = 5;
  }
  e.buyEquipment('rack');
  e.buyEquipment('sand');
  e.cook('herb');
  e.startPreserve('dried');
  e.setGoal(7);
  s.upcoming = UpcomingDisaster(
    type: s.upcoming!.type,
    startDay: 3,
    severity: .5,
  );
  keepFed(e);
  e.endDay(); // วันที่ 2 (ราคา/รายงาน/อายุอาหาร)
  keepFed(e);
  e.endDay(); // วันที่ 3 น้ำท่วมเริ่ม — มี act และ dz = null
  return e;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SaveRepository repo;
  var now = 1000;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = SaveRepository(
      await SharedPreferences.getInstance(),
      clock: () => now++,
    );
  });

  test('เซฟแล้วโหลดกลับเหมือนเดิมทุกฟิลด์ (ระหว่างภัยกำลังเกิด)', () async {
    final e = playedGame();
    expect(e.state.active, isNotNull);
    expect(e.state.upcoming, isNull);
    expect(e.state.lastReport!.event, isNotNull);

    expect(await repo.save(2, e.state), isTrue);
    final loaded = repo.load(2);
    expect(jsonEncode(loaded.toJson()), jsonEncode(e.state.toJson()));
    expect(loaded.slotName, 'ทดสอบ');

    // เล่นต่อจากเซฟได้ผลเหมือนเกมเดิม
    final a = GameEngine(e.state, random: FixedRandom());
    final b = GameEngine(loaded, random: FixedRandom());
    for (final x in [a, b]) {
      keepFed(x);
      x.endDay();
    }
    expect(jsonEncode(b.state.toJson()), jsonEncode(a.state.toJson()));
  });

  test('เกมใหม่เซฟ/โหลดได้ และมีภัยที่ประกาศไว้', () async {
    final e = newEngine();
    await repo.save(1, e.state);
    final l = repo.load(1);
    expect(l.upcoming!.startDay, 7);
    expect(jsonEncode(l.toJson()), jsonEncode(e.state.toJson()));
  });

  test('3 ช่อง: รายการ, ช่องล่าสุด, เปลี่ยนชื่อ, ลบ', () async {
    expect(repo.listSlots().values, everyElement(isNull));
    expect(repo.latestSlot(), isNull);

    final e = newEngine();
    await repo.save(3, e.state);
    e.state.slotName = 'ฟาร์มสอง';
    await repo.save(1, e.state);
    final list = repo.listSlots();
    expect(list.keys, [1, 2, 3]);
    expect(list[2], isNull);
    expect(list[1]!.name, 'ฟาร์มสอง');
    expect(list[3]!.day, 1);
    expect(list[3]!.money, 500);
    expect(repo.latestSlot(), 1);

    await repo.rename(3, 'ชื่อใหม่');
    expect(repo.load(3).slotName, 'ชื่อใหม่');

    await repo.delete(1);
    expect(repo.listSlots()[1], isNull);
    expect(repo.latestSlot(), 3);
    expect(() => repo.load(1), throwsA(isA<SaveException>()));
    expect(() => repo.load(4), throwsA(isA<SaveException>()));
  });

  test('เกมจบ (Game Over) ไม่ถูกบันทึกทับ', () async {
    final e = newEngine();
    await repo.save(1, e.state);
    e.state
      ..over = true
      ..day = 99;
    expect(await repo.save(1, e.state), isFalse);
    expect(repo.load(1).day, 1);
  });

  test('เซฟเวอร์ชันอื่นไม่รองรับ', () async {
    SharedPreferences.setMockInitialValues({
      kSaveKey: jsonEncode({
        '1': {
          'v': 3,
          'name': 'เก่า',
          'ts': 1,
          'S': GameState.initial().toJson(),
        },
      }),
    });
    final r = SaveRepository(await SharedPreferences.getInstance());
    expect(
      () => r.load(1),
      throwsA(
        isA<SaveException>().having(
          (x) => x.message,
          'message',
          'เวอร์ชันเซฟไม่รองรับ',
        ),
      ),
    );
  });
}
