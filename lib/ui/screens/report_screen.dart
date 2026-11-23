import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../data/food_data.dart';
import '../providers.dart';
import '../theme.dart';

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
      'A' => AquaColors.sky,
      _ => Colors.white,
    };

    TableRow row(String icon, String k, String v) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              PixelIcon(icon, size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(k)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
    TableRow kv(String k, String v) => TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Muted(k, size: 14),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(v),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GoldTitle('รายงานประจำวัน — วันที่ ${r.day}'),
            const SizedBox(height: 8),
            PixelPanel(
              child: Column(
                children: [
                  Text(
                    r.grade,
                    style: TextStyle(
                      fontSize: 84,
                      height: 1,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                      shadows: const [
                        Shadow(offset: Offset(4, 4), color: Colors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      row('coin', 'รายได้วันนี้', '${r.earned}฿'),
                      row('coin', 'เงินคงเหลือ', '${r.money}฿'),
                      row(
                        'drop',
                        'น้ำ / ออกซิเจน',
                        '${r.water}% / ${r.o2.round()}%',
                      ),
                      row(
                        'f_nila',
                        'ปลาในบ่อ',
                        '${r.fish} ตัว${r.died > 0 ? ' (สูญเสีย ${r.died})' : ''}',
                      ),
                      row(
                        'fry',
                        'เสบียง',
                        '${r.servings} จาน · อยู่ได้ ${fmtNum(r.supplyDays)} วัน',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (r.done.isNotEmpty)
              Muted(
                'ถนอมอาหารเสร็จ: ${r.done.map((d) => '${kFoods[d.food]!.name} x${d.qty}').join(', ')}',
                color: AquaColors.ok,
                size: 14,
              ),
            if (r.spoiled > 0)
              Muted(
                'อาหารหมดอายุ ${r.spoiled} จาน (ไปทิ้งที่คลังสินค้า)',
                color: AquaColors.bad,
                size: 14,
              ),
            if (z != null)
              PixelPanel(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kDisasters[z.type]!.name} — วันที่ ${z.dayIndex + 1}/${z.duration}',
                      style: const TextStyle(
                        color: AquaColors.bad,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Muted(z.text, size: 14),
                    const SizedBox(height: 6),
                    Table(
                      children: [
                        kv('ความพร้อมของอุปกรณ์วันนี้', '${z.protectionPct}%'),
                        kv(
                          'ปลาที่สูญเสียวันนี้ / สะสม',
                          '${z.lost} / ${z.cumulativeLost} (เหลือ ${z.fishAfter} จาก ${z.fishBefore})',
                        ),
                        kv(
                          'ค่าเสียหายวันนี้ / สะสม',
                          '${z.cost}฿ / ${z.cumulativeCost}฿',
                        ),
                        if (z.food > 0 || z.cumulativeFood > 0)
                          kv(
                            'อาหารเสียหายจากน้ำ',
                            '${z.food} จาน (สะสม ${z.cumulativeFood})',
                          ),
                        if (z.sandUsed > 0)
                          kv('กระสอบทรายที่ใช้สะสม', '${z.sandUsed}'),
                      ],
                    ),
                    if (z.outage)
                      const Muted(
                        'ไฟดับ — ตู้เย็นหยุดทำงาน อาหารเสียเร็วขึ้น',
                        color: AquaColors.bad,
                        size: 14,
                      ),
                    if (z.marketClosed)
                      const Muted(
                        'ตลาดปิด — ซื้อขายไม่ได้ ต้องใช้เสบียง',
                        color: AquaColors.bad,
                        size: 14,
                      ),
                    const SizedBox(height: 6),
                    if (z.last) ...[
                      Text(
                        'สรุปภัยพิบัติ: ปลาก่อนเกิดภัย ${z.fishBefore} → เหลือ ${z.fishAfter} · ค่าฟื้นฟู ${s.repairCost}฿ · เสบียงเหลืออยู่ได้ ${fmtNum(z.supplyDaysAfter)} วัน',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      s.repairCost > 0
                          ? const Muted(
                              'ไปที่ "เตรียมภัย" เพื่อซ่อมแซมและฟื้นฟู · ซื้อปลาใหม่ที่ร้านปลา',
                              size: 14,
                            )
                          : const Muted(
                              'ฟาร์มไม่เสียหาย',
                              color: AquaColors.ok,
                              size: 14,
                            ),
                    ] else
                      const Muted(
                        'ภัยยังไม่จบ กด "เริ่มวันใหม่" แล้วตรวจฟาร์ม/เสบียง ก่อนกด "จบวัน"',
                        size: 14,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            PixelButton(
              label: 'เริ่มวันใหม่',
              style: PixelButtonStyle.gold,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
