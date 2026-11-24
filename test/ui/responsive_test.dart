import 'package:aqua_farm/ui/layout/responsive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Responsive at(double w, double h) => Responsive.fromSize(Size(w, h));

Widget host(Size size, Widget child, {double dpr = 1}) => MediaQuery(
  data: MediaQueryData(size: size, devicePixelRatio: dpr),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  group('ประเภทจอ', () {
    test('แบ่งตามความกว้าง 600 / 1000', () {
      expect(classifyWidth(360), ScreenClass.compact);
      expect(classifyWidth(599), ScreenClass.compact);
      expect(classifyWidth(600), ScreenClass.medium);
      expect(classifyWidth(1000), ScreenClass.medium);
      expect(classifyWidth(1001), ScreenClass.expanded);
    });

    test('ทุกขนาดที่ตรวจได้ประเภทและเมนูถูกต้อง', () {
      final cases = {
        (360.0, 740.0): (ScreenClass.compact, false),
        (390.0, 844.0): (ScreenClass.compact, false),
        (430.0, 932.0): (ScreenClass.compact, false),
        (844.0, 390.0): (ScreenClass.medium, true),
        (932.0, 430.0): (ScreenClass.medium, true),
        (768.0, 1024.0): (ScreenClass.medium, true),
        (1024.0, 768.0): (ScreenClass.expanded, true),
        (1180.0, 820.0): (ScreenClass.expanded, true),
        (1366.0, 768.0): (ScreenClass.expanded, true),
        (1920.0, 1080.0): (ScreenClass.expanded, true),
        (2560.0, 1440.0): (ScreenClass.expanded, true),
      };
      cases.forEach((s, want) {
        final r = at(s.$1, s.$2);
        expect(r.screen, want.$1, reason: '$s');
        expect(r.useSideNav, want.$2, reason: '$s');
      });
    });

    test('โทรศัพท์แนวนอนแบ่งซ้าย-ขวา แต่แท็บเล็ตแนวตั้งไม่แบ่ง', () {
      expect(at(844, 390).isLandscapePhone, isTrue);
      expect(at(844, 390).useSplit, isTrue);
      expect(at(932, 430).useSplit, isTrue);
      expect(at(1024, 768).isLandscapePhone, isFalse);
      expect(at(768, 1024).useSplit, isFalse);
      expect(at(390, 844).useSplit, isFalse);
    });
  });

  group('ตัวคูณขนาด', () {
    test('ฟอนต์ไม่ต่ำกว่าขั้นต่ำที่ 360x740 และปุ่มไม่ต่ำกว่า 48', () {
      final r = at(360, 740);
      expect(r.font(10), Responsive.minFont);
      expect(r.font(17), greaterThanOrEqualTo(15.5));
      expect(r.tap(30), 48);
    });

    test('จอใหญ่ขยายขึ้นตามลำดับ ไม่ตัวจิ๋วบน 2560', () {
      final phone = at(390, 844).scale;
      final tablet = at(768, 1024).scale;
      final desk = at(1366, 768).scale;
      final big = at(2560, 1440).scale;
      expect(phone, 1.0);
      expect(tablet, greaterThan(phone));
      expect(desk, greaterThanOrEqualTo(phone));
      expect(at(1920, 1080).scale, greaterThan(desk));
      expect(big, greaterThan(desk));
      expect(big, lessThanOrEqualTo(1.6));
    });

    test('โทรศัพท์แนวนอนไม่ขยาย (จอเตี้ย)', () {
      expect(at(844, 390).scale, 1.0);
    });

    test('ความกว้างเนื้อหาจำกัดที่ 1100', () {
      expect(at(390, 844).contentWidth, 390);
      expect(at(1920, 1080).contentWidth, Breakpoints.maxContent);
    });
  });

  group('ฉากพิกเซลจำนวนเต็มเท่า', () {
    const art = Size(320, 180);

    test('พิกเซลจริงเป็นจำนวนเต็มเท่าของภาพ และคง 16:9', () {
      for (final (w, h, dpr) in [
        (366.0, 400.0, 3.0),
        (342.0, 400.0, 2.0),
        (1000.0, 700.0, 1.0),
        (700.0, 300.0, 2.625),
      ]) {
        final s = integerSceneSize(Size(w, h), dpr, art);
        final k = s.width * dpr / art.width;
        expect(k, closeTo(k.roundToDouble(), 1e-9), reason: '$w $dpr');
        expect(s.width / s.height, closeTo(16 / 9, 1e-9));
        expect(s.width, lessThanOrEqualTo(w));
        expect(s.height, lessThanOrEqualTo(h));
      }
    });

    test('เลือกเท่าที่ใหญ่สุดที่ใส่ได้', () {
      // 366 x dpr 3 = 1098 พิกเซลจริง → 3 เท่า (960) = 320 logical
      expect(integerSceneSize(const Size(366, 400), 3, art).width, 320);
      // 1000 logical dpr 1 → 3 เท่า = 960
      expect(integerSceneSize(const Size(1000, 700), 1, art).width, 960);
    });

    test('พื้นที่เล็กกว่าภาพ: ย่อตามสัดส่วน', () {
      final s = integerSceneSize(const Size(160, 400), 1, art);
      expect(s, const Size(160, 90));
    });

    testWidgets('PixelStage วางฉากกลางและเติมพื้นหลังรอบ ๆ', (tester) async {
      await tester.pumpWidget(
        host(
          const Size(400, 800),
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 366,
              child: PixelStage(
                fill: ColoredBox(key: Key('fill'), color: Color(0xFF00FF00)),
                child: ColoredBox(key: Key('scene'), color: Color(0xFFFF0000)),
              ),
            ),
          ),
          dpr: 3,
        ),
      );
      final scene = tester.getSize(find.byKey(const Key('scene')));
      expect(scene, const Size(320, 180));
      expect(tester.getSize(find.byKey(const Key('fill'))).width, 366);
    });
  });

  group('โครงหน้า', () {
    Widget shell(Size size) => host(
      size,
      const AdaptiveShell(
        top: SizedBox(height: 40, key: Key('top')),
        body: SizedBox.expand(key: Key('body')),
        bottomNav: SizedBox(height: 60, key: Key('bottom')),
        sideNav: SizedBox(width: 90, key: Key('side')),
      ),
    );

    testWidgets('compact ใช้เมนูล่าง', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(shell(const Size(390, 844)));
      expect(find.byKey(const Key('bottom')), findsOneWidget);
      expect(find.byKey(const Key('side')), findsNothing);
    });

    testWidgets('medium/expanded ใช้เมนูข้าง', (tester) async {
      for (final s in const [Size(768, 1024), Size(1366, 768)]) {
        tester.view.physicalSize = s;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(shell(s));
        expect(find.byKey(const Key('side')), findsOneWidget);
        expect(find.byKey(const Key('bottom')), findsNothing);
      }
      tester.view.reset();
    });

    testWidgets('AppFrame จำกัดความกว้างเนื้อหาที่ 1100 จัดกลาง', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const Size(1920, 1080),
          const AppFrame(
            background: ColoredBox(color: Color(0xFF000000)),
            child: SizedBox.expand(key: Key('content')),
          ),
        ),
      );
      final r = tester.getRect(find.byKey(const Key('content')));
      expect(r.width, Breakpoints.maxContent);
      expect(r.center.dx, 960);
    });

    testWidgets('SplitLayout: แนวนอนวางซ้าย-ขวา แนวตั้งเรียงลง', (
      tester,
    ) async {
      Future<(Rect, Rect)> rects(Size s) async {
        tester.view.physicalSize = s;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          host(
            s,
            const SplitLayout(
              scene: SizedBox(height: 100, key: Key('scene')),
              controls: SizedBox(height: 100, key: Key('ctl')),
            ),
          ),
        );
        return (
          tester.getRect(find.byKey(const Key('scene'))),
          tester.getRect(find.byKey(const Key('ctl'))),
        );
      }

      final (s1, c1) = await rects(const Size(844, 390));
      expect(c1.left, greaterThan(s1.right - 1));
      final (s2, c2) = await rects(const Size(390, 844));
      expect(c2.top, greaterThanOrEqualTo(s2.bottom));
      tester.view.reset();
    });
  });

  group('ตัวคูณกลาง (ScaledApp)', () {
    testWidgets(
      'จอ 1920x1080: เนื้อหาเต็มกรอบ 1100 และวางในพื้นที่ logical ที่หารตัวคูณแล้ว',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Size? inner;
        Responsive? r;
        await tester.pumpWidget(
          host(
            const Size(1920, 1080),
            AppFrame(
              background: const SizedBox.expand(),
              child: ScaledApp(
                child: Builder(
                  builder: (c) {
                    inner = MediaQuery.sizeOf(c);
                    r = c.rs;
                    return const SizedBox.expand(key: Key('content'));
                  },
                ),
              ),
            ),
          ),
        );
        final s = Responsive.fromSize(const Size(1920, 1080)).scale;
        expect(s, greaterThan(1.3));
        final rect = tester.getRect(find.byKey(const Key('content')));
        expect(rect.width, closeTo(Breakpoints.maxContent, .5));
        expect(rect.height, closeTo(1080, .5));
        expect(inner!.width, closeTo(Breakpoints.maxContent / s, .01));
        expect(r!.applied, isTrue);
        expect(r!.isExpanded, isTrue);
        // ฟังก์ชันขนาดไม่คูณซ้ำเมื่อขยายที่รากแล้ว
        expect(r!.font(20), 20);
      },
    );

    testWidgets('มือถือ: ไม่ขยาย และตัวอักษรต่ำสุด 13', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late double scaled;
      await tester.pumpWidget(
        host(
          const Size(360, 740),
          ScaledApp(
            child: Builder(
              builder: (c) {
                scaled = MediaQuery.textScalerOf(c).scale(10);
                return const SizedBox.expand(key: Key('content'));
              },
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('content'))),
        const Size(360, 740),
      );
      expect(scaled, Responsive.minFont);
    });
  });
}
