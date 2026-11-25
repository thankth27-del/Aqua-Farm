import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/fish_data.dart';
import '../../game/tutorial.dart';
import '../design/design_system.dart' show DsColors;
import '../dialogs.dart';
import '../../game/story.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../../game/game_engine.dart';
import '../../game/game_state.dart';
import '../scenes/fish_swim.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/feed_choice.dart';
import '../widgets/game_hud.dart';
import '../widgets/story_gate.dart';
import '../widgets/guide_bars.dart';
import 'fish_detail_screen.dart';

/// ฉากบ่อใต้น้ำเต็มจอ (พื้นหลังของหน้าบ่อ) — ปลาว่ายจำตำแหน่งตัวเองไว้ตลอดอายุฉาก
class PondBackdrop extends ConsumerStatefulWidget {
  const PondBackdrop({super.key});

  @override
  ConsumerState<PondBackdrop> createState() => _PondBackdropState();
}

class _PondBackdropState extends ConsumerState<PondBackdrop> {
  final _swim = PondSwim();

  @override
  Widget build(BuildContext context) {
    final scene = PondSceneData.fromState(ref.watch(gameProvider)!.state);
    return PixelScene(
      key: const ValueKey('pond-backdrop'),
      backdrop: true,
      framed: false,
      focus: const Offset(.5, .58),
      painterBuilder: (t) => PondPainter(t, scene, _swim),
    );
  }
}

/// คุณภาพน้ำแบบคำเดียวสำหรับหน้าหลัก: ดี / เริ่มแย่ / อันตราย
String waterWord(WaterStatus ws) => switch (ws) {
  WaterStatus.excellent || WaterStatus.good => 'ดี',
  WaterStatus.warning => 'เริ่มแย่',
  WaterStatus.critical => 'อันตราย',
};

/// แท็บ "ปลา": บ่อปลา และร้านปลา
class FishTab extends ConsumerStatefulWidget {
  const FishTab({super.key, this.onShopChanged, this.initialShop = false});

  /// เปิดที่หน้าร้านปลา (จากแถบ "ตอนนี้ควรทำ")
  final bool initialShop;

  /// แจ้งว่ากำลังดูร้านปลา (true) หรือบ่อปลา (false) — ใช้กับบทเรียน
  final ValueChanged<bool>? onShopChanged;

  @override
  ConsumerState<FishTab> createState() => _FishTabState();
}

class _FishTabState extends ConsumerState<FishTab> {
  late bool _shop = widget.initialShop;

  void _set(bool shop) {
    setState(() => _shop = shop);
    widget.onShopChanged?.call(shop);
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(gameProvider)!.engine.tutorialStep?.target;
    // เนื้อเรื่อง: ชี้ปุ่มสลับบ่อ/ร้านตามสิ่งที่ต้องทำต่อ
    final story = watchStory(ref);
    final next = story == null ? null : Story.nextTarget(story.$1, story.$2);
    final storyShop = next == StoryTarget.buyFish;
    final storyPond = next != null && !storyShop && storyTabOf(next) == 1;
    final toggle = Row(
      children: [
        Expanded(
          child: Spotlight(
            on: _shop && (target == TutorialTarget.pond || storyPond),
            child: PixelButton(
              label: 'บ่อปลา',
              icon: const PixelIcon('drop', size: 24),
              style: _shop ? PixelButtonStyle.wood : PixelButtonStyle.green,
              onPressed: () => _set(false),
            ),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Spotlight(
            on: !_shop && (target == TutorialTarget.shop || storyShop),
            child: PixelButton(
              label: 'ร้านปลา',
              icon: const PixelIcon('f_nila', size: 30),
              style: _shop ? PixelButtonStyle.green : PixelButtonStyle.wood,
              onPressed: () => _set(true),
            ),
          ),
        ),
      ],
    );
    if (!_shop) {
      // หน้าบ่อ: ไม่มีแถบสลับเต็มกว้าง (ให้เห็นฉาก) → ปุ่มกลม "ร้านปลา" ในถาดล่าง
      final shopButton = Spotlight(
        on: target == TutorialTarget.shop || storyShop,
        child: RoundAction(
          key: const ValueKey('open-shop'),
          icon: const PixelIcon('f_nila', size: 32),
          label: 'ร้านปลา',
          labelOnScene: true,
          diameter: ScenePage.round(context),
          color: DsColors.primarySoft,
          onPressed: () => _set(true),
        ),
      );
      return _PondView(shopButton: shopButton, onShop: () => _set(true));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
          child: toggle,
        ),
        const Expanded(child: _FishShop()),
      ],
    );
  }
}

