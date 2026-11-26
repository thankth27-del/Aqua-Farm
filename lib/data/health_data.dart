/// ดูแลน้ำและโรคปลา (ค่าในเกม — แบบจำลองเพื่อการเรียนรู้ ไม่ใช่คำแนะนำการเลี้ยงจริง)
library;

// ---------------------------------------------------------------- ดูแลน้ำ

/// เครื่องเติมอากาศ (อุปกรณ์ 'air'): เปิดไว้ ออกซิเจนตอนเช้าไม่ต่ำกว่าค่านี้
const double kAeratorO2Floor = 80;

/// ค่าไฟเครื่องเติมอากาศต่อวัน (บาท) — ไฟดับ = ไม่ทำงาน ไม่เสียค่าไฟ
const int kAeratorPowerCost = 5;

/// ตัวกรองสกปรกขึ้นต่อวัน ตามปริมาณอาหาร [ไม่ให้, น้อย, พอดี, มาก]
const List<int> kFilterDirtPerDay = [2, 6, 10, 14];

/// ตัวกรองสกปรก 100 = กรองของเสียได้ครึ่งเดียว (ประสิทธิภาพ × (1 - สกปรก/200))
const double kFilterDirtPenalty = 200;

/// ล้างตัวกรอง: พลังงาน และแบคทีเรียดีที่หายไป (ล้างบ่อยเกินไม่ดี)
const int kCleanFilterEnergy = 6;
const int kCleanFilterBioLoss = 10;

/// สกปรกน้อยกว่านี้ยังไม่ต้องล้าง
const int kCleanFilterMin = 10;

/// ตรวจน้ำด้วยชุดตรวจ (อุปกรณ์ 'kit'): พลังงาน
const int kTestWaterEnergy = 2;

/// บ่อพักแยกปลา (อุปกรณ์ 'qtank'): จุได้กี่ตัวต่อ 1 บ่อ
const int kQuarantineSlots = 2;

// ---------------------------------------------------------------- โรคปลา

class DiseaseSpec {
  const DiseaseSpec({
    required this.id,
    required this.name,
    required this.symptom,
    required this.cause,
    required this.medicine,
  });

  final String id;
  final String name;

  /// อาการที่ผู้เล่นเห็น
  final String symptom;

  /// สาเหตุ (ความรู้)
  final String cause;

  /// ยาที่ถูก (id ใน [kMedicines])
  final String medicine;
}

const Map<String, DiseaseSpec> kDiseases = {
  'ich': DiseaseSpec(
    id: 'ich',
    name: 'โรคจุดขาว',
    symptom: 'มีจุดขาวเล็กๆ ตามตัวและครีบ ปลาถูตัวกับขอบบ่อ',
    cause: 'ปรสิตเซลล์เดียว มักระบาดเมื่ออุณหภูมิน้ำแกว่ง หรือหลังน้ำท่วม',
    medicine: 'salt',
  ),
  'spot': DiseaseSpec(
    id: 'spot',
    name: 'โรคตัวด่าง',
    symptom: 'มีแผลด่างขาวบนหลัง เหงือกซีด ว่ายเชื่องช้า',
    cause: 'แบคทีเรีย ฉวยโอกาสเมื่อน้ำแย่ติดกันหลายวัน หรือปลาแน่นบ่อ',
    medicine: 'kmno4',
  ),
  'bleed': DiseaseSpec(
    id: 'bleed',
    name: 'โรคตกเลือด',
    symptom: 'มีจุดเลือดออกตามตัว ครีบกร่อน ไม่ค่อยกินอาหาร',
    cause: 'แบคทีเรีย พบเมื่อน้ำร้อนจัด หรือหลังน้ำเสียไหลเข้าบ่อ',
    medicine: 'antibio',
  ),
};

class MedicineSpec {
  const MedicineSpec({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    this.dose = 1,
    this.ingredient = false,
  });

  final String id;
  final String name;

  /// ราคาต่อ 1 หน่วย (คงที่) — เกลือใช้ราคาวัตถุดิบของวันนั้น
  final int price;
  final String icon;
  final String description;

  /// ใช้ครั้งละกี่หน่วย
  final int dose;

  /// เป็นวัตถุดิบในตลาด (เก็บในช่องวัตถุดิบ)
  final bool ingredient;
}

const Map<String, MedicineSpec> kMedicines = {
  'salt': MedicineSpec(
    id: 'salt',
    name: 'เกลือแช่ปลา',
    price: 4,
    icon: 'salt',
    description: 'แช่น้ำเกลือ ใช้เกลือ 2 ถุง ช่วยกำจัดปรสิต (จุดขาว)',
    dose: 2,
    ingredient: true,
  ),
  'kmno4': MedicineSpec(
    id: 'kmno4',
    name: 'ด่างทับทิม',
    price: 25,
    icon: 'vin',
    description: 'ฆ่าเชื้อแผลภายนอก ใช้กับโรคตัวด่าง',
  ),
  'antibio': MedicineSpec(
    id: 'antibio',
    name: 'ยาปฏิชีวนะสำหรับปลา',
    price: 60,
    icon: 'herb',
    description: 'ผสมอาหาร รักษาการติดเชื้อในตัว ใช้กับโรคตกเลือด',
  ),
};

/// ลำดับยาในหน้าตลาด/หน้ารักษา
const List<String> kMedicineOrder = ['salt', 'kmno4', 'antibio'];

/// โอกาสป่วยต่อตัวต่อวัน
const double kSickBadWater = .15; // น้ำต่ำกว่าเส้นดี ติดกัน 2 วัน
const double kSickDangerWater = .30; // น้ำต่ำกว่าเส้นอันตราย ติดกัน 2 วัน
const int kSickBadWaterDays = 2;
const double kSickCrowded = .05; // ปลาเกิน [kCrowdedFish] ตัว
const int kCrowdedFish = 6;
const double kSickHot = .10; // น้ำ ≥ [kHotTemp]
const double kHotTemp = 33;
const double kSickTempSwing = .10; // อุณหภูมิเปลี่ยน ≥ [kTempSwing] ใน 1 วัน
const double kTempSwing = 2;
const double kSickOutbreak = .20; // ช่วงหลังภัย
const int kOutbreakDays = 2;
const double kSickSpread = .10; // ต่อปลาป่วย 1 ตัวที่ไม่ได้แยกบ่อ

/// ปลาป่วย: สุขภาพลดต่อวัน และตายถ้าไม่รักษาภายใน N วัน (ปลาทน +1 วัน)
const int kSickDamage = 15;
const int kSickDaysToDie = 3;

/// ปลาทนทาน (toughness ≥ ค่านี้) อยู่ได้นานขึ้น 1 วัน
const int kToughFish = 4;

/// ยาถูกตัว: หายใน N วัน (น้ำต้องไม่ต่ำกว่าเส้นอันตราย ยาถึงได้ผล)
const int kTreatDays = 2;
const int kTreatEnergy = 3;
