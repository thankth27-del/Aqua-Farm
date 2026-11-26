import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/health_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/story.dart';

/// ตัวเล่นเนื้อเรื่องตามบท ใช้ได้ทั้งเทสต์ตรรกะล้วนและเทสต์ผ่าน Riverpod
abstract class StoryDriver {
  GameEngine get engine;
  StoryProgress get progress;
  Future<void> act(void Function(GameEngine e) action);
  Future<void> endDay();
  Future<void> next();
}

/// ให้อิ่มและจบวัน (ไม่ให้แพ้เพราะหิวระหว่างทดสอบ)
Future<void> fedDay(StoryDriver d) async {
  await d.act((e) {
    e.state.hunger = 100;
    if (e.state.pond.isNotEmpty && e.state.fed == 0) e.feed(2);
  });
  await d.endDay();
}

/// เล่นให้ผ่านบทปัจจุบัน (บทลงบ่อ-ภัยจริง) แล้วกด "บทถัดไป"
Future<void> clearChapter(StoryDriver d) async {
  final ch = d.progress.chapter;
  switch (ch) {
    case StoryCh.farm:
      await d.act((e) => e.buyFish('nila', kStoryPondFish));
      while (!d.progress.done) {
        if (d.progress.failed) {
          throw StateError(
            'บท ${d.progress.chapter} แพ้: ${d.progress.failReason}',
          );
        }
        await fedDay(d);
      }
    case StoryCh.water:
      while (d.engine.state.filterDirt < kCleanFilterMin) {
        await fedDay(d);
      }
      await d.act((e) {
        e.cleanFilter();
        if (e.state.water < kWaterGoodLine) e.changeWater();
      });
    case StoryCh.market:
      while (d.engine.matureCount == 0 && d.engine.fishTotal == 0) {
        await fedDay(d);
      }
      await d.act((e) {
        if (e.fishTotal == 0) e.catchFish();
        e.sellFish(
          e.state.fishStock.entries.firstWhere((x) => x.value > 0).key,
        );
      });
    case StoryCh.kitchen:
      await d.act((e) {
        e.buyIngredient('spice');
        e.cook('fry');
      });
    case StoryCh.preserve:
      await d.act((e) {
        e.buyEquipment('rack');
        e.startPreserve('dried');
        // จับปลาไปหมดแล้ว: ปล่อยปลาชุดใหม่ (บทถัดไปลุงพบปลาป่วยในบ่อ)
        if (e.state.pond.isEmpty) e.buyFish('nila', 2);
      });
    case StoryCh.sick:
      // ลุงพบปลาเป็นจุดขาว → แช่เกลือ แล้วรอจนหาย
      await d.act((e) {
        final i = e.state.pond.indexWhere((f) => f.sick);
        final med = kDiseases[e.state.pond[i].disease]!.medicine;
        for (var k = 0; k < kMedicines[med]!.dose; k++) {
          e.buyMedicine(med);
        }
        e.treat(i, med);
      });
      while (!d.progress.done) {
        if (d.progress.failed) {
          throw StateError(
            'บท ${d.progress.chapter} แพ้: ${d.progress.failReason}',
          );
        }
        await d.act((e) {
          if (e.state.water < kWaterGoodLine) e.changeWater();
        });
        await fedDay(d);
      }
    case StoryCh.warning:
      await d.act((e) => e.buyEquipment('sand'));
    case StoryCh.disaster:
      while (!d.progress.done) {
        if (d.progress.failed) {
          throw StateError(
            'บท ${d.progress.chapter} แพ้: ${d.progress.failReason}',
          );
        }
        // ดูแลน้ำระหว่างน้ำท่วม (ล้างตัวกรอง/เติมอากาศ/เปลี่ยนน้ำ)
        await d.act((e) {
          if (e.state.filterDirt >= kCleanFilterMin) e.cleanFilter();
          if (e.state.o2 < e.pondO2Need) e.aerate();
          if (e.state.water < kWaterGoodLine) e.changeWater();
        });
        await fedDay(d);
      }
  }
  if (!d.progress.done) throw StateError('บท $ch ยังไม่ผ่าน');
  await d.next();
}
