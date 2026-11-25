import 'package:aqua_farm/data/constants.dart';
import 'package:aqua_farm/game/story.dart';
import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/app.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/screens/game_shell.dart';
import 'package:aqua_farm/ui/screens/story_summary_screen.dart';
import 'package:aqua_farm/ui/sound.dart';
import 'package:aqua_farm/ui/story_provider.dart';
import 'package:aqua_farm/ui/theme/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/helpers.dart';
import 'uncle_helpers.dart';

class _SilentBeeper implements Beeper {
  @override
  void beep(double freq) {}
  @override
  void dispose() {}
}

late ProviderContainer container;

Future<void> pumpStory(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final repo = SaveRepository(await SharedPreferences.getInstance());
  container = ProviderContainer(
    overrides: [
      saveRepositoryProvider.overrideWithValue(repo),
      sceneAnimationProvider.overrideWithValue(false),
      beeperProvider.overrideWithValue(_SilentBeeper()),
      storyRandomProvider.overrideWithValue(FixedRandom()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AquaFarmApp()),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('menu-story')));
  await tester.pumpAndSettle();
  await hearUncle(tester);
}

StoryProgress get progress => container.read(storyProvider)!;
StoryTarget? get nextTarget =>
    Story.nextTarget(progress, container.read(gameProvider)!.engine);

/// ปุ่ม/ส่วนที่กำลังกะพริบชี้ (ต้องมีตัวเดียว)
Finder lit(String name) => find.byWidgetPredicate(
  (w) => w is Spotlight && w.on && w.key == ValueKey('story-gate-$name'),
);

/// ปุ่มที่ต้องกดอยู่บนจอครบทั้งปุ่ม ไม่ต้องเลื่อนหา (ไม่ถูกเมนูล่างบัง)
void expectNoScroll(WidgetTester tester, Finder f, String what) {
  expect(f, findsOneWidget, reason: 'ต้องมี "$what" กะพริบตัวเดียว');
  final r = tester.getRect(f);
  final screen = tester.view.physicalSize.height;
  final nav = find.byType(GameNavBar);
  // แผ่นรายละเอียดเปิดอยู่ → เมนูล่างอยู่ใต้แผ่น ใช้ทั้งความสูงจอได้
  final sheet = find.byKey(const ValueKey('sheet-close')).evaluate().isNotEmpty;
  final bottom = nav.evaluate().isEmpty || sheet
      ? screen
      : tester.getRect(nav).top;
  expect(
    r.top >= 0 && r.bottom <= bottom + .5,
    isTrue,
    reason:
        'บท ${progress.chapter}: "$what" อยู่นอกจอ $r (พื้นที่ 0..$bottom) ต้องเลื่อนหา',
  );
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
  // เปิดบทใหม่ → ลุงทองเล่าก่อน
  await hearUncle(tester);
}

/// เนื้อเรื่องไม่มีเมนูล่าง: ลุงทองพาไปหน้า [name] เอง — ตรวจว่าไม่มีเมนูให้กด
Future<void> openTab(WidgetTester tester, String name) async {
  expect(find.byType(GameNavBar), findsNothing, reason: 'ไปหน้า$name');
  await settle(tester);
}

Future<void> pressIn(
  WidgetTester tester,
  String gate,
  String label, {
  String? confirm,
}) async {
  final g = lit(gate);
  expectNoScroll(tester, g, gate);
  await tester.tap(find.descendant(of: g, matching: find.text(label)).first);
  await settle(tester);
  if (confirm != null) {
    await tester.tap(find.widgetWithText(PixelButton, confirm).last);
    await settle(tester);
  }
}

/// ปุ่มในถาดเปิดแผ่นรายละเอียด: ถ้ายังไม่เห็นปุ่มที่กะพริบ ให้กดปุ่มเปิดแผ่น [opener]
Future<void> openSheetFor(
  WidgetTester tester,
  String gate,
  String opener,
) async {
  if (lit(gate).evaluate().isNotEmpty) return;
  await tester.tap(find.byKey(ValueKey(opener)));
  await settle(tester);
}

