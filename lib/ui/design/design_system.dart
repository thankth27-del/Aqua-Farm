/// ระบบดีไซน์กลางของเกม (ไฟล์เดียว): สี ตัวอักษร ระยะห่าง มุมมน เงา
/// และ widget มาตรฐาน — หน้าต่าง ๆ ใช้ของในไฟล์นี้เท่านั้น ห้ามกำหนดสี/ขนาดเองในหน้า
///
/// ทิศทาง: ฟาร์มปลาอบอุ่น เป็นมิตร อ่านง่าย ไม่รก — พื้นหลังสีนุ่ม การ์ดมุมมน เงาบาง
/// สีน้อยแต่คงที่: หลัก (ฟ้า-เขียวน้ำทะเล) / เน้น (เหลืองส้ม) / เตือน (แดง) / สำเร็จ (เขียว)
library;

import 'package:material_ui/material_ui.dart';

// ============================================================================
// โทเคน
// ============================================================================

/// สีทั้งหมดของเกม (ห้ามใช้สีอื่นในหน้า)
abstract final class DsColors {
  // หลัก: ฟ้า-เขียวน้ำทะเล
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF0B5A54);
  static const primarySoft = Color(0xFFD5EFEB);

  // เน้น: เหลืองส้ม (ปุ่มหลัก จุดที่ต้องกด)
  static const accent = Color(0xFFF59E0B);
  static const accentDark = Color(0xFFB45309);
  static const accentSoft = Color(0xFFFEF0D2);
  static const onAccent = Color(0xFF3B2500);

  // เตือน: แดง
  static const danger = Color(0xFFD64545);
  static const dangerSoft = Color(0xFFFDE6E6);

  // สำเร็จ: เขียว
  static const success = Color(0xFF2E9E5B);
  static const successSoft = Color(0xFFE1F4E8);

  // พื้นและตัวอักษร
  static const background = Color(0xFFEEF5F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6FAF8);
  static const border = Color(0xFFD5E2DE);
  static const text = Color(0xFF1E2D2B);
  static const textMuted = Color(0xFF5A6B68);
  static const onPrimary = Color(0xFFFFFFFF);
  static const scrim = Color(0x8C0F1F1D);

  // ชั้นทับฉากแบบเกม: แผงเข้มกึ่งโปร่ง ตัวอักษรขาว ขอบเข้มรอบปุ่ม
  static const glass = Color(0xD60E2826);
  static const glassEdge = Color(0x4DFFFFFF);
  static const onGlass = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0B2623);
}

/// ระยะห่าง 4 / 8 / 16 / 24
abstract final class DsSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
}

