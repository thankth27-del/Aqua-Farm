import 'dart:math';

import 'package:aqua_farm/data/disaster_data.dart';
import 'package:aqua_farm/game/game_engine.dart';

/// Random ที่คืนค่าคงที่ เพื่อให้ผลทดสอบแน่นอน
class FixedRandom implements Random {
  FixedRandom([this.value = .5]);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// ภัยแรกเป็นน้ำท่วมตามต้นแบบ (เกมจริงสุ่มภัยแรก)
GameEngine newEngine() => GameEngine.newGame(
  'ทดสอบ',
  random: FixedRandom(),
  firstDisaster: DisasterType.flood,
);

/// ให้ผู้เล่นอิ่มตลอด เพื่อทดสอบระบบอื่นโดยไม่ตายเพราะหิว
void keepFed(GameEngine e) => e.state.hunger = 100;
