import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/story_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/helpers.dart';
import '../game/story_script.dart';

/// เล่นเนื้อเรื่องผ่าน StoryController + GameController เหมือนที่ UI เรียก
class RiverpodDriver implements StoryDriver {
  RiverpodDriver(this.c);
  final ProviderContainer c;

  @override
  GameEngine get engine => c.read(gameProvider)!.engine;
  @override
  StoryProgress get progress => c.read(storyProvider)!;

  @override
  Future<void> act(void Function(GameEngine e) action) async {
    c.read(gameProvider.notifier).update(action);
    await pumpEventQueue();
  }

  @override
  Future<void> endDay() => c.read(gameProvider.notifier).endDay();

  @override
  Future<void> next() => c.read(storyProvider.notifier).next();
}

Future<ProviderContainer> container() async {
  final repo = SaveRepository(await SharedPreferences.getInstance());
  final c = ProviderContainer(
    overrides: [
      saveRepositoryProvider.overrideWithValue(repo),
      storyRandomProvider.overrideWithValue(FixedRandom()),
    ],
  );
  c.listen(storyProvider, (_, _) {});
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('เริ่มต้น: โหมดเอาชีวิตรอดยังล็อก ไม่มีเนื้อเรื่องค้าง', () async {
    final c = await container();
    expect(c.read(survivalUnlockedProvider), isFalse);
    expect(c.read(storySavedProvider), isFalse);
    expect(c.read(storyProvider.notifier).resume(), isFalse);
  });

  test('เล่นจบเนื้อเรื่อง → ปลดล็อกโหมดเอาชีวิตรอด (เซฟลงเครื่อง)', () async {
    final c = await container();
    await c.read(storyProvider.notifier).startNew();
    expect(c.read(gameProvider)!.slot, kStorySlot);
    final d = RiverpodDriver(c);
    while (!d.progress.finished) {
      await clearChapter(d);
    }
    expect(c.read(survivalUnlockedProvider), isFalse);
    await c.read(storyProvider.notifier).finish();
    expect(c.read(survivalUnlockedProvider), isTrue);
    expect(c.read(gameProvider), isNull);
    expect(c.read(storyProvider), isNull);
    // เซฟเนื้อเรื่องถูกลบ แต่การปลดล็อกยังอยู่
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kSurvivalUnlockKey), '1');
    expect(prefs.getString(kStoryKey), isNull);
    // ช่องเซฟโหมดเอาชีวิตรอดไม่ถูกแตะ
    expect(prefs.getString(kSaveKey), isNull);
  });

  test('เซฟ/โหลดบท: ออกแอปแล้วกลับมาเล่นต่อที่บทเดิม', () async {
    final c = await container();
    await c.read(storyProvider.notifier).startNew();
    final d = RiverpodDriver(c);
    while (d.progress.chapter < StoryCh.kitchen) {
      await clearChapter(d);
    }
    // อยู่บทครัว และทำเป้าหมายไปครึ่งทาง (ซื้อวัตถุดิบแล้ว)
    await d.act((e) => e.buyIngredient('spice'));
    final day = d.engine.state.day;
    final money = d.engine.state.money;
    expect(d.progress.chapter, StoryCh.kitchen);
    await c.read(storyProvider.notifier).exit();
    expect(c.read(gameProvider), isNull);

    // "เปิดแอปใหม่" = container ใหม่ที่อ่าน SharedPreferences เดิม
    final c2 = await container();
    expect(c2.read(storySavedProvider), isTrue);
    expect(c2.read(storyProvider.notifier).resume(), isTrue);
    final d2 = RiverpodDriver(c2);
    expect(d2.progress.chapter, StoryCh.kitchen);
    expect(d2.engine.state.day, day);
    expect(d2.engine.state.money, money);
    expect(d2.engine.state.inventory['spice'], 1);
    await clearChapter(d2);
    expect(d2.progress.chapter, StoryCh.preserve);
  });

  test('เซฟอัตโนมัติหลังทุกการกระทำ (ไม่ต้องกดบันทึก)', () async {
    final c = await container();
    await c.read(storyProvider.notifier).startNew();
    await RiverpodDriver(c).act((e) => e.buyFish('nila', 2));
    final saved = c.read(saveRepositoryProvider).loadStory()!;
    expect(saved.$2.pond, hasLength(2));
  });

  test('แพ้บทภัยจริง แล้วลองใหม่ผ่าน controller', () async {
    final c = await container();
    await c.read(storyProvider.notifier).startNew();
    final d = RiverpodDriver(c);
    while (d.progress.chapter < StoryCh.disaster) {
      await clearChapter(d);
    }
    while (d.engine.state.active == null) {
      await fedDay(d);
    }
    await d.act((e) => e.state.hunger = 0);
    await d.endDay();
    expect(c.read(gameProvider)!.state.over, isFalse);
    expect(d.progress.failed, isTrue);
    await c.read(storyProvider.notifier).retry();
    expect(d.progress.chapter, StoryCh.disaster);
    expect(d.progress.failed, isFalse);
    // เซฟหลังลองใหม่ก็กลับมาที่บทเดิม
    expect(
      c.read(saveRepositoryProvider).loadStory()!.$1.chapter,
      StoryCh.disaster,
    );
  });
}
