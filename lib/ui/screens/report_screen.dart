import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../data/disaster_data.dart';
import '../../data/food_data.dart';
import '../../game/game_state.dart';
import '../design/design_system.dart' show DsColors, DsText;
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';
import '../widgets/game_hud.dart';

/// รายงานประจำวัน (หลังกด "จบวัน") แบบฉากเต็มจอ:
/// เกรดใหญ่ + ดาว + ตัวเลขสำคัญ 3 ค่า + ปุ่มใหญ่ "เริ่มวันใหม่"
/// ตัวเลขทั้งหมด (น้ำ ออกซิเจน เงิน ภัย) อยู่ใน "ดูรายละเอียด"
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final s = session.state;
    final r = s.lastReport!;
    final scene = FarmSceneData.fromState(s, session.engine.warnDays);
    final short = ScenePage.short(context);

    final column = Padding(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        // แผงสรุปบนสุด (เลื่อนได้ถ้าจอเตี้ย) · ถาดปุ่มล่างสุด · ตรงกลางเห็นฉาก
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(report: r, short: short),
                  if (_alert(r) case final a?) ...[
                    const SizedBox(height: Gap.s),
                    a,
                  ],
                ],
              ),
            ),
          ),
          ActionTray(
            leading: RoundAction(
              key: const ValueKey('report-details'),
              icon: const PixelIcon('scroll', size: 32),
              label: 'รายละเอียด',
              tooltip: 'ดูรายละเอียด',
              labelOnScene: true,
              diameter: ScenePage.round(context),
              onPressed: () => showReportDetails(context),
            ),
            primary: TrayPrimary(
              key: const ValueKey('report-next'),
              label: 'เริ่มวันใหม่',
              icon: const PixelGlyph(
                Glyph.sun,
                size: 26,
                color: AquaColors.goldLight,
              ),
              note: 'ไปวันที่ ${s.day}',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      key: const ValueKey('report-screen'),
      backgroundColor: DsColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ฉากฟาร์มเต็มจอ (สภาพที่จะกลับไปเล่นต่อ)
          PixelScene(
            backdrop: true,
            framed: false,
            focus: const Offset(.6, .62),
            painterBuilder: (t) => FarmPainter(t, scene),
          ),
          SafeArea(
            child: context.rs.useSideNav
                // จอกว้าง/แนวนอน: แผงสรุปชิดขวา เห็นฉากด้านซ้าย
                ? Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: column,
                    ),
                  )
                : column,
          ),
        ],
      ),
    );
  }

  /// เรื่องเดียวที่ควรรู้ของวันนี้ (ภัย > อาหารเสีย > ถนอมเสร็จ) — ไม่มีก็ไม่แสดง
  static Widget? _alert(DayReport r) {
    final z = r.event;
    if (z != null) {
      final name = kDisasters[z.type]!.name;
      return _AlertLine(
        key: const ValueKey('report-alert'),
        icon: disasterIcon(z.type, size: 32),
        text: z.last
            ? '$nameจบแล้ว · เสียปลารวม ${z.cumulativeLost} ตัว'
            : '$name วันที่ ${z.dayIndex + 1}/${z.duration}'
                  '${z.lost > 0 ? ' · เสียปลา ${z.lost} ตัว' : ' · ปลาปลอดภัย'}',
        bad: true,
      );
    }
    final health = diseaseLine(r);
    if (health != null && (r.sickNew.isNotEmpty || r.diseaseDied > 0)) {
      return _AlertLine(
        key: const ValueKey('report-alert'),
        icon: const PixelIcon('herb', size: 32),
        text: health,
        bad: true,
      );
    }
    if (r.spoiled > 0) {
      return _AlertLine(
        key: const ValueKey('report-alert'),
        icon: const PixelIcon('warn', size: 32),
        text: 'อาหารเสีย ${r.spoiled} จาน ไปทิ้งที่คลัง',
        bad: true,
      );
    }
    if (r.done.isNotEmpty) {
      return _AlertLine(
        key: const ValueKey('report-alert'),
        icon: passGlyph(true, size: 24),
        text:
            'ถนอมเสร็จ: ${r.done.map((d) => '${kFoods[d.food]!.name} x${d.qty}').join(', ')}',
      );
    }
    return null;
  }
}