/// ทำสิ่งที่เนื้อเรื่องชี้ 1 อย่างผ่าน UI (ตรวจว่าเห็นปุ่มโดยไม่ต้องเลื่อน)
Future<void> step(WidgetTester tester) async {
  final t = nextTarget;
  // แผ่นรายละเอียดจากขั้นก่อนยังเปิดอยู่ → ปิดกลับไปที่ฉากก่อน
  final close = find.byKey(const ValueKey('sheet-close'));
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.last);
    await settle(tester);
  }
  switch (t) {
    case StoryTarget.next:
      final b = find.byKey(const ValueKey('story-next'));
      expectNoScroll(tester, b, 'บทถัดไป');
      await tester.tap(b);
      await settle(tester);
    case StoryTarget.buyFish:
      await openTab(tester, 'ปลา');
      if (lit('buyFish').evaluate().isEmpty) {
        await tester.tap(find.text('ร้านปลา').first);
        await settle(tester);
      }
      expectNoScroll(tester, lit('buyFish'), 'การ์ดปลานิล');
      await tester.tap(lit('buyFish'));
      await settle(tester);
      final buy = lit('buyFish');
      expect(buy, findsOneWidget);
      await tester.tap(
        find.descendant(of: buy, matching: find.text('ซื้อปลา')),
      );
      await settle(tester);
      await tester.tap(find.widgetWithText(PixelButton, 'ตกลง').last);
      await settle(tester);
    case StoryTarget.feed || StoryTarget.catchFish:
      await openTab(tester, 'ปลา');
      if (find.byKey(const ValueKey('pond-water')).evaluate().isEmpty) {
        await tester.tap(find.widgetWithText(PixelButton, 'บ่อปลา'));
        await settle(tester);
      }
      if (t == StoryTarget.feed) {
        await pressIn(tester, 'feed', 'พอดี');
      } else {
        await pressIn(tester, 'catchFish', 'จับปลา');
      }
    case StoryTarget.endDay:
      await pressIn(tester, 'endDay', 'จบวัน');
      if (find.text('ดูรายงานทันที').evaluate().isNotEmpty) {
        await tester.tap(find.text('ดูรายงานทันที'));
        await settle(tester);
      }
      // หน้ารายงาน (วันเกิดภัยยาว) — ปุ่มอยู่ท้ายรายงาน
      await tester.scrollUntilVisible(
        find.text('เริ่มวันใหม่'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('เริ่มวันใหม่'));
      await settle(tester);
      await tester.tap(find.text('เริ่มวันใหม่'));
      await settle(tester);
    case StoryTarget.sellFish:
      await openTab(tester, 'ตลาด');
      await openSheetFor(tester, 'sellFish', 'market-sell');
      expectNoScroll(tester, lit('sellFish'), 'ขายปลา');
      await tester.tap(lit('sellFish'));
      await settle(tester);
      await tester.tap(find.widgetWithText(PixelButton, 'ตกลง').last);
      await settle(tester);
    case StoryTarget.buyIngredient:
      await openTab(tester, 'ตลาด');
      await openSheetFor(tester, 'buyIngredient', 'market-buy');
      expectNoScroll(tester, lit('buyIngredient'), 'ซื้อเครื่องปรุง');
      await tester.tap(lit('buyIngredient'));
      await settle(tester);
      await tester.tap(find.widgetWithText(PixelButton, 'ตกลง').last);
      await settle(tester);
    case StoryTarget.buyTool:
      await openTab(tester, 'ตลาด');
      await openSheetFor(tester, 'buyTool', 'market-tools');
      await pressIn(tester, 'buyTool', 'ซื้อ', confirm: 'ตกลง');
    case StoryTarget.cook:
      await openTab(tester, 'ครัว');
      await openSheetFor(tester, 'cook', 'kitchen-cook');
      await pressIn(tester, 'cook', 'ทำอาหาร');
    case StoryTarget.preserve:
      await openTab(tester, 'ครัว');
      await openSheetFor(tester, 'preserve', 'kitchen-preserve');
      await pressIn(tester, 'preserve', 'เริ่มถนอม');
    case StoryTarget.buyEquipment:
      await openTab(tester, 'ฟาร์ม');
      // อุปกรณ์อยู่ในแผ่น "ป้องกัน" (ปุ่มกลมในถาดกะพริบชี้)
      if (lit('buyEquipment').evaluate().isEmpty) {
        await tester.tap(find.byKey(const ValueKey('farm-prepare')));
        await settle(tester);
      }
      await pressIn(tester, 'buyEquipment', 'ซื้อ', confirm: 'ตกลง');
      // ซื้อแล้วปิดแผ่นกลับไปที่ฉาก
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await settle(tester);
    case StoryTarget.eat:
      await openTab(tester, 'คลัง');
      await openSheetFor(tester, 'eat', 'storage-food');
      await pressIn(tester, 'eat', 'กิน', confirm: 'กิน');
    default:
      fail('บท ${progress.chapter}: ไม่มีสิ่งที่ต้องทำต่อ ($t)');
  }
}

void main() {
  testWidgets(
    'เล่นเนื้อเรื่องบท 1-7 ผ่าน UI: ทุกขั้นเห็นปุ่มที่ต้องกดโดยไม่ต้องเลื่อนจอ',
    (tester) async {
      await pumpStory(tester);
      final chapters = <int>{};
      var guard = 0;
      while (find.byType(StorySummaryScreen).evaluate().isEmpty) {
        expect(guard++ < 150, isTrue, reason: 'เนื้อเรื่องไม่จบใน 150 ขั้น');
        expect(progress.failed, isFalse, reason: progress.failReason);
        chapters.add(progress.chapter);
        // แถบเป้าหมายอยู่บนจอทุกขั้น
        expect(find.byKey(const ValueKey('story-goal')), findsOneWidget);
        await step(tester);
      }
      expect(chapters, {1, 2, 3, 4, 5, 6});
      expect(find.byKey(const ValueKey('story-grade')), findsOneWidget);
      expect(find.byKey(const ValueKey('story-ending')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('story-finish')));
      await settle(tester);
      // กลับเมนูหลัก และโหมดเอาชีวิตรอดปลดล็อกแล้ว
      expect(find.text('20 / 30 / 60 วัน'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kSurvivalUnlockKey), '1');
    },
  );
}
