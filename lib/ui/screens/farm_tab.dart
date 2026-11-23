import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../data/disaster_data.dart';
import '../../data/equipment_data.dart';
import '../../game/hints.dart';
import '../../game/tutorial.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';
import '../widgets/equipment_row.dart';
import 'profile_screen.dart';

/// ตำแหน่งแผง "เตรียมภัย" สำหรับปุ่มลัดจากการ์ดข่าวเตือนภัย
final _prepareKey = GlobalKey();

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
    final hint = farmHint(e);
    final target = e.tutorialStep?.target;

    // Column ใน SingleChildScrollView: ทุกแผงถูกสร้างไว้ ปุ่มลัดเลื่อนไปหาได้เสมอ
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            scene: PixelScene(painterBuilder: (t) => FarmPainter(t, scene)),
            title: 'ฟาร์ม',
            icon: const PixelIcon('house', size: 30),
          ),
          if (hint != null) ...[
            _HintBubble(hint),
            const SizedBox(height: Gap.m),
          ],
          Spotlight(
            on: target == TutorialTarget.status,
            child: _CharacterCard(
              restSpotlight: target == TutorialTarget.home,
              onRest: () => showResult(context, ctl.run((e) => e.rest())),
              onPond: () => onOpenTab(1),
            ),
          ),
          _DisasterCard(
            onRepair: () => showResult(context, ctl.run((e) => e.repair())),
          ),
          KeyedSubtree(
            key: _prepareKey,
            child: Spotlight(
              on: target == TutorialTarget.prepare,
              child: const _PreparePanel(),
            ),
          ),
        ],
      ),
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
      canvas.drawRect(Rect.fromLTWH(size.width - w, 4 + i * 3.0, w + 1, 3), p);
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
  const _CharacterCard({
    required this.onRest,
    required this.onPond,
    this.restSpotlight = false,
  });
  final VoidCallback onRest;
  final VoidCallback onPond;
  final bool restSpotlight;

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
            trailing: const _ProfileButton(),
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
          Spotlight(
            on: restSpotlight,
            child: PixelButton(
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

/// เปิดหน้าข้อมูลตัวละคร (prof ในต้นแบบ)
class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) => PixelIconButton(
    key: const ValueKey('open-profile'),
    icon: const PixelGlyph(Glyph.question, size: 20, color: AquaColors.paper),
    tooltip: 'ข้อมูลตัวละคร',
    style: PixelButtonStyle.water,
    onPressed: () => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
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
        Muted(
          disasterDayText(a.type, a.duration, a.dayIndex),
          size: FontSize.body,
        ),
        const SizedBox(height: Gap.s),
        Tag(
          'ปลาโตได้ ${(e.protection(a.type) * 100).round()}% ระหว่างภัย (ตามอุปกรณ์ป้องกัน)',
          key: const ValueKey('growth-info'),
          color: e.protection(a.type) >= 1
              ? AquaColors.creamDark
              : AquaColors.redPale,
          icon: const PixelIcon('f_nila', size: 18),
        ),
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
            Tag('นาน ${dz.duration} วัน'),
            Tag(
              severityLabel(dz.severity),
              color: AquaColors.redPale,
              icon: const PixelIcon('warn', size: 16),
            ),
          ],
        ),
        const SizedBox(height: Gap.s),
        Muted(d.message, size: FontSize.body),
        const SizedBox(height: Gap.xs),
        const Muted(
          'ระหว่างภัย ปลาจะโตตามความพร้อมของอุปกรณ์ ไม่มีอุปกรณ์ = ปลาไม่โตเลย',
          size: FontSize.body,
          color: AquaColors.red,
        ),
        const SizedBox(height: Gap.m),
        Row(
          children: [
            const PixelIcon('shield', size: 28),
            const SizedBox(width: Gap.s),
            const Expanded(child: Bold('ความพร้อมรับภัย')),
            OutlinedText('${rd.pct}%', size: FontSize.title, color: rc),
          ],
        ),
        const SizedBox(height: Gap.xs),
        PixelBar(value: rd.pct, color: rc, height: 22),
        const SizedBox(height: Gap.s),
        // คะแนนมาจากไหน: อุปกรณ์ 50 + เสบียง 30 + น้ำ 10 + เงิน 10
        Wrap(
          key: const ValueKey('readiness-parts'),
          spacing: Gap.xs,
          runSpacing: Gap.xs,
          children: [
            _PartTag(
              'อุปกรณ์',
              rd.equipmentPts,
              50,
              icon: const PixelIcon('shield', size: 16),
            ),
            _PartTag(
              'เสบียง ${fmtNum(e.supplyDays)}/${dz.duration} วัน',
              rd.supplyPts,
              30,
              icon: const PixelIcon('crate', size: 16),
            ),
            _PartTag(
              'น้ำ ${s.water}%',
              rd.waterPts,
              10,
              icon: const PixelIcon('drop', size: 16),
            ),
            _PartTag(
              'เงิน ${s.money}฿',
              rd.moneyPts,
              10,
              icon: const PixelIcon('coin', size: 16),
            ),
          ],
        ),
        const SizedBox(height: Gap.xs),
        const Muted(
          'คะแนน: อุปกรณ์ครบ 50 · เสบียงพอตลอดภัย 30 · น้ำดีขึ้นไป 10 · เงิน 100฿ ขึ้นไป 10',
          size: 13,
        ),
        const SizedBox(height: Gap.m),
        Bold('อุปกรณ์ที่${d.name}ต้องใช้'),
        const SizedBox(height: Gap.xs),
        for (final k in d.equipment.keys)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.xs),
            child: _EquipTile(
              icon: kEquipment[k]!.icon,
              name: kEquipment[k]!.name,
              have: s.equipmentCount(k),
              need: d.equipment[k]!,
            ),
          ),
        if (d.equipment.keys.any(
          (k) => s.equipmentCount(k) < d.equipment[k]!,
        )) ...[
          const SizedBox(height: Gap.xs),
          PixelButton(
            key: const ValueKey('go-prepare'),
            label: 'ไปซื้ออุปกรณ์ที่ขาด',
            icon: const PixelIcon('shield', size: 24),
            expand: true,
            onPressed: () {
              final c = _prepareKey.currentContext;
              if (c != null) {
                Scrollable.ensureVisible(
                  c,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
        ],
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
                      Tag('ก่อน ${d.leadDays} วัน', size: 12),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Gap.s),
        const Muted(
          'ตัวเลข = ระบบจะเตือนกี่วันก่อนภัยมาถึง · ภัยเกิดต่อเนื่องหลายวัน',
          align: TextAlign.center,
        ),
      ]);
    }

    if (s.damaged) {
      children.addAll([
        const SizedBox(height: Gap.m),
        Muted(
          'ฟาร์มเสียหาย: ปลาโตได้แค่ ${(kDamagedGrowth * 100).round()}% จนกว่าจะซ่อม',
          key: const ValueKey('damaged-info'),
          size: FontSize.body,
          color: AquaColors.red,
        ),
        const SizedBox(height: Gap.s),
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

/// เตรียมภัย: ซื้ออุปกรณ์ป้องกัน 7 ชนิด (eqRow ในหน้า alert ของต้นแบบ)
class _PreparePanel extends ConsumerWidget {
  const _PreparePanel();

  /// "น้ำท่วม (ต้อง 2), ภัยแล้ง (ต้อง 1)"
  static String _usedWith(String id) => [
    for (final d in kDisasters.values)
      if (d.equipment.containsKey(id)) '${d.name} (ต้อง ${d.equipment[id]})',
  ].join(', ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final s = session.state;
    final e = session.engine;
    final ctl = ref.read(gameProvider.notifier);
    final dType = s.active?.type ?? s.upcoming?.type;
    final needs = dType == null
        ? const <String, int>{}
        : kDisasters[dType]!.equipment;
    final order = [
      ...kDefenseEquipmentOrder.where(needs.containsKey),
      ...kDefenseEquipmentOrder.where((id) => !needs.containsKey(id)),
    ];
    return WoodPanel(
      key: const ValueKey('prepare'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(
            'เตรียมภัย: อุปกรณ์ป้องกัน',
            icon: PixelIcon('shield', size: 28),
          ),
          if (dType != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: Muted(
                'อุปกรณ์ที่${kDisasters[dType]!.name}ต้องใช้อยู่ด้านบน',
                size: 13,
              ),
            ),
          for (final id in order)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: EquipmentRow(
                key: ValueKey('eq-$id'),
                spec: kEquipment[id]!,
                price: e.equipmentPrice(id),
                owned: s.equipmentCount(id),
                closed: s.marketClosed,
                badge: needs.containsKey(id)
                    ? (s.equipmentCount(id) >= needs[id]!
                          ? '${kDisasters[dType]!.name}: ครบแล้ว'
                          : '${kDisasters[dType]!.name}: ยังขาด ${needs[id]! - s.equipmentCount(id)}')
                    : null,
                badgeOk:
                    needs.containsKey(id) && s.equipmentCount(id) >= needs[id]!,
                usage: [
                  'ประโยชน์: ${kEquipment[id]!.use}',
                  if (_usedWith(id).isNotEmpty) 'ใช้กับ: ${_usedWith(id)}',
                ].join(' · '),
                onBuy: () async {
                  final q = kEquipment[id]!;
                  // ตลาดปิดหรือเงินไม่พอ → ให้ engine บอกเหตุผล ไม่ต้องถาม
                  final price = e.equipmentPrice(id);
                  if (s.marketClosed || s.money < price) {
                    showResult(context, ctl.run((e) => e.buyEquipment(id)));
                    return;
                  }
                  final ok = await confirmDialog(
                    context,
                    'ยืนยันซื้อ${q.name} ราคา $price บาท?',
                    icon: PixelIcon(q.icon, size: 56),
                  );
                  if (ok && context.mounted) {
                    showResult(context, ctl.run((e) => e.buyEquipment(id)));
                  }
                },
              ),
            ),
        ],
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

/// ป้ายคะแนนย่อยของความพร้อม: "อุปกรณ์ 25/50" แดงเมื่อยังไม่เต็ม
class _PartTag extends StatelessWidget {
  const _PartTag(this.label, this.pts, this.max, {required this.icon});
  final String label;
  final int pts;
  final int max;
  final Widget icon;

  @override
  Widget build(BuildContext context) => Tag(
    '$label $pts/$max',
    size: 13,
    icon: icon,
    color: pts >= max ? AquaColors.creamDark : AquaColors.redPale,
    textColor: pts >= max ? AquaColors.text : AquaColors.redDark,
  );
}

/// ช่องอุปกรณ์: ไอคอน + ชื่อ + มี/ต้อง + เครื่องหมายผ่าน
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
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                PixelIcon(icon, size: 32),
                const SizedBox(width: 6),
                Expanded(child: Bold(name, maxLines: 2)),
                const SizedBox(width: 6),
                Text(
                  'มี $have / ต้อง $need',
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
