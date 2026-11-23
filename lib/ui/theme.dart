/// สีและวิดเจ็ตพื้นฐานสไตล์พิกเซล (สีจาก :root ของต้นแบบ)
library;

import 'package:material_ui/material_ui.dart';

abstract final class AquaColors {
  static const ink = Color(0xFF0A2229); // --k
  static const bg = Color(0xFF04161C); // --bg
  static const panel = Color(0xFF0F3A49); // --pn
  static const primary = Color(0xFF0E7490); // --pu
  static const light = Color(0xFFE8DCC4); // --pl / --mu
  static const gold = Color(0xFFE9B949); // --go
  static const red = Color(0xFFE0584D); // --rd
  static const card = Color(0xFF14505F);
  static const cardEdge = Color(0xFF2D7F8F);
  static const dark = Color(0xFF164E63);
  static const ok = Color(0xFF7BE07A);
  static const bad = Color(0xFFFF8F86);
  static const sky = Color(0xFF38BDF8);
  static const green = Color(0xFF65A30D);
}

/// ขนาดปุ่มกดขั้นต่ำตามกติกาโปรเจกต์
const double kMinTap = 48;

ThemeData buildAquaTheme() {
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AquaColors.primary,
      secondary: AquaColors.gold,
      surface: AquaColors.panel,
      error: AquaColors.red,
      onPrimary: Colors.white,
      onSecondary: AquaColors.ink,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: AquaColors.bg,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AquaColors.panel,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AquaColors.primary, width: 4),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AquaColors.gold,
      contentTextStyle: TextStyle(
        color: AquaColors.ink,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AquaColors.ink, width: 3),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AquaColors.panel,
      indicatorColor: AquaColors.gold,
      indicatorShape: square,
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AquaColors.ink,
      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.light, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AquaColors.gold, width: 3),
      ),
    ),
  );
}

/// ภาพพิกเซลจาก assets/pixel/ — ขยายแบบไม่เบลอ
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.name, {super.key, this.size = 28});

  /// ชื่อไฟล์ (ไม่รวม .png) เช่น 'coin', 'f_nila'
  final String name;

  /// ความกว้าง (ความสูงคำนวณตามสัดส่วนภาพ)
  final double size;

  @override
  Widget build(BuildContext context) {
    final fish = name.startsWith('f_');
    return Image.asset(
      'assets/pixel/$name.png',
      width: size,
      height: fish ? size * 7 / 12 : size,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}

/// กรอบหน้าต่างสไตล์ .win / .rc ของต้นแบบ
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.color = AquaColors.card,
    this.edge = AquaColors.cardEdge,
    this.padding = const EdgeInsets.all(10),
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final Widget child;
  final Color color;
  final Color edge;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AquaColors.ink,
        border: Border.all(color: AquaColors.ink, width: 3),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: edge, width: 3),
        ),
        child: child,
      ),
    );
  }
}

enum PixelButtonStyle { normal, gold, dark }

/// ปุ่มสไตล์ .btn ของต้นแบบ — สูงอย่างน้อย 48dp
class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = PixelButtonStyle.normal,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final PixelButtonStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      PixelButtonStyle.gold => (
        AquaColors.gold,
        AquaColors.ink,
        const Color(0xFFFFF3C4),
      ),
      PixelButtonStyle.dark => (
        AquaColors.dark,
        Colors.white,
        AquaColors.light,
      ),
      PixelButtonStyle.normal => (
        AquaColors.primary,
        Colors.white,
        AquaColors.light,
      ),
    };
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: .4),
        disabledForegroundColor: fg.withValues(alpha: .6),
        minimumSize: const Size(kMinTap, kMinTap),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: onPressed == null ? border.withValues(alpha: .4) : border,
            width: 3,
          ),
        ),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// แถบค่า (.bar ของต้นแบบ)
class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 14,
  });

  /// 0-100
  final num value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AquaColors.ink,
        border: Border.all(color: AquaColors.cardEdge, width: 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (value.clamp(0, 100)) / 100,
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// หัวข้อสีทอง (h2)
class GoldTitle extends StatelessWidget {
  const GoldTitle(this.text, {super.key, this.size = 21});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AquaColors.gold,
      fontSize: size,
      fontWeight: FontWeight.bold,
      shadows: const [Shadow(offset: Offset(2, 2), color: Colors.black)],
    ),
  );
}

/// ข้อความรอง (p)
class Muted extends StatelessWidget {
  const Muted(
    this.text, {
    super.key,
    this.color = AquaColors.light,
    this.size = 13,
  });
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: size),
  );
}

/// แสดงตัวเลขแบบเดียวกับ JS ของต้นแบบ (2.0 → "2", 2.5 → "2.5") ทั้งบนมือถือและเว็บ
String fmtNum(num? v) {
  if (v == null) return '-';
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toString();
}

/// ความกว้างสูงสุดของเกม (แนวตั้ง) เมื่อเปิดบนจอกว้าง
const double kMaxPhoneWidth = 480;