/// แผ่นรายละเอียด: ดูแลบ่อ (ค่าน้ำทุกค่า + ปริมาณอาหาร + เปลี่ยนน้ำ/เติมอากาศ)
Future<void> showPondCareSheet(BuildContext context) {
  return showDetailSheet<void>(
    context,
    title: 'ดูแลบ่อ',
    icon: const PixelIcon('drop', size: 32),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final session = ref.watch(gameProvider)!;
        final e = session.engine;
        final s = session.state;
        final ctl = ref.read(gameProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _waterPanel(e, s),
            WoodPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    'ให้อาหาร',
                    icon: const PixelIcon('fry', size: 28),
                    trailing: s.fed > 0
                        ? Tag(
                            'ให้แล้ว',
                            color: AquaColors.leafLight,
                            icon: passGlyph(true, size: 12),
                          )
                        : Tag('${e.feedUnit} หน่วย/วัน'),
                  ),
                  // เลือกปริมาณ: น้อย/พอดี/มาก พร้อมผลต่อการโตและน้ำเสีย
                  const FeedChoices(),
                  const SizedBox(height: Gap.m),
                  StoryGate(
                    target: StoryTarget.water,
                    child: Row(
                      children: [
                        Expanded(
                          child: PixelButton(
                            key: const ValueKey('change-water'),
                            label: 'เปลี่ยนน้ำ',
                            icon: const PixelIcon('drop', size: 22),
                            style: PixelButtonStyle.water,
                            below: const CoinTag(
                              kChangeWaterCost,
                              boxed: true,
                              size: FontSize.small,
                            ),
                            onPressed: () => showResult(
                              context,
                              ctl.run((e) => e.changeWater()),
                            ),
                          ),
                        ),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: PixelButton(
                            key: const ValueKey('aerate'),
                            label: 'เติมอากาศ',
                            icon: const PixelIcon('bub', size: 22),
                            style: PixelButtonStyle.water,
                            below: const CoinTag(
                              kAerateCost,
                              boxed: true,
                              size: FontSize.small,
                            ),
                            onPressed: () =>
                                showResult(context, ctl.run((e) => e.aerate())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// แผ่นรายละเอียด: ปลาในบ่อทีละตัว + เหตุผลว่าจับได้หรือยัง
Future<void> showPondFishSheet(
  BuildContext context, {
  required VoidCallback onShop,
}) {
  return showDetailSheet<void>(
    context,
    title: 'ปลาในบ่อ',
    icon: const PixelIcon('f_nila', size: 32),
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final session = ref.watch(gameProvider)!;
        final e = session.engine;
        final s = session.state;
        return WoodPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                'ปลา ${s.pond.length}/$kPondCapacity ตัว',
                icon: const PixelIcon('f_nila', size: 30),
              ),
              Muted(
                s.pond.isEmpty
                    ? 'บ่อยังว่าง ซื้อปลาที่ "ร้านปลา" ก่อน'
                    : e.matureCount == 0
                    ? 'ยังจับไม่ได้: ปลาโตสุด ${e.maxPondGrowth}% (จับได้เมื่อโตครบ 100%)'
                    : 'จับปลาที่โตครบ ${e.matureCount} ตัว ไปเก็บในคลังเพื่อทำอาหาร',
                key: const ValueKey('catch-info'),
                size: FontSize.body,
              ),
              const SizedBox(height: Gap.s),
              if (s.pond.isEmpty)
                PixelButton(
                  key: const ValueKey('go-shop'),
                  label: 'ไปร้านปลา',
                  icon: const PixelIcon('f_nila', size: 28),
                  expand: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShop();
                  },
                )
              else
                _FishCards(fish: s.pond, fed: s.fed),
            ],
          ),
        );
      },
    ),
  );
}

