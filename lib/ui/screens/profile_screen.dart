import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../layout/responsive.dart';
import '../providers.dart';
import '../theme/theme.dart';

/// ข้อมูลตัวละคร (prof ในต้นแบบ): ชื่อ เงิน วัน เสบียง แถบค่าทั้ง 4 และกติกาสั้นๆ
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final s = session.state;
    final e = session.engine;

    Widget bar(String label, int value, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Bold(label)),
              Bold('$value%'),
            ],
          ),
          const SizedBox(height: 2),
          PixelBar(value: value, color: color, height: 20),
        ],
      ),
    );

    return Scaffold(
      key: const ValueKey('profile-screen'),
      body: GrassBackground(
        child: SafeArea(
          child: TabScroll(
            children: [
              WoodPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(
                      'ข้อมูลตัวละคร',
                      icon: PixelIcon('face', size: 30),
                    ),
                    Row(
                      children: [
                        const PixelIcon('face', size: 96),
                        const SizedBox(width: Gap.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Bold(
                                '${s.character} — เจ้าของฟาร์ม',
                                size: FontSize.label,
                                maxLines: 2,
                              ),
                              const SizedBox(height: Gap.xs),
                              Muted(
                                'เงิน ${s.money}฿ · วันที่ ${s.day} · เสบียงอยู่ได้ ${fmtNum(e.supplyDays)} วัน',
                                size: FontSize.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.m),
                    bar('อิ่ม', s.hunger, AquaColors.hunger),
                    bar('พลังงาน', s.energy, AquaColors.energy),
                    bar('สุขภาพ', s.health, AquaColors.health),
                    bar('ความสุข', s.joy, AquaColors.joy),
                    const SizedBox(height: Gap.xs),
                    const Muted(
                      'ความอิ่มหมด → สุขภาพลด · สุขภาพ 0 = Game Over · กินอาหารฟื้นอิ่ม/พลังงาน',
                      size: FontSize.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.m),
              PixelButton(
                label: 'กลับ',
                style: PixelButtonStyle.wood,
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
