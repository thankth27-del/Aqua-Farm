import 'package:aqua_farm/data/fish_data.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/scenes/fish_swim.dart';
import 'package:aqua_farm/ui/scenes/pixel_scene.dart';
import 'package:aqua_farm/ui/theme/fish_sprite.dart';
import 'package:aqua_farm/ui/theme/pixel_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _K {
  _K(this.i);
  final int i;
}

Future<void> _pump(WidgetTester tester, Widget child, {double dpr = 1}) async {
  tester.view
    ..physicalSize = Size(390 * dpr, 844 * dpr)
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sceneAnimationProvider.overrideWithValue(false)],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  test('ปลาทุกชนิดมีไฟล์แถบเฟรม', () {
    for (final id in kFish.keys) {
      expect(fishStripAsset(id), 'assets/fish/${id}_strip.png');
    }
  });

  test('เฟรมวนครบ 8 เฟรม และเริ่มต่างกันได้', () {
    expect(
      [for (var t = 0; t < 9; t++) fishFrameAt(t, 0)],
      [
        0, 1, 2, 3, 4, 5, 6, 7, 0, //
      ],
    );
    expect(fishFrameAt(0, 3), 3);
    expect(fishFrameAt(6, 3), 1);
  });

  test('ปลาในบ่อเริ่มเฟรมต่างกัน (ไม่ขยับพร้อมกัน)', () {
    final p = PondSwim()
      ..sync([
        for (var i = 0; i < 8; i++)
          SwimFish(key: _K(i), type: 'nila', growth: 50),
      ], fed: false);
    final starts = {for (final s in p.swimmers) s.frameStart};
    expect(starts.length, greaterThan(1));
    expect(starts.every((f) => f >= 0 && f < kFishFrames), isTrue);
  });

  testWidgets('ตัดเฟรมจากแถบ ไม่เบลอ และถอดรหัสพอดีพิกเซลจริงเมื่อเล็ก', (
    tester,
  ) async {
    await _pump(
      tester,
      const Center(child: FishSprite('tap', size: FishSize.small, frame: 3)),
      dpr: 1,
    );
    final box = tester.getSize(find.byType(FishSprite));
    expect(box, const Size(64, 64));
    final img = tester.widget<Image>(find.byType(Image));
    expect(img.filterQuality, FilterQuality.none);
    expect(img.width, 64 * kFishFrames);
    expect(img.image, isA<ResizeImage>());
    final r = img.image as ResizeImage;
    expect(r.width, 64 * kFishFrames);
    expect(r.height, 64);
    // เฟรมที่ 3 → เลื่อนแถบไปทางซ้าย 3 ช่อง
    final shift = tester.widget<Transform>(
      find
          .ancestor(of: find.byType(Image), matching: find.byType(Transform))
          .first,
    );
    expect(shift.transform.getTranslation().x, -3 * 64);
  });

  testWidgets('ขนาดใหญ่ขยายเป็นจำนวนเต็มเท่าของ 128 พิกเซลจริง', (
    tester,
  ) async {
    await _pump(
      tester,
      const Center(child: FishSprite('nila', size: FishSize.large, frame: 0)),
      dpr: 2,
    );
    final img = tester.widget<Image>(find.byType(Image));
    expect(img.image, isA<AssetImage>());
    // 256 logical × dpr 2 = 512 พิกเซลจริง = 4 เท่าของ 128
    expect(img.height! * 2 % kFishFramePx, 0);
    expect(img.height, 256);
  });

  testWidgets('ไอคอนปลา (f_<id>) ใช้ปลาชุดใหม่ ไอคอนเล็กเป็นภาพนิ่ง', (
    tester,
  ) async {
    await _pump(tester, const Center(child: PixelIcon('f_carp', size: 30)));
    final s = tester.widget<FishSprite>(find.byType(FishSprite));
    expect(s.type, 'carp');
    expect(s.animate, isFalse);
    expect(FishClock.running, isFalse);
  });

  testWidgets('บ่อ: ปลาทุกตัววาดด้วย FishSprite และหันหัวตามทิศที่ว่าย', (
    tester,
  ) async {
    final swim = PondSwim();
    final data = PondSceneData(
      fish: [
        for (var i = 0; i < 5; i++)
          SwimFish(key: _K(i), type: kFish.keys.elementAt(i), growth: 40),
      ],
      water: 90,
      o2: 60,
      fed: false,
    );
    await _pump(
      tester,
      PixelScene(painterBuilder: (t) => PondPainter(t, data, swim)),
    );
    final sprites = tester
        .widgetList<FishSprite>(find.byType(FishSprite))
        .toList();
    expect(sprites, hasLength(5));
    for (var i = 0; i < 5; i++) {
      expect(sprites[i].type, swim.swimmers[i].fish.type);
      expect(sprites[i].flipX, swim.swimmers[i].faceLeft);
    }
    // ทุกตัวอยู่ในกรอบฉาก
    final scene = tester.getRect(find.byType(SceneFishLayer));
    for (final e in find.byType(FishSprite).evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(scene.inflate(1).contains(r.center), isTrue);
    }
  });
}