/// มุมมน
abstract final class DsRadius {
  static const small = 8.0;
  static const card = 14.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

/// เงาบาง
abstract final class DsShadow {
  static const card = [
    BoxShadow(color: Color(0x140F3D36), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x240F3D36), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

/// ฟอนต์ไทยเดียวทั้งแอป + ลำดับขนาด หัวข้อ / เนื้อหา / คำอธิบายเล็ก
abstract final class DsText {
  static const font = 'Sarabun';

  /// หัวข้อหน้า/ส่วน
  static const title = TextStyle(
    fontFamily: font,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: DsColors.text,
  );

  /// เนื้อหา
  static const body = TextStyle(
    fontFamily: font,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: DsColors.text,
  );

  /// คำอธิบายเล็ก
  static const caption = TextStyle(
    fontFamily: font,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: DsColors.textMuted,
  );

  /// ตัวเลข/ค่าเด่น และป้ายปุ่ม (ระดับเนื้อหา แต่หนา)
  static const strong = TextStyle(
    fontFamily: font,
    fontSize: 16,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: DsColors.text,
  );
}

/// ปุ่มกดได้ขั้นต่ำ (กติกาโปรเจกต์)
const double kDsMinTap = 48;

/// ธีมของระบบดีไซน์ใหม่ (ฟอนต์ Sarabun พื้นสีนุ่ม)
ThemeData buildDesignTheme() {
  final base = ThemeData(
    brightness: Brightness.light,
    fontFamily: DsText.font,
    colorScheme: const ColorScheme.light(
      primary: DsColors.primary,
      secondary: DsColors.accent,
      surface: DsColors.surface,
      error: DsColors.danger,
      onPrimary: DsColors.onPrimary,
      onSecondary: DsColors.onAccent,
      onSurface: DsColors.text,
    ),
    scaffoldBackgroundColor: DsColors.background,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          fontFamily: DsText.font,
          bodyColor: DsColors.text,
          displayColor: DsColors.text,
        )
        .copyWith(
          titleLarge: DsText.title,
          bodyMedium: DsText.body,
          bodySmall: DsText.caption,
        ),
  );
}

// ============================================================================
// ปุ่ม
// ============================================================================

/// กดแล้วยุบเล็กน้อย (ฟีดแบ็กสั้น ๆ ของปุ่ม/การ์ดที่กดได้)
class _Press extends StatefulWidget {
  const _Press({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? .96 : 1,
      duration: const Duration(milliseconds: 90),
      child: widget.child,
    ),
  );
}

/// แบบปุ่มพื้นฐาน (ใช้ผ่าน [PrimaryButton] / [SecondaryButton])
class _DsButton extends StatelessWidget {
  const _DsButton({
    required this.label,
    required this.onPressed,
    required this.fill,
    required this.fg,
    required this.border,
    required this.shadow,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color fill;
  final Color fg;
  final Color? border;
  final bool shadow;
  final Widget? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: DsSpace.s)],
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: DsText.strong.copyWith(color: fg),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: _Press(
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : .45,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kDsMinTap,
                minWidth: kDsMinTap,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(DsRadius.card),
                  border: border == null
                      ? null
                      : Border.all(color: border!, width: 1.5),
                  boxShadow: shadow && enabled ? DsShadow.card : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.m,
                    vertical: DsSpace.s,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มหลัก: เด่นสุดในหน้า (ใช้หน้าละ 1 ปุ่ม) — สีเน้นเหลืองส้ม
/// [danger] = ยืนยันการลบ/ทิ้ง (พื้นแดง)
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;
  final bool danger;

  @override
  Widget build(BuildContext context) => _DsButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    expand: expand,
    fill: danger ? DsColors.danger : DsColors.accent,
    fg: danger ? DsColors.onPrimary : DsColors.onAccent,
    border: null,
    shadow: true,
  );
}

/// ปุ่มรอง: พื้นขาว ขอบสีหลัก — [danger] = ขอบ/ตัวอักษรแดง (เช่น ทิ้ง)
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool expand;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? DsColors.danger : DsColors.primary;
    return _DsButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      expand: expand,
      fill: DsColors.surface,
      fg: c,
      border: c,
      shadow: false,
    );
  }
}

// ============================================================================
// การ์ด ป้าย แถบ หัวข้อ
// ============================================================================

/// โทนของการ์ด/ป้าย
enum DsTone { normal, info, accent, success, danger }

Color _toneFill(DsTone t) => switch (t) {
  DsTone.normal => DsColors.surface,
  DsTone.info => DsColors.primarySoft,
  DsTone.accent => DsColors.accentSoft,
  DsTone.success => DsColors.successSoft,
  DsTone.danger => DsColors.dangerSoft,
};

Color _toneStrong(DsTone t) => switch (t) {
  DsTone.normal => DsColors.border,
  DsTone.info => DsColors.primary,
  DsTone.accent => DsColors.accentDark,
  DsTone.success => DsColors.success,
  DsTone.danger => DsColors.danger,
};

/// การ์ดมุมมน เงาบาง — [onTap] = กดได้ (ยุบเล็กน้อยตอนกด)
/// [selected] = ขอบสีหลักหนา (ตัวที่เลือกอยู่)
class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.onTap,
    this.tone = DsTone.normal,
    this.selected = false,
    this.padding = const EdgeInsets.all(DsSpace.m),
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final DsTone tone;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: _toneFill(tone),
        borderRadius: BorderRadius.circular(DsRadius.card),
        border: Border.all(
          color: selected ? DsColors.primary : _toneStrong(tone),
          width: selected ? 2.5 : 1,
        ),
        boxShadow: DsShadow.card,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Press(enabled: true, child: card),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: card,
    );
  }
}