/// ค่าน้ำทุกค่า (ใช้ในแผ่น "ดูแลบ่อ")
Widget _waterPanel(GameEngine e, GameState s) {
  final ws = e.pondStatus;
  final wc = Color(ws.color);
  final advice = e.waterAdvice;
  return WoodPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'คุณภาพน้ำ',
          icon: const PixelIcon('drop', size: 28),
          trailing: Tag(
            '${ws.label} ${s.water}%',
            color: wc,
            textColor: AquaColors.ink,
          ),
        ),
        PixelBar(value: s.water, color: wc, height: 22),
        const SizedBox(height: Gap.m),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Gap.s,
          crossAxisSpacing: Gap.s,
          childAspectRatio: 1.25,
          children: [
            _Gauge(
              'แอมโมเนีย',
              s.ammonia.toStringAsFixed(2),
              'ppm',
              level: e.ammoniaLevel,
              help: 'ของเสียจากปลาและเศษอาหาร (NH3) ยิ่งต่ำยิ่งดี',
            ),
            _Gauge(
              'ไนไตรต์',
              s.nitrite.toStringAsFixed(2),
              'ppm',
              level: e.nitriteLevel,
              help: 'ของเสียที่ตัวกรองย่อยมาครึ่งทาง (NO2) ยิ่งต่ำยิ่งดี',
            ),
            _Gauge(
              'ไนเตรต',
              s.nitrate.toStringAsFixed(1),
              'ppm',
              level: e.nitrateLevel,
              help: 'ของเสียที่ย่อยแล้ว (NO3) อันตรายน้อย แต่สะสมได้ เปลี่ยนน้ำเพื่อลด',
            ),
            _Gauge(
              'อุณหภูมิ',
              s.temp.toStringAsFixed(1),
              '°C',
              level: e.tempLevel,
              help: 'น้ำเกิน 31°C ปลาเริ่มเครียด',
              icon: const PixelGlyph(
                Glyph.sun,
                size: 14,
                color: AquaColors.gold,
              ),
            ),
            _Gauge(
              'ออกซิเจน',
              _num(s.o2),
              '%',
              level: e.o2Level,
              help: s.pond.isEmpty
                  ? 'ออกซิเจนในน้ำ ลดลงทุกคืนตามจำนวนปลา'
                  : 'ปลาในบ่อต้องการอย่างน้อย ${e.pondO2Need}% ต่ำกว่านี้ปลาเสียสุขภาพ',
              icon: const PixelIcon('bub', size: 16),
            ),
            _Gauge(
              'ตัวกรอง',
              '${s.bio}',
              '%',
              help: 'ตัวกรองชีวภาพ: แบคทีเรียช่วยย่อยของเสีย โตขึ้นเองทุกวันที่มีปลา',
              icon: const PixelIcon('filt', size: 16),
            ),
          ],
        ),
        if (advice != null) ...[
          const SizedBox(height: Gap.s),
          PaperCard(
            key: const ValueKey('water-advice'),
            fill: AquaColors.goldPale,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Text(
              advice,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: FontSize.body,
                color: AquaColors.text,
              ),
            ),
          ),
        ],
        const SizedBox(height: Gap.xs),
        const Muted(
          'แตะค้างที่การ์ดเพื่อดูคำอธิบาย · สีเหลือง = เริ่มแย่ · สีแดง = อันตราย',
          size: 13,
          align: TextAlign.center,
        ),
        const SizedBox(height: Gap.xs),
        const Muted(
          'ค่าน้ำเป็นแบบจำลองเพื่อการเรียนรู้ ไม่ใช่คำแนะนำการเลี้ยงจริง',
          size: 13,
          align: TextAlign.center,
        ),
      ],
    ),
  );
}

/// หน้า "บ่อปลา": ฉากบ่อเต็มจอ (วาดเป็นพื้นหลังของหน้าเกม) + ป้ายน้ำ/ปลา + ถาดปุ่ม
/// รายละเอียดค่าน้ำและการ์ดปลาเปิดเป็นแผ่นด้านล่าง
class _PondView extends ConsumerWidget {
  const _PondView({required this.shopButton, required this.onShop});

