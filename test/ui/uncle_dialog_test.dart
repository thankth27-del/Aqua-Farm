import 'package:aqua_farm/data/story_script.dart';
import 'package:aqua_farm/ui/widgets/uncle_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _lines = [
  ScriptLine(UncleMood.smile, 'สวัสดีหลาน'),
  ScriptLine(UncleMood.worry, 'น้ำกำลังมา'),
];

Future<void> _pump(WidgetTester tester, UncleTalk talk) async {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: UncleTalkLayer(talk: talk)),
    ),
  );
}

String _text(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('uncle-text'))).data!;

void main() {
  testWidgets(
    'พิมพ์ทีละตัว · แตะข้ามการพิมพ์ · แตะไปต่อ · จบแล้วเรียก onDone',
    (tester) async {
      var done = 0;
      final seen = <String>[];
      await _pump(
        tester,
        UncleTalk(
          lines: _lines,
          onDone: () => done++,
          onLine: (l) => seen.add(l.text),
        ),
      );
      await tester.pump(const Duration(milliseconds: kUncleTypeMs * 3 + 5));
      // กำลังพิมพ์: ยังแสดงไม่ครบ
      expect(_text(tester).length, lessThan('สวัสดีหลาน'.length));
      expect(find.byKey(const ValueKey('uncle-smile')), findsOneWidget);
      expect(find.text(Uncle.name), findsOneWidget);

      // แตะระหว่างพิมพ์ = แสดงทั้งบรรทัด (ยังไม่ไปบรรทัดถัดไป)
      await tester.tap(find.byKey(const ValueKey('uncle-talk')));
      await tester.pump();
      expect(_text(tester), 'สวัสดีหลาน');
      expect(find.text('1/2'), findsOneWidget);

      // แตะอีกครั้ง = บรรทัดถัดไป อารมณ์เปลี่ยน
      await tester.tap(find.byKey(const ValueKey('uncle-talk')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_text(tester), 'น้ำกำลังมา');
      expect(find.byKey(const ValueKey('uncle-worry')), findsOneWidget);
      expect(seen, ['สวัสดีหลาน', 'น้ำกำลังมา']);
      expect(done, 0);

      await tester.tap(find.byKey(const ValueKey('uncle-talk')));
      await tester.pump();
      expect(done, 1);
    },
  );

  testWidgets('ตัวเลือก: แสดงหลังบรรทัดสุดท้าย ปุ่มสูง ≥48 แตะแล้วส่งเลขข้อ', (
    tester,
  ) async {
    int? picked;
    await _pump(
      tester,
      UncleTalk(
        lines: const [ScriptLine(UncleMood.think, 'เลือกปลาตัวไหนดี?')],
        options: const [
          UncleOption('ปลานิล', detail: 'ทนทาน'),
          UncleOption('ปลาดุก'),
        ],
        onOption: (i) => picked = i,
      ),
    );
    expect(find.byKey(const ValueKey('uncle-option-0')), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ทนทาน'), findsOneWidget);
    for (final i in [0, 1]) {
      final r = tester.getRect(find.byKey(ValueKey('uncle-option-$i')));
      expect(r.height, greaterThanOrEqualTo(48));
      expect(r.bottom, lessThanOrEqualTo(844));
    }
    await tester.tap(find.byKey(const ValueKey('uncle-option-1')));
    expect(picked, 1);
  });

  testWidgets('รูปลุงเป็นภาพพิกเซลไม่เบลอ', (tester) async {
    await _pump(tester, const UncleTalk(lines: _lines));
    final img = tester.widget<Image>(find.byType(Image).first);
    expect(img.filterQuality, FilterQuality.none);
  });
}