/// แผงสรุป: เกรดใหญ่ + ดาว + คำชม และตัวเลขสำคัญ 3 ค่า
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report, required this.short});
  final DayReport report;
  final bool short;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final stars = kGradePoints[r.grade] ?? 1;
    final (fill, word) = switch (r.grade) {
      'S' => (DsColors.accent, 'ยอดเยี่ยม!'),
      'A' => (DsColors.primary, 'ทำได้ดี'),
      _ => (DsColors.textMuted, 'พอใช้'),
    };
    final badge = short ? 76.0 : 96.0;

    return GlassPanel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BounceIn(
                from: .2,
                duration: const Duration(milliseconds: 700),
                child: Semantics(
                  label: 'เกรด ${r.grade}',
                  container: true,
                  excludeSemantics: true,
                  child: Container(
                    key: const ValueKey('report-grade'),
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DsColors.ink, width: 3),
                      boxShadow: const [
                        BoxShadow(color: DsColors.ink, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: OutlinedText(
                        r.grade,
                        size: badge * .7,
                        color: Colors.white,
                        stroke: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รายงานประจำวัน — วันที่ ${r.day}',
                      maxLines: 2,
                      style: glassText(),
                    ),
                    const SizedBox(height: 2),
                    Text(word, maxLines: 1, style: glassText(size: 26)),
                    const SizedBox(height: 4),
                    Semantics(
                      label: 'ได้ $stars ดาว จาก 3',
                      container: true,
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: PixelGlyph(
                                  Glyph.star,
                                  size: short ? 24 : 30,
                                  color: i < stars
                                      ? AquaColors.goldLight
                                      : const Color(0x55FFFFFF),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  key: const ValueKey('report-earned'),
                  icon: const PixelIcon('coin', size: 32),
                  label: 'รายได้วันนี้',
                  value: _CountUp(r.earned, prefix: '+', suffix: '฿'),
                ),
              ),
              Expanded(
                child: _Stat(
                  key: const ValueKey('report-fish'),
                  icon: const PixelIcon('f_nila', size: 32),
                  label: r.died > 0 ? 'ปลา (ตาย ${r.died})' : 'ปลาในบ่อ',
                  value: _Value('${r.fish} ตัว'),
                  bad: r.died > 0,
                ),
              ),
              Expanded(
                child: _Stat(
                  key: const ValueKey('report-supply'),
                  icon: const PixelIcon('crate', size: 32),
                  label: 'อาหารพอกิน',
                  value: _Value('${fmtNum(r.supplyDays)} วัน'),
                  bad: r.supplyDays < 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ค่า 1 ช่อง: ไอคอน + ตัวเลขใหญ่ + ชื่อค่า
class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.bad = false,
  });
  final Widget icon;
  final String label;
  final Widget value;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          style: glassText(
            size: 22,
            color: bad ? const Color(0xFFFFB4A8) : DsColors.onGlass,
          ),
          child: FittedBox(fit: BoxFit.scaleDown, child: value),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: glassText(
            color: bad ? const Color(0xFFFFB4A8) : const Color(0xE6FFFFFF),
          ),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, maxLines: 1);
}

/// แถบเรื่องที่ควรรู้ 1 บรรทัดใต้แผงสรุป
class _AlertLine extends StatelessWidget {
  const _AlertLine({
    super.key,
    required this.icon,
    required this.text,
    this.bad = false,
  });
  final Widget icon;
  final String text;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      color: bad ? const Color(0xE0A3302B) : const Color(0xE01E6B45),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// แผ่น "ดูรายละเอียด": ตัวเลขทั้งหมดของวัน + ผลภัยพิบัติ
Future<void> showReportDetails(BuildContext context) {
  return showDetailSheet<void>(
    context,
    title: 'รายละเอียดของวัน',
    icon: const PixelIcon('scroll', size: 32),
    builder: (c) => const _ReportDetails(),
  );
}

class _ReportDetails extends ConsumerWidget {
  const _ReportDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    final r = s.lastReport!;
    final z = r.event;
    const gap = SizedBox(height: Gap.s);
    return Column(
      key: const ValueKey('report-details-body'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: const PixelIcon('coin', size: 30),
                label: 'รายได้วันนี้',
                value: '${r.earned > 0 ? '+' : ''}${r.earned}฿',
              ),
            ),
            const SizedBox(width: Gap.s),
            Expanded(
              child: _Tile(
                icon: const PixelIcon('coin', size: 30),
                label: 'เงินคงเหลือ',
                value: '${r.money}฿',
              ),
            ),
          ],
        ),
        gap,
        _Tile(
          icon: const PixelIcon('drop', size: 28),
          label: 'น้ำ / ออกซิเจน',
          value: '${r.water}% / ${r.o2.round()}%',
        ),
        gap,
        _Tile(
          icon: const PixelIcon('f_nila', size: 34),
          label: 'ปลาในบ่อ',
          value: '${r.fish} ตัว${r.died > 0 ? ' (สูญเสีย ${r.died})' : ''}',
          bad: r.died > 0,
        ),
        gap,
        _Tile(
          icon: const PixelIcon('fry', size: 30),
          label: 'เสบียง',
          value: '${r.servings} จาน · อยู่ได้ ${fmtNum(r.supplyDays)} วัน',
        ),
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
            text: 'อาหารหมดอายุ ${r.spoiled} จาน (ไปทิ้งที่คลังสินค้า)',
            color: AquaColors.bad,
          ),
        if (diseaseLine(r) case final line?)
          _Note(
            key: const ValueKey('report-health'),
            icon: const PixelIcon('herb', size: 18),
            text: line,
            color: r.sickNew.isEmpty && r.diseaseDied == 0 && r.treatFailed == 0
                ? AquaColors.ok
                : AquaColors.bad,
          ),
        if (r.aeratorCost > 0 || r.aeratorOff)
          _Note(
            icon: const PixelIcon('bub', size: 18),
            text: r.aeratorOff
                ? 'เงินไม่พอค่าไฟ เครื่องเติมอากาศปิดเอง'
                : 'ค่าไฟเครื่องเติมอากาศ ${r.aeratorCost} บาท',
            color: r.aeratorOff ? AquaColors.bad : AquaColors.textSoft,
          ),
        if (z != null) ...[
          const SizedBox(height: Gap.m),
          PixelBox(
            fill: AquaColors.red,
            depth: 4,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          gap,
          Text(z.text, style: DsText.body),
          gap,
          _Tile(
            icon: const PixelIcon('shield', size: 28),
            label: 'ความพร้อมของอุปกรณ์วันนี้',
            value: '${z.protectionPct}%',
          ),
          gap,
          _Tile(
            icon: const PixelIcon('f_nila', size: 34),
            label: 'ปลาที่สูญเสียวันนี้ / สะสม',
            value:
                '${z.lost} / ${z.cumulativeLost} (เหลือ ${z.fishAfter} จาก ${z.fishBefore})',
            bad: z.lost > 0,
          ),
          gap,
          _Tile(
            icon: const PixelIcon('coin', size: 28),
            label: 'ค่าเสียหายวันนี้ / สะสม',
            value: '${z.cost}฿ / ${z.cumulativeCost}฿',
            bad: z.cost > 0,
          ),
          if (z.food > 0 || z.cumulativeFood > 0) ...[
            gap,
            _Tile(
              icon: const PixelIcon('fry', size: 28),
              label: 'อาหารเสียหายจากน้ำ',
              value: '${z.food} จาน (สะสม ${z.cumulativeFood})',
              bad: z.food > 0,
            ),
          ],
          if (z.sandUsed > 0) ...[
            gap,
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
          gap,
          if (z.last) ...[
            Text(
              'สรุปภัยพิบัติ: ปลาก่อนเกิดภัย ${z.fishBefore} → เหลือ ${z.fishAfter} · ค่าฟื้นฟู ${s.repairCost}฿ · เสบียงเหลืออยู่ได้ ${fmtNum(z.supplyDaysAfter)} วัน',
              style: DsText.body.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              s.repairCost > 0
                  ? 'ไปที่ "เตรียมภัย" เพื่อซ่อมแซมและฟื้นฟู · ซื้อปลาใหม่ที่ร้านปลา'
                  : 'ฟาร์มไม่เสียหาย',
              style: DsText.body.copyWith(
                color: s.repairCost > 0 ? null : AquaColors.ok,
              ),
            ),
          ] else
            Text(
              'ภัยยังไม่จบ กด "เริ่มวันใหม่" แล้วตรวจฟาร์ม/เสบียง ก่อนกด "จบวัน"',
              style: DsText.body,
            ),
        ],
      ],
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
      builder: (_, v, _) =>
          Text('${value > 0 ? prefix : ''}${v.round()}$suffix', maxLines: 1),
    );
  }
}

/// ช่องข้อมูลในแผ่นรายละเอียด: ไอคอน + หัวเล็ก + ค่า
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.bad = false,
  });
  final Widget icon;
  final String label;
  final String value;
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
                    fontSize: FontSize.small,
                    color: AquaColors.textSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
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
  const _Note({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });
  final Widget icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Gap.s),
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
                fontSize: FontSize.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ผลเรื่องโรคปลาของคืนนี้ (ป่วยใหม่ หาย ตาย ยาไม่ได้ผล) — null = ไม่มีอะไร
String? diseaseLine(DayReport r) {
  final parts = <String>[
    if (r.sickNew.isNotEmpty)
      'ปลาป่วยใหม่ ${r.sickNew.length} ตัว ไปดูอาการที่ "รักษาปลา"',
    if (r.cured > 0) 'รักษาหาย ${r.cured} ตัว',
    if (r.treatFailed > 0) 'ยาไม่ได้ผล ${r.treatFailed} ตัว เพราะน้ำแย่มาก',
    if (r.diseaseDied > 0) 'ตายจากโรค ${r.diseaseDied} ตัว',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
