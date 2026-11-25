import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/equipment_data.dart';
import '../../data/fish_data.dart';
import '../../data/food_data.dart';
import '../../data/ingredients.dart';
import '../../game/game_engine.dart';
import '../../game/game_state.dart';
import '../design/design_system.dart' show DsColors;
import '../dialogs.dart';
import '../../game/story.dart';
import '../../game/tutorial.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../scenes/room_scenes.dart';
import '../theme/theme.dart';
import '../widgets/game_hud.dart';
import '../widgets/story_gate.dart';
import '../widgets/guide_bars.dart';

/// ฉากคลังเต็มจอ (พื้นหลังของหน้าคลัง) — ของบนชั้นเพิ่ม/ลดตามเสบียงที่มีจริง
class StorageBackdrop extends ConsumerWidget {
  const StorageBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    var meals = 0, preserved = 0;
    for (final b in s.stock) {
      if (kFoods[b.food]!.kind == FoodKind.meal) {
        meals += b.qty;
      } else {
        preserved += b.qty;
      }
    }
    final raw =
        s.fishStock.values.fold<int>(0, (n, v) => n + v) +
        s.inventory.values.fold<int>(0, (n, v) => n + v);
    return PixelScene(
      key: const ValueKey('storage-backdrop'),
      backdrop: true,
      framed: false,
      // ชั้นวางของอยู่ครึ่งบนของฉาก → จุดกลางอยู่สูง ให้ของบนชั้นลงมาพ้นแถบบนและคำแนะนำ
      focus: const Offset(.5, .3),
      painterBuilder: (t) =>
          StoragePainter(t, meals: meals, preserved: preserved, raw: raw),
    );
  }
}

/// แผ่นรายละเอียดของคลัง: อาหาร (กิน ขาย ทิ้ง) · เสบียงฉุกเฉิน · ของสดและอุปกรณ์
enum StorageSheet { food, supply, items }

Future<void> showStorageSheet(BuildContext context, StorageSheet kind) {
  final (title, icon) = switch (kind) {
    StorageSheet.food => ('อาหารในคลัง', 'fry'),
    StorageSheet.supply => ('เสบียงฉุกเฉิน', 'crate'),
    StorageSheet.items => ('ของสดและอุปกรณ์', 'veg'),
  };
  return showDetailSheet<void>(
    context,
    title: title,
    icon: PixelIcon(icon, size: 32),
    builder: (_) => _StorageSheetBody(kind),
  );
}

