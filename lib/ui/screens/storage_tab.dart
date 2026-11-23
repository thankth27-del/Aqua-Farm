import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/equipment_data.dart';
import '../../data/fish_data.dart';
import '../../data/food_data.dart';
import '../../data/ingredients.dart';
import '../../game/game_engine.dart';
import '../../game/game_state.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';

/// แท็บ "คลัง" (store ในต้นแบบ): เสบียงฉุกเฉิน เป้าหมายเสบียง อาหาร (กิน ขาย ทิ้ง)
/// วัตถุดิบสด และอุปกรณ์ — กิน ขาย ทิ้ง ต้องผ่านหน้ายืนยัน
class StorageTab extends ConsumerWidget {
  const StorageTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);

    final meals = <int>[];
    final preserved = <int>[];
    for (var i = 0; i < s.stock.length; i++) {
      (kFoods[s.stock[i].food]!.kind == FoodKind.meal ? meals : preserved).add(
        i,
      );
    }

    Widget batch(int i) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: _BatchRow(
        key: ValueKey('batch-$i'),
        engine: e,
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
    );

    Widget empty(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.s),
      child: Muted(text, size: FontSize.body, align: TextAlign.center),
    );

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

    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        PageHeader(
          scene: PixelScene(painterBuilder: RoomPainter.new),
          title: 'คลังสินค้า',
          icon: const PixelIcon('crate', size: 30),
        ),

        _SupplyPanel(engine: e, onGoal: (g) => ctl.run((e) => e.setGoal(g))),

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
}

/// เสบียงฉุกเฉิน (คำนวณจากความอิ่ม) + เป้าหมายเสบียง
class _SupplyPanel extends StatelessWidget {
  const _SupplyPanel({required this.engine, required this.onGoal});
  final GameEngine engine;
  final ValueChanged<int> onGoal;

  @override
  Widget build(BuildContext context) {
    final e = engine;
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
          const Muted('คำนวณจากความอิ่ม ไม่ใช่นับจาน', size: 13),
          const SizedBox(height: Gap.s),
          Wrap(
            spacing: Gap.xs,
            runSpacing: Gap.xs,
            children: [
              Tag('อาหารกินได้ ${e.servings} จาน'),
              Tag('ความอิ่มรวม ${e.supplyHunger} หน่วย'),
              Tag(
                'อยู่ได้ ${fmtNum(e.supplyDays)} วัน (ต้องการ $kHungerPerDay/วัน)',
                color: AquaColors.goldPale,
              ),
              Tag('ภัยครั้งถัดไป ${need > 0 ? '~$need วัน' : '—'}'),
            ],
          ),
          if (need > 0) ...[
            const SizedBox(height: Gap.s),
            Text(
              after >= 0
                  ? 'หลังภัยพิบัติเหลือ ${fmtNum(after)} วัน'
                  : 'ขาดเสบียงอีก ${fmtNum(-after)} วัน',
              key: const ValueKey('supply-after'),
              style: TextStyle(
                color: after >= 0 ? AquaColors.ok : AquaColors.bad,
                fontWeight: FontWeight.w700,
                fontSize: FontSize.label,
              ),
            ),
          ],
          const SizedBox(height: Gap.m),
          const Bold('เป้าหมายเสบียง'),
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
                        ? PixelButtonStyle.gold
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
  });

  final GameEngine engine;
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
                    Muted(
                      'อิ่ม +${it.hunger} · พลังงาน +${it.energy} · ${it.kcal} kcal · โปรตีน ${it.protein} g${it.coolable ? ' · แช่เย็นได้' : ''}',
                      size: 13,
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
                child: PixelButton(
                  label: 'กิน',
                  style: PixelButtonStyle.green,
                  onPressed: expired ? null : onEat,
                ),
              ),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: PixelButton(
                  label: closed ? 'ปิด' : 'ขาย',
                  style: closed ? PixelButtonStyle.wood : PixelButtonStyle.gold,
                  below: CoinTag(
                    engine.foodSellPrice(batch.food),
                    boxed: true,
                    size: FontSize.small,
                  ),
                  onPressed: expired ? null : onSell,
                ),
              ),
              const SizedBox(width: Gap.xs),
              Expanded(
                child: PixelButton(
                  label: 'ทิ้ง',
                  style: PixelButtonStyle.danger,
                  onPressed: onDiscard,
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
