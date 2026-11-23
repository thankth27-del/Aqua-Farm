/// โหมดความยาก เป้าหมายรอดครบวัน และความยากที่เพิ่มตามความคืบหน้า
///
/// ตัวเลขทั้งหมดของระบบนี้อยู่ที่ไฟล์นี้ที่เดียว
/// - โหมด: ความหนักพื้นฐาน (ตัวคูณชุดเดียวต่อโหมด) และจำนวนวันที่ต้องรอด
/// - ขั้นความยาก: แบ่งเกมเป็น [kDifficultyStages] ขั้นตามความคืบหน้า (วันปัจจุบัน ÷ วันเป้าหมาย)
///   ขึ้นเป็นขั้น ไม่ต่อเนื่อง ผู้เล่นจะรู้สึกได้และวางแผนทัน
/// - ปานกลาง ขั้นแรก = ตัวคูณ 1 ทุกตัว (เท่าต้นแบบเป๊ะ)
library;

import 'dart:math' as math;

enum Difficulty { easy, normal, hard }

/// ความหนักพื้นฐานของโหมด (คูณกับตัวคูณของขั้น)
class DifficultySpec {
  const DifficultySpec({
    required this.name,
    required this.targetDays,
    required this.buy,
    required this.sell,
    required this.severity,
    required this.water,
  });

  final String name;

  /// รอดครบกี่วันจึงชนะ
  final int targetDays;

  /// ราคาซื้อ: วัตถุดิบ อุปกรณ์ อาหารปลา
  final double buy;

  /// ราคาขาย: ปลา อาหาร
  final double sell;

  /// ความรุนแรงของภัย
  final double severity;

  /// น้ำเสียเร็วขึ้น (ของเสียที่เกิดต่อวัน)
  final double water;
}

const Map<Difficulty, DifficultySpec> kDifficulties = {
  Difficulty.easy: DifficultySpec(
    name: 'ง่าย',
    targetDays: 15,
    buy: .9,
    sell: 1.1,
    severity: .8,
    water: .85,
  ),
  // ปานกลาง = ต้นแบบ
  Difficulty.normal: DifficultySpec(
    name: 'ปานกลาง',
    targetDays: 30,
    buy: 1,
    sell: 1,
    severity: 1,
    water: 1,
  ),
  Difficulty.hard: DifficultySpec(
    name: 'ยาก',
    targetDays: 60,
    buy: 1.15,
    sell: .9,
    severity: 1.25,
    water: 1.15,
  ),
};

/// จำนวนขั้นความยากต่อเกม
const int kDifficultyStages = 6;

/// ตัวคูณต่อขั้น (ขั้น 0 ถึง 5) — ขั้น 0 ต้องเป็น 1 / 0 ทั้งหมด
/// ราคาซื้อขึ้นเรื่อย ๆ
const List<double> kStageBuy = [1, 1.1, 1.2, 1.3, 1.4, 1.5];

/// ราคาขายขึ้นตาม แต่ช้ากว่าราคาซื้อ
const List<double> kStageSell = [1, 1.05, 1.1, 1.15, 1.2, 1.25];

/// ความรุนแรงของภัย
const List<double> kStageSeverity = [1, 1, 1, 1.2, 1.4, 1.6];

/// ภัยนานขึ้นกี่วัน (ยืดช่วงที่รุนแรงที่สุด)
const List<int> kStageExtraDays = [0, 0, 0, 1, 1, 2];

/// ข่าวเตือนล่วงหน้าลดลงกี่วัน (เหลืออย่างน้อย [kMinWarnDays])
const List<int> kStageWarnCut = [0, 0, 1, 1, 2, 2];
const int kMinWarnDays = 1;

/// น้ำเสียเร็วขึ้น
const List<double> kStageWater = [1, 1, 1.1, 1.2, 1.3, 1.4];

/// เกรดรวมตอนชนะ: เฉลี่ยคะแนนเกรดรายวัน (S=3 A=2 B=1)
const Map<String, int> kGradePoints = {'S': 3, 'A': 2, 'B': 1};
const double kOverallS = 2.5;
const double kOverallA = 1.75;

/// ขั้นความยาก 0..5 จากความคืบหน้า = วันปัจจุบัน ÷ วันเป้าหมาย
int difficultyStage(int day, int targetDays) => math.min(
  kDifficultyStages - 1,
  math.max(0, day) * kDifficultyStages ~/ targetDays,
);

Difficulty difficultyFromName(String? name) => Difficulty.values.firstWhere(
  (d) => d.name == name,
  orElse: () => Difficulty.normal,
);
