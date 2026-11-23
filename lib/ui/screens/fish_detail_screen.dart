import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/fish_data.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../theme.dart';

/// รายละเอียดปลาก่อนซื้อ + เลือกจำนวน + หน้ายืนยันการซื้อ
class FishDetailScreen extends ConsumerStatefulWidget {
  const FishDetailScreen({super.key, required this.fishId});
  final String fishId;

  @override
  ConsumerState<FishDetailScreen> createState() => _FishDetailScreenState();
}

class _FishDetailScreenState extends ConsumerState<FishDetailScreen> {
  int _qty = 1;

  Future<void> _buy(FishSpec f) async {
    final s = ref.read(gameProvider)!.state;
    final total = f.buyPrice * _qty;
    final ok = await confirmDialog(
      context,
      'ยืนยันซื้อ${f.name} $_qty ตัว รวม $total บาท? (เงินคงเหลือ ${s.money - total} บาท)',
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
    final stars = '★' * f.toughness + '☆' * (5 - f.toughness);

    TableRow row(String k, String v) => TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AquaColors.dark, width: 2)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(k, style: const TextStyle(fontSize: 14)),
        ),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            v,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    final String? problem = s.marketClosed
        ? 'ตลาดปิดชั่วคราว ซื้อไม่ได้'
        : _qty > free
        ? 'พื้นที่ในบ่อไม่พอ'
        : s.money < total
        ? 'เงินไม่พอ'
        : null;

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Container(
          color: AquaColors.panel,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PixelButton(
                    label: '−',
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_qty',
                      key: const ValueKey('qty'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PixelButton(
                    label: '+',
                    onPressed: _qty < max(1, free)
                        ? () => setState(() => _qty++)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Muted(
                      'รวม $total฿ · เงิน ${s.money}฿ · บ่อว่าง $free ตัว',
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'ซื้อปลา',
                      style: PixelButtonStyle.gold,
                      onPressed: problem == null ? () => _buy(f) : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PixelButton(
                      label: 'ยกเลิก',
                      style: PixelButtonStyle.dark,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              if (problem != null)
                Muted(problem, color: AquaColors.bad, size: 14),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PixelButton(
                label: '← กลับร้านปลา',
                style: PixelButtonStyle.dark,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            PixelPanel(
              child: Column(
                children: [
                  PixelIcon('f_${f.id}', size: 150),
                  const SizedBox(height: 6),
                  GoldTitle(f.name),
                  Muted(f.forWho, size: 14),
                ],
              ),
            ),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.1),
                1: FlexColumnWidth(1),
              },
              children: [
                row('ราคาซื้อ', '${f.buyPrice}฿ / ตัว'),
                row('ราคาขายเมื่อโตเต็มวัย', '${f.sellPrice}฿'),
                row('ระยะเวลาเติบโต', '~${f.daysToGrow} วัน (ให้อาหารพอดี)'),
                row('ความเร็วเติบโต', f.growthLabel),
                row('ความทนทาน / ทนสภาพน้ำ', stars),
                row('ต้องการออกซิเจน', '≥ ${f.o2Need}%'),
                row('อาหารที่ต้องใช้', '${f.feed} หน่วย/วัน'),
                row('ผลผลิตอาหาร', '${f.yieldDishes} จาน/ตัว'),
                row('ข้อดี', f.pros),
                row('ข้อเสีย', f.cons),
              ],
            ),
            const Muted('ค่าตัวเลขเป็นค่าจำลองในเกมเพื่อความสมดุล', size: 12),
          ],
        ),
      ),
    );
  }
}
