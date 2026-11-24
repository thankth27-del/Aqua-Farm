import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/equipment_data.dart';
import '../../data/fish_data.dart';
import '../../data/food_data.dart';
import '../../data/ingredients.dart';
import '../../game/game_engine.dart';
import '../../game/story.dart';
import '../../game/tutorial.dart';
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/equipment_row.dart';
import '../widgets/story_gate.dart';
import '../widgets/sub_tabs.dart';
import '../widgets/guide_bars.dart';

/// แท็บ "ตลาด" (market ในต้นแบบ): ซื้อวัตถุดิบ ขายปลาในคลัง ขายอาหาร ซื้ออุปกรณ์ครัว
/// ทุกการซื้อขายต้องผ่านหน้ายืนยัน · ตลาดปิดตอนเกิดภัย (ซื้อขายไม่ได้)
class MarketTab extends ConsumerStatefulWidget {
  const MarketTab({super.key});

  @override
  ConsumerState<MarketTab> createState() => _MarketTabState();

  /// อุปกรณ์ครัวที่ขายในตลาด (ตามต้นแบบ: rack, jar, fridge, canner)
  static final kitchenEquipment = [
    for (final id in kKitchenEquipmentOrder) kEquipment[id]!,
  ];
}

class _MarketTabState extends ConsumerState<MarketTab> {
  /// แท็บย่อย: false = ซื้อ (วัตถุดิบ อุปกรณ์) · true = ขาย (ปลา อาหาร)
  bool _sell = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final closed = s.marketClosed;

    /// ตลาดปิด หรือรู้แน่ว่าทำไม่ได้ → ให้ engine ตอบเหตุผลเลย (ไม่เปลี่ยนสถานะ)
    /// ไม่งั้นถามยืนยันก่อน แล้วค่อยทำ
    Future<void> act(
      bool blocked,
      String confirm,
      Widget icon,
      ActionResult Function(GameEngine e) action,
    ) async {
      if (blocked) {
        showResult(context, ctl.run(action));
        return;
      }
      if (!await confirmDialog(context, confirm, icon: icon)) return;
      if (context.mounted) showResult(context, ctl.run(action));
    }

