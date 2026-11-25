import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../../game/game_state.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import '../widgets/disaster_icon.dart';
import 'report_screen.dart';

/// เวลาที่ฉากภัยเล่นก่อนไปหน้ารายงานเอง (ต้นแบบ: 70 เฟรม × 100ms)
const kEventSceneDuration = Duration(milliseconds: 7000);

/// ฉากภัยพิบัติหลังจบวัน (event ในต้นแบบ): ฟาร์มพร้อมเอฟเฟกต์ภัยเต็มระดับของวันนั้น
/// แถบเวลา และกล่องข้อความ "ภัย วันที่ x/y" — ครบเวลาหรือกดปุ่มแล้วไปหน้ารายงาน
class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bar =
      AnimationController(vsync: this, duration: kEventSceneDuration)
        ..addStatusListener((st) {
          if (st == AnimationStatus.completed) _toReport();
        })
        ..forward();
  bool _left = false;

  void _toReport() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ReportScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider)!.state;
    final ev = s.lastReport?.event;
    if (ev == null) return const ReportScreen();
    final d = kDisasters[ev.type]!;
    final base = FarmSceneData.fromState(s, 0);
    final scene = FarmSceneData(
      pond: base.pond,
      equipment: base.equipment,
      damaged: base.damaged,
      fxType: ev.type,
      fxLevel:
          d.visualLevel[disasterBaseDay(ev.type, ev.duration, ev.dayIndex)],
    );

    return Scaffold(
      key: const ValueKey('event-screen'),
      body: GrassBackground(
        child: SafeArea(
          // แนวนอน: ฉาก | ข้อความและปุ่ม
          child: TabScroll(
            header: 1,
            children: [
              PixelScene(painterBuilder: (t) => FarmPainter(t, scene)),
              const SizedBox(height: Gap.s),
              AnimatedBuilder(
                animation: _bar,
                builder: (_, _) => PixelBar(
                  value: (_bar.value * 100).round(),
                  color: AquaColors.gold,
                  height: 14,
                ),
              ),
              const SizedBox(height: Gap.m),
              _EventBubble(event: ev, name: d.name),
              const SizedBox(height: Gap.m),
              PixelButton(
                label: 'ดูรายงานทันที',
                size: PixelButtonSize.large,
                expand: true,
                onPressed: _toReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventBubble extends StatelessWidget {
  const _EventBubble({required this.event, required this.name});
  final EventReport event;
  final String name;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      fill: Colors.white,
      depth: 4,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              disasterIcon(event.type, size: 32),
              const SizedBox(width: Gap.s),
              Flexible(
                child: Bold(
                  '$name วันที่ ${event.dayIndex + 1}/${event.duration}',
                  key: const ValueKey('event-title'),
                  size: FontSize.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          Text(
            event.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: FontSize.body,
              color: AquaColors.text,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
