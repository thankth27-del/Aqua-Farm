import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/fish_data.dart';
import '../../game/story.dart';
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../story_provider.dart';
import '../widgets/story_gate.dart';

/// รายละเอียดปลาก่อนซื้อ + เลือกจำนวน + หน้ายืนยันการซื้อ
class FishDetailScreen extends ConsumerStatefulWidget {
  const FishDetailScreen({super.key, required this.fishId});
  final String fishId;

  @override
  ConsumerState<FishDetailScreen> createState() => _FishDetailScreenState();
}

class _FishDetailScreenState extends ConsumerState<FishDetailScreen> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    // เนื้อเรื่องบท 1: ตั้งจำนวนให้ครบเป้าหมายเลย
    final p = ref.read(storyProvider);
    final s = ref.read(gameProvider)!.state;
    if (p != null && p.chapter == 1 && s.pond.length < kStoryPondFish) {
      _qty = kStoryPondFish - s.pond.length;
    }
  }

  Future<void> _buy(FishSpec f) async {
    final s = ref.read(gameProvider)!.state;
    final total = f.buyPrice * _qty;
    final ok = await confirmDialog(
      context,
      'ยืนยันซื้อ${f.name} $_qty ตัว รวม $total บาท? (เงินคงเหลือ ${s.money - total} บาท)',
      icon: PixelIcon('f_${f.id}', size: 72),
    );
    if (!ok || !mounted) return;
    final r = ref.read(gameProvider.notifier).run((e) => e.buyFish(f.id, _qty));
    showResult(context, r);
    if (r.ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider)!.state;
    final f = kFish[widget.fishId]!;
    final free = kPondCapacity - s.pond.length;
    final total = f.buyPrice * _qty;

    final String? problem = s.marketClosed
        ? 'ตลาดปิดชั่วคราว ซื้อไม่ได้'
        : _qty > free
        ? 'พื้นที่ในบ่อไม่พอ'
        : s.money < total
        ? 'เงินไม่พอ'
        : null;

    return Scaffold(
      bottomNavigationBar: WoodPlank(
        padding: EdgeInsets.fromLTRB(
          Gap.m,
          Gap.m,
          Gap.m,
          Gap.m + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PixelIconButton(
                  key: const ValueKey('qty-minus'),
                  icon: const PixelGlyph(
                    Glyph.minus,
                    size: 18,
                    color: AquaColors.paper,
                  ),
                  tooltip: 'ลดจำนวน',
                  style: PixelButtonStyle.water,
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                ),
                SizedBox(
                  width: 56,
                  child: Center(
                    child: AnimatedCount(
                      value: _qty,
                      duration: const Duration(milliseconds: 200),
                      builder: (_, v) => OutlinedText(
                        '$v',
                        key: const ValueKey('qty'),
                        size: FontSize.big,
                        color: AquaColors.paper,
                      ),
                    ),
                  ),
                ),
                PixelIconButton(
                  key: const ValueKey('qty-plus'),
                  icon: const PixelGlyph(
                    Glyph.plus,
                    size: 18,
                    color: AquaColors.paper,
                  ),
                  tooltip: 'เพิ่มจำนวน',
                  style: PixelButtonStyle.water,
                  onPressed: _qty < max(1, free)
                      ? () => setState(() => _qty++)
                      : null,
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'รวม',
                      style: TextStyle(
                        color: AquaColors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AnimatedCount(
                      value: total,
                      duration: const Duration(milliseconds: 300),
                      builder: (_, v) =>
                          CoinTag(v, boxed: true, size: FontSize.label),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Gap.s),
            Row(
              children: [
                Tag(
                  'บ่อว่าง $free',
                  color: AquaColors.paper,
                  icon: const PixelIcon('drop', size: 16),
                ),
                const SizedBox(width: Gap.s),
                Tag(
                  '${s.money}',
                  color: AquaColors.paper,
                  icon: const PixelIcon('coin', size: 16),
                ),
                const SizedBox(width: Gap.s),
                if (problem != null)
                  Expanded(
                    child: Tag(
                      problem,
                      color: AquaColors.red,
                      textColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.m),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PixelButton(
                    label: 'ยกเลิก',
                    style: PixelButtonStyle.wood,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  flex: 3,
                  child: StoryGate(
                    target: StoryTarget.buyFish,
                    child: PixelButton(
                      label: 'ซื้อปลา',
                      icon: const PixelIcon('coin', size: 24),
                      onPressed: problem == null ? () => _buy(f) : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: GrassBackground(
        child: SafeArea(
          bottom: false,
          child: TabScroll(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: PixelButton(
                  label: 'กลับร้านปลา',
                  icon: const PixelGlyph(
                    Glyph.arrowRight,
                    flipX: true,
                    size: 18,
                    color: AquaColors.paper,
                  ),
                  style: PixelButtonStyle.wood,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: Gap.m),
              PageHeader(
                scene: PixelScene(
                  painterBuilder: (t) => PondPainter(
                    t,
                    const PondSceneData(
                      fish: [],
                      water: 100,
                      o2: 60,
                      fed: false,
                    ),
                  ),
                  overlay: Center(
                    child: BounceIn(
                      child: Bob(
                        dx: 6,
                        dy: 4,
                        period: const Duration(milliseconds: 2200),
                        child: PixelIcon('f_${f.id}', size: 170),
                      ),
                    ),
                  ),
                ),
                title: f.name,
              ),
              PaperCard(
                child: Text(
                  f.forWho,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: FontSize.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: Gap.m),
              WoodPanel(
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: Gap.s,
                      crossAxisSpacing: Gap.s,
                      childAspectRatio: 2.3,
                      children: [
                        _Stat(
                          icon: const PixelIcon('coin', size: 26),
                          label: 'ราคาซื้อ / ตัว',
                          value: '${f.buyPrice}฿',
                        ),
                        _Stat(
                          icon: const PixelIcon('coin', size: 26),
                          label: 'ขายเมื่อโตเต็มวัย',
                          value:
                              '${ref.watch(gameProvider)!.engine.fishSellPrice(f.id)}฿',
                        ),
                        _Stat(
                          icon: const PixelIcon('cal', size: 26),
                          label: 'โต (อาหารพอดี)',
                          value: '~${f.daysToGrow} วัน',
                        ),
                        _Stat(
                          icon: const PixelGlyph(
                            Glyph.arrowRight,
                            size: 20,
                            color: AquaColors.grass,
                          ),
                          label: 'ความเร็วเติบโต',
                          value: f.growthLabel,
                        ),
                        _Stat(
                          icon: const PixelIcon('shield', size: 26),
                          label: 'ทนทาน / ทนน้ำ',
                          valueWidget: _Stars(f.toughness),
                          value: '${f.toughness}/5',
                        ),
                        _Stat(
                          icon: const PixelIcon('bub', size: 26),
                          label: 'ต้องการออกซิเจน',
                          value: 'อย่างน้อย ${f.o2Need}%',
                        ),
                        _Stat(
                          icon: const PixelIcon('fry', size: 26),
                          label: 'อาหาร / วัน',
                          value: '${f.feed} หน่วย',
                        ),
                        _Stat(
                          icon: const PixelIcon('tomyum', size: 26),
                          label: 'ผลผลิตอาหาร',
                          value: '${f.yieldDishes} จาน/ตัว',
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.m),
                    _ProCon(ok: true, text: f.pros),
                    const SizedBox(height: Gap.s),
                    _ProCon(ok: false, text: f.cons),
                  ],
                ),
              ),
              const Muted(
                'ค่าตัวเลขเป็นค่าจำลองในเกมเพื่อความสมดุล',
                color: AquaColors.cream,
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });
  final Widget icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      child: ExcludeSemantics(
        child: PaperCard(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: icon)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AquaColors.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    valueWidget ??
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: FontSize.body,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1),
            child: PixelGlyph(
              Glyph.star,
              size: 14,
              color: i < n ? AquaColors.gold : AquaColors.creamDark,
              outline: i < n ? AquaColors.ink : AquaColors.textSoft,
            ),
          ),
      ],
    );
  }
}

class _ProCon extends StatelessWidget {
  const _ProCon({required this.ok, required this.text});
  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(width: 24, child: passGlyph(ok, size: 16)),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: FontSize.body,
              color: ok ? AquaColors.ok : AquaColors.bad,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
