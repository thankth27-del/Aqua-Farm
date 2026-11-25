import 'package:aqua_farm/game/tutorial.dart';
import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/data/difficulty.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/equipment_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/app.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/screens/event_screen.dart';
import 'package:aqua_farm/ui/screens/fish_tab.dart';
import 'package:aqua_farm/ui/screens/game_shell.dart';
import 'package:aqua_farm/ui/screens/kitchen_tab.dart';
import 'package:aqua_farm/ui/screens/market_tab.dart';
import 'package:aqua_farm/ui/screens/storage_tab.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/ui/sound.dart';
import 'package:aqua_farm/ui/story_provider.dart';

import 'uncle_helpers.dart';

import 'package:aqua_farm/ui/theme/theme.dart';
import 'package:aqua_farm/ui/widgets/guide_bars.dart';
import 'package:aqua_farm/data/food_data.dart';
import 'package:aqua_farm/data/ingredients.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SaveRepository repo;
late ProviderContainer container;
late FakeBeeper beeper;

/// เก็บความถี่ที่บี๊บไว้ตรวจ (ไม่เล่นเสียงจริงในเทสต์)
class FakeBeeper implements Beeper {
  final beeps = <double>[];
  @override
  void beep(double freq) => beeps.add(freq);
  @override
  void dispose() {}
}

/// เปิดแอปที่เมนูหลัก — [unlocked] = เล่นเนื้อเรื่องจบแล้ว (โหมดเอาชีวิตรอดเปิด)
/// [tips] = แสดงคำแนะนำครั้งแรกของแต่ละหน้า (ค่าเริ่มต้นถือว่าเห็นครบแล้ว)
Future<void> pumpApp(
  WidgetTester tester, {
  bool unlocked = true,
  bool tips = false,
}) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    if (unlocked) kSurvivalUnlockKey: '1',
    if (!tips) kTipsKey: GameScreen.values.map((s) => s.name).join(','),
  });
  repo = SaveRepository(await SharedPreferences.getInstance());
  container = ProviderContainer(
    overrides: [
      saveRepositoryProvider.overrideWithValue(repo),
      sceneAnimationProvider.overrideWithValue(false),
      beeperProvider.overrideWithValue(beeper = FakeBeeper()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AquaFarmApp()),
  );
  await tester.pumpAndSettle();
}

/// เมนูหลัก → เอาชีวิตรอด → (เมนูย่อย) เกมใหม่ หรือ เล่นต่อ/โหลดเกม
Future<void> openSurvival(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(const ValueKey('menu-survival')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('sheet-$item')));
  await tester.pumpAndSettle();
}

/// เมนูหลัก → เอาชีวิตรอด → เกมใหม่ → ช่อง 1 → เลือกโหมด → ตั้งชื่อ → ตกลง
/// (โหมดเอาชีวิตรอดไม่เริ่มบทเรียน 9 ขั้น — skipTutorial: false = เปิดบทเรียนเอง)
Future<void> startNewGame(
  WidgetTester tester, {
  bool skipTutorial = true,
  Difficulty mode = Difficulty.normal,
}) async {
  await openSurvival(tester, 'new');
  await tester.tap(find.widgetWithText(PixelButton, 'เกมใหม่').first);
  await tester.pumpAndSettle();
  expect(find.text('เลือกความยาก'), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('mode-${mode.name}')));
  await tester.pumpAndSettle();
  expect(find.text('ตั้งชื่อ Save'), findsOneWidget);
  await tester.tap(find.text('ตกลง'));
  await tester.pumpAndSettle();
  if (!skipTutorial) {
    container.read(gameProvider.notifier).update((e) => e.tutorialRestart());
    await tester.pumpAndSettle();
  }
}

