/// คะแนนสรุปตอนจบเกม (ใช้ทั้งหน้าชนะและหน้า Game Over)
library;

import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../game/game_engine.dart';
import '../theme/theme.dart';
import 'mode_dialog.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final GameSummary summary;

  @override
  Widget build(BuildContext context) {
    final sum = summary;
    return Column(
      key: const ValueKey('summary'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Tag(
            'โหมด${kDifficulties[sum.mode]!.name}',
            color: modeColor(sum.mode),
            textColor: AquaColors.paper,
          ),
        ),
        const SizedBox(height: Gap.m),
        _GradeStars(grade: sum.grade),
        const SizedBox(height: Gap.m),
        PaperCard(
          child: Column(
            children: [
              _Row(
                icon: const PixelGlyph(
                  Glyph.star,
                  size: 22,
                  color: AquaColors.gold,
                ),
                label: 'เกรดรวม',
                value: sum.grade,
              ),
              _Row(
                icon: const PixelIcon('warn', size: 24),
                label: 'ภัยที่รอด',
                value: '${sum.disastersSurvived} ครั้ง',
              ),
              _Row(
                icon: const PixelIcon('coin', size: 24),
                label: 'เงินคงเหลือ',
                value: '${sum.money}฿',
              ),
              _Row(
                icon: const PixelIcon('cal', size: 24),
                label: sum.won ? 'จำนวนวัน' : 'วันที่ไปถึง',
                value: '${sum.days}/${sum.targetDays} วัน',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradeStars extends StatelessWidget {
  const _GradeStars({required this.grade});
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'เกรดรวม $grade',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: PixelGlyph(
                  Glyph.star,
                  size: 34,
                  color: i < (kGradePoints[grade] ?? 1)
                      ? AquaColors.gold
                      : AquaColors.creamDark,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 30, child: Center(child: icon)),
          const SizedBox(width: Gap.s),
          Expanded(child: Muted(label, size: FontSize.body)),
          Bold(value, size: FontSize.label),
        ],
      ),
    );
  }
}
