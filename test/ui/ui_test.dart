import 'package:aqua_farm/data/difficulty.dart';
import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/data/equipment_data.dart';
import 'package:aqua_farm/game/game_engine.dart';
import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/app.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/screens/game_shell.dart';
import 'package:aqua_farm/ui/screens/kitchen_tab.dart';
import 'package:aqua_farm/ui/screens/market_tab.dart';
import 'package:aqua_farm/ui/screens/storage_tab.dart';
import 'package:aqua_farm/ui/sound.dart';
import 'package:aqua_farm/ui/theme/theme.dart';
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

Future<void> pumpApp(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
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

/// เมนูหลัก → เกมใหม่ → ช่อง 1 → เลือกโหมด → ตั้งชื่อ → ตกลง
/// (ข้ามบทเรียนเป็นค่าเริ่มต้น เพื่อทดสอบส่วนอื่นได้เต็มจอ)
Future<void> startNewGame(
  WidgetTester tester, {
  bool skipTutorial = true,
  Difficulty mode = Difficulty.normal,
}) async {
  await tester.tap(find.text('เกมใหม่'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PixelButton, 'เกมใหม่').first);
  await tester.pumpAndSettle();
  expect(find.text('เลือกความยาก'), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('mode-${mode.name}')));
  await tester.pumpAndSettle();
  expect(find.text('ตั้งชื่อ Save'), findsOneWidget);
  await tester.tap(find.text('ตกลง'));
  await tester.pumpAndSettle();
  if (skipTutorial) {
    await tester.tap(find.widgetWithText(PixelButton, 'ข้าม'));
    await tester.pumpAndSettle();
  }
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

void main() {
  testWidgets('เมนูหลักมีปุ่มครบ และเล่นต่อเมื่อไม่มีเซฟแจ้งเตือน', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('AQUA FARM'), findsOneWidget);
    for (final t in ['เกมใหม่', 'เล่นต่อ', 'โหลดเกม', 'เครดิต']) {
      expect(find.text(t), findsOneWidget);
    }
    await tester.tap(find.text('เล่นต่อ'));
    await tester.pump();
    expect(find.text('ยังไม่มีเซฟ'), findsOneWidget);
  });

  testWidgets('สร้างเกมใหม่ในช่อง 1 แล้วเข้าหน้าฟาร์ม แถบบนและเมนูล่างครบ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester, skipTutorial: false);
    // เกมใหม่เริ่มบทเรียน และซ่อนคำแนะนำจนกว่าจะจบบทเรียน (ตามต้นแบบ)
    expect(find.text('บทเรียน 1/9'), findsOneWidget);
    expect(find.text('ซื้อปลาที่ร้านปลา แล้วปล่อยลงบ่อ'), findsNothing);
    await tester.tap(find.widgetWithText(PixelButton, 'ข้าม'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tutorial')), findsNothing);
    expect(repo.listSlots()[1]!.name, 'ฟาร์มของฉัน');
    expect(find.text('500฿'), findsOneWidget);
    expect(find.text('วัน 1/30'), findsOneWidget);
    expect(find.text('2 วัน'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.widgetWithText(PixelButton, 'จบวัน'), findsOneWidget);
    for (final t in ['ฟาร์ม', 'ปลา', 'ตลาด', 'ครัว', 'คลัง']) {
      expect(
        find.descendant(of: find.byType(GameNavBar), matching: find.text(t)),
        findsOneWidget,
      );
    }
    expect(find.text('ซื้อปลาที่ร้านปลา แล้วปล่อยลงบ่อ'), findsOneWidget);
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

    // รอ toast "ซื้อปลา..." หายก่อน แล้วสลับไปบ่อปลา เลื่อนลงหาปุ่มให้อาหาร
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บ่อปลา'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('พอดี'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('พอดี'));
    await tester.pump();
    expect(find.text('ให้อาหารพอดี ปลาโตดี'), findsOneWidget);
    expect(container.read(gameProvider)!.state.fed, 2);

    await tester.tap(find.widgetWithText(PixelButton, 'จบวัน'));
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
    expect(find.text('วัน 2/30'), findsOneWidget);
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
    final list = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('pond-fish-1')),
      200,
      scrollable: list,
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
    await tester.tap(find.text('เกมใหม่'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PixelButton, 'เกมใหม่').first);
    await tester.pumpAndSettle();
    for (final t in ['ง่าย', 'ปานกลาง', 'ยาก']) {
      expect(find.text(t), findsOneWidget);
    }
    for (final t in ['รอดครบ 15 วัน', 'รอดครบ 30 วัน', 'รอดครบ 60 วัน']) {
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
    expect(find.text('วัน 1/60'), findsOneWidget);
    expect(repo.listSlots()[1]!.mode, Difficulty.hard);
    await container.read(gameProvider.notifier).exitToMenu();
    await tester.pumpAndSettle();
    await tester.tap(find.text('โหลดเกม'));
    await tester.pumpAndSettle();
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
        ..day = 15
        ..hunger = 100
        ..health = 100
        ..money = 777;
    });
    await ctl.save();
    await tester.pumpAndSettle();
    expect(find.text('วัน 15/15'), findsOneWidget);
    await tester.tap(find.widgetWithText(PixelButton, 'จบวัน'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('win')), findsOneWidget);
    expect(find.text('ชนะ!'), findsOneWidget);
    expect(find.text('รอดครบ 15 วัน'), findsOneWidget);
    expect(find.text('โหมดง่าย'), findsOneWidget);
    expect(find.text('เกรดรวม'), findsOneWidget);
    expect(find.text('ภัยที่รอด'), findsOneWidget);
    expect(find.text('เงินคงเหลือ'), findsOneWidget);
    expect(find.text('15/15 วัน'), findsOneWidget);
    // ไม่มีรายงานประจำวันซ้อน และเซฟยังเป็นวันที่ 15 ก่อนจบเกม
    expect(find.textContaining('รายงานประจำวัน'), findsNothing);
    expect(repo.listSlots()[1]!.day, 15);

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
    await tester.tap(find.widgetWithText(PixelButton, 'จบวัน'));
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
    final growth = find.byKey(const ValueKey('growth-info'));
    await tester.scrollUntilVisible(growth, 200);
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

  testWidgets('ช่องเซฟ: ลบต้องยืนยัน และเปลี่ยนชื่อได้', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await container.read(gameProvider.notifier).exitToMenu();
    await tester.pumpAndSettle();
    await tester.tap(find.text('โหลดเกม'));
    await tester.pumpAndSettle();

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
    Finder marketScroll() => find
        .descendant(
          of: find.byType(MarketTab),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> openMarket(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('ตลาด'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MarketTab), findsOneWidget);
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
      await openMarket(tester);

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
        expect(find.text('ตลาดปิดชั่วคราว'), findsOneWidget);
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
        await tapBlocked(find.byKey(const ValueKey('sell-fish-nila')));
        await tapBlocked(
          find.descendant(
            of: find.byKey(const ValueKey('sell-food-0')),
            matching: find.byType(PixelButton),
          ),
        );
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
    Future<void> openKitchen(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('ครัว'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KitchenTab), findsOneWidget);
    }

    Finder kitchenScroll() => find
        .descendant(
          of: find.byType(KitchenTab),
          matching: find.byType(Scrollable),
        )
        .first;

    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(f, 200, scrollable: kitchenScroll());
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
    }

    Finder buttonIn(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(PixelButton),
    );

    bool enabled(WidgetTester tester, Finder f) =>
        tester.widget<PixelButton>(f).onPressed != null;

    testWidgets('ไม่มีปลา: ทำอาหารไม่ได้ และบอกให้จับปลาก่อน', (tester) async {
      await pumpApp(tester);
      await startNewGame(tester);
      await openKitchen(tester);
      expect(find.text('ไม่มีปลาในคลัง จับปลาที่บ่อก่อน'), findsOneWidget);
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
      await openKitchen(tester);
      await tester.tap(find.widgetWithText(PixelButton, 'ถนอมอาหาร'));
      await tester.pumpAndSettle();

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
    Future<void> openStorage(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GameNavBar),
          matching: find.text('คลัง'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(StorageTab), findsOneWidget);
    }

    Future<void> scrollTo(WidgetTester tester, Finder f) async {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find
            .descendant(
              of: find.byType(StorageTab),
              matching: find.byType(Scrollable),
            )
            .first,
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
      await openStorage(tester);

      expect(find.text('อาหารกินได้ 2 จาน'), findsOneWidget);
      expect(
        find.text('อยู่ได้ ${fmtNum(e.supplyDays)} วัน (ต้องการ 20/วัน)'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('supply-after')), findsOneWidget);
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
      await openStorage(tester);
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
      final fry = find.descendant(
        of: find.byKey(const ValueKey('recipe-fry')),
        matching: find.byType(PixelButton),
      );
      await tester.scrollUntilVisible(
        fry,
        200,
        scrollable: find
            .descendant(
              of: find.byType(KitchenTab),
              matching: find.byType(Scrollable),
            )
            .first,
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
      expect(find.text('ซื้อปลาที่ร้านปลา แล้วปล่อยลงบ่อ'), findsOneWidget);

      await tester.tap(navTab('คลัง'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('เมนู / พัก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('เล่นบทเรียนซ้ำ'));
      await tester.pumpAndSettle();
      expect(find.text('บทเรียน 1/9'), findsOneWidget);
      // กลับมาหน้าฟาร์ม และซ่อนคำแนะนำระหว่างบทเรียน
      expect(find.text('ซื้อปลาที่ร้านปลา แล้วปล่อยลงบ่อ'), findsNothing);
      expect(container.read(gameProvider)!.state.tut, 0);
    });
  });

  testWidgets('เตรียมภัย: ซื้ออุปกรณ์ป้องกันต้องยืนยันก่อน', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    final s = container.read(gameProvider)!.state;
    final sand = kEquipment['sand']!;
    final buy = find.descendant(
      of: find.byKey(const ValueKey('eq-sand')),
      matching: find.byType(PixelButton),
    );
    await tester.scrollUntilVisible(
      buy,
      200,
      scrollable: find.byType(Scrollable).first,
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

  testWidgets('ใช้ฟอนต์ไทยที่ฝังในแอป (Mali) กับข้อความทั้งเกม', (
    tester,
  ) async {
    await pumpApp(tester);
    final ctx = tester.element(find.text('เกมใหม่'));
    expect(Theme.of(ctx).textTheme.bodyMedium!.fontFamily, kFont);
    expect(DefaultTextStyle.of(ctx).style.fontFamily, kFont);
  });
}
