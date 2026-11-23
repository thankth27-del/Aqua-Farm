/// วัตถุดิบในตลาด (ING ในต้นแบบ)
library;

class IngredientSpec {
  const IngredientSpec(this.id, this.name, this.basePrice, this.icon);
  final String id;
  final String name;

  /// ราคาฐาน ราคาจริงสุ่มรายวัน = max(2, round(ฐาน × (0.6..1.5)))
  final int basePrice;
  final String icon;
}

const Map<String, IngredientSpec> kIngredients = {
  'garlic': IngredientSpec('garlic', 'กระเทียม', 8, 'garlic'),
  'chili': IngredientSpec('chili', 'พริก', 6, 'chili'),
  'lime': IngredientSpec('lime', 'มะนาว', 5, 'lime'),
  'veg': IngredientSpec('veg', 'ผัก', 7, 'veg'),
  'spice': IngredientSpec('spice', 'เครื่องปรุง', 10, 'spice'),
  'salt': IngredientSpec('salt', 'เกลือ', 4, 'salt'),
  'vin': IngredientSpec('vin', 'น้ำส้มสายชู', 6, 'vin'),
  'herb': IngredientSpec('herb', 'สมุนไพร', 9, 'herb'),
  'cans': IngredientSpec('cans', 'กระป๋อง', 8, 'can'),
};
