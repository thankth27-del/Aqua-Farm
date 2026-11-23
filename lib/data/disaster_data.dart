/// ภัยพิบัติ 4 แบบ (DZ, ORDER ในต้นแบบ)
library;

enum DisasterType { flood, drought, poll, heat }

class DisasterSpec {
  const DisasterSpec({
    required this.type,
    required this.name,
    required this.leadDays,
    required this.duration,
    required this.equipment,
    required this.visualLevel,
    required this.powerOut,
    required this.marketClosed,
    required this.message,
    required this.dayTexts,
  });

  final DisasterType type;
  final String name;

  /// แจ้งเตือนล่วงหน้ากี่วัน (lead)
  final int leadDays;

  /// ระยะเวลาภัย (dur)
  final int duration;

  /// อุปกรณ์ที่ต้องมี {id: จำนวน} (eq)
  final Map<String, int> equipment;

  /// ระดับเอฟเฟกต์ภาพรายวัน (lv) — ใช้กับ UI
  final List<double> visualLevel;

  /// ไฟดับรายวัน (out)
  final List<bool> powerOut;

  /// ตลาดปิดรายวัน (mk)
  final List<bool> marketClosed;
  final String message;
  final List<String> dayTexts;
}

const Map<DisasterType, DisasterSpec> kDisasters = {
  DisasterType.flood: DisasterSpec(
    type: DisasterType.flood,
    name: 'น้ำท่วม',
    leadDays: 5,
    duration: 4,
    equipment: {'sand': 4, 'pump': 1, 'net': 1},
    visualLevel: [.35, .65, 1, .45],
    powerOut: [false, true, true, false],
    marketClosed: [false, true, true, false],
    message: 'ฝนตกหนักต่อเนื่อง ระดับน้ำสูงขึ้น บ่อเสียหาย ปลาอาจหลุด ไฟอาจดับและเส้นทางตลาดถูกตัด',
    dayTexts: [
      'วันที่ 1 — ฝนตกหนัก ระดับน้ำเริ่มสูง ตรวจบ่อปลาและอุปกรณ์',
      'วันที่ 2 — น้ำท่วมพื้นที่ฟาร์ม ไฟดับ ตลาดปิด ตรวจกระสอบทรายและเครื่องสูบน้ำ',
      'วันที่ 3 — น้ำท่วมรุนแรง บ่อเสี่ยงเสียหาย ปลาอาจหลุด ต้องใช้เสบียง',
      'วันที่ 4 — น้ำเริ่มลด ตรวจความเสียหายและเริ่มฟื้นฟู',
    ],
  ),
  DisasterType.drought: DisasterSpec(
    type: DisasterType.drought,
    name: 'ภัยแล้ง',
    leadDays: 3,
    duration: 5,
    equipment: {'tank': 1, 'shade': 1},
    visualLevel: [.3, .5, .8, 1, .4],
    powerOut: [false, false, false, false, false],
    marketClosed: [false, false, false, false, false],
    message: 'ฝนทิ้งช่วงนาน น้ำในบ่อลดลง อุณหภูมิน้ำสูง ปลาเครียด ผลผลิตลดลง',
    dayTexts: [
      'วันที่ 1 — ฝนทิ้งช่วง น้ำในบ่อเริ่มลด',
      'วันที่ 2 — อากาศแห้ง อุณหภูมิน้ำเพิ่มขึ้น',
      'วันที่ 3 — น้ำน้อยมาก ปลาเริ่มเครียด',
      'วันที่ 4 — แล้งหนักที่สุด ผลผลิตลดลง',
      'วันที่ 5 — ฝนเริ่มกลับมา ประเมินความเสียหาย',
    ],
  ),
  DisasterType.poll: DisasterSpec(
    type: DisasterType.poll,
    name: 'น้ำเสีย',
    leadDays: 4,
    duration: 3,
    equipment: {'filter': 1, 'air': 1},
    visualLevel: [.5, 1, .4],
    powerOut: [false, false, false],
    marketClosed: [false, false, false],
    message: 'มีน้ำเสียไหลเข้าแหล่งน้ำ คุณภาพน้ำและออกซิเจนลดลง ปลาเจ็บป่วย',
    dayTexts: [
      'วันที่ 1 — พบน้ำเสียไหลเข้า คุณภาพน้ำเริ่มลด',
      'วันที่ 2 — น้ำเสียหนัก ออกซิเจนต่ำ ปลาเจ็บป่วย',
      'วันที่ 3 — น้ำเริ่มดีขึ้น ตรวจปลาที่เหลือ',
    ],
  ),
  DisasterType.heat: DisasterSpec(
    type: DisasterType.heat,
    name: 'อากาศร้อนจัด',
    leadDays: 3,
    duration: 3,
    equipment: {'shade': 1, 'air': 1, 'tank': 1},
    visualLevel: [.5, 1, .4],
    powerOut: [false, true, false],
    marketClosed: [false, false, false],
    message: 'อุณหภูมิสูงผิดปกติ ออกซิเจนละลายน้ำลดลง ไฟฟ้าอาจขัดข้อง ตู้เย็นหยุดทำงาน',
    dayTexts: [
      'วันที่ 1 — อากาศร้อนจัด อุณหภูมิน้ำสูง',
      'วันที่ 2 — ร้อนที่สุด ไฟฟ้าขัดข้อง ตู้เย็นหยุดทำงาน',
      'วันที่ 3 — อากาศเริ่มเย็นลง ตรวจปลาและอาหาร',
    ],
  ),
};

/// ลำดับการวนภัยถัดไป (ORDER)
const List<DisasterType> kDisasterOrder = [
  DisasterType.drought,
  DisasterType.poll,
  DisasterType.heat,
  DisasterType.flood,
];

/// ภัยแรกของเกมใหม่
const DisasterType kFirstDisaster = DisasterType.flood;
const int kFirstDisasterDay = 7;
const double kFirstDisasterSeverity = .5;

/// วันเว้นว่างเพิ่มหลังภัยจบก่อนเริ่มภัยถัดไป (นอกเหนือจาก lead)
const int kDisasterGapDays = 3;

/// ป้ายความรุนแรง
String severityLabel(double sev) => sev >= .6
    ? 'รุนแรง'
    : sev >= .45
    ? 'ปานกลาง'
    : 'เบา';

/// วันของภัยที่อาจถูกยืดออก (ภัยนาน [duration] วัน) → วันในข้อมูลต้นแบบ
/// ช่วงที่รุนแรงที่สุด (visualLevel สูงสุด) ถูกยืด วันอื่นคงเดิม
/// ถ้า duration เท่าต้นแบบ จะได้ [i] เดิม
int disasterBaseDay(DisasterType type, int duration, int i) {
  final d = kDisasters[type]!;
  final extra = duration - d.duration;
  if (extra <= 0) return i.clamp(0, d.duration - 1);
  var peak = 0;
  for (var k = 1; k < d.duration; k++) {
    if (d.visualLevel[k] > d.visualLevel[peak]) peak = k;
  }
  if (i <= peak) return i;
  if (i <= peak + extra) return peak;
  return (i - extra).clamp(0, d.duration - 1);
}

/// ข้อความประจำวันของภัย (เลขวันตรงกับวันจริงเมื่อภัยถูกยืด)
String disasterDayText(DisasterType type, int duration, int i) {
  final t = kDisasters[type]!.dayTexts[disasterBaseDay(type, duration, i)];
  if (duration == kDisasters[type]!.duration) return t;
  return t.replaceFirst(RegExp(r'^วันที่ \d+'), 'วันที่ ${i + 1}');
}
