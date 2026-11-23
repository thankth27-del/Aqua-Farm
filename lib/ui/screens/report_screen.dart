import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/food_data.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';

/// รายงานประจำวัน (หลังกด "จบวัน")
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    final r = s.lastReport!;
    final z = r.event;
    final gradeColor = switch (r.grade) {
      'S' => AquaColors.gold,
      'A' => AquaColors.waterLight,
      _ => AquaColors.paper,
    };

    return Scaffold(
      body: GrassBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              PageHeader(
                scene: PixelScene(
                  painterBuilder: RoomPainter.new,
                  overlay: Align(
                    alignment: const Alignment(-.55, .1),
                    child: BounceIn(
                      from: .2,
                      duration: const Duration(milliseconds: 700),
                      child: Semantics(
                        label: 'เกรด ${r.grade}',
                        child: PixelBox(
                          fill: AquaColors.woodDark,
                          depth: 5,
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                          child: OutlinedText(
                            r.grade,
                            size: 76,
                            color: gradeColor,
                            stroke: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: 'รายงานประจำวัน — วันที่ ${r.day}',
                titleSize: 19,
              ),
              WoodPanel(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: const PixelIcon('coin', size: 30),
                            label: 'รายได้วันนี้',
                            child: _CountUp(r.earned, prefix: '+', suffix: '฿'),
                          ),
                        ),
                        const SizedBox(width: Gap.s),
                        Expanded(
                          child: _Tile(
                            icon: const PixelIcon('coin', size: 30),
                            label: 'เงินคงเหลือ',
                            child: _CountUp(r.money, suffix: '฿'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.s),
                    _Tile(
                      icon: const PixelIcon('drop', size: 28),
                      label: 'น้ำ / ออกซิเจน',
                      value: '${r.water}% / ${r.o2.round()}%',
                    ),
                    const SizedBox(height: Gap.s),
                    _Tile(
                      icon: const PixelIcon('f_nila', size: 34),
                      label: 'ปลาในบ่อ',
                      value:
                          '${r.fish} ตัว${r.died > 0 ? ' (สูญเสีย ${r.died})' : ''}',
                      bad: r.died > 0,
                    ),
                    const SizedBox(height: Gap.s),
                    _Tile(
                      icon: const PixelIcon('fry', size: 30),
                      label: 'เสบียง',
                      value:
                          '${r.servings} จาน · อยู่ได้ ${fmtNum(r.supplyDays)} วัน',
                    ),
                    if (r.done.isNotEmpty || r.spoiled > 0)
                      const SizedBox(height: Gap.s),
                    if (r.done.isNotEmpty)
                      _Note(
                        icon: passGlyph(true, size: 14),
                        text:
                            'ถนอมอาหารเสร็จ: ${r.done.map((d) => '${kFoods[d.food]!.name} x${d.qty}').join(', ')}',
                        color: AquaColors.ok,
                      ),
                    if (r.spoiled > 0)
                      _Note(
                        icon: const PixelIcon('warn', size: 18),
                        text:
                            'อาหารหมดอายุ ${r.spoiled} จาน (ไปทิ้งที่คลังสินค้า)',
                        color: AquaColors.bad,
                      ),
                  ],
                ),
              ),
              if (z != null)
                WoodPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PixelBox(
                        fill: AquaColors.red,
                        depth: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            disasterIcon(z.type, size: 32),
                            const SizedBox(width: Gap.s),
                            Expanded(
                              child: Text(
                                kDisasters[z.type]!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: FontSize.label,
                                ),
                              ),
                            ),
                            Tag(
                              'วันที่ ${z.dayIndex + 1}/${z.duration}',
                              color: AquaColors.goldPale,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Gap.s),
                      Muted(z.text, size: FontSize.body),
                      const SizedBox(height: Gap.s),
                      _Tile(
                        icon: const PixelIcon('shield', size: 28),
                        label: 'ความพร้อมของอุปกรณ์วันนี้',
                        value: '${z.protectionPct}%',
                      ),
                      const SizedBox(height: Gap.s),
                      _Tile(
                        icon: const PixelIcon('f_nila', size: 34),
                        label: 'ปลาที่สูญเสียวันนี้ / สะสม',
                        value:
                            '${z.lost} / ${z.cumulativeLost} (เหลือ ${z.fishAfter} จาก ${z.fishBefore})',
                        bad: z.lost > 0,
                      ),
                      const SizedBox(height: Gap.s),
                      _Tile(
                        icon: const PixelIcon('coin', size: 28),
                        label: 'ค่าเสียหายวันนี้ / สะสม',
                        value: '${z.cost}฿ / ${z.cumulativeCost}฿',
                        bad: z.cost > 0,
                      ),
                      if (z.food > 0 || z.cumulativeFood > 0) ...[
                        const SizedBox(height: Gap.s),
                        _Tile(
                          icon: const PixelIcon('fry', size: 28),
                          label: 'อาหารเสียหายจากน้ำ',
                          value: '${z.food} จาน (สะสม ${z.cumulativeFood})',
                          bad: z.food > 0,
                        ),
                      ],
                      if (z.sandUsed > 0) ...[
                        const SizedBox(height: Gap.s),
                        _Tile(
                          icon: const PixelIcon('sand', size: 28),
                          label: 'กระสอบทรายที่ใช้สะสม',
                          value: '${z.sandUsed}',
                        ),
                      ],
                      if (z.outage)
                        const _Note(
                          icon: PixelIcon('fridge', size: 20),
                          text: 'ไฟดับ — ตู้เย็นหยุดทำงาน อาหารเสียเร็วขึ้น',
                          color: AquaColors.bad,
                        ),
                      if (z.marketClosed)
                        const _Note(
                          icon: PixelIcon('garlic', size: 20),
                          text: 'ตลาดปิด — ซื้อขายไม่ได้ ต้องใช้เสบียง',
                          color: AquaColors.bad,
                        ),
                      const SizedBox(height: Gap.s),
                      if (z.last) ...[
                        Bold(
                          'สรุปภัยพิบัติ: ปลาก่อนเกิดภัย ${z.fishBefore} → เหลือ ${z.fishAfter} · ค่าฟื้นฟู ${s.repairCost}฿ · เสบียงเหลืออยู่ได้ ${fmtNum(z.supplyDaysAfter)} วัน',
                        ),
                        s.repairCost > 0
                            ? const Muted(
                                'ไปที่ "เตรียมภัย" เพื่อซ่อมแซมและฟื้นฟู · ซื้อปลาใหม่ที่ร้านปลา',
                                size: FontSize.body,
                              )
                            : const Muted(
                                'ฟาร์มไม่เสียหาย',
                                color: AquaColors.ok,
                                size: FontSize.body,
                              ),
                      ] else
                        const Muted(
                          'ภัยยังไม่จบ กด "เริ่มวันใหม่" แล้วตรวจฟาร์ม/เสบียง ก่อนกด "จบวัน"',
                          size: FontSize.body,
                        ),
                    ],
                  ),
                ),
              PixelButton(
                label: 'เริ่มวันใหม่',
                icon: const PixelGlyph(
                  Glyph.sun,
                  size: 24,
                  color: AquaColors.goldLight,
                ),
                size: PixelButtonSize.large,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ตัวเลขนับขึ้นจาก 0 ตอนเปิดรายงาน
class _CountUp extends StatelessWidget {
  const _CountUp(this.value, {this.prefix = '', this.suffix = ''});
  final int value;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(
        '${value > 0 ? prefix : ''}${v.round()}$suffix',
        style: const TextStyle(
          fontSize: FontSize.label + 2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// ช่องข้อมูล: ไอคอน + หัวเล็ก + ค่าใหญ่
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    this.value,
    this.child,
    this.bad = false,
  });
  final Widget icon;
  final String label;
  final String? value;
  final Widget? child;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      fill: bad ? AquaColors.redPale : AquaColors.paper,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          SizedBox(width: 36, child: Center(child: icon)),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AquaColors.textSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child ??
                    Text(
                      value!,
                      style: TextStyle(
                        fontSize: FontSize.body,
                        fontWeight: FontWeight.w700,
                        color: bad ? AquaColors.bad : AquaColors.text,
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

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, required this.color});
  final Widget icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 3), child: icon),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: FontSize.small + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
