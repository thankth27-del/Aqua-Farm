import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
import '../story_provider.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/story_gate.dart';
import '../widgets/guide_bars.dart';

/// แท็บ "ครัว" (cook ในต้นแบบ): ทำอาหาร 5 เมนู และถนอมอาหาร 4 วิธี
/// ใช้ปลาจากคลัง 1 ตัว + วัตถุดิบ ได้อาหารเท่ากับจำนวนจานของปลาตัวนั้น
class KitchenTab extends ConsumerStatefulWidget {
  const KitchenTab({super.key, this.onOpenTab});

  /// เปิดแท็บอื่น (1 = ปลา, 2 = ตลาด) จากปุ่มบอกทางเมื่อของไม่พอ
  final ValueChanged<int>? onOpenTab;

  @override
  ConsumerState<KitchenTab> createState() => _KitchenTabState();
}

class _KitchenTabState extends ConsumerState<KitchenTab> {
  bool _preserve = false;

  @override
  void initState() {
    super.initState();
    // เนื้อเรื่องบทถนอมอาหาร: เปิดหน้าถนอมเลย
    final story = ref.read(gameProvider.notifier).isStory
        ? ref.read(storyProvider)
        : null;
    if (story != null && story.chapter == 4) _preserve = true;
  }

  @override
  Widget build(BuildContext context) {
    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
          child: Row(
            children: [
              Expanded(
                child: Spotlight(
                  on: _preserve && next == StoryTarget.cook,
                  child: PixelButton(
                    label: 'ทำอาหาร',
                    icon: const PixelIcon('fry', size: 26),
                    style: _preserve
                        ? PixelButtonStyle.wood
                        : PixelButtonStyle.gold,
                    onPressed: () => setState(() => _preserve = false),
                  ),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: StoryGate(
                  target: StoryTarget.preserve,
                  point: false,
                  child: Spotlight(
                    on: !_preserve && next == StoryTarget.preserve,
                    child: PixelButton(
                      label: 'ถนอมอาหาร',
                      icon: const PixelIcon('jar', size: 26),
                      style: _preserve
                          ? PixelButtonStyle.gold
                          : PixelButtonStyle.wood,
                      onPressed: () => setState(() => _preserve = true),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _KitchenView(preserve: _preserve, onOpenTab: widget.onOpenTab),
        ),
      ],
    );
  }
}

class _KitchenView extends ConsumerWidget {
  const _KitchenView({required this.preserve, this.onOpenTab});
  final bool preserve;
  final ValueChanged<int>? onOpenTab;

  /// เหตุผลที่ยังทำไม่ได้ (null = ทำได้)
  static String? _reason(
    GameEngine e,
    Map<String, int> need, {
    String? equipment,
  }) {
    final s = e.state;
    final parts = <String>[
      if (e.fishForCooking.isEmpty) 'ไม่มีปลาในคลัง',
      for (final n in need.entries)
        if ((s.inventory[n.key] ?? 0) < n.value)
          'ขาด${kIngredients[n.key]!.name}',
      if (equipment != null && e.freeCapacity(equipment) <= 0)
        s.equipmentCount(equipment) == 0
            ? 'ยังไม่มี${kEquipment[equipment]!.name}'
            : '${kEquipment[equipment]!.name}ไม่ว่าง',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// ขาดของที่ซื้อได้ที่ตลาด (วัตถุดิบ / อุปกรณ์ถนอม)
  static bool _needsMarket(
    GameEngine e,
    Map<String, int> need, {
    String? equipment,
  }) =>
      need.entries.any((n) => (e.state.inventory[n.key] ?? 0) < n.value) ||
      (equipment != null && e.state.equipmentCount(equipment) == 0);

  /// ข้อความตอนไม่มีปลาในคลัง: บอกว่าทำไมและต้องทำอะไรต่อ
  static String _noFishText(GameEngine e) {
    if (e.state.pond.isEmpty) {
      return 'ไม่มีปลาในคลัง และบ่อยังว่าง ซื้อปลาที่ร้านปลาก่อน';
    }
    if (e.matureCount == 0) {
      return 'ไม่มีปลาในคลัง ปลาในบ่อโตสุด ${e.maxPondGrowth}% จับได้เมื่อโตครบ 100%';
    }
    return 'ไม่มีปลาในคลัง ไปกด "จับปลา" ที่บ่อ (โตครบแล้ว ${e.matureCount} ตัว)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final fish = e.fishForCooking;
    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);

    /// การ์ดที่เนื้อเรื่องชี้ให้กด (สูตรแรกที่ง่ายสุด)
    Widget pick(bool on, StoryTarget target, Widget child) =>
        on && next == target ? StoryGate(target: target, child: child) : child;

    final fishPanel = WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'ปลาที่ใช้',
            icon: const PixelIcon('f_nila', size: 30),
            trailing: Tag('${e.fishTotal} ตัว'),
          ),
          if (fish.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gap.s),
              child: Muted(
                _noFishText(e),
                key: const ValueKey('no-fish'),
                size: FontSize.body,
                align: TextAlign.center,
              ),
            ),
            if (onOpenTab != null)
              PixelButton(
                key: const ValueKey('go-pond'),
                label: 'ไปบ่อปลา',
                icon: const PixelIcon('drop', size: 24),
                style: PixelButtonStyle.water,
                expand: true,
                onPressed: () => onOpenTab!(1),
              ),
          ] else
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                for (final f in kFish.values)
                  if ((s.fishStock[f.id] ?? 0) > 0)
                    _FishChoice(
                      key: ValueKey('cook-fish-${f.id}'),
                      spec: f,
                      count: s.fishStock[f.id]!,
                      selected: f.id == fish,
                      onTap: () => ctl.run((e) {
                        e.setCookFish(f.id);
                        return const ActionResult.ok('');
                      }),
                    ),
              ],
            ),
        ],
      ),
    );

    final fishFirst = story == null && fish.isEmpty;
    return TabScroll(
      listKey: PageStorageKey(preserve ? 'kitchen-pres' : 'kitchen-cook'),
      header: story == null ? 1 : 0,
      decorative: true,
      children: [
        if (story == null)
          PageHeader(
            scene: PixelScene(painterBuilder: RoomPainter.new),
            title: preserve ? 'ถนอมอาหาร' : 'ครัวและสูตรอาหาร',
            icon: PixelIcon(preserve ? 'jar' : 'tomyum', size: 30),
            titleSize: 21,
          ),

        // ---------- ปลาที่ใช้ ----------
        // ไม่มีปลา: แผงนี้ขึ้นก่อน (บอกเหตุผล + ปุ่มไปบ่อ)
        // มีปลา: ไว้ท้าย ให้ปุ่ม "ทำอาหาร" อยู่บนจอ (การ์ดสูตรบอกปลาที่ใช้อยู่แล้ว)
        if (fishFirst) fishPanel,

        if (!preserve)
          // ---------- สูตรอาหาร ----------
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'สูตรอาหาร',
                  icon: PixelIcon('tomyum', size: 28),
                ),
                for (final r in kRecipes.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: pick(
                      r.id == 'fry',
                      StoryTarget.cook,
                      TipSpot(
                        screen: GameScreen.kitchen,
                        enabled: r.id == kRecipes.keys.first,
                        child: _RecipeCard(
                          key: ValueKey('recipe-${r.id}'),
                          food: kFoods[r.id]!,
                          details: [
                            'อิ่ม +${kFoods[r.id]!.hunger}',
                            'เก็บได้ ${kFoods[r.id]!.shelfDays} วัน',
                            'ขาย ${e.foodSellPrice(r.id)} บาท',
                          ],
                          more: [
                            'พลังงาน +${kFoods[r.id]!.energy}',
                            '${kFoods[r.id]!.kcal} kcal',
                            'โปรตีน ${kFoods[r.id]!.protein} g',
                            'ปรุง ${r.minutes} นาที',
                          ].join(' · '),
                          reason: _reason(e, r.need),
                          onMarket: onOpenTab != null && _needsMarket(e, r.need)
                              ? () => onOpenTab!(2)
                              : null,
                          chips: [
                            _fishChip(fish),
                            ..._ingredientChips(r.need, s.inventory),
                          ],
                          action: 'ทำอาหาร',
                          enabled: e.canCook(r.id),
                          onPressed: () =>
                              showResult(context, ctl.run((e) => e.cook(r.id))),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else ...[
          // ---------- วิธีถนอม ----------
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(
                  'วิธีถนอมอาหาร',
                  icon: PixelIcon('jar', size: 28),
                ),
                for (final p in kPreserveMethods.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: pick(
                      p.id == 'dried',
                      StoryTarget.preserve,
                      _RecipeCard(
                        key: ValueKey('preserve-${p.id}'),
                        food: kFoods[p.id]!,
                        title: '${p.name} → ${kFoods[p.id]!.name}',
                        details: [
                          p.description,
                          'ใช้เวลา ${p.days} วัน',
                          'ขาย ${e.foodSellPrice(p.id)} บาท',
                        ],
                        chips: [
                          _fishChip(fish),
                          ..._ingredientChips(p.need, s.inventory),
                          _equipmentChip(
                            kEquipment[p.equipment]!,
                            e.freeCapacity(p.equipment),
                            s.equipmentCount(p.equipment),
                          ),
                        ],
                        action: 'เริ่มถนอม',
                        reason: _reason(e, p.need, equipment: p.equipment),
                        onMarket:
                            onOpenTab != null &&
                                _needsMarket(e, p.need, equipment: p.equipment)
                            ? () => onOpenTab!(2)
                            : null,
                        enabled: e.canPreserve(p.id),
                        onPressed: () => showResult(
                          context,
                          ctl.run((e) => e.startPreserve(p.id)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ---------- ตู้เย็น ---------- (เนื้อเรื่องซ่อน ไม่ต้องเลื่อนผ่าน)
          if (story == null)
            _FridgeStatus(
              owned: s.equipmentCount('fridge') > 0,
              power: s.power,
            ),

          // ---------- กำลังถนอม ----------
          WoodPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(
                  'กำลังถนอม',
                  icon: const PixelIcon('cal', size: 26),
                  trailing: Tag('${s.processing.length} ชุด'),
                ),
                if (s.processing.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Gap.s),
                    child: Muted(
                      'ไม่มี',
                      size: FontSize.body,
                      align: TextAlign.center,
                    ),
                  ),
                for (var i = 0; i < s.processing.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: PaperCard(
                      key: ValueKey('job-$i'),
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      child: Row(
                        children: [
                          PixelIcon(
                            kFoods[s.processing[i].method]!.icon,
                            size: 36,
                          ),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            child: Bold(
                              '${kPreserveMethods[s.processing[i].method]!.name} x${s.processing[i].qty}',
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: Gap.s),
                          Tag(
                            'เหลือ ${s.processing[i].daysLeft} วัน',
                            color: AquaColors.goldPale,
                            icon: const PixelIcon('cal', size: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (!fishFirst) fishPanel,
      ],
    );
  }

  static Widget _fishChip(String fish) => _Chip(
    icon: fish.isEmpty ? 'f_nila' : 'f_$fish',
    text: 'ปลา 1',
    ok: fish.isNotEmpty,
  );

  static List<Widget> _ingredientChips(
    Map<String, int> need,
    Map<String, int> inv,
  ) => [
    for (final n in need.entries)
      _Chip(
        icon: kIngredients[n.key]!.icon,
        text: '${kIngredients[n.key]!.name} ${inv[n.key] ?? 0}/${n.value}',
        ok: (inv[n.key] ?? 0) >= n.value,
      ),
  ];

  static Widget _equipmentChip(EquipmentSpec eq, int free, int total) =>
      _Chip(icon: eq.icon, text: '${eq.name} ว่าง $free/$total', ok: free > 0);
}

/// ป้ายของที่ต้องใช้ — สีแดงเมื่อไม่พอ
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.ok});
  final String icon;
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Tag(
    text,
    size: 13,
    icon: PixelIcon(icon, size: 18),
    color: ok ? AquaColors.creamDark : AquaColors.redPale,
    textColor: ok ? AquaColors.text : AquaColors.redDark,
  );
}

/// ตัวเลือกปลา: ไอคอน ชื่อ จำนวน → ได้กี่จาน
class _FishChoice extends StatelessWidget {
  const _FishChoice({
    super.key,
    required this.spec,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final FishSpec spec;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      label:
          'ใช้${spec.name} มี $count ตัว ได้ ${spec.yieldDishes} จาน${selected ? ' (เลือกอยู่)' : ''}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: PaperCard(
          fill: selected ? AquaColors.goldPale : AquaColors.paper,
          border: selected ? AquaColors.goldDark : AquaColors.woodDark,
          padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelIcon('f_${spec.id}', size: 40),
              const SizedBox(width: Gap.xs),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bold('${spec.name} ($count)', size: 15),
                  Muted('→ ${spec.yieldDishes} จาน', size: 13),
                ],
              ),
              if (selected) ...[
                const SizedBox(width: Gap.xs),
                const PixelGlyph(Glyph.check, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// การ์ดสูตร / วิธีถนอม: ไอคอน ชื่อ รายละเอียด ของที่ต้องใช้ ปุ่มทำ
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    super.key,
    required this.food,
    required this.details,
    required this.chips,
    required this.action,
    required this.enabled,
    required this.onPressed,
    this.title,
    this.more,
    this.reason,
    this.onMarket,
  });

  final FoodSpec food;
  final String? title;
  final List<String> details;

  /// รายละเอียดเพิ่มเติม (แตะค้างที่รายละเอียดเพื่อดู)
  final String? more;

  /// เหตุผลที่ยังทำไม่ได้
  final String? reason;

  /// ปุ่มไปตลาด (เมื่อขาดของที่ซื้อได้ที่ตลาด)
  final VoidCallback? onMarket;
  final List<Widget> chips;
  final String action;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PixelIcon(food.icon, size: 52),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bold(title ?? food.name, size: FontSize.label),
                    const SizedBox(height: 2),
                    if (more == null)
                      Muted(details.join(' · '), size: 13)
                    else
                      Tooltip(
                        message: more!,
                        triggerMode: TooltipTriggerMode.longPress,
                        child: Muted(details.join(' · '), size: 13),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          // ป้ายของที่ต้องใช้กว้างเต็มการ์ด (ชื่ออุปกรณ์ยาว) แล้วปุ่มอยู่ขวาล่าง
          Wrap(spacing: Gap.xs, runSpacing: Gap.xs, children: chips),
          const SizedBox(height: Gap.s),
          if (!enabled && reason != null) ...[
            Text(
              reason!,
              style: const TextStyle(
                color: AquaColors.bad,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: Gap.xs),
          ],
          Row(
            children: [
              if (!enabled && onMarket != null) ...[
                Expanded(
                  child: PixelButton(
                    label: 'ไปตลาด',
                    style: PixelButtonStyle.wood,
                    expand: true,
                    onPressed: onMarket,
                  ),
                ),
                const SizedBox(width: Gap.s),
              ] else
                const Spacer(),
              PixelButton(
                label: action,
                style: PixelButtonStyle.green,
                onPressed: enabled ? onPressed : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// สถานะตู้เย็น (ช่วยให้อาหารสุกเสื่อมช้าลง แต่หยุดทำงานเมื่อไฟดับ)
class _FridgeStatus extends StatelessWidget {
  const _FridgeStatus({required this.owned, required this.power});
  final bool owned;
  final bool power;

  @override
  Widget build(BuildContext context) {
    final (text, color) = !owned
        ? ('ยังไม่มี (ซื้อที่ตลาด)', AquaColors.textSoft)
        : power
        ? ('ทำงาน — อาหารสุกเสื่อมช้าลงครึ่งหนึ่ง', AquaColors.ok)
        : ('ไฟดับ ตู้เย็นหยุดทำงาน!', AquaColors.bad);
    return WoodPanel(
      child: Row(
        children: [
          const PixelIcon('fridge', size: 40),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bold('ตู้เย็น (Refrigeration)'),
                Text(
                  text,
                  key: const ValueKey('fridge-status'),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: FontSize.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