/// หน้าฟาร์ม: เปิดแผ่นรายละเอียด (ภัย+อุปกรณ์ / สถานะตัวละคร)
Future<void> openFarmSheet(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> openFishShopCard(WidgetTester tester, String id) async {
  await tester.tap(find.text('ปลา'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ร้านปลา').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('fish-card-$id')));
  await tester.pumpAndSettle();
}

Future<void> buyFish(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ตกลง'));
  await tester.pumpAndSettle();
}

/// แตะป้ายบนฉากบ่อ เพื่อเปิดแผ่นรายละเอียด (pond-water = ดูแลบ่อ, pond-fish = ปลาในบ่อ)
Future<void> openPondSheet(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// รายการเลื่อนของแผ่นรายละเอียดที่เปิดอยู่
Finder sheetScroll() => find.byType(Scrollable).last;

/// ค่าวันในช่องวันของแถบบน เช่น "1/30"
Finder dayChip(String v) => find.descendant(
  of: find.byKey(const ValueKey('day-chip')),
  matching: find.text(v),
);

void main() {
  testWidgets('เมนูหลักมีปุ่มครบ และเล่นต่อเมื่อไม่มีเซฟแจ้งเตือน', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('AQUA FARM'), findsOneWidget);
    for (final t in ['เนื้อเรื่อง', 'เอาชีวิตรอด', 'เครดิต']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('menu-survival')));
    await tester.pumpAndSettle();
    for (final t in ['เกมใหม่', 'เล่นต่อ', 'โหลดเกม']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('sheet-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ยังไม่มีเซฟ'), findsOneWidget);
  });

  group('เนื้อเรื่อง: แถบเป้าหมายและไฮไลต์', () {
    Future<void> startStory(WidgetTester tester, {bool choose = false}) async {
      await pumpApp(tester, unlocked: false);
      await tester.tap(find.byKey(const ValueKey('menu-story')));
      await tester.pumpAndSettle();
      // ลุงทองเล่าเปิดบท 1 ก่อน แล้วถามให้เลือกปลา
      expect(find.byKey(const ValueKey('uncle-talk')), findsOneWidget);
      await hearUncle(tester, pick: null);
      expect(find.byKey(const ValueKey('uncle-option-2')), findsOneWidget);
      if (choose) {
        await hearUncle(tester);
        return;
      }
      // เลือกแล้วกด "ยกเลิก" ที่หน้ายืนยัน = ยังไม่ซื้อ (ไปซื้อเองที่ร้านปลาได้)
      await tester.tap(find.byKey(const ValueKey('uncle-option-0')));
      await tester.pumpAndSettle();
      while (find.text('ยกเลิก').evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('uncle-talk')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      await hearUncle(tester);
    }

    bool lit(WidgetTester tester, String target) =>
        tester.widget<Spotlight>(find.byKey(ValueKey('story-gate-$target'))).on;

    testWidgets(
      'แถบเป้าหมายติดบนจอ: บท 1/7 เป้าหมาย คำอธิบายไม่เกิน 2 บรรทัด',
      (tester) async {
        await startStory(tester);
        expect(find.byKey(const ValueKey('story-goal')), findsOneWidget);
        expect(find.text('บทที่ 1/7 · ลงบ่อ'), findsOneWidget);
        expect(
          find.text('เป้าหมาย: ซื้อปลา 1 ชนิด 3 ตัวลงบ่อ แล้วดูแล 2 วัน'),
          findsOneWidget,
        );
        final hint = tester.widget<Text>(
          find.byKey(const ValueKey('story-hint')),
        );
        expect(hint.maxLines, 2);
        // แถบเป้าหมายอยู่ใต้แถบบน ไม่อยู่ในส่วนที่เลื่อน
        expect(
          find.ancestor(
            of: find.byKey(const ValueKey('story-goal')),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
        );
        // บทเรียน 9 ขั้นเดิมไม่แสดงในเนื้อเรื่อง และไม่มี "เล่นบทเรียนซ้ำ"
        expect(find.byKey(const ValueKey('tutorial')), findsNothing);
        await tester.tap(find.byTooltip('เมนู / พัก'));
        await tester.pumpAndSettle();
        expect(find.text('เล่นบทเรียนซ้ำ'), findsNothing);
      },
    );

    testWidgets('ไม่มีเมนูล่าง: ลุงพาไปหน้าที่ต้องใช้ เหลือปุ่มพักมุมจอ', (
      tester,
    ) async {
      await startStory(tester);
      expect(find.byType(GameNavBar), findsNothing);
      expect(find.byTooltip('เมนู / พัก'), findsOneWidget);
      // บท 1 เริ่มที่หน้าปลา
      expect(find.byType(FishTab), findsOneWidget);
    });

    testWidgets('บท 1: เลือกปลาแล้วยืนยัน = ซื้อปลาชนิดนั้นครบ 3 ตัวจริง', (
      tester,
    ) async {
      await pumpApp(tester, unlocked: false);
      await tester.tap(find.byKey(const ValueKey('menu-story')));
      await tester.pumpAndSettle();
      await hearUncle(tester, pick: null);
      final money = container.read(gameProvider)!.state.money;
      // ข้อ 2 = ปลาดุก
      await tester.tap(find.byKey(const ValueKey('uncle-option-1')));
      await tester.pumpAndSettle();
      while (find.text('ตกลง').evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('uncle-talk')));
        await tester.pumpAndSettle();
      }
      expect(
        find.text('ซื้อปลาดุก 3 ตัว ราคา 90฿ ปล่อยลงบ่อ?'),
        findsOneWidget,
      );
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      final s = container.read(gameProvider)!.state;
      expect(s.pond.map((f) => f.type), ['dook', 'dook', 'dook']);
      expect(s.money, money - 90);
      expect(container.read(storyProvider)!.choices['fish'], 'dook');
      // ถัดไปลุงสอนให้อาหาร
      expect(find.byKey(const ValueKey('talk-1-t:feed')), findsOneWidget);
    });

    testWidgets(
      'บท 4: ลุงสอนทีละวิธี ถามสั้น ตอบผิดลุงอธิบายแล้วให้เลือกใหม่',
      (tester) async {
        await startStory(tester, choose: true);
        container.read(storyProvider)!
          ..chapter = 4
          ..talked = 4
          ..heard.clear();
        container.read(gameProvider.notifier).update((_) {});
        await tester.pumpAndSettle();
        Finder k(String s) => find.byKey(ValueKey(s));
        Future<void> next() async {
          await tester.tap(k('uncle-talk'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
        }

        // สอนตากแห้ง 2 ประโยค (แตะข้าม typewriter แล้วแตะไปต่อ)
        expect(k('talk-4-l:dried'), findsOneWidget);
        for (
          var i = 0;
          i < 4 && k('talk-4-l:dried').evaluate().isNotEmpty;
          i++
        ) {
          await next();
        }
        expect(k('talk-4-q:dried'), findsOneWidget);
        expect(find.text('ทำไมปลาตากแห้งถึงเก็บได้นาน?'), findsWidgets);
        expect(k('uncle-option-2'), findsOneWidget);
        final money = container.read(gameProvider)!.state.money;

        // ตอบผิด → ลุงอธิบาย (หน้าคิด ไม่ตำหนิ) → ถามข้อเดิมอีกครั้ง
        await tester.tap(k('uncle-option-1'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(k('talk-reply'), findsOneWidget);
        expect(k('uncle-think'), findsOneWidget);
        expect(find.textContaining('ลองดูอีกทีนะ'), findsWidgets);
        await next();
        expect(k('talk-4-q:dried'), findsOneWidget);
        expect(container.read(gameProvider)!.state.money, money);

        // ตอบถูก → ลุงชม แล้วชวนลองทำ (พาไปหน้าครัว)
        await tester.pump(const Duration(seconds: 2));
        await tester.tap(k('uncle-option-0'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(k('uncle-smile'), findsOneWidget);
        expect(find.textContaining('ถูกต้อง!'), findsWidgets);
        await next();
        expect(k('talk-4-try:dried'), findsOneWidget);
        expect(k('talk-4-l:salted'), findsNothing);
        expect(container.read(storyProvider)!.heard, contains('q:dried'));
      },
    );

    testWidgets('ปุ่มจบวันจางจนกว่าจะซื้อปลาครบและให้อาหาร แล้วจึงกะพริบ', (
      tester,
    ) async {
      await startStory(tester);
      expect(find.byKey(const ValueKey('story-locked-endDay')), findsOneWidget);
      expect(find.text('ซื้อปลาให้ครบ 3 ตัวก่อน'), findsOneWidget);
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) => e.buyFish('nila', 3));
      await tester.pumpAndSettle();
      expect(find.text('ให้อาหารปลาก่อนจบวัน'), findsOneWidget);
      expect(find.byKey(const ValueKey('story-locked-endDay')), findsOneWidget);
      ctl.update((e) => e.feed(2));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-locked-endDay')), findsNothing);
      expect(lit(tester, 'endDay'), isTrue);
    });

    testWidgets('ผ่านบทแล้ว: ปุ่ม "บทถัดไป" กะพริบ กดแล้วไปบท 2 เปิดแท็บตลาด', (
      tester,
    ) async {
      await startStory(tester);
      final p = container.read(storyProvider)!;
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) {
        e.buyFish('nila', 3);
        e.state.day = p.startDay + kStoryCareDays;
      });
      await tester.pumpAndSettle();
      // จบบท: ลุงชม แล้วให้การ์ด "ลุงรู้มา" พร้อมตัวเลขติดป้าย "ค่าในเกม"
      expect(find.byKey(const ValueKey('talk-1-done')), findsOneWidget);
      while (find.byKey(const ValueKey('card-keep')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('uncle-talk')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('card-fish')), findsOneWidget);
      expect(find.text('ค่าในเกม'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('card-keep')));
      await tester.pumpAndSettle();
      expect(container.read(storyProvider)!.cards, ['fish']);
      expect(find.text('ผ่านบทนี้แล้ว! กด "บทถัดไป"'), findsOneWidget);
      expect(find.byKey(const ValueKey('story-locked-endDay')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-next')));
      await tester.pumpAndSettle();
      // บทใหม่: ลุงทองเล่าเปิดบทก่อนให้ทำ
      expect(find.byKey(const ValueKey('talk-2-intro')), findsOneWidget);
      await hearUncle(tester);
      expect(find.text('บทที่ 2/7 · ตลาด'), findsOneWidget);
      final saved = container.read(saveRepositoryProvider).loadStory()!.$1;
      expect(saved.chapter, 2);
      expect(saved.cards, ['fish']);
    });

    testWidgets('แพ้บท: แถบเป้าหมายเป็นสีแดง บอกเหตุผล และลองใหม่ได้', (
      tester,
    ) async {
      await startStory(tester);
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) {
        e.buyFish('nila', 3);
        e.feed(2);
        e.state
          ..hunger = 0
          ..health = 5;
      });
      await tester.pumpAndSettle();
      await ctl.endDay();
      await tester.pumpAndSettle();
      // ไม่ไปหน้า Game Over
      expect(find.byType(GameShell), findsOneWidget);
      // ปิดหน้ารายงาน (เปิดจากปุ่มจบวันเท่านั้น — ที่นี่เรียกตรง จึงไม่มี)
      expect(find.text('แพ้บทนี้: สุขภาพหมด ตัวละครล้มป่วย'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-retry')));
      await tester.pumpAndSettle();
      expect(container.read(gameProvider)!.state.pond, isEmpty);
      await hearUncle(tester, pick: null);
      expect(find.text('บทที่ 1/7 · ลงบ่อ'), findsOneWidget);
    });
  });

  group('เมนูหลัก: เนื้อเรื่อง / เอาชีวิตรอด', () {
    testWidgets('ยังไม่จบเนื้อเรื่อง: เอาชีวิตรอดล็อก กดแล้วบอกวิธีปลดล็อก', (
      tester,
    ) async {
      await pumpApp(tester, unlocked: false);
      expect(
        find.text('ล็อกอยู่ · เล่นเนื้อเรื่องจบเพื่อปลดล็อก'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('menu-survival')));
      await tester.pump();
      expect(find.text('เกมใหม่'), findsNothing);
      expect(
        find.text('เล่นเนื้อเรื่องให้จบก่อน เพื่อปลดล็อกโหมดนี้'),
        findsOneWidget,
      );
      expect(container.read(gameProvider), isNull);
    });

    testWidgets('เนื้อเรื่อง: เริ่มบท 1 แล้วออกมาเล่นต่อได้จากเมนู', (
      tester,
    ) async {
      await pumpApp(tester, unlocked: false);
      expect(find.text('เรียนรู้ทีละบท 7 บท'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('menu-story')));
      await tester.pumpAndSettle();
      expect(container.read(gameProvider)!.slot, kStorySlot);
      expect(container.read(storyProvider)!.chapter, 1);

      await container.read(gameProvider.notifier).exitToMenu();
      await tester.pumpAndSettle();
      expect(find.text('เล่นต่อจากบทที่ค้างไว้'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('menu-story')));
      await tester.pumpAndSettle();
      expect(find.text('เล่นต่อ บทที่ 1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sheet-continue')));
      await tester.pumpAndSettle();
      expect(container.read(storyProvider)!.chapter, 1);
      // เนื้อเรื่องไม่ใช้ช่องเซฟ 1-3
      expect(repo.listSlots().values.whereType<SlotInfo>(), isEmpty);
    });

    testWidgets('จบเนื้อเรื่องแล้ว: เอาชีวิตรอดปลดล็อกทันที', (tester) async {
      await pumpApp(tester, unlocked: false);
      await tester.tap(find.byKey(const ValueKey('menu-story')));
      await tester.pumpAndSettle();
      final p = container.read(storyProvider)!
        ..chapter = kStoryChapters
        ..done = true;
      expect(p.finished, isTrue);
      await container.read(storyProvider.notifier).finish();
      await tester.pumpAndSettle();
      expect(find.text('20 / 30 / 60 วัน'), findsOneWidget);
      await openSurvival(tester, 'new');
      expect(find.text('เลือกช่องบันทึก'), findsWidgets);
    });

    testWidgets('มีเซฟเอาชีวิตรอดเดิมอยู่แล้ว: ไม่ล็อก (ไม่เสียเซฟเก่า)', (
      tester,
    ) async {
      await pumpApp(tester, unlocked: false);
      await repo.save(2, GameEngine.newGame('เดิม').state);
      container.invalidate(survivalUnlockedProvider);
      await tester.pumpAndSettle();
      expect(find.text('20 / 30 / 60 วัน'), findsOneWidget);
    });
  });

  testWidgets('สร้างเกมใหม่ในช่อง 1 แล้วเข้าหน้าฟาร์ม แถบบนและเมนูล่างครบ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    // โหมดเอาชีวิตรอดไม่เริ่มบทเรียน 9 ขั้น (สอนในโหมดเนื้อเรื่องแทน)
    expect(find.byKey(const ValueKey('tutorial')), findsNothing);
    expect(container.read(gameProvider)!.state.tut, kTutorialSteps);
    expect(repo.listSlots()[1]!.name, 'ฟาร์มของฉัน');
    expect(find.text('500฿'), findsOneWidget);
    expect(dayChip('1/30'), findsOneWidget);
    expect(find.text('2 วัน'), findsOneWidget);
    // HUD: ไอคอน + ตัวเลข (ชื่อค่าอยู่ใน tooltip)
    expect(find.byTooltip('อาหารในคลังพอกินอีกกี่วัน'), findsOneWidget);
    // คุณภาพน้ำเป็นคำเดียว ดี/เริ่มแย่/อันตราย (สถานะละเอียดอยู่ในแผ่นดูแลบ่อ)
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('water-chip')),
        matching: find.text('ดี'),
      ),
      findsOneWidget,
    );
    expect(find.text('Excellent'), findsNothing);
    expect(find.byKey(const ValueKey('end-day')), findsOneWidget);
    for (final t in ['ฟาร์ม', 'ปลา', 'ตลาด', 'ครัว', 'คลัง']) {
      expect(
        find.descendant(of: find.byType(GameNavBar), matching: find.text(t)),
        findsOneWidget,
      );
    }
    // ตัวละครบอกสิ่งที่ควรทำต่อ (กล่องคำพูด)
    expect(find.byKey(const ValueKey('next-step')), findsOneWidget);
  });

  testWidgets('ซื้อปลาต้องยืนยันก่อน: ยกเลิกแล้วไม่ซื้อ ตกลงแล้วซื้อ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await openFishShopCard(tester, 'nila');

    await tester.tap(find.byKey(const ValueKey('qty-plus')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
    await tester.pumpAndSettle();
    expect(
      find.text('ยืนยันซื้อปลานิล 2 ตัว รวม 80 บาท? (เงินคงเหลือ 420 บาท)'),
      findsOneWidget,
    );
    await tester.tap(find.text('ยกเลิก').last);
    await tester.pumpAndSettle();
    expect(container.read(gameProvider)!.state.pond, isEmpty);

    await buyFish(tester);
    final s = container.read(gameProvider)!.state;
    expect(s.pond.length, 2);
    expect(s.money, 420);
    expect(find.text('420฿'), findsOneWidget);
  });

  testWidgets('เงินเปลี่ยน: ตัวเลขนับลงทีละน้อย และมีเหรียญลอยแล้วหายไป', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await openFishShopCard(tester, 'nila');
    await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    // กลางแอนิเมชัน: ตัวเลขยังไม่ถึงค่าสุดท้าย และมีตัวเลข -40 ลอยอยู่
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('460฿'), findsNothing);
    expect(find.text('-40'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('460฿'), findsOneWidget);
    expect(find.text('-40'), findsNothing);
  });

  testWidgets('บ่อปลา: ให้อาหาร แล้วจบวันเห็นรายงาน และบันทึกอัตโนมัติ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await openFishShopCard(tester, 'nila');
    await buyFish(tester);

    // รอ toast "ซื้อปลา..." หายก่อน แล้วสลับไปบ่อปลา ปุ่มให้อาหารอยู่ถาดล่าง
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บ่อปลา'));
    await tester.pumpAndSettle();
    final feed = find.byKey(const ValueKey('feed-main'));
    expect(
      find.descendant(of: feed, matching: find.text('พอดี')),
      findsOneWidget,
    );
    await tester.tap(feed);
    await tester.pump();
    expect(find.text('ให้อาหารพอดี ปลาโตดี'), findsOneWidget);
    expect(container.read(gameProvider)!.state.fed, 2);

    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pumpAndSettle();
    expect(find.text('รายงานประจำวัน — วันที่ 1'), findsOneWidget);
    expect(repo.load(1).day, 2);
    await tester.scrollUntilVisible(
      find.text('เริ่มวันใหม่'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('เริ่มวันใหม่'));
    await tester.pumpAndSettle();
    expect(dayChip('2/30'), findsOneWidget);
  });

  testWidgets('ปลาในบ่อ: การ์ดต่อตัว มีป้ายป่วย/หิวชัดเจน', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await openFishShopCard(tester, 'nila');
    await tester.tap(find.byKey(const ValueKey('qty-plus')));
    await tester.pumpAndSettle();
    await buyFish(tester);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    // ปลาตัวแรกป่วย (สุขภาพต่ำกว่าครึ่ง)
    container
        .read(gameProvider.notifier)
        .update((e) => e.state.pond[0].health = 30);
    await tester.tap(find.text('บ่อปลา'));
    await tester.pumpAndSettle();

    Finder inCard(int i, Finder f) =>
        find.descendant(of: find.byKey(ValueKey('pond-fish-$i')), matching: f);
    // ป้ายปลาบนฉากบอกว่ามีตัวป่วย/หิว แตะแล้วเห็นการ์ดรายตัว
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('pond-fish')),
        matching: find.text('ป่วย 1 · หิว'),
      ),
      findsOneWidget,
    );
    await openPondSheet(tester, 'pond-fish');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pond-fish-1')),
      200,
      scrollable: sheetScroll(),
    );
    await tester.pumpAndSettle();
    expect(inCard(0, find.text('ป่วย')), findsOneWidget);
    expect(inCard(1, find.text('ป่วย')), findsNothing);
    // ยังไม่ให้อาหาร: หิวทั้งสองตัว
    expect(inCard(0, find.text('หิว')), findsNWidgets(2));
    expect(inCard(1, find.text('หิว')), findsNWidgets(2));
    expect(inCard(1, find.text('ปลานิล')), findsOneWidget);
    expect(inCard(1, find.byType(PixelBar)), findsNWidgets(3));

    container.read(gameProvider.notifier).run((e) => e.feed(2));
    await tester.pumpAndSettle();
    expect(inCard(1, find.text('หิว')), findsNothing);
    expect(inCard(1, find.text('พอดี')), findsOneWidget);
  });

  testWidgets('เสียง: บี๊บตอนแจ้งผล และปิดเสียงได้ในเมนู (จำค่าไว้)', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final before = beeper.beeps.length;

    await tester.tap(find.byTooltip('เมนู / พัก'));
    await tester.pumpAndSettle();
    expect(find.text('เสียง: เปิด'), findsOneWidget);
    await tester.tap(find.text('บันทึกเกม'));
    await tester.pumpAndSettle();
    expect(beeper.beeps.sublist(before), [kBeepOk]);

    // ปิดเสียง: ปุ่มเปลี่ยนทันทีโดยไม่ปิดเมนู และจำค่าไว้ในเครื่อง
    await tester.tap(find.byTooltip('เมนู / พัก'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sound-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('เสียง: ปิด'), findsOneWidget);
    expect(repo.soundOn, isFalse);
    await tester.tap(find.text('บันทึกเกม'));
    await tester.pumpAndSettle();
    // ปิดเสียงแล้ว: ไม่มีเสียงบี๊บเพิ่ม
    expect(beeper.beeps.sublist(before), [kBeepOk]);
  });

  testWidgets('เลือกโหมดก่อนตั้งชื่อ: ยกเลิกแล้วไม่สร้างเกม', (tester) async {
    await pumpApp(tester);
    await openSurvival(tester, 'new');
    await tester.tap(find.widgetWithText(PixelButton, 'เกมใหม่').first);
    await tester.pumpAndSettle();
    for (final t in ['ง่าย', 'ปานกลาง', 'ยาก']) {
      expect(find.text(t), findsOneWidget);
    }
    for (final t in ['รอดครบ 20 วัน', 'รอดครบ 30 วัน', 'รอดครบ 60 วัน']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(PixelButton, 'ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text('ตั้งชื่อ Save'), findsNothing);
    expect(repo.listSlots()[1], isNull);
    expect(container.read(gameProvider), isNull);
  });

  testWidgets('เกมใหม่โหมดยาก: แถบบนนับวัน 1/60 และช่องเซฟแสดงโหมด', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester, mode: Difficulty.hard);
    expect(container.read(gameProvider)!.state.mode, Difficulty.hard);
    expect(dayChip('1/60'), findsOneWidget);
    expect(repo.listSlots()[1]!.mode, Difficulty.hard);
    await container.read(gameProvider.notifier).exitToMenu();
    await tester.pumpAndSettle();
    await openSurvival(tester, 'load');
    expect(find.text('วัน 1/60'), findsOneWidget);
    expect(find.text('ยาก'), findsOneWidget);
  });

  testWidgets('รอดถึงวันสุดท้าย: เปิดหน้าชนะพร้อมคะแนน ไม่บันทึกทับเซฟ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester, mode: Difficulty.easy);
    final ctl = container.read(gameProvider.notifier);
    // ข้ามไปวันสุดท้าย (ให้อิ่มและปลอดภัยเพื่อไม่ให้ตายระหว่างทาง)
    ctl.update((e) {
      e.state
        ..day = 20
        ..hunger = 100
        ..health = 100
        ..money = 777;
    });
    await ctl.save();
    await tester.pumpAndSettle();
    expect(dayChip('20/20'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('win')), findsOneWidget);
    expect(find.text('ชนะ!'), findsOneWidget);
    expect(find.text('รอดครบ 20 วัน'), findsOneWidget);
    expect(find.text('โหมดง่าย'), findsOneWidget);
    expect(find.text('เกรดรวม'), findsOneWidget);
    expect(find.text('ภัยที่รอด'), findsOneWidget);
    expect(find.text('เงินคงเหลือ'), findsOneWidget);
    expect(find.text('20/20 วัน'), findsOneWidget);
    // ไม่มีรายงานประจำวันซ้อน และเซฟยังเป็นวันที่ 20 ก่อนจบเกม
    expect(find.textContaining('รายงานประจำวัน'), findsNothing);
    expect(repo.listSlots()[1]!.day, 20);

    await tester.tap(find.widgetWithText(PixelButton, 'กลับเมนูหลัก'));
    await tester.pumpAndSettle();
    expect(container.read(gameProvider), isNull);
    expect(find.text('AQUA FARM'), findsOneWidget);
  });

  testWidgets('Game Over: แสดงคะแนนสรุปแบบเดียวกับหน้าชนะ', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester, mode: Difficulty.hard);
    final ctl = container.read(gameProvider.notifier);
    ctl.update((e) {
      e.state
        ..day = 12
        ..hunger = 0
        ..health = 10
        ..money = 321
        ..survived = 1;
    });
    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pumpAndSettle();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.byKey(const ValueKey('summary')), findsOneWidget);
    expect(find.text('โหมดยาก'), findsOneWidget);
    expect(find.text('เกรดรวม'), findsOneWidget);
    expect(find.text('1 ครั้ง'), findsOneWidget);
    expect(find.text('321฿'), findsOneWidget);
    expect(find.text('วันที่ไปถึง'), findsOneWidget);
    expect(find.text('12/60 วัน'), findsOneWidget);
    expect(find.widgetWithText(PixelButton, 'โหลดเซฟล่าสุด'), findsOneWidget);
  });

  testWidgets('หน้าฟาร์มบอกว่าภัยและฟาร์มเสียหายทำให้ปลาโตช้า', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final ctl = container.read(gameProvider.notifier);
    ctl.update((e) {
      e.state
        ..upcoming = null
        ..active = ActiveDisaster(
          type: DisasterType.flood,
          duration: 4,
          severity: .5,
          fishBefore: 0,
        )
        ..damaged = true
        ..repairCost = 30;
    });
    await tester.pumpAndSettle();
    // หน้าหลักบอกสั้น ๆ แตะป้ายภัยแล้วเห็นรายละเอียด
    expect(find.text('น้ำท่วมกำลังเกิด'), findsOneWidget);
    await openFarmSheet(tester, 'farm-disaster');
    final growth = find.byKey(const ValueKey('growth-info'));
    await tester.scrollUntilVisible(
      growth,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('ปลาโตได้ 0% ระหว่างภัย (ตามอุปกรณ์ป้องกัน)'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('damaged-info')), findsOneWidget);
    expect(
      find.text('ฟาร์มเสียหาย: ปลาโตได้แค่ 50% จนกว่าจะซ่อม'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ข่าวเตือนภัย: บอกว่าภัยมาในอีกกี่วัน แยกคะแนนความพร้อม และปุ่มลัดไปซื้ออุปกรณ์',
    (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) => e.state.day = 2);
      await tester.pumpAndSettle();
      expect(find.text('น้ำท่วมในอีก 5 วัน'), findsOneWidget);
      // ป้ายภัยบนฉาก: อีกกี่วัน + ความพร้อม
      expect(find.text('น้ำท่วมอีก 5 วัน'), findsOneWidget);
      await openFarmSheet(tester, 'farm-prepare');

      final parts = find.byKey(const ValueKey('readiness-parts'));
      await tester.scrollUntilVisible(
        parts,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('ความพร้อมรับภัย'), findsOneWidget);
      expect(find.text('Readiness Check'), findsNothing);
      expect(
        find.descendant(of: parts, matching: find.text('อุปกรณ์ 0/50')),
        findsOneWidget,
      );
      // ช่องอุปกรณ์มีชื่อ ไม่ใช่ไอคอนอย่างเดียว
      expect(find.text('มี 0 / ต้อง 4'), findsOneWidget);

      final go = find.byKey(const ValueKey('go-prepare'));
      await tester.scrollUntilVisible(
        go,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(go);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('eq-sand')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text('น้ำท่วม: ยังขาด 4'), findsOneWidget);
    },
  );

  testWidgets('วันที่ภัยเกิด: จบวันแล้วเห็นฉากภัยก่อน แล้วไปรายงานเอง', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final ctl = container.read(gameProvider.notifier);
    ctl.update((e) {
      e.state
        ..day = 6
        ..hunger = 100;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('event-screen')), findsOneWidget);
    expect(find.text('น้ำท่วม วันที่ 1/4'), findsOneWidget);
    // ครบเวลาแล้วไปหน้ารายงานเอง
    await tester.pump(kEventSceneDuration);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-screen')), findsNothing);
    expect(find.textContaining('รายงานประจำวัน'), findsOneWidget);
  });

  testWidgets('วันที่ภัยเกิด: กด "ดูรายงานทันที" ข้ามฉากภัยได้', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    container.read(gameProvider.notifier).update((e) {
      e.state
        ..day = 6
        ..hunger = 100;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(PixelButton, 'ดูรายงานทันที'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-screen')), findsNothing);
    expect(find.textContaining('รายงานประจำวัน'), findsOneWidget);
  });

  testWidgets('วันปกติ: จบวันแล้วไปหน้ารายงานเลย ไม่มีฉากภัย', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await tester.tap(find.byKey(const ValueKey('end-day')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('event-screen')), findsNothing);
    expect(find.textContaining('รายงานประจำวัน'), findsOneWidget);
  });

  testWidgets('ปุ่ม ? ที่ตัวละคร: เปิดหน้าข้อมูลตัวละคร แล้วกลับได้', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final s = container.read(gameProvider)!.state;
    await openFarmSheet(tester, 'farm-status');
    final open = find.byKey(const ValueKey('open-profile'));
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
    expect(find.text('${s.character} — เจ้าของฟาร์ม'), findsOneWidget);
    for (final t in ['อิ่ม', 'พลังงาน', 'สุขภาพ', 'ความสุข']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profile-screen')),
          matching: find.text(t),
        ),
        findsOneWidget,
      );
    }
    await tester.tap(find.widgetWithText(PixelButton, 'กลับ'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-screen')), findsNothing);
  });

  testWidgets('บ่อปลา: ค่าน้ำมีสีและคำแนะนำ ปุ่มจับปลาบอกเหตุผล', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final ctl = container.read(gameProvider.notifier);
    ctl.update((e) {
      e.buyFish('nila', 2);
      e.state.ammonia = .83;
    });
    await tester.tap(find.text('ปลา').last);
    await tester.pumpAndSettle();
    // หน้าหลักไม่มีตัวเลขเทคนิค: แตะป้ายน้ำจึงเห็นค่าน้ำ
    expect(find.text('แอมโมเนีย'), findsNothing);
    await openPondSheet(tester, 'pond-water');
    expect(find.text('แอมโมเนีย'), findsOneWidget);
    expect(find.text('NH3'), findsNothing);
    expect(find.text('เริ่มสูง'), findsOneWidget);
    expect(
      find.text('ดี'),
      findsWidgets,
    ); // ป้ายน้ำในบ่อลดจาก "ดีมาก" เป็น "ดี"

    final advice = find.byKey(const ValueKey('water-advice'));
    await tester.scrollUntilVisible(advice, 200, scrollable: sheetScroll());
    expect(find.textContaining('กด "เปลี่ยนน้ำ"'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('sheet-close')));
    await tester.pumpAndSettle();
    await openPondSheet(tester, 'pond-fish');
    final info = find.byKey(const ValueKey('catch-info'));
    expect(info, findsOneWidget);
    expect(
      find.text('ยังจับไม่ได้: ปลาโตสุด 0% (จับได้เมื่อโตครบ 100%)'),
      findsOneWidget,
    );
  });

  testWidgets('ช่องเซฟ: ลบต้องยืนยัน และเปลี่ยนชื่อได้', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await container.read(gameProvider.notifier).exitToMenu();
    await tester.pumpAndSettle();
    await openSurvival(tester, 'load');

    await tester.tap(find.text('ชื่อ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ฟาร์มใหม่');
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    expect(find.text('ฟาร์มใหม่'), findsOneWidget);
    expect(find.widgetWithText(PixelButton, 'เกมใหม่'), findsNWidgets(2));

    await tester.tap(find.text('ลบ').first);
    await tester.pumpAndSettle();
    expect(find.text('ลบเซฟ ฟาร์มใหม่? ย้อนกลับไม่ได้'), findsOneWidget);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(repo.listSlots()[1], isNotNull);

    await tester.tap(find.text('ลบ').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PixelButton, 'ลบ').last);
    await tester.pumpAndSettle();
    expect(repo.listSlots()[1], isNull);
    expect(find.text('ฟาร์มใหม่'), findsNothing);
    expect(find.widgetWithText(PixelButton, 'เกมใหม่'), findsNWidgets(3));
  });

  testWidgets('ภาพพิกเซลไม่เบลอ และปุ่มกดสูงอย่างน้อย 48dp', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);

    void checkScreen() {
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images, isNotEmpty);
      for (final img in images) {
        expect(img.filterQuality, FilterQuality.none);
      }
      final tappables = [
        ...find.byType(PixelButton).evaluate(),
        ...find.byType(Pressable).evaluate(),
        ...find
            .descendant(
              of: find.byType(GameNavBar),
              matching: find.byType(GestureDetector),
            )
            .evaluate(),
      ];
      expect(tappables, isNotEmpty);
      for (final e in tappables) {
        final size = (e.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(kMinTap));
        expect(size.width, greaterThanOrEqualTo(kMinTap));
      }
    }

    // หน้าฟาร์ม บ่อปลา ร้านปลา
    checkScreen();
    await tester.tap(find.text('ปลา'));
    await tester.pumpAndSettle();
    checkScreen();
    await tester.tap(find.text('ร้านปลา').first);
    await tester.pumpAndSettle();
    checkScreen();
  });

  group('ตลาด', () {
    /// รายการในแผ่นที่เปิดอยู่
    Finder marketScroll() => find.byType(Scrollable).last;

    /// เปิดแผ่นของตลาด: buy (ปุ่มหลัก) · sell · tools (ปิดแผ่นเดิมก่อน)
    Future<void> subTab(WidgetTester tester, String key) async {
      final close = find.byKey(const ValueKey('sheet-close'));
      if (close.evaluate().isNotEmpty) {
        await tester.tap(close);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('market-$key')));
      await tester.pumpAndSettle();
    }

    /// เปิดหน้าตลาด แล้วเปิดแผ่น [sheet] (null = อยู่ที่ฉาก)
    Future<void> openMarket(
      WidgetTester tester, {
      String? sheet = 'buy',
    }) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('ตลาด'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MarketTab), findsOneWidget);
      if (sheet != null) await subTab(tester, sheet);
    }

    /// เลื่อนจนเห็นทั้งชิ้น (ไม่ใช่แค่โผล่ขอบ) ก่อนกด
    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: marketScroll());
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
    }

    testWidgets('การ์ดวัตถุดิบแสดงไอคอน ราคาวันนี้ และราคาเมื่อวาน', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.prevPrices['garlic'] = s.prices['garlic']! - 2;
      await openMarket(tester);

      final card = find.byKey(const ValueKey('ing-garlic'));
      expect(card, findsOneWidget);
      Finder inCard(Finder f) => find.descendant(of: card, matching: f);
      expect(inCard(find.text('กระเทียม')), findsOneWidget);
      expect(inCard(find.byType(PixelIcon)), findsWidgets);
      expect(inCard(find.text('${s.prices['garlic']}')), findsOneWidget);
      expect(
        inCard(find.text('เมื่อวาน ${s.prices['garlic']! - 2}')),
        findsOneWidget,
      );
      expect(inCard(find.text('▲2')), findsOneWidget);
      expect(inCard(find.text('ซื้อ')), findsOneWidget);
      expect(find.byKey(const ValueKey('market-closed')), findsNothing);
    });

    testWidgets('ซื้อวัตถุดิบต้องยืนยัน: ยกเลิกไม่ซื้อ ตกลงแล้วซื้อ', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester);
      await openMarket(tester);
      final s = container.read(gameProvider)!.state;
      final p = s.prices['garlic']!;

      await tester.tap(find.byKey(const ValueKey('ing-garlic')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'ยืนยันซื้อกระเทียม 1 ชิ้น ราคา $p บาท? (เงินคงเหลือ ${500 - p} บาท)',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.inventory['garlic'] ?? 0, 0);
      expect(s.money, 500);

      await tester.tap(find.byKey(const ValueKey('ing-garlic')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(s.inventory['garlic'], 1);
      expect(s.money, 500 - p);
    });

    testWidgets('ขายปลาในคลังต้องยืนยันก่อน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.fishStock['nila'] = 2;
      await openMarket(tester);
      await subTab(tester, 'sell');

      final card = find.byKey(const ValueKey('sell-fish-nila'));
      await scrollTo(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันขายปลานิล 1 ตัว ได้ 90 บาท?'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.fishStock['nila'], 2);
      expect(s.money, 500);

      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(s.fishStock['nila'], 1);
      expect(s.money, 590);
    });

    testWidgets('ขายอาหารต้องยืนยันก่อน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      expect(s.stock.single.food, 'dried');
      expect(s.stock.single.qty, 2);
      await openMarket(tester);
      await subTab(tester, 'sell');

      final sell = find.descendant(
        of: find.byKey(const ValueKey('sell-food-0')),
        matching: find.byType(PixelButton),
      );
      await scrollTo(tester, sell);
      await tester.tap(sell);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันขายปลาแห้ง 1 จาน ได้ 42 บาท?'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.stock.single.qty, 2);

      await tester.tap(sell);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(s.stock.single.qty, 1);
      expect(s.money, 542);
    });

    testWidgets('ซื้ออุปกรณ์ครัวต้องยืนยันก่อน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      final before = s.equipmentCount('rack');
      await openMarket(tester, sheet: 'tools');

      final buy = find.descendant(
        of: find.byKey(const ValueKey('eq-rack')),
        matching: find.byType(PixelButton),
      );
      await scrollTo(tester, buy);
      await tester.tap(buy);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันซื้อแผงตากปลา ราคา 60 บาท?'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.equipmentCount('rack'), before);

      await tester.tap(buy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(s.equipmentCount('rack'), before + 1);
      expect(s.money, 440);
    });

    testWidgets(
      'ตลาดปิดตอนเกิดภัย: มีป้ายบอกเหตุผล ซื้อขายไม่ได้ ไม่ขึ้นหน้ายืนยัน',
      (tester) async {
        await pumpApp(tester);
        await startNewGame(tester);
        final s = container.read(gameProvider)!.state;
        s.marketClosed = true;
        s.fishStock['nila'] = 1;
        await openMarket(tester);

        expect(find.byKey(const ValueKey('market-closed')), findsOneWidget);
        // ป้ายบนฉาก + แผ่นรายละเอียด
        expect(find.text('ตลาดปิดชั่วคราว'), findsWidgets);
        expect(
          find.textContaining('ซื้อขายไม่ได้ ใช้เสบียงที่เตรียมไว้'),
          findsOneWidget,
        );

        const reason = 'ตลาดปิดชั่วคราว เส้นทางถูกตัดขาดจากภัยพิบัติ';
        Future<void> tapBlocked(Finder f) async {
          await scrollTo(tester, f);
          await tester.tap(f);
          await tester.pump();
          expect(find.byType(ConfirmDialog), findsNothing);
          expect(find.text(reason), findsOneWidget);
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
        }

        await tapBlocked(find.byKey(const ValueKey('ing-garlic')));
        await subTab(tester, 'sell');
        await tapBlocked(find.byKey(const ValueKey('sell-fish-nila')));
        await tapBlocked(
          find.descendant(
            of: find.byKey(const ValueKey('sell-food-0')),
            matching: find.byType(PixelButton),
          ),
        );
        await subTab(tester, 'tools');
        await tapBlocked(
          find.descendant(
            of: find.byKey(const ValueKey('eq-rack')),
            matching: find.byType(PixelButton),
          ),
        );

        expect(s.money, 500);
        expect(s.inventory['garlic'] ?? 0, 0);
        expect(s.fishStock['nila'], 1);
        expect(s.stock.single.qty, 2);
      },
    );

    testWidgets('ข้อความแจ้งเตือนอยู่ใต้แถบบน ไม่บังเมนูล่าง', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      container.read(gameProvider)!.state.marketClosed = true;
      await openMarket(tester);

      final card = find.byKey(const ValueKey('ing-garlic'));
      await scrollTo(tester, card);
      await tester.tap(card);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final bubble = tester.getRect(find.byType(ToastBubble));
      final top = tester.getRect(find.byType(TopBar));
      final nav = tester.getRect(find.byType(GameNavBar));
      expect(bubble.top, greaterThanOrEqualTo(top.bottom));
      expect(bubble.bottom, lessThan(nav.top));
      expect(bubble.top, lessThan(844 / 3));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.byType(ToastBubble), findsNothing);
    });

    testWidgets('ปุ่มในตลาดสูงอย่างน้อย 48dp และภาพไม่เบลอ', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      await openMarket(tester);
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        expect(img.filterQuality, FilterQuality.none);
      }
      final tappables = [
        ...find.byType(PixelButton).evaluate(),
        ...find.byType(Pressable).evaluate(),
      ];
      expect(tappables, isNotEmpty);
      for (final e in tappables) {
        final size = (e.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(kMinTap));
        expect(size.width, greaterThanOrEqualTo(kMinTap));
      }
    });
  });

  group('ครัว', () {
    /// เปิดแผ่นของครัว: cook (ปุ่มหลัก) · preserve · fish (ปิดแผ่นเดิมก่อน)
    Future<void> kitchenSheet(WidgetTester tester, String key) async {
      final close = find.byKey(const ValueKey('sheet-close'));
      if (close.evaluate().isNotEmpty) {
        await tester.tap(close);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(ValueKey('kitchen-$key')));
      await tester.pumpAndSettle();
    }

    Future<void> openKitchen(
      WidgetTester tester, {
      String? sheet = 'cook',
    }) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('ครัว'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KitchenTab), findsOneWidget);
      if (sheet != null) await kitchenSheet(tester, sheet);
    }

    /// รายการในแผ่นที่เปิดอยู่
    Finder kitchenScroll() => find.byType(Scrollable).last;

    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: kitchenScroll());
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
    }

    Finder buttonIn(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byWidgetPredicate(
        (w) =>
            w is PixelButton &&
            (w.label == 'ทำอาหาร' || w.label == 'เริ่มถนอม'),
      ),
    );

    bool enabled(WidgetTester tester, Finder f) =>
        tester.widget<PixelButton>(f).onPressed != null;

    testWidgets('ไม่มีปลา: ทำอาหารไม่ได้ และบอกให้จับปลาก่อน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      await openKitchen(tester);
      // บ่อยังว่าง → บอกเหตุผล และมีปุ่มพาไปบ่อปลา
      expect(
        find.text('ไม่มีปลาในคลัง และบ่อยังว่าง ซื้อปลาที่ร้านปลาก่อน'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('go-pond')), findsOneWidget);
      for (final r in ['fry', 'garlic', 'tomyum', 'bake', 'herb']) {
        await scrollTo(tester, buttonIn('recipe-$r'));
        expect(enabled(tester, buttonIn('recipe-$r')), isFalse);
      }
    });

    testWidgets('ทำปลาทอด: ใช้ปลา 1 ตัวและเครื่องปรุง ได้อาหารเข้าคลัง', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.fishStock['nila'] = 1;
      s.inventory['spice'] = 1;
      await openKitchen(tester);

      // แผงเลือกปลาอยู่ท้ายหน้า (ปุ่มทำอาหารขึ้นก่อน)
      await scrollTo(tester, find.byKey(const ValueKey('cook-fish-nila')));
      expect(find.byKey(const ValueKey('cook-fish-nila')), findsOneWidget);
      final fry = buttonIn('recipe-fry');
      await scrollTo(tester, fry);
      expect(enabled(tester, fry), isTrue);
      expect(enabled(tester, buttonIn('recipe-garlic')), isFalse);
      await tester.tap(fry);
      await tester.pump();
      expect(find.text('ทำปลาทอดได้ 2 จาน (ใช้ปลานิล)'), findsOneWidget);
      expect(s.fishStock['nila'], 0);
      expect(s.inventory['spice'], 0);
      expect(s.energy, 92);
      expect(s.stock.any((b) => b.food == 'fry' && b.qty == 2), isTrue);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(enabled(tester, fry), isFalse);
    });

    testWidgets('เลือกปลาที่จะใช้ได้', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.fishStock['nila'] = 1;
      s.fishStock['dook'] = 1;
      await openKitchen(tester);
      final e = container.read(gameProvider)!.engine;
      expect(e.fishForCooking, 'nila');
      await scrollTo(tester, find.byKey(const ValueKey('cook-fish-dook')));
      await tester.tap(find.byKey(const ValueKey('cook-fish-dook')));
      await tester.pumpAndSettle();
      expect(e.fishForCooking, 'dook');
      expect(s.cookFish, 'dook');
    });

    testWidgets('ถนอมอาหาร: ต้องมีอุปกรณ์ว่าง แล้วเริ่มงานได้', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.fishStock['nila'] = 2;
      await openKitchen(tester, sheet: 'preserve');

      final dry = buttonIn('preserve-dried');
      await scrollTo(tester, dry);
      expect(find.text('แผงตากปลา ว่าง 0/0'), findsOneWidget);
      expect(enabled(tester, dry), isFalse);

      s.equipment['rack'] = 1;
      container
          .read(gameProvider.notifier)
          .run((e) => const ActionResult.ok(''));
      await tester.pumpAndSettle();
      expect(find.text('แผงตากปลา ว่าง 1/1'), findsOneWidget);
      // เหตุผลและปุ่ม "ไปตลาด" หายไป การ์ดเตี้ยลง → เลื่อนหาปุ่มใหม่
      await scrollTo(tester, dry);
      await tester.tap(dry);
      await tester.pump();
      expect(find.text('เริ่มตากแห้ง (Drying) ใช้เวลา 2 วัน'), findsOneWidget);
      expect(s.processing.single.method, 'dried');
      expect(s.fishStock['nila'], 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('แผงตากปลา ว่าง 0/1'), findsOneWidget);
      expect(enabled(tester, dry), isFalse);
      await scrollTo(tester, find.byKey(const ValueKey('fridge-status')));
      expect(find.text('ยังไม่มี (ซื้อที่ตลาด)'), findsOneWidget);
      await scrollTo(tester, find.byKey(const ValueKey('job-0')));
      expect(find.text('เหลือ 2 วัน'), findsOneWidget);
    });

    testWidgets('ปุ่มในครัวสูงอย่างน้อย 48dp และภาพไม่เบลอ', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      container.read(gameProvider)!.state.fishStock['nila'] = 1;
      await openKitchen(tester);
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        expect(img.filterQuality, FilterQuality.none);
      }
      for (final e in [
        ...find.byType(PixelButton).evaluate(),
        ...find.byType(Pressable).evaluate(),
      ]) {
        final size = (e.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(kMinTap));
        expect(size.width, greaterThanOrEqualTo(kMinTap));
      }
    });
  });

  group('คลัง', () {
    /// เปิดหน้าคลัง แล้วเปิดแผ่น: food (ปุ่มหลัก) · supply-btn · items
    Future<void> openStorage(
      WidgetTester tester, {
      String? sheet = 'food',
    }) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('คลัง'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StorageTab), findsOneWidget);
      if (sheet != null) {
        await tester.tap(find.byKey(ValueKey('storage-$sheet')));
        await tester.pumpAndSettle();
      }
    }

    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
    }

    Finder batchButton(int i, String label) => find.descendant(
      of: find.byKey(ValueKey('batch-$i')),
      matching: find.widgetWithText(PixelButton, label),
    );

    testWidgets('เสบียงฉุกเฉิน: คำนวณวันจากความอิ่ม และตั้งเป้าหมายได้', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final e = container.read(gameProvider)!.engine;
      await openStorage(tester, sheet: 'supply-btn');

      // แผ่นเสบียงฉุกเฉิน
      await scrollTo(tester, find.byKey(const ValueKey('supply-after')));
      expect(
        find.text('อาหารพอกิน ${fmtNum(e.supplyDays)} วัน'),
        findsOneWidget,
      );
      expect(find.textContaining('มีอาหาร 2 จาน'), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-after')), findsOneWidget);
      // ส่วนตั้งเป้าหมายพับไว้ → กดเปิดก่อน
      await scrollTo(tester, find.byKey(const ValueKey('goal-toggle')));
      await tester.tap(find.byKey(const ValueKey('goal-toggle')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.byKey(const ValueKey('goal-status')));
      expect(
        find.text('ขาดอีก ${fmtNum(e.goalShortfall)} วันจึงถึงเป้า'),
        findsOneWidget,
      );

      await scrollTo(tester, find.byKey(const ValueKey('goal-3')));
      await tester.tap(find.byKey(const ValueKey('goal-3')));
      await tester.pumpAndSettle();
      expect(e.state.goal, 3);
      expect(
        find.text('ขาดอีก ${fmtNum(e.goalShortfall)} วันจึงถึงเป้า'),
        findsOneWidget,
      );
    });

    testWidgets('กินอาหารต้องยืนยัน: ยกเลิกไม่กิน ตกลงแล้วกิน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.hunger = 50;
      await openStorage(tester);

      final eat = batchButton(0, 'กิน');
      await scrollTo(tester, eat);
      await tester.tap(eat);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('กินปลาแห้ง? ความอิ่ม 50 → 70'),
        findsOneWidget,
      );
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.stock.single.qty, 2);
      expect(s.hunger, 50);

      await tester.tap(eat);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PixelButton, 'กิน').last);
      await tester.pumpAndSettle();
      expect(s.stock.single.qty, 1);
      expect(s.hunger, 70);
    });

    testWidgets('อิ่มแล้ว: กินไม่ได้ และไม่ขึ้นหน้ายืนยัน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.hunger = 100;
      await openStorage(tester);
      final eat = batchButton(0, 'กิน');
      await scrollTo(tester, eat);
      await tester.tap(eat);
      await tester.pump();
      expect(find.byType(ConfirmDialog), findsNothing);
      expect(find.text('อิ่มแล้ว'), findsOneWidget);
      expect(s.stock.single.qty, 2);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('ขายอาหารจากคลังต้องยืนยัน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      await openStorage(tester);
      final sell = batchButton(0, 'ขาย');
      await scrollTo(tester, sell);
      await tester.tap(sell);
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันขายปลาแห้ง 1 จาน ได้ 42 บาท?'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.money, 500);
      await tester.tap(sell);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      expect(s.money, 542);
      expect(s.stock.single.qty, 1);
    });

    testWidgets('ทิ้งอาหารต้องยืนยัน แล้วหายทั้งล็อต', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      await openStorage(tester);
      final discard = batchButton(0, 'ทิ้ง');
      await scrollTo(tester, discard);
      await tester.tap(discard);
      await tester.pumpAndSettle();
      expect(find.text('ทิ้งปลาแห้ง 2 จาน?'), findsOneWidget);
      await tester.tap(find.text('ยกเลิก').last);
      await tester.pumpAndSettle();
      expect(s.stock, hasLength(1));

      await tester.tap(discard);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PixelButton, 'ทิ้ง').last);
      await tester.pumpAndSettle();
      expect(s.stock, isEmpty);
    });

    testWidgets('อาหารหมดอายุ: กินและขายไม่ได้ แต่ทิ้งได้', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.stock.single.age = 99;
      await openStorage(tester);
      final eat = batchButton(0, 'กิน');
      await scrollTo(tester, eat);
      expect(tester.widget<PixelButton>(eat).onPressed, isNull);
      expect(
        tester.widget<PixelButton>(batchButton(0, 'ขาย')).onPressed,
        isNull,
      );
      expect(
        tester.widget<PixelButton>(batchButton(0, 'ทิ้ง')).onPressed,
        isNotNull,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('batch-0')),
          matching: find.text('หมดอายุ'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('แสดงวัตถุดิบสดและอุปกรณ์ในคลัง', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final s = container.read(gameProvider)!.state;
      s.fishStock['nila'] = 3;
      s.inventory['salt'] = 2;
      s.equipment['rack'] = 1;
      await openStorage(tester, sheet: 'items');
      await scrollTo(tester, find.byKey(const ValueKey('raw-nila')));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('raw-nila')),
          matching: find.text('x3'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('raw-salt')), findsOneWidget);
      await scrollTo(tester, find.byKey(const ValueKey('equip-rack')));
      expect(find.byKey(const ValueKey('equip-rack')), findsOneWidget);
    });

    testWidgets('ปุ่มในคลังสูงอย่างน้อย 48dp และภาพไม่เบลอ', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      await openStorage(tester);
      await scrollTo(tester, batchButton(0, 'ทิ้ง'));
      for (final img in tester.widgetList<Image>(find.byType(Image))) {
        expect(img.filterQuality, FilterQuality.none);
      }
      for (final e in [
        ...find.byType(PixelButton).evaluate(),
        ...find.byType(Pressable).evaluate(),
      ]) {
        final size = (e.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(kMinTap));
        expect(size.width, greaterThanOrEqualTo(kMinTap));
      }
    });
  });

  group('บทเรียน', () {
    Finder next() => find.widgetWithText(PixelButton, 'ถัดไป');
    bool nextEnabled(WidgetTester t) =>
        t.widget<PixelButton>(next()).onPressed != null;
    Finder navTab(String t) =>
        find.descendant(of: find.byType(GameNavBar), matching: find.text(t));

    testWidgets('กดถัดไปได้เมื่อทำขั้นนั้นสำเร็จ และชี้เมนูที่ต้องไป', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester, skipTutorial: false);
      expect(find.text('บทเรียน 1/9'), findsOneWidget);
      expect(
        tester
            .widget<PixelButton>(find.widgetWithText(PixelButton, 'ย้อนกลับ'))
            .onPressed,
        isNull,
      );
      await tester.tap(next());
      await tester.pumpAndSettle();
      await tester.tap(next());
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 3/9'), findsOneWidget);
      expect(
        find.text('ไปที่เมนู "ปลา" เพื่อเข้าไปดูแลบ่อปลา'),
        findsOneWidget,
      );
      expect(nextEnabled(tester), isFalse);

      // เมนู "ปลา" กะพริบชี้ให้ไป
      final lit = tester
          .widgetList<Spotlight>(
            find.descendant(
              of: find.byType(GameNavBar),
              matching: find.byType(Spotlight),
            ),
          )
          .toList();
      expect(lit.where((s) => s.on), hasLength(1));
      expect(lit[1].on, isTrue);

      await tester.tap(navTab('ปลา'));
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);
      await tester.tap(next());
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 4/9'), findsOneWidget);
      expect(nextEnabled(tester), isFalse);

      await tester.tap(find.widgetWithText(PixelButton, 'ย้อนกลับ'));
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 3/9'), findsOneWidget);
    });

    testWidgets('ขั้นทำอาหาร: แจกปลาและเครื่องปรุง ผ่านเมื่อทำปลาทอดในครัว', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester, skipTutorial: false);
      final ctl = container.read(gameProvider.notifier);
      final s = container.read(gameProvider)!.state;
      ctl.update((e) => s.tut = 5);
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 6/9'), findsOneWidget);
      await tester.tap(navTab('ปลา'));
      await tester.pumpAndSettle();
      await tester.tap(next());
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 7/9'), findsOneWidget);
      expect(s.fishStock['nila'], 1);
      expect(s.inventory['spice'], 1);
      expect(nextEnabled(tester), isFalse);

      await tester.tap(navTab('ครัว'));
      await tester.pumpAndSettle();
      // ปุ่มหลัก "ทำอาหาร" ในถาดเปิดแผ่นสูตรอาหาร
      await tester.tap(find.byKey(const ValueKey('kitchen-cook')));
      await tester.pumpAndSettle();
      final fry = find.descendant(
        of: find.byKey(const ValueKey('recipe-fry')),
        matching: find.byType(PixelButton),
      );
      await tester.scrollUntilVisible(
        fry,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(fry);
      await tester.pumpAndSettle();
      await tester.tap(fry);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);
    });

    testWidgets('ข้ามบทเรียนแล้วเล่นซ้ำได้จากเมนู', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      expect(find.byKey(const ValueKey('tutorial')), findsNothing);
      // ตัวละครบอกสิ่งที่ควรทำต่อ (กล่องคำพูด)
      expect(find.byKey(const ValueKey('next-step')), findsOneWidget);

      await tester.tap(navTab('คลัง'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('เมนู / พัก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เล่นบทเรียนซ้ำ'));
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 1/9'), findsOneWidget);
      // กลับมาหน้าฟาร์ม และซ่อนคำแนะนำระหว่างบทเรียน
      expect(find.byKey(const ValueKey('tip-bar')), findsNothing);
      expect(find.byKey(const ValueKey('next-step')), findsNothing);
      expect(container.read(gameProvider)!.state.tut, 0);
    });
  });

  testWidgets('เตรียมภัย: ซื้ออุปกรณ์ป้องกันต้องยืนยันก่อน', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final s = container.read(gameProvider)!.state;
    final sand = kEquipment['sand']!;
    await openFarmSheet(tester, 'farm-prepare');
    final buy = find.descendant(
      of: find.byKey(const ValueKey('eq-sand')),
      matching: find.byType(PixelButton),
    );
    await tester.scrollUntilVisible(
      buy,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(buy);
    await tester.pumpAndSettle();
    for (final id in kDefenseEquipmentOrder) {
      expect(find.byKey(ValueKey('eq-$id')), findsOneWidget);
    }

    await tester.tap(buy);
    await tester.pumpAndSettle();
    expect(
      find.text('ยืนยันซื้อ${sand.name} ราคา ${sand.price} บาท?'),
      findsOneWidget,
    );
    await tester.tap(find.text('ยกเลิก').last);
    await tester.pumpAndSettle();
    expect(s.equipmentCount('sand'), 0);

    await tester.tap(buy);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    expect(s.equipmentCount('sand'), 1);
    expect(s.money, 500 - sand.price);
  });

  testWidgets('ใช้ฟอนต์ไทยเดียวที่ฝังในแอป (Sarabun) กับข้อความทั้งเกม', (
    tester,
  ) async {
    await pumpApp(tester);
    final ctx = tester.element(find.text('เนื้อเรื่อง'));
    expect(kFont, 'Sarabun');
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, kFont);
    expect(DefaultTextStyle.of(ctx).style.fontFamily, kFont);
  });

  group('กดใช้ง่าย', () {
    Finder navItem(String label) => find.descendant(
      of: find.byType(GameNavBar),
      matching: find.text(label),
    );

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(navItem(label));
      await tester.pumpAndSettle();
    }

    /// ทั้งชิ้นอยู่บนจอ ไม่ทับเมนูล่าง และกดโดนจริง
    void fullyVisible(WidgetTester tester, Finder f, String why) {
      expect(f, findsWidgets, reason: why);
      final r = tester.getRect(f.first);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final nav = tester.getRect(find.byType(GameNavBar));
      expect(r.top, greaterThanOrEqualTo(0), reason: why);
      expect(r.right, lessThanOrEqualTo(screen.width + .5), reason: why);
      final inNav = find
          .descendant(of: find.byType(GameNavBar), matching: f)
          .evaluate()
          .isNotEmpty;
      final sideNav = nav.height > nav.width;
      expect(r.bottom, lessThanOrEqualTo(screen.height + .5), reason: why);
      if (!inNav && sideNav) {
        // เมนูข้าง: ไม่ทับเมนูทางซ้าย
        expect(r.left, greaterThanOrEqualTo(nav.right - .5), reason: why);
      } else if (!inNav) {
        expect(
          r.bottom,
          lessThanOrEqualTo(nav.top + .5),
          reason: '$why ทับเมนู',
        );
      }
    }

    for (final size in const [Size(360, 740), Size(390, 844), Size(844, 390)]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: ทุกหน้าเห็นเมนูและปุ่มหลักโดยไม่ต้องเลื่อน',
        (tester) async {
          await pumpApp(tester);
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          await startNewGame(tester);
          final ctl = container.read(gameProvider.notifier);
          ctl.update((e) => e.state.fishStock['nila'] = 1);
          await tester.pumpAndSettle();

          void check(String page, Finder primary) {
            expect(tester.takeException(), isNull, reason: page);
            // เมนูครบทุกช่อง = มีทางไปหน้าอื่นเสมอ
            for (final t in ['ฟาร์ม', 'ปลา', 'ตลาด', 'ครัว', 'คลัง']) {
              fullyVisible(tester, navItem(t), '$page: เมนู $t');
            }
            fullyVisible(tester, primary, '$page: ปุ่มหลัก');
            fullyVisible(
              tester,
              find.byKey(const ValueKey('next-step')),
              '$page: ตอนนี้ควรทำ',
            );
          }

          check('ฟาร์ม', find.byKey(const ValueKey('end-day')));
          await openTab(tester, 'ปลา');
          check('บ่อ', find.byKey(const ValueKey('primary-pond')));
          await tester.tap(find.text('ร้านปลา').first);
          await tester.pumpAndSettle();
          check(
            'ร้านปลา',
            find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey &&
                  '${(w.key! as ValueKey).value}'.startsWith('fish-card-'),
            ),
          );

          /// แผ่นรายละเอียด: ของชิ้นแรกเห็นทันทีโดยไม่ต้องเลื่อน แล้วปิดกลับ
          Future<void> sheet(String opener, String page, Finder first) async {
            await tester.tap(find.byKey(ValueKey(opener)));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: page);
            final r = tester.getRect(first.first);
            final screen =
                tester.view.physicalSize / tester.view.devicePixelRatio;
            expect(r.top, greaterThanOrEqualTo(0), reason: page);
            expect(r.bottom, lessThanOrEqualTo(screen.height), reason: page);
            await tester.tap(find.byKey(const ValueKey('sheet-close')));
            await tester.pumpAndSettle();
          }

          await openTab(tester, 'ตลาด');
          check('ตลาด', find.byKey(const ValueKey('primary-market')));
          for (final k in ['market-sell', 'market-tools']) {
            fullyVisible(tester, find.byKey(ValueKey(k)), 'ตลาด: $k');
          }
          await sheet(
            'market-buy',
            'ตลาด (ซื้อ)',
            find.descendant(
              of: find.byKey(ValueKey('ing-${kIngredients.keys.first}')),
              matching: find.text('ซื้อ'),
            ),
          );
          await sheet(
            'market-sell',
            'ตลาด (ขาย)',
            find.byKey(const ValueKey('sell-fish-nila')),
          );
          await openTab(tester, 'ครัว');
          check('ครัว', find.byKey(const ValueKey('primary-kitchen')));
          for (final k in ['kitchen-fish', 'kitchen-preserve']) {
            fullyVisible(tester, find.byKey(ValueKey(k)), 'ครัว: $k');
          }
          await sheet(
            'kitchen-cook',
            'ครัว (สูตร)',
            find.descendant(
              of: find.byKey(ValueKey('recipe-${kRecipes.keys.first}')),
              matching: find.widgetWithText(PixelButton, 'ทำอาหาร'),
            ),
          );
          await openTab(tester, 'คลัง');
          check('คลัง', find.byKey(const ValueKey('primary-storage')));
          for (final k in ['storage-supply-btn', 'storage-items']) {
            fullyVisible(tester, find.byKey(ValueKey(k)), 'คลัง: $k');
          }
          await sheet(
            'storage-food',
            'คลัง (อาหาร)',
            find.descendant(
              of: find.byKey(const ValueKey('batch-0')),
              matching: find.widgetWithText(PixelButton, 'กิน'),
            ),
          );
        },
      );
    }

    for (final size in const [
      Size(390, 844),
      Size(844, 390),
      Size(1366, 768),
    ]) {
      final name = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$name: รายงานแบบฉากเต็มจอ เกรด ดาว 3 ค่า และรายละเอียด', (
        tester,
      ) async {
        await pumpApp(tester);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        await startNewGame(tester);
        await tester.tap(find.byKey(const ValueKey('end-day')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        for (final k in [
          'report-grade',
          'report-earned',
          'report-fish',
          'report-supply',
          'report-details',
          'report-next',
        ]) {
          final r = tester.getRect(find.byKey(ValueKey(k)));
          expect(r.top, greaterThanOrEqualTo(0), reason: '$name $k');
          expect(r.bottom, lessThanOrEqualTo(screen.height), reason: k);
          expect(r.right, lessThanOrEqualTo(screen.width), reason: k);
        }
        final grade = container.read(gameProvider)!.state.lastReport!.grade;
        expect(find.bySemanticsLabel('เกรด $grade'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'ได้ [123] ดาว จาก 3')), findsOne);
        // ตัวเลขเชิงเทคนิค (น้ำ/ออกซิเจน/เงินคงเหลือ) ไม่อยู่หน้าหลัก
        expect(find.text('น้ำ / ออกซิเจน'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('report-details')));
        await tester.pumpAndSettle();
        expect(find.text('น้ำ / ออกซิเจน'), findsOneWidget);
        expect(find.text('เงินคงเหลือ'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('sheet-close')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('report-next')));
        await tester.pumpAndSettle();
        expect(find.byType(GameNavBar), findsOneWidget);

        // เมนูพัก: เห็นทุกปุ่มโดยไม่ต้องเลื่อน กด "เล่นต่อ" แล้วปิด
        await tester.tap(find.byTooltip('เมนู / พัก'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final f in [
          find.byKey(const ValueKey('menu-resume')),
          find.widgetWithText(PixelButton, 'บันทึกเกม'),
          find.byKey(const ValueKey('sound-toggle')),
          find.widgetWithText(PixelButton, 'เล่นบทเรียนซ้ำ'),
          find.widgetWithText(PixelButton, 'กลับเมนูหลัก'),
        ]) {
          final r = tester.getRect(f);
          expect(r.top, greaterThanOrEqualTo(0), reason: '$name $f');
          expect(r.bottom, lessThanOrEqualTo(screen.height), reason: '$f');
          expect(r.height, greaterThanOrEqualTo(48), reason: '$f');
        }
        await tester.tap(find.byKey(const ValueKey('menu-resume')));
        await tester.pumpAndSettle();
        expect(find.text('เมนู / พัก'), findsNothing);
      });
    }

    testWidgets('หน้ารายงานหลังจบวัน: ปุ่มไปต่ออยู่บนจอเสมอ', (tester) async {
      await pumpApp(tester);
      tester.view.physicalSize = const Size(360, 740);
      await tester.pumpAndSettle();
      await startNewGame(tester);
      await tester.tap(find.byKey(const ValueKey('end-day')));
      await tester.pumpAndSettle();
      final next = find.widgetWithText(PixelButton, 'เริ่มวันใหม่');
      expect(next, findsOneWidget);
      expect(tester.getRect(next).bottom, lessThanOrEqualTo(740));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.byType(GameNavBar), findsOneWidget);
    });

    testWidgets('แถบ "ตอนนี้ควรทำ": กดแล้วพาไปหน้านั้น', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      // บ่อว่าง → ไปร้านปลา
      expect(find.text('บ่อว่าง ไปซื้อปลาที่ร้านปลา'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-step')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fish-card-nila')), findsOneWidget);

      // มีปลาแต่ยังไม่ให้อาหาร → ไปบ่อ
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) => e.buyFish('nila', 1));
      await openTab(tester, 'คลัง');
      expect(find.text('ปลายังไม่ได้กิน ไปให้อาหารที่บ่อ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-step')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('primary-pond')), findsOneWidget);
    });

    testWidgets('เมนูมีป้ายเมื่อมีงานรอ และไม่ขึ้นที่แท็บที่เปิดอยู่', (
      tester,
    ) async {
      await pumpApp(tester);
      await startNewGame(tester);
      final ctl = container.read(gameProvider.notifier);
      ctl.update((e) {
        e.buyFish('nila', 1);
        e.state.fishStock['nila'] = 2;
      });
      await tester.pumpAndSettle();
      Finder badge(int i) => find.byKey(ValueKey('nav-badge-$i'));
      // ปลา: ยังไม่ให้อาหาร (จุด) · ตลาด: ปลาขายได้ 2 · ครัว: มีปลาทำอาหาร
      expect(badge(1), findsOneWidget);
      expect(
        find.descendant(of: badge(2), matching: find.text('2')),
        findsOneWidget,
      );
      expect(badge(3), findsOneWidget);
      await openTab(tester, 'ตลาด');
      expect(badge(2), findsNothing);
      // ให้อาหารแล้ว → ป้ายบ่อหาย
      ctl.update((e) => e.feed(2));
      await tester.pumpAndSettle();
      expect(badge(1), findsNothing);
    });

    testWidgets('คำแนะนำครั้งแรก: แสดงครั้งเดียว บันทึกไว้ และกด ? ดูซ้ำได้', (
      tester,
    ) async {
      await pumpApp(tester, tips: true);
      await startNewGame(tester);
      expect(find.byKey(const ValueKey('tip-bar')), findsOneWidget);
      expect(find.text(kPageTips[GameScreen.farm]!), findsOneWidget);
      // ระหว่างแสดงคำแนะนำ แถบ "ตอนนี้ควรทำ" ถูกแทนที่
      expect(find.byKey(const ValueKey('next-step')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tip-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tip-bar')), findsNothing);
      expect(find.byKey(const ValueKey('next-step')), findsOneWidget);
      expect(repo.tipsSeen, contains('farm'));

      // หน้าใหม่ → คำแนะนำของหน้านั้น
      await openTab(tester, 'ตลาด');
      expect(find.text(kPageTips[GameScreen.market]!), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tip-ok')));
      await tester.pumpAndSettle();

      // กลับมาหน้าเดิม: ไม่แสดงอีก
      await openTab(tester, 'ฟาร์ม');
      expect(find.byKey(const ValueKey('tip-bar')), findsNothing);

      // ปุ่ม ? → แสดงซ้ำ
      await tester.tap(find.byKey(const ValueKey('tip-help')));
      await tester.pumpAndSettle();
      expect(find.text(kPageTips[GameScreen.farm]!), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tip-ok')));
      await tester.pumpAndSettle();
      expect(repo.tipsSeen, containsAll(['farm', 'market']));
    });
  });
}
