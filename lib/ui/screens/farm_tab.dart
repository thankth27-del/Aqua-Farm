import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/equipment_data.dart';
import '../../game/game_engine.dart';
import '../../game/hints.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme.dart';

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
      padding: const EdgeInsets.all(12),
      children: [
        PixelScene(painterBuilder: (t) => FarmPainter(t, scene)),
        const SizedBox(height: 10),
        _HintBubble(farmHint(e)),
        const SizedBox(height: 10),
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

class _HintBubble extends StatelessWidget {
  const _HintBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AquaColors.gold, width: 3),
        boxShadow: const [BoxShadow(color: AquaColors.ink, spreadRadius: 3)],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AquaColors.ink,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _CharacterCard extends ConsumerWidget {
  const _CharacterCard({required this.onRest, required this.onPond});
  final VoidCallback onRest;
  final VoidCallback onPond;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    Widget stat(String label, int v, Color c) => Row(
      children: [
        SizedBox(width: 64, child: Muted(label)),
        Expanded(
          child: PixelBar(value: v, color: c, height: 12),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '$v%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIcon('face', size: 56),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.character} — เจ้าของฟาร์ม',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Muted(
                      'ความอิ่มลดลง 20/วัน · อิ่มหมด → สุขภาพลด · สุขภาพ 0 = Game Over',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          stat('อิ่ม', s.hunger, AquaColors.gold),
          stat('พลังงาน', s.energy, AquaColors.green),
          stat('สุขภาพ', s.health, AquaColors.red),
          stat('ความสุข', s.joy, AquaColors.sky),
          const SizedBox(height: 6),
          PixelButton(
            label: 'พักผ่อน (+40 พลังงาน)',
            icon: const PixelIcon('house', size: 20),
            style: PixelButtonStyle.gold,
            expand: true,
            onPressed: onRest,
          ),
          const SizedBox(height: 6),
          PixelButton(
            label: 'ไปบ่อปลา',
            icon: const PixelIcon('drop', size: 20),
            expand: true,
            onPressed: onPond,
          ),
        ],
      ),
    );
  }
}

class _DisasterCard extends ConsumerWidget {
  const _DisasterCard({required this.onRepair});
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final GameEngine e = session.engine;
    final s = session.state;
    final a = s.active;
    final dz = s.upcoming;
    final w = e.warnDays;

    final children = <Widget>[
      const Row(
        children: [
          PixelIcon('warn', size: 24),
          SizedBox(width: 8),
          Expanded(child: GoldTitle('ข่าวเตือนภัย', size: 18)),
        ],
      ),
      const SizedBox(height: 6),
    ];

    if (a != null) {
      final d = kDisasters[a.type]!;
      children
        ..add(
          Text(
            '${d.name}กำลังเกิด วันที่ ${a.dayIndex + 1}/${a.duration}',
            style: const TextStyle(
              color: AquaColors.bad,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        )
        ..add(Muted(d.dayTexts[a.dayIndex], size: 14));
    } else if (w > 0 && dz != null) {
      final d = kDisasters[dz.type]!;
      final rd = e.readiness()!;
      final rc = rd.pct >= 70
          ? AquaColors.green
          : (rd.pct >= 40 ? AquaColors.gold : AquaColors.red);
      children.addAll([
        Text(
          'แจ้งเตือน${d.name} — เริ่มในอีก $w วัน (วันที่ ${dz.startDay}) นาน ${d.duration} วัน',
          style: const TextStyle(
            color: AquaColors.bad,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Muted(d.message, size: 14),
        Muted('ความรุนแรง: ${severityLabel(dz.severity)}', size: 14),
        const SizedBox(height: 6),
        Text(
          'Readiness Check: ${rd.pct}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        PixelBar(value: rd.pct, color: rc),
        for (final k in d.equipment.keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                PixelIcon(kEquipment[k]!.icon, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${kEquipment[k]!.name}: มี ${s.equipmentCount(k)} / ต้อง ${d.equipment[k]}',
                  ),
                ),
                s.equipmentCount(k) >= d.equipment[k]!
                    ? const Text(
                        'พร้อม ✓',
                        style: TextStyle(
                          color: AquaColors.ok,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Text(
                        'ยังไม่พอ ✗',
                        style: TextStyle(
                          color: AquaColors.bad,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),
        Muted(
          'เสบียง ${fmtNum(e.supplyDays)} วัน / ภัย ${d.duration} วัน · น้ำ ${e.waterStatus.label} · เงิน ${s.money}฿',
          size: 13,
        ),
      ]);
    } else {
      children.addAll(const [
        Text(
          'ยังไม่มีประกาศภัยพิบัติ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Muted(
          'ภัยมี 4 แบบ: น้ำท่วม (แจ้ง 5 วัน) ภัยแล้ง (3) น้ำเสีย (4) อากาศร้อนจัด (3) และเกิดต่อเนื่องหลายวัน',
        ),
      ]);
    }

    if (s.damaged) {
      children.addAll([
        const SizedBox(height: 8),
        PixelButton(
          label: 'ซ่อมแซมและฟื้นฟูฟาร์ม ${s.repairCost}฿',
          icon: const PixelIcon('wrench', size: 20),
          style: PixelButtonStyle.gold,
          expand: true,
          onPressed: onRepair,
        ),
      ]);
    }

    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
