import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/screens/game_shell.dart';
import 'package:aqua_farm/ui/theme/theme.dart';
import 'package:aqua_farm/ui/widgets/game_hud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'ui_test.dart' as u;

/// สัดส่วนจอที่ยังเห็นฉาก (ไม่ถูกแผง/ปุ่ม/เมนูทับ) — วัดเป็นตาราง 4px
double visibleScene(WidgetTester tester, Size screen) {
  final rects = <Rect>[
    for (final f in [
      find.byType(GlassPanel),
      find.byType(SpeechBubble),
      find.byType(RoundAction),
      find.byType(PixelButton),
      find.byKey(const ValueKey('end-day')),
      find.byType(GameNavBar),
    ])
      for (final e in f.evaluate())
        tester.getRect(find.byElementPredicate((x) => x == e)),
  ];
  var free = 0, all = 0;
  for (var y = 2.0; y < screen.height; y += 4) {
    for (var x = 2.0; x < screen.width; x += 4) {
      all++;
      final p = Offset(x, y);
      if (!rects.any((r) => r.contains(p))) free++;
    }
  }
  return free / all;
}

void main() {
  for (final page in const ['ฟาร์ม', 'บ่อ', 'ตลาด', 'ครัว', 'คลัง']) {
    for (final size in const [
      Size(390, 844),
      Size(844, 390),
      Size(1366, 768),
    ]) {
      final name = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('หน้า$page $name: เห็นฉากอย่างน้อย 55% ของจอ', (
        tester,
      ) async {
        await u.pumpApp(tester);
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        await u.startNewGame(tester);
        if (page != 'ฟาร์ม') {
          u.container
              .read(gameProvider.notifier)
              .update((e) => e.buyFish('nila', 2));
          await tester.tap(
            find.descendant(
              of: find.byType(GameNavBar),
              matching: find.text(page == 'บ่อ' ? 'ปลา' : page),
            ),
          );
          await tester.pumpAndSettle();
        }
        final v = visibleScene(tester, size);
        // ignore: avoid_print
        print('SCENE $page $name: ${(v * 100).toStringAsFixed(1)}%');
        expect(v, greaterThanOrEqualTo(.55));
      });
    }
  }
}
