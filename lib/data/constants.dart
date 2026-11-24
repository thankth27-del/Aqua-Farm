/// ค่าคงที่หลักของเกม (ตรงกับต้นแบบ reference/index.html)
library;

/// จำนวนปลาสูงสุดในบ่อ (CAP)
const int kPondCapacity = 8;

/// ความอิ่มที่ลดลงต่อวัน และใช้คำนวณเสบียงกี่วัน (NEED)
const int kHungerPerDay = 20;

/// เวอร์ชันรูปแบบเซฟ (SAVE_V)
const int kSaveVersion = 4;

/// คีย์ที่เก็บเซฟทั้ง 3 ช่อง (SK)
const String kSaveKey = 'aquafarm_slots_v3';

/// คีย์ตั้งค่าเสียง (ต่อเครื่อง)
const String kSoundKey = 'aq_snd';

/// คีย์เซฟเนื้อเรื่อง (ความคืบหน้าบท + สถานะเกม)
const String kStoryKey = 'aquafarm_story_v1';

/// คีย์บอกว่าเล่นเนื้อเรื่องจบแล้ว (ปลดล็อกโหมดเอาชีวิตรอด)
const String kSurvivalUnlockKey = 'aquafarm_survival_unlocked';

/// คีย์เก็บว่าเห็นคำแนะนำหน้าไหนแล้ว (ต่อเครื่อง คั่นด้วยจุลภาค)
const String kTipsKey = 'aquafarm_tips_seen';

/// ช่องเซฟที่ใช้ได้
const List<int> kSaveSlots = [1, 2, 3];

/// เป้าหมายเสบียง (วัน)
const List<int> kSupplyGoals = [3, 5, 7, 10];

/// ตัวคูณค่าอาหารปลาตามระดับ 0=ไม่ให้ 1=น้อย 2=พอดี 3=มาก
const List<int> kFeedCostMultiplier = [0, 1, 2, 4];

/// แอมโมเนียที่เพิ่มขึ้นตามระดับการให้อาหาร
const List<double> kFeedAmmonia = [0, .1, .25, .8];

/// การเติบโตต่อวันตามระดับการให้อาหาร
const List<int> kFeedGrowth = [8, 30, 50, 50];

/// น้ำหนักความรุนแรงของภัยแต่ละวัน (ตัดตามจำนวนวันของภัย)
const List<double> kDisasterDayWeights = [.15, .25, .35, .15, .1];

/// ค่าใช้จ่ายและพลังงานของกิจกรรมต่าง ๆ
const int kChangeWaterCost = 20;
const int kChangeWaterEnergy = 8;
const int kAerateCost = 15;
const int kAerateEnergy = 5;
const int kFeedEnergy = 3;
const int kCatchEnergy = 10;
const int kCookEnergy = 8;
const int kPreserveEnergy = 8;
const int kBuyEquipmentEnergy = 3;
const int kRepairEnergy = 15;
const int kRestEnergyGain = 40;
const int kRestHungerCost = 5;
const int kNightEnergyGain = 60;
