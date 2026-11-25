import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../data/disaster_data.dart';
import '../../data/equipment_data.dart';
import '../../game/story.dart';
import '../../game/tutorial.dart';
import '../design/design_system.dart' show DsColors;
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';
import '../widgets/equipment_row.dart';
import '../widgets/game_hud.dart';
import '../widgets/story_gate.dart';
import 'profile_screen.dart';

/// ตำแหน่งแผง "เตรียมภัย" สำหรับปุ่มลัดจากการ์ดข่าวเตือนภัย
final _prepareKey = GlobalKey();

/// ฉากฟาร์มเต็มจอ (พื้นหลังของหน้าฟาร์ม)
class FarmBackdrop extends ConsumerWidget {
  const FarmBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final scene = FarmSceneData.fromState(
      session.state,
      session.engine.warnDays,
    );
    return PixelScene(
      key: const ValueKey('farm-backdrop'),
      backdrop: true,
      framed: false,
      // บ้าน + บ่ออยู่กลางจอ
      focus: const Offset(.6, .62),
      painterBuilder: (t) => FarmPainter(t, scene),
    );
  }
}

/// แผ่นรายละเอียด: ภัยพิบัติ + อุปกรณ์ป้องกัน (เนื้อเรื่อง: อุปกรณ์อยู่บนสุด)
Future<void> showDisasterSheet(BuildContext context, {required bool story}) {
  return showDetailSheet<void>(
    context,
    title: 'ภัยพิบัติและการป้องกัน',
    icon: const PixelIcon('shield', size: 32),
    builder: (c) => Consumer(
      builder: (context, ref, _) {
        final ctl = ref.read(gameProvider.notifier);
        final disaster = _DisasterCard(
          onRepair: () => showResult(context, ctl.run((e) => e.repair())),
        );
        final prepare = KeyedSubtree(
          key: _prepareKey,
          child: const _PreparePanel(),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: story ? [prepare, disaster] : [disaster, prepare],
        );
      },
    ),
  );
}

/// แผ่นรายละเอียด: สถานะตัวละคร
Future<void> showCharacterSheet(BuildContext context, String name) {
  return showDetailSheet<void>(
    context,
    title: name,
    icon: const PixelIcon('face', size: 32),
    builder: (_) => const _CharacterCard(),
  );
}

/// หน้า "ฟาร์ม": ฉากฟาร์มเต็มจอ + ป้ายสถานะตัวละคร + ป้ายภัย + ถาดปุ่ม
/// (รายละเอียดเปิดเป็นแผ่นด้านล่าง ไม่วางบนหน้าหลัก)
class FarmTab extends ConsumerWidget {
  const FarmTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ctl = ref.read(gameProvider.notifier);
    final target = e.tutorialStep?.target;
    final story = watchStory(ref);
    final isStory = story != null;
    final storyNext = story == null
        ? null
        : Story.nextTarget(story.$1, story.$2);
    final r = context.rs;

    final status = Spotlight(
      on: target == TutorialTarget.status,
      child: _StatusChip(onTap: () => showCharacterSheet(context, s.character)),
    );
    final disaster = _DisasterChip(
      onTap: () => showDisasterSheet(context, story: isStory),
    );

    final tray = ActionTray(
      leading: RoundAction(
        key: const ValueKey('farm-pond'),
        icon: const PixelIcon('drop', size: 32),
        label: 'บ่อปลา',
        color: DsColors.primarySoft,
        labelOnScene: true,
        onPressed: () => onOpenTab(1),
      ),
      primary: Spotlight(
        on: target == TutorialTarget.home,
        child: StoryGate(
          target: StoryTarget.rest,
          child: PixelButton(
            key: const ValueKey('farm-rest'),
            label: 'พักผ่อน',
            size: PixelButtonSize.large,
            icon: const PixelIcon('house', size: 32),
            below: Text(
              '+40 พลังงาน',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DsColors.onAccent.withValues(alpha: .85),
              ),
            ),
            tooltip: 'พักผ่อน +40 พลังงาน',
            expand: true,
            onPressed: () => showResult(context, ctl.run((e) => e.rest())),
          ),
        ),
      ),
      trailing: Spotlight(
        on:
            target == TutorialTarget.prepare ||
            storyNext == StoryTarget.buyEquipment,
        child: RoundAction(
          key: const ValueKey('farm-prepare'),
          icon: const PixelIcon('shield', size: 34),
          label: 'ป้องกัน',
          labelOnScene: true,
          color: s.active != null || e.warnDays > 0
              ? const Color(0xFFFFD9D2)
              : DsColors.surface,
          onPressed: () => showDisasterSheet(context, story: isStory),
        ),
      ),
    );

    // มือถือแนวตั้ง: ป้ายสองอันเรียงแถวบนสุด ถาดปุ่มล่างสุด ตรงกลางเห็นฉาก
    // แนวนอน/คอม: คอลัมน์ควบคุมชิดขวา ฉากเห็นเต็มด้านซ้าย
    final column = Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s, Gap.s, Gap.s, Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: status),
              const SizedBox(width: Gap.s),
              Expanded(flex: 5, child: disaster),
            ],
          ),
          const Spacer(),
          tray,
        ],
      ),
    );
    if (!r.useSideNav) return column;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: column,
      ),
    );
  }
}

