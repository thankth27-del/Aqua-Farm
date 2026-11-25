/// หน้าเลือกโหมดความยาก (ก่อนตั้งชื่อเซฟเกมใหม่)
library;

import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart' show DsColors;

import '../../data/difficulty.dart';
import '../theme/theme.dart';

/// สีประจำโหมด
Color modeColor(Difficulty d) => switch (d) {
  Difficulty.easy => AquaColors.leaf,
  Difficulty.normal => AquaColors.goldDark,
  Difficulty.hard => AquaColors.redDark,
};

const Map<Difficulty, String> _modeHint = {
  Difficulty.easy: 'ของถูก ขายได้ราคาดี ภัยเบา',
  Difficulty.normal: 'ความหนักมาตรฐาน',
  Difficulty.hard: 'ของแพง ขายได้น้อย ภัยรุนแรง น้ำเสียเร็ว',
};

/// คืนโหมดที่เลือก หรือ null เมื่อยกเลิก
Future<Difficulty?> modeDialog(BuildContext context) {
  return showDialog<Difficulty>(
    context: context,
    barrierDismissible: false,
    barrierColor: DsColors.scrim,
    builder: (c) => PixelDialog(
      title: 'เลือกความยาก',
      icon: const PixelIcon('warn', size: 48),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final d in Difficulty.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.s),
              child: _ModeCard(mode: d, onTap: () => Navigator.pop(c, d)),
            ),
          const Muted(
            'ยิ่งใกล้วันเป้าหมาย ของยิ่งแพง ภัยยิ่งหนัก และข่าวเตือนมาช้าลง',
            align: TextAlign.center,
          ),
        ],
      ),
      actions: [
        PixelButton(
          label: 'ยกเลิก',
          style: PixelButtonStyle.wood,
          onPressed: () => Navigator.pop(c),
        ),
      ],
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final Difficulty mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = kDifficulties[mode]!;
    return Pressable(
      key: ValueKey('mode-${mode.name}'),
      label: 'โหมด${spec.name} รอดครบ ${spec.targetDays} วัน',
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: PaperCard(
          child: Row(
            children: [
              PixelBox(
                fill: modeColor(mode),
                depth: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: SizedBox(
                  width: 72,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: OutlinedText(
                        spec.name,
                        size: FontSize.label,
                        color: AquaColors.paper,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bold('รอดครบ ${spec.targetDays} วัน'),
                    Muted(_modeHint[mode]!),
                  ],
                ),
              ),
              const PixelGlyph(
                Glyph.arrowRight,
                size: 18,
                color: AquaColors.textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
