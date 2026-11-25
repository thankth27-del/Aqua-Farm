import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart';
import 'colors.dart';

/// ฟอนต์ไทยเดียวทั้งแอป (Sarabun ฝังไว้ใน assets/fonts ไม่ดึงจากเน็ต)
const String kFont = DsText.font;

/// ขนาดปุ่มกดขั้นต่ำตามกติกาโปรเจกต์
const double kMinTap = 48;

/// ระยะห่างมาตรฐาน (ตามระบบดีไซน์ 4 / 8 / 16 / 24)
abstract final class Gap {
  static const xs = DsSpace.xs;
  static const s = DsSpace.s;
  static const m = DsSpace.m;
  static const l = DsSpace.l;
  static const xl = 32.0;
}

/// ขนาดตัวอักษร: คำอธิบายเล็ก / เนื้อหา / ป้ายปุ่ม / หัวข้อ / ตัวเลขใหญ่
abstract final class FontSize {
  static const small = 14.0;
  static const body = 16.0;
  static const label = 17.0;
  static const title = 22.0;
  static const big = 28.0;
}

ThemeData buildAquaTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    fontFamily: kFont,
    colorScheme: const ColorScheme.light(
      primary: DsColors.primary,
      secondary: DsColors.accent,
      surface: DsColors.surface,
      error: DsColors.danger,
      onPrimary: DsColors.onPrimary,
      onSecondary: DsColors.onAccent,
      onSurface: AquaColors.text,
    ),
    scaffoldBackgroundColor: AquaColors.bgGreen,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: kFont,
          bodyColor: AquaColors.text,
          displayColor: AquaColors.text,
        )
        .copyWith(
          bodyMedium: const TextStyle(
            fontFamily: kFont,
            fontSize: FontSize.body,
            color: AquaColors.text,
            height: 1.35,
          ),
        ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: DsColors.text,
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
      ),
      textStyle: TextStyle(
        fontFamily: kFont,
        color: DsColors.surface,
        fontSize: FontSize.small,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AquaColors.text,
      selectionColor: AquaColors.goldLight,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AquaColors.paper,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
        borderSide: BorderSide(color: DsColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
        borderSide: BorderSide(color: DsColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
        borderSide: BorderSide(color: AquaColors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(DsRadius.small)),
        borderSide: BorderSide(color: AquaColors.red, width: 2),
      ),
    ),
  );
}

/// แสดงตัวเลขแบบเดียวกับ JS ของต้นแบบ (2.0 → "2", 2.5 → "2.5") ทั้งบนมือถือและเว็บ
String fmtNum(num? v) {
  if (v == null) return '-';
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toString();
}
