import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/equipment_data.dart';
import '../../game/hints.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';

/// หน้า "ฟาร์ม": ฉากฟาร์ม คำแนะนำ สถานะตัวละคร (พักผ่อน) และข่าวเตือนภัย
class FarmTab extends ConsumerWidget {
  const FarmTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final scene = FarmSceneData.fromState(s, e.warnDays);

    return ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        PageHeader(
          scene: PixelScene(painterBuilder: (t) => FarmPainter(t, scene)),
          title: 'ฟาร์ม',
          icon: const PixelIcon('house', size: 30),
        ),
        _HintBubble(farmHint(e)),
        const SizedBox(height: Gap.m),
        _CharacterCard(
          onRest: () => showResult(context, ctl.run((e) => e.rest())),
          onPond: () => onOpenTab(1),
        ),
        _DisasterCard(
          onRepair: () => showResult(context, ctl.run((e) => e.repair())),
        ),
      ],
    );
  }
}

/// คำแนะนำเป็นคำพูดของตัวละคร
class _HintBubble extends StatelessWidget {
  const _HintBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Bob(
          dy: 2,
          period: Duration(milliseconds: 1800),
          child: PixelIcon('face', size: 52),
        ),
        // หางของกล่องคำพูด
        CustomPaint(size: const Size(12, 20), painter: _TailPainter()),
        Expanded(
          child: PixelBox(
            fill: AquaColors.paper,
            depth: 4,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              text,
              style: const TextStyle(
                color: AquaColors.text,
                fontWeight: FontWeight.w700,
                fontSize: FontSize.body,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    for (var i = 0; i < 4; i++) {
      final w = 3.0 * (i + 1);
      p.color = AquaColors.ink;
      canvas.drawRect(
        Rect.fromLTWH(size.width - w, 4 + i * 3.0, w + 1, 3),
        p,
      );
      if (i > 0) {
        p.color = AquaColors.paper;
        canvas.drawRect(
          Rect.fromLTWH(size.width - w + 3, 4 + i * 3.0, w - 2, 3),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

class _CharacterCard extends ConsumerWidget {
  const _CharacterCard({required this.onRest, required this.onPond});
  final VoidCallback onRest;
  final VoidCallback onPond;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    return WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            s.character,
            icon: const PixelIcon('face', size: 30),
            trailing: _HelpButton(
              title: 'เจ้าของฟาร์ม',
              lines: const [
                'ความอิ่มลดลง 20/วัน',
                'อิ่มหมด → สุขภาพลด',
                'สุขภาพ 0 = Game Over',
              ],
            ),
          ),
          StatBar(
            icon: const PixelIcon('fry', size: 24),
            label: 'อิ่ม',
            value: s.hunger,
            color: AquaColors.hunger,
            suffix: '%',
          ),
          const SizedBox(height: Gap.s),
          StatBar(
            icon: const PixelGlyph(
              Glyph.bolt,
              size: 22,
              color: AquaColors.goldLight,
            ),
            label: 'พลังงาน',
            value: s.energy,
            color: AquaColors.energy,
            suffix: '%',
          ),
          const SizedBox(height: Gap.s),
          StatBar(
            icon: const PixelGlyph(
              Glyph.heart,
              size: 20,
              color: AquaColors.red,
            ),
            label: 'สุขภาพ',
            value: s.health,
            color: AquaColors.health,
            suffix: '%',
          ),
          const SizedBox(height: Gap.s),
          StatBar(
            icon: const PixelGlyph(
              Glyph.smile,
              size: 20,
              color: AquaColors.goldLight,
            ),
            label: 'ความสุข',
            value: s.joy,
            color: AquaColors.joy,
            suffix: '%',
          ),
          const SizedBox(height: Gap.m),
          PixelButton(
            label: 'พักผ่อน',
            icon: const PixelIcon('house', size: 26),
            trailing: const Tag(
              '+40',
              color: AquaColors.paper,
              icon: PixelGlyph(Glyph.bolt, size: 14, color: AquaColors.gold),
            ),
            tooltip: 'พักผ่อน +40 พลังงาน',
            expand: true,
            onPressed: onRest,
          ),
          const SizedBox(height: Gap.s),
          PixelButton(
            label: 'ไปบ่อปลา',
            icon: const PixelIcon('drop', size: 24),
            style: PixelButtonStyle.water,
            expand: true,
            onPressed: onPond,
          ),
        ],
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => PixelIconButton(
    icon: const PixelGlyph(Glyph.question, size: 20, color: AquaColors.paper),
    tooltip: 'อธิบาย',
    style: PixelButtonStyle.water,
    onPressed: () => infoDialog(context, title, lines),
  );
}

class _DisasterCard extends ConsumerWidget {
  const _DisasterCard({required this.onRepair});
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final a = s.active;
    final dz = s.upcoming;
    final w = e.warnDays;

    final children = <Widget>[
      const SectionTitle('ข่าวเตือนภัย', icon: PixelIcon('warn', size: 28)),
    ];

    if (a != null) {
      final d = kDisasters[a.type]!;
      children.addAll([
        _Banner(
          icon: disasterIcon(a.type, size: 34),
          title: '${d.name}กำลังเกิด',
          badge: 'วันที่ ${a.dayIndex + 1}/${a.duration}',
        ),
        const SizedBox(height: Gap.s),
        Muted(d.dayTexts[a.dayIndex], size: FontSize.body),
      ]);
    } else if (w > 0 && dz != null) {
      final d = kDisasters[dz.type]!;
      final rd = e.readiness()!;
      final rc = rd.pct >= 70
          ? AquaColors.grass
          : (rd.pct >= 40 ? AquaColors.gold : AquaColors.red);
      children.addAll([
        _Banner(
          icon: disasterIcon(dz.type, size: 34),
          title: 'แจ้งเตือน${d.name}',
          badge: 'อีก $w วัน',
        ),
        const SizedBox(height: Gap.s),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.xs,
          children: [
            Tag(
              'เริ่มวันที่ ${dz.startDay}',
              icon: const PixelIcon('cal', size: 16),
            ),
            Tag('นาน ${d.duration} วัน'),
            Tag(
              severityLabel(dz.severity),
              color: AquaColors.redPale,
              icon: const PixelIcon('warn', size: 16),
            ),
          ],
        ),
        const SizedBox(height: Gap.s),
        Muted(d.message, size: FontSize.body),
        const SizedBox(height: Gap.m),
        Row(
          children: [
            const PixelIcon('shield', size: 28),
            const SizedBox(width: Gap.s),
            const Expanded(child: Bold('Readiness Check')),
            OutlinedText(
              '${rd.pct}%',
              size: FontSize.title,
              color: rc,
            ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        PixelBar(value: rd.pct, color: rc, height: 22),
        const SizedBox(height: Gap.m),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.s,
          children: [
            for (final k in d.equipment.keys)
              _EquipTile(
                icon: kEquipment[k]!.icon,
                name: kEquipment[k]!.name,
                have: s.equipmentCount(k),
                need: d.equipment[k]!,
              ),
          ],
        ),
        const SizedBox(height: Gap.m),
        Wrap(
          spacing: Gap.s,
          runSpacing: Gap.xs,
          children: [
            Tag(
              'เสบียง ${fmtNum(e.supplyDays)}/${d.duration} วัน',
              icon: const PixelIcon('crate', size: 16),
              color: e.supplyDays >= d.duration
                  ? AquaColors.creamDark
                  : AquaColors.redPale,
            ),
            Tag(
              e.waterStatus.label,
              icon: const PixelIcon('drop', size: 16),
            ),
            CoinTag(s.money, boxed: true, size: FontSize.small),
          ],
        ),
      ]);
    } else {
      children.addAll([
        const Bold('ยังไม่มีประกาศภัยพิบัติ'),
        const SizedBox(height: Gap.s),
        Row(
          children: [
            for (final d in kDisasters.values)
              Expanded(
                child: Tooltip(
                  message: '${d.name} แจ้งล่วงหน้า ${d.leadDays} วัน',
                  child: Column(
                    children: [
                      SizedBox(
                        height: 36,
                        child: Center(child: disasterIcon(d.type, size: 30)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Tag('${d.leadDays} วัน', size: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Gap.s),
        const Muted(
          'ตัวเลข = แจ้งเตือนล่วงหน้า · ภัยเกิดต่อเนื่องหลายวัน',
          align: TextAlign.center,
        ),
      ]);
    }

    if (s.damaged) {
      children.addAll([
        const SizedBox(height: Gap.m),
        PixelButton(
          label: 'ซ่อมแซมและฟื้นฟูฟาร์ม',
          icon: const PixelIcon('wrench', size: 24),
          trailing: CoinTag(s.repairCost, boxed: true, size: FontSize.small),
          expand: true,
          onPressed: onRepair,
        ),
      ]);
    }

    return WoodPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// ป้ายภัยสีแดง: ไอคอน + ชื่อ + ป้ายวัน
class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.badge});
  final Widget icon;
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      fill: AquaColors.red,
      depth: 4,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Blink(low: .6, child: icon),
          const SizedBox(width: Gap.s),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: FontSize.label,
              ),
            ),
          ),
          Tag(badge, color: AquaColors.goldPale),
        ],
      ),
    );
  }
}

/// ช่องอุปกรณ์: ไอคอน + มี/ต้อง + เครื่องหมายผ่าน
class _EquipTile extends StatelessWidget {
  const _EquipTile({
    required this.icon,
    required this.name,
    required this.have,
    required this.need,
  });
  final String icon;
  final String name;
  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Tooltip(
      message: '$name: มี $have / ต้อง $need',
      child: Semantics(
        label: '$name มี $have ต้อง $need',
        child: ExcludeSemantics(
          child: PaperCard(
            fill: ok ? AquaColors.paper : AquaColors.redPale,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PixelIcon(icon, size: 32),
                const SizedBox(width: 6),
                Text(
                  '$have/$need',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: FontSize.body,
                    color: ok ? AquaColors.ok : AquaColors.bad,
                  ),
                ),
                const SizedBox(width: 4),
                passGlyph(ok, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