  /// ปุ่มไปร้านปลา
  final Widget shopButton;

  /// ไปหน้าร้านปลา (ตอนบ่อว่าง)
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final target = e.tutorialStep?.target;
    final story = watchStory(ref);
    final storyNext = story == null
        ? null
        : Story.nextTarget(story.$1, story.$2);
    final ws = e.pondStatus;
    final wc = Color(ws.color);
    final danger = ws == WaterStatus.critical;
    final empty = s.pond.isEmpty;
    // จอเตี้ย (มือถือแนวนอน): ป้ายเป็นปุ่มกลมเล็ก ให้ฉากเหลือมากพอ
    final short = ScenePage.short(context);
    final sick = s.pond.where(fishSick).length;

    final water = Spotlight(
      // บทเรียน "ดูการ์ดค่าน้ำ" (หลังให้อาหารแล้ว) · เนื้อเรื่อง "ดูแลน้ำ"
      on:
          (target == TutorialTarget.pond && s.fed > 0) ||
          storyNext == StoryTarget.water,
      child: short
          ? RoundAction(
              key: const ValueKey('pond-water'),
              icon: const PixelIcon('drop', size: 30),
              label: 'น้ำ${waterWord(ws)}',
              labelOnScene: true,
              diameter: 52,
              color: wc,
              tooltip: 'คุณภาพน้ำ ${waterWord(ws)} แตะเพื่อดูค่าน้ำ',
              onPressed: () => showPondCareSheet(context),
            )
          : SceneChip(
              key: const ValueKey('pond-water'),
              color: danger ? const Color(0xE6B42318) : DsColors.glass,
              icon: const PixelIcon('drop', size: 32),
              text: 'น้ำ${waterWord(ws)}',
              semanticLabel: 'คุณภาพน้ำ ${waterWord(ws)} แตะเพื่อดูค่าน้ำ',
              below: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: PixelBar(value: s.water, color: wc, height: 10),
              ),
              onTap: () => showPondCareSheet(context),
            ),
    );

    final note = [
      if (sick > 0) 'ป่วย $sick',
      if (!empty && s.fed == 0) 'หิว',
      if (e.matureCount > 0) 'พร้อมจับ ${e.matureCount}',
    ].join(' · ');
    final Widget fish = short
        ? RoundAction(
            key: const ValueKey('pond-fish'),
            icon: const PixelIcon('f_nila', size: 32),
            label: 'ปลา ${s.pond.length}/$kPondCapacity',
            labelOnScene: true,
            diameter: 52,
            color: sick > 0 ? const Color(0xFFFFB4A8) : DsColors.surface,
            tooltip: 'ปลาในบ่อ ${s.pond.length} ตัว $note แตะเพื่อดูปลา',
            onPressed: () => showPondFishSheet(context, onShop: onShop),
          )
        : SceneChip(
            key: const ValueKey('pond-fish'),
            color: sick > 0 ? const Color(0xE6B42318) : DsColors.glass,
            icon: const PixelIcon('f_nila', size: 32),
            text: 'ปลา ${s.pond.length}/$kPondCapacity',
            semanticLabel: 'ปลาในบ่อ ${s.pond.length} ตัว $note แตะเพื่อดูปลา',
            below: note.isEmpty
                ? null
                : Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: glassText(color: const Color(0xFFFFE7A8)),
                  ),
            onTap: () => showPondFishSheet(context, onShop: onShop),
          );

    // ปุ่มหลัก: บ่อว่าง → ไปร้านปลา · มีปลา → ให้อาหาร (เปิดแผ่นเลือก น้อย/พอดี/มาก)
    final Widget primary;
    if (empty) {
      primary = PixelButton(
        key: const ValueKey('go-shop'),
        label: 'ไปร้านปลา',
        size: short ? PixelButtonSize.normal : PixelButtonSize.large,
        icon: const PixelIcon('f_nila', size: 32),
        below: short ? null : _belowText('บ่อยังว่าง'),
        expand: true,
        onPressed: onShop,
      );
    } else {
      final fed = s.fed > 0;
      primary = Spotlight(
        on: target == TutorialTarget.pond && !fed,
        child: StoryGate(
          target: StoryTarget.feed,
          child: PixelButton(
            key: const ValueKey('feed-main'),
            label: fed ? 'ให้อาหารแล้ว' : 'ให้อาหาร',
            size: short ? PixelButtonSize.normal : PixelButtonSize.large,
            icon: const PixelIcon('fry', size: 32),
            below: short
                ? null
                : _belowText(
                    fed ? 'พรุ่งนี้ให้อีกครั้ง' : 'เลือก น้อย/พอดี/มาก',
                  ),
            tooltip: 'ให้อาหารปลา เลือกปริมาณได้',
            expand: true,
            onPressed: fed ? null : () => showFeedPicker(context),
          ),
        ),
      );
    }

    final tray = ActionTray(
      leading: shopButton,
      primary: TipSpot(
        screen: GameScreen.pond,
        child: KeyedSubtree(
          key: const ValueKey('primary-pond'),
          child: primary,
        ),
      ),
      trailing: StoryGate(
        target: StoryTarget.catchFish,
        hide: true,
        child: RoundAction(
          key: const ValueKey('pond-catch'),
          icon: const PixelIcon('net', size: 32),
          label: 'จับปลา',
          labelOnScene: true,
          diameter: short ? 52 : 60,
          color: e.matureCount > 0 ? DsColors.accent : DsColors.surface,
          tooltip: 'ปลาที่โตพอจับ ${e.matureCount} ตัว',
          onPressed: () => showResult(context, ctl.run((e) => e.catchFish())),
        ),
      ),
    );

    final column = Padding(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (short)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                water,
                const SizedBox(width: Gap.s),
                fish,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: water),
                const SizedBox(width: Gap.s),
                Expanded(child: fish),
              ],
            ),
          const Spacer(),
          tray,
        ],
      ),
    );
    if (!context.rs.useSideNav) return column;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: column,
      ),
    );
  }
}

