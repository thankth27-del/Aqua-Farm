import 'package:aqua_farm/ui/design/design_system.dart';
import 'package:aqua_farm/ui/screens/design_preview_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: DesignPreviewScreen()));
  await tester.pumpAndSettle();
}

void main() {
  group('ระบบดีไซน์', () {
    for (final size in const [
      Size(360, 740),
      Size(390, 844),
      Size(1366, 768),
    ]) {
      testWidgets('หน้าตัวอย่างไม่ล้นจอที่ ${size.width.toInt()}', (
        tester,
      ) async {
        await _pump(tester, size);
        expect(find.text('ตัวอย่างระบบดีไซน์'), findsOneWidget);
        // เลื่อนจนสุดเพื่อให้ทุกส่วนถูกวาด
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('ds-open-sheet')),
          300,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ปุ่มกดได้สูงอย่างน้อย 48 และใช้ฟอนต์ Sarabun', (tester) async {
      await _pump(tester, const Size(390, 844));
      final btn = find.byKey(const ValueKey('ds-primary'));
      // รายการวาดแบบ lazy: เลื่อนให้ปุ่มเข้ามาในจอก่อน
      await tester.scrollUntilVisible(btn, 300);
      expect(tester.getSize(btn).height, greaterThanOrEqualTo(kDsMinTap));
      final title = tester.widget<Text>(find.text('ขายปลา'));
      expect(title.style?.fontFamily, DsText.font);
    });

    testWidgets('หน้าต่างยืนยันคืนค่า true/false', (tester) async {
      await _pump(tester, const Size(390, 844));
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildDesignTheme(),
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      var f = showGameDialog(ctx, title: 'ขาย?', confirmLabel: 'ขาย');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ขาย'));
      await tester.pumpAndSettle();
      expect(await f, isTrue);

      f = showGameDialog(ctx, title: 'ขาย?', confirmLabel: 'ขาย');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(await f, isFalse);
    });

    testWidgets('แผ่นล่างเปิดและปิดได้', (tester) async {
      await _pump(tester, const Size(390, 844));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('ds-open-sheet')),
        300,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('ds-open-sheet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ds-open-sheet')));
      await tester.pumpAndSettle();
      expect(find.text('เมนู / พัก'), findsOneWidget);
      await tester.tap(find.text('เล่นต่อ'));
      await tester.pumpAndSettle();
      expect(find.text('เมนู / พัก'), findsNothing);
    });
  });
}
