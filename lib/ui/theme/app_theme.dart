import 'package:material_ui/material_ui.dart';

import 'colors.dart';

/// ฟอนต์ไทยกลมมน ฝังไว้ใน assets/fonts (ไม่ดึงจากเน็ต)
const String kFont = 'Mali';

/// ขนาดปุ่มกดขั้นต่ำตามกติกาโปรเจกต์
const double kMinTap = 48;

/// ความกว้างสูงสุดของเกม (แนวตั้ง) เมื่อเปิดบนจอกว้าง
const double kMaxPhoneWidth = 480;

/// ระยะห่างมาตรฐาน
abstract final class Gap {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 14.0;
  static const l = 20.0;
  static const xl = 28.0;
}

/// ขนาดตัวอักษร (ใหญ่ขึ้นจากเดิม อ่านง่ายบนมือถือ)
abstract final class FontSize {
  static const small = 14.0;
  static const body = 17.0;
  static const label = 18.0;
  static const title = 24.0;
  static const big = 30.0;
}

ThemeData buildAquaTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    fontFamily: kFont,
    colorScheme: const ColorScheme.light(
      primary: AquaColors.gold,
      secondary: AquaColors.water,
      surface: AquaColors.cream,
      error: AquaColors.red,
      onPrimary: AquaColors.ink,
      onSecondary: Colors.white,
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
      decoration: BoxDecoration(color: AquaColors.ink),
      textStyle: TextStyle(
        fontFamily: kFont,
        color: AquaColors.cream,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.ink, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.goldDark, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.red, width: 3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.red, width: 3),
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
