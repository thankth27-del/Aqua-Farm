import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Finder _k(String key) => find.byKey(ValueKey(key));

/// ฟังลุงทองจนเงียบ: แตะไปต่อ · การ์ดความรู้กดเก็บลงสมุด
/// · ตัวเลือก: เลือกข้อ [pick] ฟังลุงตอบ แล้วกด "ตกลง" ที่หน้ายืนยันของผลตัวเลือก
///   ([pick] = null → หยุดรอให้เทสต์เลือกเอง)
/// · คำถามบท 4: ตอบผิดแล้วลุงถามข้อเดิม → ลองตัวเลือกถัดไปจนถูก
Future<void> hearUncle(WidgetTester tester, {int? pick = 0}) async {
  final tries = <String, int>{};
  for (var i = 0; i < 160; i++) {
    if (_k('uncle-option-0').evaluate().isNotEmpty) {
      if (pick == null) return;
      final key = _talkKey();
      final n = tries[key] = (tries[key] ?? -1) + 1;
      final count = find
          .byWidgetPredicate((w) => '${w.key}'.contains("'uncle-option-"))
          .evaluate()
          .length;
      await tester.tap(_k('uncle-option-${(pick + n) % count}'));
      await tester.pumpAndSettle();
      // ลุงตอบ → หน้ายืนยัน (ถ้าตัวเลือกนั้นมีผลซื้อ/ขาย)
      for (var j = 0; j < 10 && _k('talk-reply').evaluate().isNotEmpty; j++) {
        await tester.tap(_k('uncle-talk').last);
        await tester.pumpAndSettle();
      }
      if (find.text('ยกเลิก').evaluate().isNotEmpty) {
        await tester.tap(find.text('ตกลง').last);
      }
    } else if (_k('card-keep').evaluate().isNotEmpty) {
      await tester.tap(_k('card-keep'));
    } else if (_k('uncle-talk').evaluate().isNotEmpty) {
      await tester.tap(_k('uncle-talk').last, warnIfMissed: false);
    } else {
      return;
    }
    await tester.pump();
    await tester.pumpAndSettle();
  }
  final text = find.byKey(const ValueKey('uncle-text'));
  final keys = find
      .byWidgetPredicate((w) => '${w.key}'.contains('talk-'))
      .evaluate()
      .map((e) => '${e.widget.key}')
      .join(', ');
  fail(
    'ลุงทองพูดไม่จบ: ${text.evaluate().isEmpty ? '-' : tester.widget<Text>(text.first).data} [$keys]',
  );
}

/// key ของกล่องบทสนทนาที่แสดงอยู่ (talk-...)
String _talkKey() => find
    .byWidgetPredicate((w) => '${w.key}'.contains("'talk-"))
    .evaluate()
    .map((e) => '${e.widget.key}')
    .join();
