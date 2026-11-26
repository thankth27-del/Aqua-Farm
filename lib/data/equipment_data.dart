/// อุปกรณ์ (EQ ในต้นแบบ)
library;

class EquipmentSpec {
  const EquipmentSpec({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    required this.use,
    this.kitchen = false,
  });

  final String id;
  final String name;
  final int price;
  final String icon;
  final String description;
  final String use;

  /// อุปกรณ์ครัว (ขายในหน้าตลาด) — ที่เหลือขายในหน้าเตรียมภัย
  final bool kitchen;

  /// อุปกรณ์ดูแลบ่อ (ขายในหน้าตลาด หมวดยาและบ่อ)
  bool get pond => kPondEquipmentOrder.contains(id);
}

const Map<String, EquipmentSpec> kEquipment = {
  'sand': EquipmentSpec(
    id: 'sand',
    name: 'กระสอบทราย',
    price: 30,
    icon: 'sand',
    description: 'กั้นน้ำเข้าฟาร์ม ใช้หมด 1 ใบต่อวันที่น้ำท่วม',
    use: 'ลดความเสียหายจากน้ำท่วม',
  ),
  'pump': EquipmentSpec(
    id: 'pump',
    name: 'เครื่องสูบน้ำ',
    price: 200,
    icon: 'pump',
    description: 'สูบน้ำที่ท่วมออกจากพื้นที่ฟาร์ม ใช้ซ้ำได้',
    use: 'ลดระดับน้ำท่วม',
  ),
  'net': EquipmentSpec(
    id: 'net',
    name: 'ตาข่ายกันปลาหลุด',
    price: 80,
    icon: 'net',
    description: 'คลุมบ่อกันปลาหลุดตอนน้ำล้น',
    use: 'ลดจำนวนปลาที่หลุดออกจากบ่อ',
  ),
  'tank': EquipmentSpec(
    id: 'tank',
    name: 'ถังเก็บน้ำ',
    price: 150,
    icon: 'tank',
    description: 'สำรองน้ำไว้เติมบ่อ',
    use: 'รับมือภัยแล้งและอากาศร้อน',
  ),
  'shade': EquipmentSpec(
    id: 'shade',
    name: 'หลังคาบังแดด',
    price: 120,
    icon: 'shade',
    description: 'ลดแสงแดดที่ส่องผิวน้ำ',
    use: 'ลดอุณหภูมิน้ำ',
  ),
  'filter': EquipmentSpec(
    id: 'filter',
    name: 'ระบบกรองสำรอง',
    price: 160,
    icon: 'filt',
    description: 'กรองน้ำเสียที่ไหลเข้าบ่อ',
    use: 'รับมือน้ำเสีย',
  ),
  'air': EquipmentSpec(
    id: 'air',
    name: 'เครื่องเติมอากาศ',
    price: 130,
    icon: 'bub',
    description: 'เพิ่มออกซิเจนละลายน้ำ',
    use: 'รับมือน้ำเสียและอากาศร้อน',
  ),
  'kit': EquipmentSpec(
    id: 'kit',
    name: 'ชุดตรวจน้ำ',
    price: 50,
    icon: 'scroll',
    description: 'วัดแอมโมเนีย ไนไตรต์ ออกซิเจน อุณหภูมิ ได้ค่าจริง',
    use: 'รู้ปัญหาน้ำก่อนปลาป่วย',
  ),
  'qtank': EquipmentSpec(
    id: 'qtank',
    name: 'บ่อพักแยกปลา',
    price: 80,
    icon: 'tank',
    description: 'แยกปลาป่วย 2 ตัว/บ่อ ไม่ให้แพร่เชื้อ',
    use: 'กันโรคระบาดในบ่อ',
  ),
  'rack': EquipmentSpec(
    id: 'rack',
    name: 'แผงตากปลา',
    price: 60,
    icon: 'rack',
    description: 'พื้นที่ตากปลาแห้ง 1 ชุด/ 1 แผง',
    use: 'ถนอมอาหารแบบตากแห้ง',
    kitchen: true,
  ),
  'jar': EquipmentSpec(
    id: 'jar',
    name: 'โหลหมัก/ดอง',
    price: 40,
    icon: 'jar',
    description: 'ภาชนะหมักเกลือและดอง 1 ชุด/ 1 โหล',
    use: 'ถนอมอาหารแบบหมักและดอง',
    kitchen: true,
  ),
  'fridge': EquipmentSpec(
    id: 'fridge',
    name: 'ตู้เย็น',
    price: 400,
    icon: 'fridge',
    description: 'ชะลอการเน่าเสียของอาหารสุกครึ่งหนึ่ง ต้องใช้ไฟฟ้า',
    use: 'ไฟดับแล้วอาหารเสียเร็วขึ้น',
    kitchen: true,
  ),
  'canner': EquipmentSpec(
    id: 'canner',
    name: 'เครื่องบรรจุกระป๋อง',
    price: 300,
    icon: 'canner',
    description: 'ปลดล็อกการทำปลากระป๋อง 1 ชุด/ 1 เครื่อง',
    use: 'เสบียงเก็บได้นานที่สุด',
    kitchen: true,
  ),
};

/// ลำดับอุปกรณ์ในหน้าตลาด (ครัว) และหน้าเตรียมภัย ตามต้นแบบ
const List<String> kKitchenEquipmentOrder = ['rack', 'jar', 'fridge', 'canner'];
const List<String> kDefenseEquipmentOrder = [
  'sand',
  'pump',
  'net',
  'tank',
  'shade',
  'filter',
  'air',
];

/// อุปกรณ์ดูแลบ่อ (หน้าตลาด หมวดยาและบ่อ)
const List<String> kPondEquipmentOrder = ['kit', 'qtank'];

/// อุปกรณ์ที่ใช้แล้วหมดไปทุกวันที่เกิดภัย
const String kSandbagId = 'sand';
