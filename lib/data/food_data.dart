/// อาหาร สูตร และวิธีถนอมอาหาร (IT, RC, PR ในต้นแบบ)
library;

enum FoodKind { meal, preserved }

class FoodSpec {
  const FoodSpec({
    required this.id,
    required this.name,
    required this.icon,
    required this.value,
    required this.hunger,
    required this.energy,
    required this.kcal,
    required this.protein,
    required this.shelfDays,
    required this.kind,
    this.coolable = false,
  });

  final String id;
  final String name;
  final String icon;

  /// ราคาขาย (v)
  final int value;

  /// ความอิ่มที่ได้ (hun)
  final int hunger;

  /// พลังงานที่ได้ (en)
  final int energy;
  final int kcal;
  final int protein;

  /// อายุเก็บรักษา (วัน)
  final int shelfDays;
  final FoodKind kind;

  /// แช่ตู้เย็นได้ (cool) — มีผลกับอัตราการเสื่อม
  final bool coolable;
}

const Map<String, FoodSpec> kFoods = {
  'fry': FoodSpec(
    id: 'fry',
    name: 'ปลาทอด',
    icon: 'fry',
    value: 110,
    hunger: 25,
    energy: 10,
    kcal: 320,
    protein: 24,
    shelfDays: 3,
    coolable: true,
    kind: FoodKind.meal,
  ),
  'garlic': FoodSpec(
    id: 'garlic',
    name: 'ปลาผัดกระเทียม',
    icon: 'garl',
    value: 130,
    hunger: 28,
    energy: 12,
    kcal: 280,
    protein: 23,
    shelfDays: 3,
    coolable: true,
    kind: FoodKind.meal,
  ),
  'tomyum': FoodSpec(
    id: 'tomyum',
    name: 'ต้มยำปลา',
    icon: 'tomyum',
    value: 160,
    hunger: 32,
    energy: 15,
    kcal: 210,
    protein: 22,
    shelfDays: 3,
    coolable: true,
    kind: FoodKind.meal,
  ),
  'bake': FoodSpec(
    id: 'bake',
    name: 'ปลาอบ',
    icon: 'bake',
    value: 140,
    hunger: 30,
    energy: 12,
    kcal: 260,
    protein: 28,
    shelfDays: 3,
    coolable: true,
    kind: FoodKind.meal,
  ),
  'herb': FoodSpec(
    id: 'herb',
    name: 'ปลาต้มสมุนไพร',
    icon: 'hsoup',
    value: 150,
    hunger: 30,
    energy: 14,
    kcal: 190,
    protein: 24,
    shelfDays: 3,
    coolable: true,
    kind: FoodKind.meal,
  ),
  'dried': FoodSpec(
    id: 'dried',
    name: 'ปลาแห้ง',
    icon: 'dry',
    value: 70,
    hunger: 20,
    energy: 8,
    kcal: 250,
    protein: 45,
    shelfDays: 14,
    kind: FoodKind.preserved,
  ),
  'salted': FoodSpec(
    id: 'salted',
    name: 'ปลาเค็ม (หมักเกลือ)',
    icon: 'salt',
    value: 90,
    hunger: 22,
    energy: 8,
    kcal: 230,
    protein: 40,
    shelfDays: 30,
    kind: FoodKind.preserved,
  ),
  'pickled': FoodSpec(
    id: 'pickled',
    name: 'ปลาดอง',
    icon: 'pick',
    value: 80,
    hunger: 20,
    energy: 8,
    kcal: 180,
    protein: 30,
    shelfDays: 21,
    kind: FoodKind.preserved,
  ),
  'canned': FoodSpec(
    id: 'canned',
    name: 'ปลากระป๋อง',
    icon: 'can',
    value: 120,
    hunger: 25,
    energy: 10,
    kcal: 240,
    protein: 32,
    shelfDays: 90,
    kind: FoodKind.preserved,
  ),
};

/// สูตรอาหาร 5 เมนู (ใช้ปลา 1 ตัว + วัตถุดิบ ได้จาน = yield ของปลา)
class Recipe {
  const Recipe(this.id, this.need, this.minutes);
  final String id;
  final Map<String, int> need;
  final int minutes;
}

const Map<String, Recipe> kRecipes = {
  'fry': Recipe('fry', {'spice': 1}, 20),
  'garlic': Recipe('garlic', {'garlic': 1, 'spice': 1}, 25),
  'tomyum': Recipe('tomyum', {'chili': 1, 'lime': 1, 'veg': 1}, 35),
  'bake': Recipe('bake', {'spice': 1, 'lime': 1}, 45),
  'herb': Recipe('herb', {'herb': 1, 'veg': 1}, 40),
};

/// วิธีถนอมอาหาร 4 วิธี
class PreserveMethod {
  const PreserveMethod({
    required this.id,
    required this.name,
    required this.need,
    required this.equipment,
    required this.days,
    required this.description,
  });

  /// id ของอาหารที่ได้ (ตรงกับ kFoods)
  final String id;
  final String name;
  final Map<String, int> need;

  /// อุปกรณ์ที่ต้องมีว่าง 1 ชุดต่อ 1 งาน
  final String equipment;
  final int days;
  final String description;
}

const Map<String, PreserveMethod> kPreserveMethods = {
  'dried': PreserveMethod(
    id: 'dried',
    name: 'ตากแห้ง (Drying)',
    need: {},
    equipment: 'rack',
    days: 2,
    description: 'ใช้แผงตาก ไม่ใช้ไฟฟ้า เก็บได้ ~14 วัน',
  ),
  'salted': PreserveMethod(
    id: 'salted',
    name: 'หมักเกลือ (Salting)',
    need: {'salt': 2},
    equipment: 'jar',
    days: 3,
    description: 'ใช้เกลือ 2 + โหลหมัก เก็บได้ ~30 วัน',
  ),
  'pickled': PreserveMethod(
    id: 'pickled',
    name: 'ดอง (Pickling)',
    need: {'vin': 1},
    equipment: 'jar',
    days: 2,
    description: 'ใช้น้ำส้มสายชู + โหลดอง เก็บได้ ~21 วัน',
  ),
  'canned': PreserveMethod(
    id: 'canned',
    name: 'บรรจุกระป๋อง (Canning)',
    need: {'cans': 1},
    equipment: 'canner',
    days: 2,
    description: 'ใช้กระป๋อง + เครื่องบรรจุ เก็บได้ ~90 วัน',
  ),
};
