import 'package:aqua_farm/game/game_state.dart';
import 'package:aqua_farm/game/tutorial.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('บทเรียน 9 ขั้น', () {
    test('เกมใหม่เริ่มบทเรียนขั้นแรก', () {
      final e = newEngine();
      expect(kTutorial, hasLength(kTutorialSteps));
      expect(e.tutorialActive, isTrue);
      expect(e.state.tut, 0);
      expect(e.tutorialCanNext, isTrue);
    });

    test('ขั้นที่มีเงื่อนไข: กดถัดไปไม่ได้จนกว่าจะทำสำเร็จ', () {
      final e = newEngine()..state.tut = 2;
      expect(e.tutorialCanNext, isFalse);
      e.tutorialNext();
      expect(e.state.tut, 2);

      expect(e.tutorialCheck(GameScreen.farm), isFalse);
      expect(e.tutorialCheck(GameScreen.pond), isTrue);
      expect(e.state.tutOk, 2);
      // ทำสำเร็จแล้วค้างไว้ แม้ออกจากหน้าบ่อ
      expect(e.tutorialCheck(GameScreen.market), isFalse);
      expect(e.tutorialCanNext, isTrue);
      e.tutorialNext();
      expect(e.state.tut, 3);
      expect(e.tutorialCanNext, isFalse);
    });

    test('ขั้นซื้อปลาและให้อาหาร ใช้สถานะเกม', () {
      final e = newEngine()..state.tut = 3;
      expect(e.tutorialCheck(GameScreen.shop), isFalse);
      e.buyFish('nila', 1);
      expect(e.tutorialCheck(GameScreen.shop), isTrue);
      e.tutorialNext();
      expect(e.tutorialCheck(GameScreen.pond), isFalse);
      e.feed(2);
      expect(e.tutorialCheck(GameScreen.pond), isTrue);
    });

    test('เข้าขั้นทำอาหาร: แจกปลานิล 1 ตัวและเครื่องปรุง 1 ทำปลาทอดได้', () {
      final e = newEngine()..state.tut = 5;
      e.tutorialCheck(GameScreen.pond);
      final fish = e.state.fishStock['nila']!;
      final spice = e.state.inventory['spice']!;
      e.tutorialNext();
      expect(e.state.tut, 6);
      expect(e.state.fishStock['nila'], fish + 1);
      expect(e.state.inventory['spice'], spice + 1);
      expect(e.canCook('fry'), isTrue);

      // อาหารเริ่มต้น (ปลาแห้ง) ไม่นับ ต้องเป็นอาหารที่ทำในครัว
      expect(e.tutorialCheck(GameScreen.kitchen), isFalse);
      e.cook('fry');
      expect(e.tutorialCheck(GameScreen.kitchen), isTrue);
    });

    test('ย้อนกลับ ข้าม จบ และเล่นซ้ำ', () {
      final e = newEngine();
      e.tutorialBack();
      expect(e.state.tut, 0);
      e.tutorialNext();
      e.tutorialNext();
      expect(e.state.tut, 2);
      e.tutorialBack();
      expect(e.state.tut, 1);

      e.state.tut = 8;
      expect(e.tutorialCheck(GameScreen.farm), isTrue);
      e.tutorialNext();
      expect(e.state.tut, kTutorialSteps);
      expect(e.tutorialActive, isFalse);
      expect(e.tutorialStep, isNull);

      e.tutorialRestart();
      expect(e.state.tut, 0);
      e.tutorialSkip();
      expect(e.tutorialActive, isFalse);
    });

    test('สถานะบทเรียนถูกเซฟและโหลดกลับได้', () {
      final e = newEngine()..state.tut = 4;
      e.state.tutOk = 4;
      final s = GameState.fromJson(e.state.toJson());
      expect(s.tut, 4);
      expect(s.tutOk, 4);
    });
  });
}