    final ingredients = kIngredients.values.toList();
    final fish = kFish.values.toList();

    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);
    if (story != null) {
      // เนื้อเรื่อง: ของที่ชี้ให้ซื้อ/ขายอยู่แถวแรก ไม่ต้องเลื่อนหา
      int first(bool hit) => hit ? 0 : 1;
      ingredients.sort(
        (a, b) => first(a.id == 'spice') - first(b.id == 'spice'),
      );
      fish.sort(
        (a, b) =>
            first((s.fishStock[a.id] ?? 0) > 0) -
            first((s.fishStock[b.id] ?? 0) > 0),
      );
    }

    /// การ์ดที่เนื้อเรื่องชี้ให้กด
    Widget pick(bool on, StoryTarget target, Widget child) =>
        on && next == target ? StoryGate(target: target, child: child) : child;

    // ---------- วัตถุดิบ ----------
    final ingredientPanel = WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'วัตถุดิบ',
            icon: PixelIcon('veg', size: 28),
            trailing: Tag('ราคาเปลี่ยนทุกวัน'),
          ),
          _Grid(
            children: [
              for (final g in ingredients)
                pick(
                  g.id == 'spice',
                  StoryTarget.buyIngredient,
                  _IngredientCard(
                    key: ValueKey('ing-${g.id}'),
                    spec: g,
                    price: s.prices[g.id] ?? g.basePrice,
                    yesterday:
                        s.prevPrices[g.id] ?? s.prices[g.id] ?? g.basePrice,
                    owned: s.inventory[g.id] ?? 0,
                    closed: closed,
                    onTap: () {
                      final p = s.prices[g.id] ?? g.basePrice;
                      act(
                        closed || s.money < p,
                        'ยืนยันซื้อ${g.name} 1 ชิ้น ราคา $p บาท? (เงินคงเหลือ ${s.money - p} บาท)',
                        PixelIcon(g.icon, size: 56),
                        (e) => e.buyIngredient(g.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // ---------- ขายปลาในคลัง ----------
    final sellFishPanel = WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'ขายปลาในคลัง',
            icon: const PixelIcon('f_nila', size: 30),
            trailing: Tag('${e.fishTotal} ตัว'),
          ),
          _Grid(
            children: [
              for (final f in fish)
                pick(
                  (s.fishStock[f.id] ?? 0) > 0,
                  StoryTarget.sellFish,
                  _SellFishCard(
                    key: ValueKey('sell-fish-${f.id}'),
                    spec: f,
                    price: e.fishSellPrice(f.id),
                    count: s.fishStock[f.id] ?? 0,
                    closed: closed,
                    onTap: () => act(
                      closed || (s.fishStock[f.id] ?? 0) <= 0,
                      'ยืนยันขาย${f.name} 1 ตัว ได้ ${e.fishSellPrice(f.id)} บาท?',
                      PixelIcon('f_${f.id}', size: 72),
                      (e) => e.sellFish(f.id),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // ---------- ขายอาหาร ----------
    final sellFoodPanel = WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'ขายอาหาร',
            icon: const PixelIcon('fry', size: 28),
            trailing: Tag('${e.servings} จาน'),
          ),
          if (s.stock.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Gap.s),
              child: Muted(
                'ยังไม่มีอาหาร ทำได้ที่ครัว',
                size: FontSize.body,
                align: TextAlign.center,
              ),
            ),
          for (var i = 0; i < s.stock.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: _FoodRow(
                key: ValueKey('sell-food-$i'),
                food: kFoods[s.stock[i].food]!,
                price: e.foodSellPrice(s.stock[i].food),
                qty: s.stock[i].qty,
                daysLeft: e.daysLeft(s.stock[i]),
                expired: e.isExpired(s.stock[i]),
                nearExpiry: e.isNearExpiry(s.stock[i]),
                closed: closed,
                onSell: () {
                  final it = kFoods[s.stock[i].food]!;
                  act(
                    closed,
                    'ยืนยันขาย${it.name} 1 จาน ได้ ${e.foodSellPrice(it.id)} บาท?',
                    PixelIcon(it.icon, size: 56),
                    (e) => e.sellStock(i),
                  );
                },
              ),
            ),
        ],
      ),
    );

    // ---------- อุปกรณ์ครัว ----------
    final toolPanel = WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'อุปกรณ์ครัว',
            icon: PixelIcon('fridge', size: 28),
          ),
          for (final eq in MarketTab.kitchenEquipment)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: pick(
                eq.id == 'rack',
                StoryTarget.buyTool,
                EquipmentRow(
                  key: ValueKey('eq-${eq.id}'),
                  spec: eq,
                  price: e.equipmentPrice(eq.id),
                  owned: s.equipmentCount(eq.id),
                  closed: closed,
                  onBuy: () => act(
                    closed || s.money < e.equipmentPrice(eq.id),
                    'ยืนยันซื้อ${eq.name} ราคา ${e.equipmentPrice(eq.id)} บาท?',
                    PixelIcon(eq.icon, size: 56),
                    (e) => e.buyEquipment(eq.id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    var sections = [
      (StoryTarget.buyIngredient, ingredientPanel),
      (StoryTarget.sellFish, sellFishPanel),
      (StoryTarget.sellFood, sellFoodPanel),
      (StoryTarget.buyTool, toolPanel),
    ];
    if (story != null) {
      // เนื้อเรื่อง: แสดงเฉพาะส่วนที่บทนี้ใช้ ส่วนที่ต้องกดต่อไปอยู่บนสุด
      final (p, ge) = story;
      sections = [
        for (final x in sections)
          if (Story.allows(p, ge, x.$1)) x,
      ]..sort((a, b) => (a.$1 == next ? 0 : 1) - (b.$1 == next ? 0 : 1));
    } else {
      // โหมดเอาชีวิตรอด: แยกแท็บย่อย ซื้อ | ขาย แทนหน้ายาว
      bool selling(StoryTarget t) =>
          t == StoryTarget.sellFish || t == StoryTarget.sellFood;
      sections = [
        for (final x in sections)
          if (selling(x.$1) == _sell) x,
      ];
    }

    final list = TabScroll(
      header: story == null ? 1 : 0,
      decorative: true,
      listKey: PageStorageKey(_sell ? 'market-sell-list' : 'market-buy-list'),
      children: [
        if (story == null)
          PageHeader(
            scene: PixelScene(painterBuilder: RoomPainter.new),
            title: 'ตลาด',
            icon: const PixelIcon('garlic', size: 30),
          ),
        if (closed) _ClosedBanner(engine: e),
        for (final x in sections) x.$2,
      ],
    );
    if (story != null) return list;
    final food = s.stock.fold<int>(0, (n, b) => n + b.qty);
    return Column(
      children: [
        TipSpot(
          screen: GameScreen.market,
          child: SubTabs(
            key: const ValueKey('primary-market'),
            selected: _sell ? 1 : 0,
            onSelect: (i) => setState(() => _sell = i == 1),
            items: [
              ('market-buy', 'ซื้อ', 'garlic', null),
              (
                'market-sell',
                'ขาย',
                'coin',
                e.fishTotal + food > 0 ? e.fishTotal + food : null,
              ),
            ],
          ),
        ),
        Expanded(child: list),
      ],
    );
  }
}

/// ป้ายตลาดปิด พร้อมเหตุผล
class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final a = engine.state.active;
    final cause = a == null
        ? 'ภัยพิบัติ'
        : '${kDisasters[a.type]!.name} (วันที่ ${a.dayIndex + 1}/${a.duration})';
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: PixelBox(
        key: const ValueKey('market-closed'),
        fill: AquaColors.red,
        depth: 5,
        depthColor: AquaColors.redDark,
        padding: const EdgeInsets.all(Gap.m),
        child: Row(
          children: [
            const Blink(low: .6, child: PixelIcon('warn', size: 40)),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OutlinedText(
                    'ตลาดปิดชั่วคราว',
                    size: FontSize.title,
                    color: AquaColors.goldPale,
                    align: TextAlign.left,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    'เส้นทางถูกตัดขาดจาก$cause ซื้อขายไม่ได้ ใช้เสบียงที่เตรียมไว้',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: FontSize.body,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ตาราง 3 คอลัมน์ ความสูงพอดีเนื้อหา
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        const gap = Gap.s;
        final w = ((c.maxWidth - gap * 2) / 3).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      },
    );
  }
}

/// ป้ายจำนวนที่มี (มุมขวาบนของการ์ด)
class _Count extends StatelessWidget {
  const _Count(this.n);
  final int n;

  @override
  Widget build(BuildContext context) => Tag(
    'x$n',
    size: 13,
    color: n > 0 ? AquaColors.gold : AquaColors.creamDark,
  );
}

/// การ์ดวัตถุดิบ: ไอคอน ชื่อ ราคาวันนี้ ราคาเมื่อวาน (ลูกศรขึ้น/ลง) จำนวนที่มี
class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    super.key,
    required this.spec,
    required this.price,
    required this.yesterday,
    required this.owned,
    required this.closed,
    required this.onTap,
  });

  final IngredientSpec spec;
  final int price;
  final int yesterday;
  final int owned;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = price - yesterday;
    final (arrow, color) = d > 0
        ? ('▲$d', AquaColors.bad)
        : d < 0
        ? ('▼${-d}', AquaColors.ok)
        : ('=', AquaColors.textSoft);
    final trend = d > 0 ? 'แพงขึ้น' : (d < 0 ? 'ถูกลง' : 'เท่าเดิม');
    return Pressable(
      label:
          'ซื้อ${spec.name} ราคาวันนี้ $price บาท เมื่อวาน $yesterday บาท $trend มี $owned',
      onTap: onTap,
      child: Opacity(
        opacity: closed ? .55 : 1,
        child: ExcludeSemantics(
          child: _CardFrame(
            badge: _Count(owned),
            footer: closed ? 'ปิด' : 'ซื้อ',
            footerStyle: closed ? PixelButtonStyle.wood : PixelButtonStyle.gold,
            children: [
              PixelIcon(spec.icon, size: 40),
              const SizedBox(height: 2),
              Bold(spec.name, size: 15, maxLines: 1),
              CoinTag(price, boxed: true, size: 15),
              const SizedBox(height: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'เมื่อวาน $yesterday',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AquaColors.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดขายปลา: ไอคอน ชื่อ ราคาขาย จำนวนในคลัง
class _SellFishCard extends StatelessWidget {
  const _SellFishCard({
    super.key,
    required this.spec,
    required this.price,
    required this.count,
    required this.closed,
    required this.onTap,
  });

  final FishSpec spec;
  final int price;
  final int count;
  final bool closed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final can = count > 0 && !closed;
    return Pressable(
      label: 'ขาย${spec.name} ได้ $price บาท มี $count ตัว',
      onTap: onTap,
      child: Opacity(
        opacity: can ? 1 : .55,
        child: ExcludeSemantics(
          child: _CardFrame(
            badge: _Count(count),
            footer: closed ? 'ปิด' : 'ขาย',
            footerStyle: can ? PixelButtonStyle.green : PixelButtonStyle.wood,
            children: [
              SizedBox(
                height: 40,
                child: Center(child: PixelIcon('f_${spec.id}', size: 56)),
              ),
              const SizedBox(height: 2),
              Bold(spec.name, size: 15, maxLines: 1),
              CoinTag(price, boxed: true, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

/// กรอบการ์ดสินค้า: กระดาษ + ป้ายจำนวน + แถบปุ่มด้านล่าง
class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.children,
    required this.badge,
    required this.footer,
    required this.footerStyle,
  });

  final List<Widget> children;
  final Widget badge;
  final String footer;
  final PixelButtonStyle footerStyle;

  @override
  Widget build(BuildContext context) {
    final (fill, fg) = switch (footerStyle) {
      PixelButtonStyle.gold => (AquaColors.gold, AquaColors.ink),
      PixelButtonStyle.green => (AquaColors.grass, Colors.white),
      _ => (AquaColors.woodLight, AquaColors.paper),
    };
    return Stack(
      children: [
        PaperCard(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children,
              const SizedBox(height: Gap.xs),
              PixelBox(
                fill: fill,
                px: 2,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Center(
                  child: Text(
                    footer,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: FontSize.body,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(top: 3, right: 3, child: badge),
      ],
    );
  }
}

/// แถวอาหาร 1 ชุด: ไอคอน ชื่อ จำนวน วันหมดอายุ ปุ่มขาย
class _FoodRow extends StatelessWidget {
  const _FoodRow({
    super.key,
    required this.food,
    required this.price,
    required this.qty,
    required this.daysLeft,
    required this.expired,
    required this.nearExpiry,
    required this.closed,
    required this.onSell,
  });

  final FoodSpec food;
  final int price;
  final int qty;
  final int daysLeft;
  final bool expired;
  final bool nearExpiry;
  final bool closed;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          PixelIcon(food.icon, size: 40),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bold('${food.name} x$qty', maxLines: 1),
                const SizedBox(height: 2),
                expired
                    ? const Tag(
                        'หมดอายุ',
                        color: AquaColors.red,
                        textColor: Colors.white,
                        size: 13,
                      )
                    : Tag(
                        'เหลือ $daysLeft วัน',
                        color: nearExpiry
                            ? AquaColors.redPale
                            : AquaColors.creamDark,
                        icon: const PixelIcon('cal', size: 14),
                        size: 13,
                      ),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          PixelButton(
            label: closed ? 'ปิด' : 'ขาย',
            style: closed ? PixelButtonStyle.wood : PixelButtonStyle.green,
            below: CoinTag(price, boxed: true, size: FontSize.small),
            onPressed: expired ? null : onSell,
          ),
        ],
      ),
    );
  }
}
