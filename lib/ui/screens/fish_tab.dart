import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/fish_data.dart';
import '../../game/tutorial.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import 'fish_detail_screen.dart';

/// แท็บ "ปลา": บ่อปลา และร้านปลา
class FishTab extends ConsumerStatefulWidget {
  const FishTab({super.key, this.onShopChanged});

  /// แจ้งว่ากำลังดูร้านปลา (true) หรือบ่อปลา (false) — ใช้กับบทเรียน
  final ValueChanged<bool>? onShopChanged;

  @override
  ConsumerState<FishTab> createState() => _FishTabState();
}

class _FishTabState extends ConsumerState<FishTab> {
  bool _shop = false;

  void _set(bool shop) {
    setState(() => _shop = shop);
    widget.onShopChanged?.call(shop);
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(gameProvider)!.engine.tutorialStep?.target;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
          child: Row(
            children: [
              Expanded(
                child: Spotlight(
                  on: _shop && target == TutorialTarget.pond,
                  child: PixelButton(
                    label: 'บ่อปลา',
                    icon: const PixelIcon('drop', size: 24),
                    style: _shop
                        ? PixelButtonStyle.wood
                        : PixelButtonStyle.gold,
                    onPressed: () => _set(false),
                  ),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                child: Spotlight(
                  on: !_shop && target == TutorialTarget.shop,
                  child: PixelButton(
                    label: 'ร้านปลา',
                    icon: const PixelIcon('f_nila', size: 30),
                    style: _shop
                        ? PixelButtonStyle.gold
                        : PixelButtonStyle.wood,
                    onPressed: () => _set(true),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _shop ? const _FishShop() : const _PondView()),
      ],
    );
  }
}

class _PondView extends ConsumerWidget {
  const _PondView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final ws = e.waterStatus;
    final wc = Color(ws.color);
    final fu = e.feedUnit;
    final scene = PondSceneData.fromState(s);

    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        // ฉากบ่อใต้น้ำ + ป้ายจำนวนปลา/คุณภาพน้ำ
        Padding(
          padding: const EdgeInsets.only(bottom: Gap.m),
          child: PixelScene(
            painterBuilder: (t) => PondPainter(t, scene),
            overlay: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Tag(
                  '${s.pond.length}/$kPondCapacity',
                  color: AquaColors.paper,
                  icon: const PixelIcon('f_nila', size: 22),
                ),
              ),
            ),
          ),
        ),
        WoodPanel(
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
                childAspectRatio: 1.45,
                children: [
                  _Gauge('NH3', s.ammonia.toStringAsFixed(2), 'ppm'),
                  _Gauge('NO2', s.nitrite.toStringAsFixed(2), 'ppm'),
                  _Gauge('NO3', s.nitrate.toStringAsFixed(1), 'ppm'),
                  _Gauge(
                    'อุณหภูมิ',
                    s.temp.toStringAsFixed(1),
                    '°C',
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
                    icon: const PixelIcon('bub', size: 16),
                  ),
                  _Gauge(
                    'กรองชีวภาพ',
                    '${s.bio}',
                    '%',
                    icon: const PixelIcon('filt', size: 16),
                  ),
                ],
              ),
              const SizedBox(height: Gap.s),
              const Muted(
                'ค่าน้ำเป็นแบบจำลองเพื่อการเรียนรู้ ไม่ใช่คำแนะนำการเลี้ยงจริง',
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
              SectionTitle(
                'ให้อาหาร',
                icon: const PixelIcon('fry', size: 28),
                trailing: s.fed > 0
                    ? Tag(
                        'ให้แล้ว',
                        color: AquaColors.leafLight,
                        icon: passGlyph(true, size: 12),
                      )
                    : Tag('$fu หน่วย/วัน'),
              ),
              Row(
                children: [
                  for (final (lv, name) in const [
                    (1, 'น้อย'),
                    (2, 'พอดี'),
                    (3, 'มาก'),
                  ]) ...[
                    Expanded(
                      child: PixelButton(
                        label: name,
                        style: lv == 2
                            ? PixelButtonStyle.green
                            : PixelButtonStyle.water,
                        below: CoinTag(
                          e.feedCost(lv),
                          boxed: true,
                          size: FontSize.small,
                        ),
                        onPressed: s.fed > 0
                            ? null
                            : () => showResult(
                                context,
                                ctl.run((e) => e.feed(lv)),
                              ),
                      ),
                    ),
                    if (lv < 3) const SizedBox(width: Gap.s),
                  ],
                ],
              ),
              const SizedBox(height: Gap.m),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'เปลี่ยนน้ำ',
                      icon: const PixelIcon('drop', size: 22),
                      style: PixelButtonStyle.water,
                      below: const CoinTag(
                        kChangeWaterCost,
                        boxed: true,
                        size: FontSize.small,
                      ),
                      onPressed: () =>
                          showResult(context, ctl.run((e) => e.changeWater())),
                    ),
                  ),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: PixelButton(
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
              const SizedBox(height: Gap.m),
              PixelButton(
                label: 'จับปลา',
                icon: const PixelIcon('net', size: 28),
                trailing: Tag(
                  '${e.matureCount}',
                  color: AquaColors.paper,
                  icon: const PixelIcon('f_nila', size: 20),
                ),
                tooltip: 'ปลาที่โตพอจับ ${e.matureCount} ตัว',
                expand: true,
                onPressed: () =>
                    showResult(context, ctl.run((e) => e.catchFish())),
              ),
            ],
          ),
        ),
        WoodPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(
                'ปลาในบ่อ',
                icon: const PixelIcon('f_nila', size: 30),
                trailing: Tag('${s.pond.length}/$kPondCapacity'),
              ),
              if (s.pond.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Gap.s),
                  child: Muted(
                    'ยังไม่มีปลา ไปซื้อที่ร้านปลา',
                    size: FontSize.body,
                    align: TextAlign.center,
                  ),
                ),
              for (var i = 0; i < s.pond.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: _FishRow(
                    type: s.pond[i].type,
                    growth: s.pond[i].growth,
                    mature: s.pond[i].mature,
                    health: s.pond[i].health.round(),
                    phase: i / 5,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// ช่องค่าน้ำ 1 ค่า
class _Gauge extends StatelessWidget {
  const _Gauge(this.label, this.value, this.unit, {this.icon});
  final String label;
  final String value;
  final String unit;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value $unit',
      child: ExcludeSemantics(
        child: PaperCard(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
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
                        fontSize: 12,
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
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AquaColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปลา 1 ตัวในบ่อ: ไอคอนว่าย + แถบโต + สุขภาพ
class _FishRow extends StatelessWidget {
  const _FishRow({
    required this.type,
    required this.growth,
    required this.mature,
    required this.health,
    required this.phase,
  });

  final String type;
  final int growth;
  final bool mature;
  final int health;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 34,
            child: Center(
              child: Bob(
                dx: 3,
                dy: 2,
                phase: phase,
                period: const Duration(milliseconds: 1600),
                child: PixelIcon('f_$type', size: 44),
              ),
            ),
          ),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Bold(
                        kFish[type]!.name,
                        size: FontSize.small,
                        maxLines: 1,
                      ),
                    ),
                    PixelGlyph(Glyph.heart, size: 12, color: AquaColors.red),
                    const SizedBox(width: 3),
                    Text(
                      '$health',
                      style: const TextStyle(
                        fontSize: FontSize.small,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                PixelBar(
                  value: growth,
                  color: mature ? AquaColors.gold : AquaColors.waterLight,
                  height: 14,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          SizedBox(
            width: 74,
            child: Align(
              alignment: Alignment.centerRight,
              child: mature
                  ? const Tag('พร้อมจับ', color: AquaColors.gold)
                  : Text(
                      '$growth%',
                      style: const TextStyle(
                        fontSize: FontSize.body,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FishShop extends ConsumerWidget {
  const _FishShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    final fish = kFish.values.toList();
    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
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
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Gap.m,
          crossAxisSpacing: Gap.m,
          childAspectRatio: 1.02,
          children: [
            for (var i = 0; i < fish.length; i++)
              Pressable(
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
                      Bold(
                        fish[i].name,
                        size: FontSize.body,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      CoinTag(fish[i].buyPrice, boxed: true),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
