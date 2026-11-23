import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../data/fish_data.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme.dart';
import 'fish_detail_screen.dart';

/// แท็บ "ปลา": บ่อปลา และร้านปลา
class FishTab extends StatefulWidget {
  const FishTab({super.key});

  @override
  State<FishTab> createState() => _FishTabState();
}

class _FishTabState extends State<FishTab> {
  bool _shop = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'บ่อปลา',
                  icon: const PixelIcon('drop', size: 20),
                  style: _shop ? PixelButtonStyle.dark : PixelButtonStyle.gold,
                  onPressed: () => setState(() => _shop = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'ร้านปลา',
                  icon: const PixelIcon('f_nila', size: 22),
                  style: _shop ? PixelButtonStyle.gold : PixelButtonStyle.dark,
                  onPressed: () => setState(() => _shop = true),
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

    Widget stat(String t) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(t, style: const TextStyle(fontSize: 13)),
    );

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PixelScene(painterBuilder: (t) => PondPainter(t, scene)),
        const SizedBox(height: 10),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'คุณภาพน้ำ: ${ws.label} (${s.water}%)',
                style: TextStyle(
                  color: wc,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              PixelBar(value: s.water, color: wc),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stat('Ammonia ${s.ammonia.toStringAsFixed(2)} ppm'),
                        stat('Nitrate ${s.nitrate.toStringAsFixed(1)} ppm'),
                        stat('อุณหภูมิ ${s.temp.toStringAsFixed(1)}°C'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stat('Nitrite ${s.nitrite.toStringAsFixed(2)} ppm'),
                        stat('ออกซิเจน ${_num(s.o2)}%'),
                        stat('กรองชีวภาพ ${s.bio}%'),
                      ],
                    ),
                  ),
                ],
              ),
              const Muted(
                'ค่าน้ำเป็นแบบจำลองเพื่อการเรียนรู้ ไม่ใช่คำแนะนำการเลี้ยงจริง',
                size: 12,
              ),
            ],
          ),
        ),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ให้อาหาร ($fu หน่วย/วัน)${s.fed > 0 ? ' — วันนี้ให้แล้ว' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final (lv, name) in const [
                    (1, 'น้อย'),
                    (2, 'พอดี'),
                    (3, 'มาก'),
                  ]) ...[
                    Expanded(
                      child: PixelButton(
                        label: '$name ${e.feedCost(lv)}฿',
                        onPressed: s.fed > 0
                            ? null
                            : () => showResult(
                                context,
                                ctl.run((e) => e.feed(lv)),
                              ),
                      ),
                    ),
                    if (lv < 3) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'เปลี่ยนน้ำ $kChangeWaterCost฿',
                      onPressed: () =>
                          showResult(context, ctl.run((e) => e.changeWater())),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PixelButton(
                      label: 'เติมอากาศ $kAerateCost฿',
                      icon: const PixelIcon('bub', size: 18),
                      onPressed: () =>
                          showResult(context, ctl.run((e) => e.aerate())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              PixelButton(
                label: 'จับปลา (${e.matureCount})',
                style: PixelButtonStyle.gold,
                expand: true,
                onPressed: () =>
                    showResult(context, ctl.run((e) => e.catchFish())),
              ),
            ],
          ),
        ),
        PixelPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ปลาในบ่อ ${s.pond.length}/$kPondCapacity',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              if (s.pond.isEmpty)
                const Muted('ยังไม่มีปลา ไปซื้อที่ร้านปลา', size: 14),
              for (final f in s.pond)
                Row(
                  children: [
                    PixelIcon('f_${f.type}', size: 26),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 84,
                      child: Text(
                        kFish[f.type]!.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: PixelBar(
                        value: f.growth,
                        color: f.mature ? AquaColors.gold : AquaColors.primary,
                        height: 12,
                      ),
                    ),
                    SizedBox(
                      width: 92,
                      child: Text(
                        '${f.mature ? 'พร้อมจับ' : '${f.growth}%'} · ♥${f.health.round()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
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

class _FishShop extends ConsumerWidget {
  const _FishShop();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameProvider)!.state;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const GoldTitle('ร้านปลา'),
        Muted(
          'แตะการ์ดเพื่อดูรายละเอียดก่อนซื้อ · บ่อ ${s.pond.length}/$kPondCapacity ตัว',
          size: 14,
        ),
        if (s.marketClosed)
          const Muted(
            'ตลาดปิดชั่วคราว ซื้อไม่ได้',
            color: AquaColors.bad,
            size: 14,
          ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            for (final f in kFish.values)
              InkWell(
                key: ValueKey('fish-card-${f.id}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FishDetailScreen(fishId: f.id),
                  ),
                ),
                child: PixelPanel(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PixelIcon('f_${f.id}', size: 72),
                      const SizedBox(height: 6),
                      Text(
                        f.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const PixelIcon('coin', size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '${f.buyPrice}',
                            style: const TextStyle(
                              color: AquaColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
