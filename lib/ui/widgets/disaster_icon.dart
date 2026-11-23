import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../theme/theme.dart';

/// ไอคอนพิกเซลของภัยแต่ละแบบ (ใช้แทนข้อความยาว)
Widget disasterIcon(DisasterType t, {double size = 28}) => switch (t) {
  DisasterType.flood => PixelGlyph(
    Glyph.wave,
    size: size,
    color: AquaColors.waterLight,
  ),
  DisasterType.drought => PixelGlyph(
    Glyph.sun,
    size: size,
    color: AquaColors.gold,
  ),
  DisasterType.poll => PixelIcon('filt', size: size),
  DisasterType.heat => PixelGlyph(Glyph.sun, size: size, color: AquaColors.red),
};