/// แท็บ "คลัง" (store ในต้นแบบ): เสบียงฉุกเฉิน เป้าหมายเสบียง อาหาร (กิน ขาย ทิ้ง)
/// วัตถุดิบสด และอุปกรณ์ — กิน ขาย ทิ้ง ต้องผ่านหน้ายืนยัน
/// หน้าหลักเป็นฉากคลัง + ถาดปุ่ม · รายการเปิดเป็นแผ่นด้านล่าง
class StorageTab extends ConsumerWidget {
  const StorageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);

    final need = e.supplyNeedDays;
    final after = e.supplyAfterDisaster;
    final short = need > 0 && after < 0;
    final near = s.stock.where((b) => e.isNearExpiry(b) && !e.isExpired(b));
    final expired = s.stock.where(e.isExpired);

    final chips = <Widget>[
      SceneChip(
        key: const ValueKey('storage-supply'),
        color: short ? const Color(0xE6B42318) : DsColors.glass,
        icon: const PixelIcon('crate', size: 32),
        text: 'พอกิน ${fmtNum(e.supplyDays)} วัน',
        below: Text(
          need <= 0
              ? 'ยังไม่มีประกาศภัย'
              : after >= 0
              ? 'พอสำหรับภัย $need วัน'
              : 'ขาดอีก ${fmtNum(-after)} วัน',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: glassText(color: const Color(0xFFFFE7A8)),
        ),
        onTap: () => showStorageSheet(context, StorageSheet.supply),
      ),
      SceneChip(
        key: const ValueKey('storage-food-chip'),
        color: expired.isNotEmpty ? const Color(0xE6B42318) : DsColors.glass,
        icon: const PixelIcon('fry', size: 32),
        text: 'อาหาร ${e.servings} จาน',
        below: Text(
          expired.isNotEmpty
              ? 'หมดอายุ ${expired.length} ชุด'
              : near.isNotEmpty
              ? 'ใกล้เสีย ${near.length} ชุด'
              : (s.stock.isEmpty ? 'ทำได้ที่ครัว' : 'ยังสดอยู่'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: glassText(color: const Color(0xFFFFE7A8)),
        ),
        onTap: () => showStorageSheet(context, StorageSheet.food),
      ),
    ];

    final round = ScenePage.round(context);
    final tray = ActionTray(
      leading: RoundAction(
        key: const ValueKey('storage-supply-btn'),
        icon: const PixelIcon('crate', size: 32),
        label: 'เสบียง',
        labelOnScene: true,
        diameter: round,
        color: short ? const Color(0xFFFFD9D2) : DsColors.primarySoft,
        tooltip: 'อาหารพอกินกี่วัน และเป้าหมายเสบียง',
        onPressed: () => showStorageSheet(context, StorageSheet.supply),
      ),
      primary: TipSpot(
        screen: GameScreen.storage,
        child: Spotlight(
          on:
              next == StoryTarget.eat ||
              next == StoryTarget.sellFood ||
              e.tutorialStep?.target == TutorialTarget.storage,
          child: KeyedSubtree(
            key: const ValueKey('primary-storage'),
            child: TrayPrimary(
              key: const ValueKey('storage-food'),
              label: 'กินอาหาร',
              icon: const PixelIcon('fry', size: 32),
              note: 'อิ่ม ${s.hunger}',
              onPressed: () => showStorageSheet(context, StorageSheet.food),
            ),
          ),
        ),
      ),
      trailing: RoundAction(
        key: const ValueKey('storage-items'),
        icon: const PixelIcon('veg', size: 32),
        label: 'ของสด',
        labelOnScene: true,
        diameter: round,
        tooltip: 'ปลา วัตถุดิบ และอุปกรณ์ในคลัง',
        onPressed: () => showStorageSheet(context, StorageSheet.items),
      ),
    );
    return ScenePage(chips: chips, tray: tray);
  }
}

/// เนื้อในแผ่นของคลัง (รายการเดิม)
class _StorageSheetBody extends ConsumerWidget {
  const _StorageSheetBody(this.kind);
  final StorageSheet kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final isStory = watchStory(ref) != null;

