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
import '../design/design_system.dart' show DsColors;
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../scenes/room_scenes.dart';
import '../theme/theme.dart';
import '../widgets/equipment_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/story_gate.dart';
import '../widgets/guide_bars.dart';

/// ฉากตลาดเต็มจอ (พื้นหลังของหน้าตลาด) — ตลาดปิดแล้วแผงลอยลงม่านเหล็ก
class MarketBackdrop extends ConsumerWidget {
  const MarketBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = ref.watch(gameProvider)!.state.marketClosed;
    return PixelScene(
      key: const ValueKey('market-backdrop'),
      backdrop: true,
      framed: false,
      focus: const Offset(.5, .55),
      painterBuilder: (t) => MarketPainter(t, closed: closed),
    );
  }
}

/// แผ่นรายละเอียดของตลาด: ซื้อวัตถุดิบ · ขาย (ปลา อาหาร) · อุปกรณ์ครัว
enum MarketSheet { buy, sell, tools }

Future<void> showMarketSheet(BuildContext context, MarketSheet kind) {
  final (title, icon) = switch (kind) {
    MarketSheet.buy => ('ซื้อวัตถุดิบ', 'veg'),
    MarketSheet.sell => ('ขายของ', 'coin'),
    MarketSheet.tools => ('อุปกรณ์ครัว', 'fridge'),
  };
  return showDetailSheet<void>(
    context,
    title: title,
    icon: PixelIcon(icon, size: 32),
    builder: (_) => _MarketSheetBody(kind),
  );
}

/// แท็บ "ตลาด" (market ในต้นแบบ): ซื้อวัตถุดิบ ขายปลาในคลัง ขายอาหาร ซื้ออุปกรณ์ครัว
/// หน้าหลักเป็นฉากตลาด + ถาดปุ่ม · รายการซื้อขายเปิดเป็นแผ่นด้านล่าง
/// ทุกการซื้อขายต้องผ่านหน้ายืนยัน · ตลาดปิดตอนเกิดภัย (ซื้อขายไม่ได้)
class MarketTab extends ConsumerWidget {
  const MarketTab({super.key});

  /// อุปกรณ์ครัวที่ขายในตลาด (ตามต้นแบบ: rack, jar, fridge, canner)
  static final kitchenEquipment = [
    for (final id in kKitchenEquipmentOrder) kEquipment[id]!,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final closed = s.marketClosed;
    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);
    bool allows(StoryTarget t) =>
        story == null || Story.allows(story.$1, story.$2, t);
    final canSell =
        allows(StoryTarget.sellFish) || allows(StoryTarget.sellFood);

    final food = s.stock.fold<int>(0, (n, b) => n + b.qty);
    final sellable = e.fishTotal + food;
    // ราคาวันนี้เทียบเมื่อวาน (ไม่มีตัวเลขราคา บอกแค่ทิศทาง)
    var cheaper = 0, dearer = 0;
    for (final g in kIngredients.values) {
      final p = s.prices[g.id] ?? g.basePrice;
      final y = s.prevPrices[g.id] ?? p;
      if (p < y) cheaper++;
      if (p > y) dearer++;
    }