/// ป้ายค่าสถานะ: ไอคอน + ชื่อเล็ก + ค่าเด่น (ใช้ในแถบบน: เงิน วัน น้ำ อาหาร)
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = DsTone.normal,
    this.tooltip,
  });

  final String label;
  final String value;
  final Widget? icon;
  final DsTone tone;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: kDsMinTap),
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpace.s,
          vertical: DsSpace.xs,
        ),
        decoration: BoxDecoration(
          color: _toneFill(tone),
          borderRadius: BorderRadius.circular(DsRadius.card),
          border: Border.all(color: _toneStrong(tone)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: DsSpace.xs)],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, style: DsText.caption),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: DsText.strong.copyWith(
                        color: tone == DsTone.danger
                            ? DsColors.danger
                            : DsColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// แถบความคืบหน้ามุมมน (ค่าเปลี่ยนแล้วเลื่อนนุ่ม ๆ)
/// [value] 0..1 · [label] ชื่อด้านซ้าย · [trailing] ข้อความด้านขวา (เช่น "80")
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.label,
    this.trailing,
    this.color = DsColors.primary,
    this.height = 10,
  });

  final double value;
  final String? label;
  final String? trailing;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(DsRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: DsColors.border),
            TweenAnimationBuilder<double>(
              tween: Tween(end: v),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (_, x, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: x,
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      label: label,
      value: trailing ?? '${(v * 100).round()}%',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null || trailing != null)
            Padding(
              padding: const EdgeInsets.only(bottom: DsSpace.xs),
              child: Row(
                children: [
                  if (label != null)
                    Expanded(child: Text(label!, style: DsText.caption)),
                  if (trailing != null) Text(trailing!, style: DsText.strong),
                ],
              ),
            ),
          bar,
        ],
      ),
    );
  }
}

/// หัวข้อส่วน 1 บรรทัด: ไอคอน + ชื่อ + ของท้าย (ป้าย/ปุ่มเล็ก)
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.s),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: DsSpace.s)],
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DsText.title,
              semanticsLabel: text,
            ),
          ),
          if (trailing != null)
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
        ],
      ),
    );
  }
}

/// ป้ายเล็กมุมมน (จำนวน สถานะ)
class DsTag extends StatelessWidget {
  const DsTag(this.text, {super.key, this.tone = DsTone.info});
  final String text;
  final DsTone tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: DsSpace.s, vertical: 2),
    decoration: BoxDecoration(
      color: _toneFill(tone == DsTone.normal ? DsTone.info : tone),
      borderRadius: BorderRadius.circular(DsRadius.pill),
    ),
    child: Text(
      text,
      style: DsText.caption.copyWith(
        fontWeight: FontWeight.w700,
        color: _toneStrong(tone == DsTone.normal ? DsTone.info : tone),
      ),
    ),
  );
}

// ============================================================================
// หน้าต่างยืนยัน / แผ่นล่าง
// ============================================================================

/// หน้าต่างยืนยันมาตรฐาน: ไอคอน หัวข้อ ข้อความ [ยกเลิก] [ตกลง]
/// คืน true เมื่อกดยืนยัน · [danger] = การลบ/ทิ้ง (ปุ่มยืนยันสีแดง)
Future<bool> showGameDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? icon,
  String confirmLabel = 'ตกลง',
  String cancelLabel = 'ยกเลิก',
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: DsColors.scrim,
    builder: (c) => Dialog(
      backgroundColor: DsColors.surface,
      insetPadding: const EdgeInsets.all(DsSpace.l),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRadius.sheet),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(DsSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon, const SizedBox(height: DsSpace.s)],
              Text(title, textAlign: TextAlign.center, style: DsText.title),
              if (message != null) ...[
                const SizedBox(height: DsSpace.s),
                Text(message, textAlign: TextAlign.center, style: DsText.body),
              ],
              const SizedBox(height: DsSpace.l),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: cancelLabel,
                      expand: true,
                      onPressed: () => Navigator.pop(c, false),
                    ),
                  ),
                  const SizedBox(width: DsSpace.s),
                  Expanded(
                    child: PrimaryButton(
                      label: confirmLabel,
                      expand: true,
                      danger: danger,
                      onPressed: () => Navigator.pop(c, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// แผ่นล่างมาตรฐาน: ขีดจับ หัวข้อ เนื้อหา (เลื่อนได้ถ้ายาว)
Future<T?> showGameSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DsColors.surface,
    barrierColor: DsColors.scrim,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DsRadius.sheet)),
    ),
    builder: (c) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DsSpace.l,
          DsSpace.s,
          DsSpace.l,
          DsSpace.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DsSpace.m),
                decoration: BoxDecoration(
                  color: DsColors.border,
                  borderRadius: BorderRadius.circular(DsRadius.pill),
                ),
              ),
            ),
            Text(title, style: DsText.title, textAlign: TextAlign.center),
            const SizedBox(height: DsSpace.m),
            builder(c),
          ],
        ),
      ),
    ),
  );
}