Widget _belowText(String t) => Text(
  t,
  style: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: DsColors.onAccent.withValues(alpha: .85),
  ),
);

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// ช่องค่าน้ำ 1 ค่า: ชื่อ ค่า และสถานะเป็นสี (แตะค้างดูคำอธิบาย)
class _Gauge extends StatelessWidget {
  const _Gauge(
    this.label,
    this.value,
    this.unit, {
    required this.help,
    this.level,
    this.icon,
  });
  final String label;
  final String value;
  final String unit;
  final String help;

  /// null = ไม่มีเกณฑ์ดี/แย่ (เช่น ตัวกรอง)
  final ValueLevel? level;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final lv = level;
    final low = label == 'ออกซิเจน';
    final (fill, status, color) = switch (lv) {
      ValueLevel.bad => (AquaColors.redPale, 'อันตราย', AquaColors.bad),
      ValueLevel.watch => (
        AquaColors.goldPale,
        low ? 'เริ่มต่ำ' : 'เริ่มสูง',
        AquaColors.goldDark,
      ),
      ValueLevel.good => (AquaColors.paper, 'ปกติ', AquaColors.ok),
      null => (AquaColors.paper, '', AquaColors.textSoft),
    };
    return Tooltip(
      message: help,
      triggerMode: TooltipTriggerMode.longPress,
      child: Semantics(
        label: '$label $value $unit $status',
        child: ExcludeSemantics(
          child: PaperCard(
            fill: fill,
            border: lv == ValueLevel.bad ? AquaColors.bad : AquaColors.woodDark,
            padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[icon!, const SizedBox(width: 3)],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AquaColors.textSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: ' $unit',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AquaColors.textSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.isNotEmpty)
                  Text(
                    status,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ระดับความอิ่มของปลาวันนี้ จากการให้อาหาร (0 = ยังไม่ให้, 1 น้อย, 2 พอดี, 3 มาก)
const _fedLabels = ['หิว', 'น้อย', 'พอดี', 'มาก'];

/// รายชื่อปลาในบ่อ: การ์ดต่อตัว 2 คอลัมน์
class _FishCards extends StatelessWidget {
  const _FishCards({required this.fish, required this.fed});

  final List<PondFish> fish;
  final int fed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - Gap.s) / 2;
        return Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (var i = 0; i < fish.length; i++)
              SizedBox(
                width: w,
                child: _FishCard(
                  key: ValueKey('pond-fish-$i'),
                  fish: fish[i],
                  fed: fed,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// ปลา 1 ตัว: ภาพพิกเซลใหญ่ (โตตามจริง) ชื่อ และแถบสุขภาพ / ความอิ่ม / การโต
/// ปลาป่วยหรือหิวมีป้ายกระพริบที่มุมภาพ
class _FishCard extends StatelessWidget {
  const _FishCard({super.key, required this.fish, required this.fed});

  final PondFish fish;
  final int fed;

  @override
  Widget build(BuildContext context) {
    final spec = kFish[fish.type]!;
    final health = fish.health.round();
    final sick = fishSick(fish);
    final hungry = fed == 0;
    final mature = fish.mature;
    final healthColor = health >= 70
        ? AquaColors.leafLight
        : (health >= 50 ? AquaColors.gold : AquaColors.red);
    // ภาพปลาโตตามการเติบโตจริง (สัดส่วนเดียวกับในบ่อ)
    final iconSize = 66 * fishUnit(fish.growth) / 3 + 22;
    final status = [
      if (sick) 'ป่วย',
      if (hungry) 'หิว',
      if (mature) 'พร้อมจับ',
    ];
    return Semantics(
      label:
          '${spec.name} สุขภาพ $health ความอิ่ม ${_fedLabels[fed.clamp(0, 3)]} '
          'โต ${fish.growth}%${status.isEmpty ? '' : ' (${status.join(' ')})'}',
      child: ExcludeSemantics(
        child: PaperCard(
          fill: sick ? AquaColors.redPale : AquaColors.paper,
          border: sick ? AquaColors.red : AquaColors.woodDark,
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 76,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PixelBox(
                        fill: sick ? AquaColors.waterDeep : AquaColors.water,
                        px: 2,
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: PixelIcon('f_${fish.type}', size: iconSize),
                        ),
                      ),
                    ),
                    // สัญลักษณ์ที่มุมภาพ: ป่วย (ซ้ายบน) หิว (ขวาบน) พร้อมจับ (ซ้ายล่าง)
                    if (sick)
                      const Positioned(
                        top: 4,
                        left: 4,
                        child: Blink(
                          child: _Mark(
                            color: AquaColors.red,
                            child: PixelGlyph(
                              Glyph.cross,
                              size: 12,
                              color: AquaColors.paper,
                            ),
                          ),
                        ),
                      ),
                    if (hungry)
                      const Positioned(
                        top: 4,
                        right: 4,
                        child: Blink(
                          child: _Mark(
                            color: AquaColors.gold,
                            child: PixelIcon('fry', size: 16),
                          ),
                        ),
                      ),
                    if (mature)
                      const Positioned(
                        left: 4,
                        bottom: 4,
                        child: _Mark(
                          color: AquaColors.goldLight,
                          child: PixelGlyph(Glyph.star, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.xs),
              Bold(spec.name, size: FontSize.small, maxLines: 1),
              if (sick || hungry || mature)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      if (sick)
                        const Tag(
                          'ป่วย',
                          size: 12,
                          color: AquaColors.red,
                          textColor: AquaColors.paper,
                        ),
                      if (hungry)
                        const Tag('หิว', size: 12, color: AquaColors.gold),
                      if (mature)
                        const Tag(
                          'พร้อมจับ',
                          size: 12,
                          color: AquaColors.goldLight,
                        ),
                    ],
                  ),
                ),
              _Meter(
                icon: const PixelGlyph(
                  Glyph.heart,
                  size: 11,
                  color: AquaColors.health,
                ),
                label: 'สุขภาพ',
                value: health,
                color: healthColor,
                text: '$health',
              ),
              _Meter(
                icon: const PixelIcon('fry', size: 13),
                label: 'อิ่ม',
                value: (fed.clamp(0, 3) * 100 / 3).round(),
                color: AquaColors.hunger,
                text: _fedLabels[fed.clamp(0, 3)],
                bad: hungry,
              ),
              _Meter(
                icon: const PixelGlyph(
                  Glyph.arrowRight,
                  size: 11,
                  color: AquaColors.waterLight,
                ),
                label: 'โต',
                value: fish.growth,
                color: mature ? AquaColors.gold : AquaColors.waterLight,
                text: '${fish.growth}%',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ค่า 1 อย่าง: ไอคอน ป้าย ตัวเลข และแถบพิกเซลเต็มความกว้าง
class _Meter extends StatelessWidget {
  const _Meter({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.text,
    this.bad = false,
  });

  final Widget icon;
  final String label;
  final int value;
  final Color color;
  final String text;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: 14, child: Center(child: icon)),
              const SizedBox(width: 4),
              Expanded(child: Muted(label, size: 12)),
              Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: bad ? AquaColors.bad : AquaColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          PixelBar(value: value, color: color, height: 10),
        ],
      ),
    );
  }
}

/// กล่องสัญลักษณ์เล็กที่มุมภาพปลา
class _Mark extends StatelessWidget {
  const _Mark({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => PixelBox(
    fill: color,
    px: 2,
    padding: const EdgeInsets.all(3),
    child: child,
  );
}

class _FishShop extends ConsumerWidget {
  const _FishShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    final fish = kFish.values.toList();
    final isStory = watchStory(ref) != null;
    return TabScroll(
      header: isStory ? 0 : 1,
      decorative: true,
      children: [
        // เนื้อเรื่อง: ไม่มีภาพหัวร้าน ให้การ์ดปลาขึ้นมาบนจอเลย
        if (!isStory)
          PageHeader(
            scene: PixelScene(painterBuilder: RoomPainter.new),
            title: 'ร้านปลา',
            icon: const PixelIcon('f_nila', size: 34),
          ),
        Row(
          children: [
            Tag(
              'บ่อ ${s.pond.length}/$kPondCapacity',
              color: AquaColors.paper,
              icon: const PixelIcon('drop', size: 16),
            ),
            const SizedBox(width: Gap.s),
            CoinTag(s.money, boxed: true, size: FontSize.small),
            const SizedBox(width: Gap.s),
            const Expanded(
              child: Muted(
                'แตะเพื่อดูก่อนซื้อ',
                color: AquaColors.cream,
                align: TextAlign.right,
              ),
            ),
          ],
        ),
        if (s.marketClosed)
          const Padding(
            padding: EdgeInsets.only(top: Gap.s),
            child: ToastBubble('ตลาดปิดชั่วคราว ซื้อไม่ได้', bad: true),
          ),
        const SizedBox(height: Gap.m),
        GridView.count(
          // แนวนอน: 3 คอลัมน์ การ์ดเตี้ยลง เห็นแถวแรกโดยไม่ต้องเลื่อน
          crossAxisCount: context.rs.useSplit ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Gap.m,
          crossAxisSpacing: Gap.m,
          childAspectRatio: context.rs.useSplit ? .95 : 1.02,
          children: [
            for (var i = 0; i < fish.length; i++)
              _ShopCardGate(
                recommended: i == 0,
                child: TipSpot(
                  screen: GameScreen.shop,
                  enabled: i == 0,
                  child: Pressable(
                    key: ValueKey('fish-card-${fish[i].id}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FishDetailScreen(fishId: fish[i].id),
                      ),
                    ),
                    child: WoodPanel(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: Bob(
                                dx: 2,
                                dy: 2,
                                phase: i / fish.length,
                                child: PixelIcon('f_${fish[i].id}', size: 84),
                              ),
                            ),
                          ),
                          Bold(fish[i].name, size: FontSize.body, maxLines: 1),
                          const SizedBox(height: 2),
                          CoinTag(fish[i].buyPrice, boxed: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// การ์ดปลาในร้าน: เนื้อเรื่องชี้ปลาตัวแนะนำ (โตเร็ว) ตอนต้องซื้อปลา
class _ShopCardGate extends StatelessWidget {
  const _ShopCardGate({required this.recommended, required this.child});
  final bool recommended;
  final Widget child;

  @override
  Widget build(BuildContext context) => recommended
      ? StoryGate(target: StoryTarget.buyFish, pad: 2, child: child)
      : child;
}
