/// ข้อมูลปลา 8 ชนิด (FISH ในต้นแบบ)
library;

class FishSpec {
  const FishSpec({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.growthMul,
    required this.toughness,
    required this.o2Need,
    required this.feed,
    required this.yieldDishes,
    required this.bodyColor,
    required this.finColor,
    required this.pros,
    required this.cons,
    required this.forWho,
    this.whiskers = false,
    this.hump = false,
    this.stripe = false,
  });

  final String id;
  final String name;

  /// ราคาซื้อ (b)
  final int buyPrice;

  /// ราคาขายเมื่อโตเต็มวัย (s)
  final int sellPrice;

  /// ตัวคูณการเติบโต (gm)
  final double growthMul;

  /// ความทนทาน 1-5 (tough)
  final int toughness;

  /// ออกซิเจนขั้นต่ำที่ต้องการ % (o2)
  final int o2Need;

  /// หน่วยอาหารต่อวัน (feed)
  final int feed;

  /// จำนวนจานที่ได้ต่อปลา 1 ตัว (yield)
  final int yieldDishes;

  /// สีสำหรับวาดสไปรต์ (c, f) และลักษณะพิเศษ (wh, hu, st)
  final int bodyColor;
  final int finColor;
  final bool whiskers;
  final bool hump;
  final bool stripe;

  final String pros;
  final String cons;
  final String forWho;

  /// จำนวนวันโดยประมาณเมื่อให้อาหารพอดี
  int get daysToGrow => (100 / (50 * growthMul)).ceil();

  /// ป้ายความเร็วเติบโต
  String get growthLabel => growthMul >= 1.1
      ? 'เร็ว'
      : growthMul >= .9
      ? 'ปานกลาง'
      : growthMul >= .7
      ? 'ช้า'
      : 'ช้ามาก';
}

/// ลำดับตรงกับต้นแบบ (ใช้เป็นลำดับเลือกปลาไปทำอาหารด้วย)
const Map<String, FishSpec> kFish = {
  'nila': FishSpec(
    id: 'nila',
    name: 'ปลานิล',
    buyPrice: 40,
    sellPrice: 90,
    growthMul: 1,
    toughness: 4,
    o2Need: 35,
    feed: 1,
    yieldDishes: 2,
    bodyColor: 0xFF8E9BB0,
    finColor: 0xFF7C5A6B,
    pros: 'ทนทาน เลี้ยงง่าย โตเร็วปานกลาง',
    cons: 'ราคาขายปานกลาง',
    forWho: 'ผู้เล่นมือใหม่',
  ),
  'dook': FishSpec(
    id: 'dook',
    name: 'ปลาดุก',
    buyPrice: 30,
    sellPrice: 80,
    growthMul: .75,
    toughness: 5,
    o2Need: 20,
    feed: 1,
    yieldDishes: 2,
    bodyColor: 0xFF4B4A5C,
    finColor: 0xFF34303F,
    whiskers: true,
    pros: 'ทนที่สุด ออกซิเจนต่ำก็รอด',
    cons: 'โตช้า',
    forWho: 'ผู้เล่นที่กลัวน้ำเสีย',
  ),
  'tap': FishSpec(
    id: 'tap',
    name: 'ปลาตะเพียน',
    buyPrice: 25,
    sellPrice: 65,
    growthMul: 1.25,
    toughness: 3,
    o2Need: 40,
    feed: 1,
    yieldDishes: 1,
    bodyColor: 0xFFD9DEE8,
    finColor: 0xFFE0584D,
    pros: 'ราคาถูก โตเร็ว',
    cons: 'ให้เนื้อน้อย ราคาขายต่ำ',
    forWho: 'ผู้เล่นทุนน้อย',
  ),
  'carp': FishSpec(
    id: 'carp',
    name: 'ปลาคาร์พ',
    buyPrice: 60,
    sellPrice: 140,
    growthMul: .6,
    toughness: 4,
    o2Need: 45,
    feed: 2,
    yieldDishes: 3,
    bodyColor: 0xFFE08A3C,
    finColor: 0xFFF2C36B,
    pros: 'ราคาขายสูง ให้เนื้อมาก',
    cons: 'โตช้า กินอาหารมาก',
    forWho: 'ผู้เล่นที่วางแผนระยะยาว',
  ),
  'rad': FishSpec(
    id: 'rad',
    name: 'ปลาแรด',
    buyPrice: 55,
    sellPrice: 120,
    growthMul: .7,
    toughness: 3,
    o2Need: 40,
    feed: 2,
    yieldDishes: 3,
    bodyColor: 0xFF6B6A58,
    finColor: 0xFF4A493C,
    hump: true,
    pros: 'ตัวใหญ่ ให้เนื้อมาก',
    cons: 'โตช้า ไวต่อน้ำเสียปานกลาง',
    forWho: 'ผู้เล่นที่เน้นผลผลิตอาหาร',
  ),
  'chon': FishSpec(
    id: 'chon',
    name: 'ปลาช่อน',
    buyPrice: 70,
    sellPrice: 170,
    growthMul: .5,
    toughness: 3,
    o2Need: 50,
    feed: 3,
    yieldDishes: 3,
    bodyColor: 0xFF6B7A3A,
    finColor: 0xFF4A5A2A,
    stripe: true,
    pros: 'ราคาขายสูงที่สุด',
    cons: 'โตช้ามาก กินอาหารเยอะ ต้องการออกซิเจนสูง',
    forWho: 'ผู้เล่นที่ดูแลน้ำเก่ง',
  ),
  'swai': FishSpec(
    id: 'swai',
    name: 'ปลาสวาย',
    buyPrice: 45,
    sellPrice: 100,
    growthMul: .9,
    toughness: 4,
    o2Need: 30,
    feed: 2,
    yieldDishes: 3,
    bodyColor: 0xFFA9B4C2,
    finColor: 0xFF7F8AA0,
    whiskers: true,
    pros: 'ทนทาน ให้เนื้อมาก',
    cons: 'กินอาหารปานกลาง',
    forWho: 'ผู้เล่นที่ต้องการสมดุล',
  ),
  'nuan': FishSpec(
    id: 'nuan',
    name: 'ปลานวลจันทร์',
    buyPrice: 35,
    sellPrice: 75,
    growthMul: 1.1,
    toughness: 2,
    o2Need: 55,
    feed: 1,
    yieldDishes: 1,
    bodyColor: 0xFFEEF2F7,
    finColor: 0xFFC9D3E0,
    pros: 'โตเร็ว กินอาหารน้อย',
    cons: 'บอบบาง ต้องการออกซิเจนสูง',
    forWho: 'ผู้เล่นที่ดูแลบ่อละเอียด',
  ),
};
