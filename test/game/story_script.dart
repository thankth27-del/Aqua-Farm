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

/// เล่นให้ผ่านบทปัจจุบัน (บท 1-6) แล้วกด "บทถัดไป"
Future<void> clearChapter(StoryDriver d) async {
  final ch = d.progress.chapter;
  switch (ch) {
    case 1:
      await d.act((e) => e.buyFish('nila', kStoryPondFish));
      while (!d.progress.done) {
        await fedDay(d);
      }
    case 2:
      while (d.engine.matureCount == 0 && d.engine.fishTotal == 0) {
        await fedDay(d);
      }
      await d.act((e) {
        if (e.fishTotal == 0) e.catchFish();
        e.sellFish(
          e.state.fishStock.entries.firstWhere((x) => x.value > 0).key,
        );
      });
    case 3:
      await d.act((e) {
        e.buyIngredient('spice');
        e.cook('fry');
      });
    case 4:
      await d.act((e) {
        e.buyEquipment('rack');
        e.startPreserve('dried');
      });
    case 5:
      await d.act((e) => e.buyEquipment('sand'));
    case 6:
      while (!d.progress.done) {
        await fedDay(d);
      }
  }
  if (!d.progress.done) throw StateError('บท $ch ยังไม่ผ่าน');
  await d.next();
}