/// ป้ายสถานะตัวละครบนฉาก: หน้า + ชื่อ + แถบสั้น 4 ค่า (ไม่มีตัวเลข)
class _StatusChip extends ConsumerWidget {
  const _StatusChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    final low = [s.hunger, s.energy, s.health, s.joy].any((v) => v < 30);
    Widget bar(int v, Color c) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: PixelBar(value: v, color: c, height: 8),
      ),
    );
    return SceneChip(
      key: const ValueKey('farm-status'),
      icon: const PixelIcon('face', size: 36),
      text: low ? '${s.character} ต้องดูแล!' : s.character,
      semanticLabel:
          '${s.character}: อิ่ม ${s.hunger} พลังงาน ${s.energy} '
          'สุขภาพ ${s.health} ความสุข ${s.joy}',
      onTap: onTap,
      below: Row(
        children: [
          bar(s.hunger, AquaColors.hunger),
          bar(s.energy, AquaColors.energy),
          bar(s.health, AquaColors.health),
          bar(s.joy, const Color(0xFF7FD3F7)),
        ],
      ),
    );
  }
}

/// ป้ายภัยบนฉาก: ไม่มีภัย / เตือนอีกกี่วัน + ความพร้อม / กำลังเกิด
class _DisasterChip extends ConsumerWidget {
  const _DisasterChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final a = s.active;
    final dz = s.upcoming;
    final w = e.warnDays;
    if (a != null) {
      return SceneChip(
        key: const ValueKey('farm-disaster'),
        color: const Color(0xE6B42318),
        icon: disasterIcon(a.type, size: 34),
        text: '${kDisasters[a.type]!.name}กำลังเกิด',
        below: Text(
          'วันที่ ${a.dayIndex + 1}/${a.duration}',
          style: glassText(size: 16, color: const Color(0xFFFFE0DB)),
        ),
        onTap: onTap,
      );
    }
    if (w > 0 && dz != null) {
      final pct = e.readiness()!.pct;
      final c = pct >= 70
          ? AquaColors.grass
          : (pct >= 40 ? AquaColors.gold : AquaColors.red);
      return SceneChip(
        key: const ValueKey('farm-disaster'),
        color: const Color(0xE6A33A12),
        icon: Blink(low: .6, child: disasterIcon(dz.type, size: 34)),
        text: '${kDisasters[dz.type]!.name}อีก $w วัน',
        // ความพร้อมรับภัย: ข้อความบน แถบล่าง (จอแคบไม่ล้น)
        below: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('พร้อม $pct%', style: glassText(size: 16)),
            ),
            const SizedBox(height: 3),
            PixelBar(value: pct, color: c, height: 10),
          ],
        ),
        onTap: onTap,
      );
    }
    // ไม่มีภัย: ไม่ต้องมีป้าย (ปุ่ม "ป้องกัน" ในถาดเปิดรายละเอียดได้) ให้เห็นฉากเต็ม
    if (!s.damaged) return const SizedBox.shrink();
    return SceneChip(
      key: const ValueKey('farm-disaster'),
      color: const Color(0xE6B42318),
      icon: const PixelIcon('wrench', size: 34),
      text: 'ฟาร์มเสียหาย',
      below: Text(
        'แตะเพื่อซ่อม',
        style: glassText(size: 16, color: const Color(0xFFFFE0DB)),
      ),
      onTap: onTap,
    );
  }
}

/// สถานะตัวละครแบบละเอียด (ในแผ่นด้านล่าง)
class _CharacterCard extends ConsumerWidget {
  const _CharacterCard();

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
              child: _BuyGate(
                // เนื้อเรื่อง: ชี้อุปกรณ์ชิ้นแรกที่ภัยนี้ต้องใช้
                point: id == order.first && needs.containsKey(id),
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
                      needs.containsKey(id) &&
                      s.equipmentCount(id) >= needs[id]!,
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
                    final warn = e.lowMoneyWarning(price);
                    final ok = await confirmDialog(
                      context,
                      'ยืนยันซื้อ${q.name} ราคา $price บาท?'
                      '${warn == null ? '' : '\n$warn'}',
                      icon: PixelIcon(q.icon, size: 56),
                    );
                    if (ok && context.mounted) {
                      showResult(context, ctl.run((e) => e.buyEquipment(id)));
                    }
                  },
                ),
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
                // จอแคบ: ย่อตัวเลขให้พอดี ไม่ล้นขอบ
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'มี $have / ต้อง $need',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: FontSize.body,
                        color: ok ? AquaColors.ok : AquaColors.bad,
                      ),
                    ),
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

/// ปุ่มซื้ออุปกรณ์กันภัย: เนื้อเรื่องล็อกจนถึงบทคำเตือน และชี้ชิ้นแรกที่ต้องใช้
class _BuyGate extends ConsumerWidget {
  const _BuyGate({required this.point, required this.child});
  final bool point;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = watchStory(ref);
    if (story == null) return child;
    final (p, e) = story;
    if (point || !Story.allows(p, e, StoryTarget.buyEquipment)) {
      return StoryGate(target: StoryTarget.buyEquipment, child: child);
    }
    return child;
  }
}
