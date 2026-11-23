import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/app.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SaveRepository repo;
late ProviderContainer container;

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
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AquaFarmApp()),
  );
  await tester.pumpAndSettle();
}

/// เมนูหลัก → เกมใหม่ → ช่อง 1 → ตั้งชื่อ → ตกลง
Future<void> startNewGame(WidgetTester tester) async {
  await tester.tap(find.text('เกมใหม่'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(PixelButton, 'เกมใหม่').first);
  await tester.pumpAndSettle();
  expect(find.text('ตั้งชื่อ Save'), findsOneWidget);
  await tester.tap(find.text('ตกลง'));
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
    await startNewGame(tester);
    expect(repo.listSlots()[1]!.name, 'ฟาร์มของฉัน');
    expect(find.text('500฿'), findsOneWidget);
    expect(find.text('วันที่ 1'), findsOneWidget);
    expect(find.text('2 วัน'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('จบวัน ▶'), findsOneWidget);
    for (final t in ['ฟาร์ม', 'ปลา', 'ตลาด', 'ครัว', 'คลัง']) {
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(t)),
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

    await tester.tap(find.text('+'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
    await tester.pumpAndSettle();
    expect(
      find.text('ยืนยันซื้อปลานิล 2 ตัว รวม 80 บาท? (เงินคงเหลือ 420 บาท)'),
      findsOneWidget,
    );
    await tester.tap(find.text('ยกเลิก').last);
    await tester.pumpAndSettle();
    expect(container.read(gameProvider)!.state.pond, isEmpty);

    await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();
    final s = container.read(gameProvider)!.state;
    expect(s.pond.length, 2);
    expect(s.money, 420);
    expect(find.text('420฿'), findsOneWidget);
  });

  testWidgets('บ่อปลา: ให้อาหาร แล้วจบวันเห็นรายงาน และบันทึกอัตโนมัติ', (
    tester,
  ) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await openFishShopCard(tester, 'nila');
    await tester.tap(find.widgetWithText(PixelButton, 'ซื้อปลา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ตกลง'));
    await tester.pumpAndSettle();

    // รอ toast "ซื้อปลา..." หายก่อน แล้วสลับไปบ่อปลา เลื่อนลงหาปุ่มให้อาหาร
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('บ่อปลา'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('พอดี 2฿'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('พอดี 2฿'));
    await tester.pump();
    expect(find.text('ให้อาหารพอดี ปลาโตดี'), findsOneWidget);
    expect(container.read(gameProvider)!.state.fed, 2);

    await tester.tap(find.text('จบวัน ▶'));
    await tester.pumpAndSettle();
    expect(find.text('รายงานประจำวัน — วันที่ 1'), findsOneWidget);
    expect(repo.load(1).day, 2);
    await tester.tap(find.text('เริ่มวันใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('วันที่ 2'), findsOneWidget);
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
    expect(find.text('ช่อง 1: ฟาร์มใหม่'), findsOneWidget);

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
    expect(find.text('ช่อง 1: ว่าง'), findsOneWidget);
  });

  testWidgets('ภาพพิกเซลไม่เบลอ และปุ่มกดสูงอย่างน้อย 48dp', (tester) async {
    await pumpApp(tester);
    await startNewGame(tester);
    await tester.tap(find.text('ปลา'));
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images, isNotEmpty);
    for (final img in images) {
      expect(img.filterQuality, FilterQuality.none);
    }
    for (final e in find.byType(ElevatedButton).evaluate()) {
      final size = tester.getSize(find.byWidget(e.widget));
      expect(size.height, greaterThanOrEqualTo(kMinTap));
      expect(size.width, greaterThanOrEqualTo(kMinTap));
    }
  });
}