    Widget empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.s),
      child: Muted(text, size: FontSize.body, align: TextAlign.center),
    );

    if (kind == StorageSheet.supply) {
      return _SupplyPanel(
        engine: e,
        // เนื้อเรื่องใช้แค่ตัวคำนวณ "อาหารพอกิน" (ไม่ต้องเลื่อนผ่านเป้าหมายเอง)
        showGoal: !isStory,
        onGoal: (g) => ctl.run((e) => e.setGoal(g)),
      );
    }

    if (kind == StorageSheet.items) {
      final fish = [
        for (final f in kFish.values)
          if ((s.fishStock[f.id] ?? 0) > 0) f,
      ];
      final ingredients = [
        for (final g in kIngredients.values)
          if ((s.inventory[g.id] ?? 0) > 0) g,
      ];
      final equipment = [
        for (final q in kEquipment.values)
          if (s.equipmentCount(q.id) > 0) q,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'วัตถุดิบสด',
                  icon: PixelIcon('veg', size: 28),
                ),
                if (fish.isEmpty && ingredients.isEmpty)
                  empty('ไม่มี')
                else
                  _SlotGrid(
                    children: [
                      for (final f in fish)
                        _Slot(
                          key: ValueKey('raw-${f.id}'),
                          icon: 'f_${f.id}',
                          name: f.name,
                          count: s.fishStock[f.id]!,
                          iconSize: 48,
                        ),
                      for (final g in ingredients)
                        _Slot(
                          key: ValueKey('raw-${g.id}'),
                          icon: g.icon,
                          name: g.name,
                          count: s.inventory[g.id]!,
                        ),
                    ],
                  ),
                const SizedBox(height: Gap.xs),
                const Muted(
                  'วัตถุดิบและปลาสดในคลังไม่หมดอายุ',
                  size: 13,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'อุปกรณ์',
                  icon: PixelIcon('shield', size: 28),
                ),
                if (equipment.isEmpty)
                  empty('ยังไม่มี')
                else
                  _SlotGrid(
                    children: [
                      for (final q in equipment)
                        _Slot(
                          key: ValueKey('equip-${q.id}'),
                          icon: q.icon,
                          name: q.name,
                          count: s.equipmentCount(q.id),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // ---------- อาหาร: กิน / ขาย / ทิ้ง ----------
    final meals = <int>[];
    final preserved = <int>[];
    for (var i = 0; i < s.stock.length; i++) {
      (kFoods[s.stock[i].food]!.kind == FoodKind.meal ? meals : preserved).add(
        i,
      );
    }
    // เนื้อเรื่อง: ชี้ปุ่ม "กิน" ของจานแรกที่กินได้ตามลำดับบนจอ (อาหารสุกก่อน เพราะเสียเร็วกว่า)
    final firstEdible = [
      ...meals,
      ...preserved,
    ].firstWhere((i) => !e.isExpired(s.stock[i]), orElse: () => -1);

    Widget batch(int i) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: TipSpot(
        screen: GameScreen.storage,
        enabled: i == firstEdible,
        child: _BatchRow(
          key: ValueKey('batch-$i'),
          engine: e,
          pointEat: i == firstEdible,
          batch: s.stock[i],
          closed: s.marketClosed,
          onEat: () async {
            final b = s.stock[i];
            final it = kFoods[b.food]!;
            // อิ่มแล้ว → บอกเหตุผลเลย ไม่ต้องถาม (ตามต้นแบบ)
            if (s.hunger >= 100) {
              showResult(context, ctl.run((e) => e.eatStock(i)));
              return;
            }
            final h2 = (s.hunger + it.hunger).clamp(0, 100);
            final e2 = (s.energy + it.energy).clamp(0, 100);
            final ok = await confirmDialog(
              context,
              'กิน${it.name}? ความอิ่ม ${s.hunger} → $h2 · พลังงาน ${s.energy} → $e2 (${it.kcal} kcal, โปรตีน ${it.protein} g)',
              ok: 'กิน',
              icon: PixelIcon(it.icon, size: 56),
            );
            if (ok && context.mounted) {
              showResult(context, ctl.run((e) => e.eatStock(i)));
            }
          },
          onSell: () async {
            final it = kFoods[s.stock[i].food]!;
            if (s.marketClosed) {
              showResult(context, ctl.run((e) => e.sellStock(i)));
              return;
            }
            final ok = await confirmDialog(
              context,
              'ยืนยันขาย${it.name} 1 จาน ได้ ${e.foodSellPrice(it.id)} บาท?',
              icon: PixelIcon(it.icon, size: 56),
            );
            if (ok && context.mounted) {
              showResult(context, ctl.run((e) => e.sellStock(i)));
            }
          },
          onDiscard: () async {
            final b = s.stock[i];
            final it = kFoods[b.food]!;
            final ok = await confirmDialog(
              context,
              'ทิ้ง${it.name} ${b.qty} จาน?',
              ok: 'ทิ้ง',
              danger: true,
              icon: PixelIcon(it.icon, size: 56),
            );
            if (ok && context.mounted) {
              showResult(context, ctl.run((e) => e.discardStock(i)));
            }
          },
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // เนื้อเรื่อง: ซ่อนแผงอาหารที่ว่าง ให้จานที่ต้องกินขึ้นมาบนจอ
        // ไม่มีอาหารสุกแต่มีอาหารถนอม → ซ่อนแผงว่าง ให้ปุ่มกินขึ้นมาบนจอ
        if (meals.isNotEmpty || (!isStory && preserved.isEmpty))
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'อาหารพร้อมรับประทาน',
                  icon: const PixelIcon('fry', size: 28),
                  trailing: Tag('${meals.length} ชุด'),
                ),
                if (meals.isEmpty) empty('ไม่มี'),
                for (final i in meals) batch(i),
              ],
            ),
          ),
        if (!isStory || preserved.isNotEmpty || s.processing.isNotEmpty)
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'อาหารถนอมแล้ว',
                  icon: const PixelIcon('jar', size: 28),
                  trailing: Tag('${preserved.length} ชุด'),
                ),
                if (preserved.isEmpty) empty('ไม่มี'),
                for (final i in preserved) batch(i),
                if (s.processing.isNotEmpty)
                  Muted(
                    'กำลังถนอม ${s.processing.length} ชุด (ดูที่ครัว)',
                    size: FontSize.body,
                    align: TextAlign.center,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// เสบียงฉุกเฉิน (คำนวณจากความอิ่ม) + เป้าหมายเสบียง
class _SupplyPanel extends StatefulWidget {
  const _SupplyPanel({
    required this.engine,
    required this.onGoal,
    this.showGoal = true,
  });
  final GameEngine engine;
  final ValueChanged<int> onGoal;
  final bool showGoal;

  @override
  State<_SupplyPanel> createState() => _SupplyPanelState();
}

class _SupplyPanelState extends State<_SupplyPanel> {
  /// ส่วนตั้งเป้าหมาย (ไม่จำเป็นต่อการเล่น) พับไว้ก่อน
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.engine;
    final showGoal = widget.showGoal;
    final onGoal = widget.onGoal;
    final s = e.state;
    final need = e.supplyNeedDays;
    final after = e.supplyAfterDisaster;
    final reached = e.goalReached;
    return WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'เสบียงฉุกเฉิน',
            icon: PixelIcon('crate', size: 28),
          ),
          // ตัวเลขหลักตัวเดียว: อาหารพอกินกี่วัน
          Text(
            'อาหารพอกิน ${fmtNum(e.supplyDays)} วัน',
            key: const ValueKey('supply-days'),
            style: const TextStyle(
              color: AquaColors.text,
              fontWeight: FontWeight.w700,
              fontSize: FontSize.title,
            ),
          ),
          if (need > 0)
            Text(
              after >= 0
                  ? 'ภัยครั้งถัดไปนาน $need วัน → พอแล้ว ✓'
                  : 'ภัยครั้งถัดไปนาน $need วัน → ยังขาดอีก ${fmtNum(-after)} วัน',
              key: const ValueKey('supply-after'),
              style: TextStyle(
                color: after >= 0 ? AquaColors.ok : AquaColors.bad,
                fontWeight: FontWeight.w700,
                fontSize: FontSize.label,
              ),
            )
          else
            const Muted('ยังไม่มีประกาศภัย', size: FontSize.body),
          const SizedBox(height: Gap.xs),
          Muted(
            'มีอาหาร ${e.servings} จาน · ความอิ่มลดวันละ $kHungerPerDay ต้องกด "กิน" เองเมื่อหิว',
            size: 13,
          ),
          if (showGoal) ...[
            const SizedBox(height: Gap.s),
            PixelButton(
              key: const ValueKey('goal-toggle'),
              label: _open
                  ? 'ซ่อนเป้าหมายเสบียง'
                  : 'เป้าหมายเสบียง (${s.goal} วัน)',
              icon: PixelGlyph(
                _open ? Glyph.cross : Glyph.arrowRight,
                size: 16,
                color: AquaColors.paper,
              ),
              style: PixelButtonStyle.wood,
              expand: true,
              onPressed: () => setState(() => _open = !_open),
            ),
          ],
          if (showGoal && _open) ...[
            const SizedBox(height: Gap.s),
            const Muted(
              'ตั้งเป้าเองเพื่อดูแถบความคืบหน้า (ไม่มีผลกับเกม)',
              size: 13,
            ),
            const SizedBox(height: Gap.xs),
            Row(
              children: [
                for (var i = 0; i < kSupplyGoals.length; i++) ...[
                  if (i > 0) const SizedBox(width: Gap.xs),
                  Expanded(
                    child: PixelButton(
                      key: ValueKey('goal-${kSupplyGoals[i]}'),
                      label: '${kSupplyGoals[i]} วัน',
                      style: s.goal == kSupplyGoals[i]
                          ? PixelButtonStyle.green
                          : PixelButtonStyle.wood,
                      onPressed: () => onGoal(kSupplyGoals[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Gap.s),
            PixelBar(
              value: e.goalProgressPct,
              color: reached ? AquaColors.grass : AquaColors.gold,
              height: 20,
            ),
            const SizedBox(height: Gap.xs),
            Bold(
              reached
                  ? 'ถึงเป้าหมาย ${s.goal} วันแล้ว'
                  : 'ขาดอีก ${fmtNum(e.goalShortfall)} วันจึงถึงเป้า',
              key: const ValueKey('goal-status'),
              color: reached ? AquaColors.ok : AquaColors.text,
            ),
            const SizedBox(height: Gap.xs),
            const Muted(
              'ประโยชน์: กันขาดอาหารช่วงภัย รักษาสุขภาพ ลดการพึ่งตลาดที่อาจปิด ใช้ช่วงฟื้นฟู',
              size: 13,
            ),
          ],
        ],
      ),
    );
  }
}

/// อาหาร 1 ล็อต: ไอคอน ชื่อ ความสด คุณค่า + ปุ่ม กิน / ขาย / ทิ้ง
class _BatchRow extends StatelessWidget {
  const _BatchRow({
    super.key,
    required this.engine,
    required this.batch,
    required this.closed,
    required this.onEat,
    required this.onSell,
    required this.onDiscard,
    this.pointEat = false,
  });

  final GameEngine engine;

  /// เนื้อเรื่อง: ชี้ปุ่มกินของล็อตนี้
  final bool pointEat;
  final StockBatch batch;
  final bool closed;
  final VoidCallback onEat;
  final VoidCallback onSell;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final it = kFoods[batch.food]!;
    final fr = engine.freshness(batch);
    final expired = fr == Freshness.expired;
    final fresh = expired
        ? fr.label
        : '${fr.label} · เหลือ ${engine.daysLeft(batch)} วัน';
    return PaperCard(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelIcon(it.icon, size: 44),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bold('${it.name} x${batch.qty}', size: FontSize.label),
                    const SizedBox(height: 2),
                    Tag(
                      fresh,
                      size: 13,
                      color: Color(fr.color),
                      textColor: fr == Freshness.near
                          ? AquaColors.ink
                          : Colors.white,
                    ),
                    const SizedBox(height: 3),
                    Tooltip(
                      message:
                          'พลังงาน +${it.energy} · ${it.kcal} kcal · โปรตีน ${it.protein} g${it.coolable ? ' · เก็บในตู้เย็นได้ (เสียช้าลง)' : ''}',
                      triggerMode: TooltipTriggerMode.longPress,
                      child: Muted('อิ่ม +${it.hunger} ต่อจาน', size: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EatGate(
                  point: pointEat,
                  child: PixelButton(
                    label: 'กิน',
                    style: PixelButtonStyle.green,
                    onPressed: expired ? null : onEat,
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: StoryGate(
                  target: StoryTarget.sellFood,
                  child: PixelButton(
                    label: closed ? 'ปิด' : 'ขาย',
                    style: PixelButtonStyle.wood,
                    below: CoinTag(
                      engine.foodSellPrice(batch.food),
                      boxed: true,
                      size: FontSize.small,
                    ),
                    onPressed: expired ? null : onSell,
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: StoryGate(
                  target: StoryTarget.sellFood,
                  child: PixelButton(
                    label: 'ทิ้ง',
                    style: PixelButtonStyle.danger,
                    onPressed: onDiscard,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ตาราง 3 คอลัมน์ สำหรับของในคลัง (ชื่ออุปกรณ์ยาว จึงไม่ใช้ 4 คอลัมน์)
class _SlotGrid extends StatelessWidget {
  const _SlotGrid({required this.children});
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

/// ช่องของ 1 ชนิด: ไอคอน ชื่อ จำนวน
class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.icon,
    required this.name,
    required this.count,
    this.iconSize = 36,
  });

  final String icon;
  final String name;
  final int count;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name $count',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            PaperCard(
              padding: const EdgeInsets.fromLTRB(3, 8, 3, 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 36,
                    child: Center(child: PixelIcon(icon, size: iconSize)),
                  ),
                  const SizedBox(height: 2),
                  Bold(name, size: 13, maxLines: 2, align: TextAlign.center),
                ],
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Tag('x$count', size: 12, color: AquaColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}

/// ปุ่มกิน: เนื้อเรื่องล็อกก่อนบทครัว และชี้เฉพาะล็อตแรกที่กินได้
class _EatGate extends ConsumerWidget {
  const _EatGate({required this.point, required this.child});
  final bool point;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = watchStory(ref);
    if (story == null) return child;
    final (p, e) = story;
    if (point || !Story.allows(p, e, StoryTarget.eat)) {
      return StoryGate(target: StoryTarget.eat, child: child);
    }
    return child;
  }
}