    final chips = <Widget>[
      if (closed)
        SceneChip(
          key: const ValueKey('market-closed-chip'),
          color: const Color(0xE6B42318),
          icon: const PixelIcon('warn', size: 32),
          text: 'ตลาดปิดชั่วคราว',
          below: Text('ซื้อขายไม่ได้', style: glassText()),
          onTap: () => showMarketSheet(context, MarketSheet.buy),
        )
      else
        SceneChip(
          key: const ValueKey('market-prices'),
          icon: const PixelIcon('veg', size: 32),
          text: 'ราคาวันนี้',
          below: Text(
            cheaper + dearer == 0
                ? 'เท่าเมื่อวาน'
                : 'ถูกลง $cheaper · แพงขึ้น $dearer',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: glassText(color: const Color(0xFFFFE7A8)),
          ),
          onTap: () => showMarketSheet(context, MarketSheet.buy),
        ),
      if (sellable > 0 && canSell)
        SceneChip(
          key: const ValueKey('market-sellable'),
          icon: const PixelIcon('coin', size: 32),
          text: 'ขายได้',
          below: Text(
            [
              if (e.fishTotal > 0) 'ปลา ${e.fishTotal}',
              if (food > 0) 'อาหาร $food',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: glassText(color: const Color(0xFFFFE7A8)),
          ),
          onTap: () => showMarketSheet(context, MarketSheet.sell),
        ),
    ];

    final round = ScenePage.round(context);
    final tray = ActionTray(
      leading: Spotlight(
        on: next == StoryTarget.sellFish || next == StoryTarget.sellFood,
        child: RoundAction(
          key: const ValueKey('market-sell'),
          icon: const PixelIcon('coin', size: 32),
          label: 'ขาย',
          labelOnScene: true,
          diameter: round,
          color: sellable > 0 ? DsColors.accent : DsColors.surface,
          tooltip: 'ขายปลาและอาหาร',
          onPressed: canSell
              ? () => showMarketSheet(context, MarketSheet.sell)
              : null,
        ),
      ),
      primary: TipSpot(
        screen: GameScreen.market,
        child: Spotlight(
          on: next == StoryTarget.buyIngredient,
          child: KeyedSubtree(
            key: const ValueKey('primary-market'),
            child: TrayPrimary(
              key: const ValueKey('market-buy'),
              label: closed ? 'ตลาดปิด' : 'ซื้อวัตถุดิบ',
              icon: const PixelIcon('garlic', size: 32),
              note: closed ? 'ใช้เสบียงที่เตรียมไว้' : 'ราคาเปลี่ยนทุกวัน',
              onPressed: allows(StoryTarget.buyIngredient)
                  ? () => showMarketSheet(context, MarketSheet.buy)
                  : null,
            ),
          ),
        ),
      ),
      trailing: Spotlight(
        on: next == StoryTarget.buyTool,
        child: RoundAction(
          key: const ValueKey('market-tools'),
          icon: const PixelIcon('fridge', size: 32),
          label: 'อุปกรณ์',
          labelOnScene: true,
          diameter: round,
          tooltip: 'อุปกรณ์ครัว (ราวตาก โหล ตู้เย็น หม้อบรรจุ)',
          onPressed: allows(StoryTarget.buyTool)
              ? () => showMarketSheet(context, MarketSheet.tools)
              : null,
        ),
      ),
    );
    return ScenePage(chips: chips, tray: tray);
  }
}

/// เนื้อในแผ่นของตลาด: รายการเดิม (การ์ดวัตถุดิบ ขายปลา ขายอาหาร อุปกรณ์)
class _MarketSheetBody extends ConsumerWidget {
  const _MarketSheetBody(this.kind);
  final MarketSheet kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    Widget ingredientPanel() => WoodPanel(
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
    Widget sellFishPanel() => WoodPanel(
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
    Widget sellFoodPanel() => WoodPanel(
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
    Widget toolPanel() => WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

    var sections = switch (kind) {
      MarketSheet.buy => [(StoryTarget.buyIngredient, ingredientPanel)],
      MarketSheet.sell => [
        (StoryTarget.sellFish, sellFishPanel),
        (StoryTarget.sellFood, sellFoodPanel),
      ],
      MarketSheet.tools => [(StoryTarget.buyTool, toolPanel)],
    };
    if (story != null) {
      // เนื้อเรื่อง: แสดงเฉพาะส่วนที่บทนี้ใช้ ส่วนที่ต้องกดต่อไปอยู่บนสุด
      final (p, ge) = story;
      sections = [
        for (final x in sections)
          if (Story.allows(p, ge, x.$1)) x,
      ]..sort((a, b) => (a.$1 == next ? 0 : 1) - (b.$1 == next ? 0 : 1));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (closed) _ClosedBanner(engine: e),
        for (final x in sections) x.$2(),
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
            footerStyle: closed
                ? PixelButtonStyle.wood
                : PixelButtonStyle.green,
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
                        fontSize: 13,
                        color: AquaColors.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    arrow,
                    style: TextStyle(
                      fontSize: 13,
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
      PixelButtonStyle.green => (AquaColors.water, AquaColors.paper),
      _ => (AquaColors.creamDark, AquaColors.textSoft),
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
