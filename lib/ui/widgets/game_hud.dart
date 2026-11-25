/// ชิ้นส่วนกลางของหน้าเกมแบบ "ฉากเต็มจอ": แผงโปร่งแสงทับฉาก, HUD แถบเดียว,
/// ปุ่มกลมใหญ่, ถาดปุ่มล่าง, กล่องคำพูดตัวละคร และแผ่นรายละเอียดด้านล่าง
///
/// ทุกหน้าใช้ชิ้นเหล่านี้ ขนาดอ่านง่ายบนฉาก: ตัวอักษรสำคัญ ≥16 หัวข้อ ≥22 ไอคอน ≥32
library;

import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart';
import '../layout/responsive.dart';
import '../theme/theme.dart';

/// ตัวอักษรขาวบนแผงเข้ม (มีเงาเข้มบาง ๆ ให้อ่านได้แม้แผงโปร่ง)
const _onGlassShadow = [
  Shadow(color: Color(0x99000000), offset: Offset(0, 1.5)),
];

TextStyle glassText({double size = 16, Color color = DsColors.onGlass}) =>
    TextStyle(
      fontFamily: DsText.font,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: color,
      shadows: _onGlassShadow,
    );

/// แผงเข้มกึ่งโปร่งวางทับฉาก — ตัวอักษรข้างในเป็นสีขาวหนา
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.radius = 18,
    this.color = DsColors.glass,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: DsColors.glassEdge, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(style: glassText(), child: child),
      ),
    );
  }
}

/// ค่า 1 ช่องใน HUD: ไอคอนใหญ่ + ตัวเลขใหญ่ (ชื่อค่าอยู่ใน tooltip/ตัวอ่านจอ)
class HudStat extends StatelessWidget {
  const HudStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.dot,
    this.tooltip,
  });

  final Widget icon;
  final String value;

  /// ชื่อค่า เช่น "เงิน" (ไม่แสดงบนจอ อ่านผ่าน tooltip และตัวอ่านจอ)
  final String label;

  /// จุดสีบอกระดับ (เช่น คุณภาพน้ำ)
  final Color? dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: Semantics(
        label: '$label $value',
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 5),
              if (dot != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, maxLines: 1, style: glassText(size: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ปุ่มกลมใหญ่ + ป้ายสั้น 1 คำ (ปุ่มรองในถาด / ปุ่มมุมจอ)
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.diameter = 60,
    this.color = DsColors.surface,
    this.showLabel = true,
    this.labelOnScene = false,
    this.tooltip,
  });

  final Widget icon;

  /// ป้ายสั้นใต้ปุ่ม (1 คำ)
  final String label;
  final VoidCallback? onPressed;
  final double diameter;
  final Color color;

  /// false = ไอคอนอย่างเดียว (ป้ายอยู่ใน tooltip)
  final bool showLabel;

  /// ป้ายวางบนฉากโดยตรง → ใส่แผงโปร่งรองหลัง
  final bool labelOnScene;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final d = diameter < Responsive.minTap ? Responsive.minTap : diameter;
    Widget circle = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: DsColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: DsColors.ink, offset: Offset(0, 3))],
      ),
      child: Center(child: icon),
    );
    Widget? text;
    if (showLabel) {
      text = Text(
        label,
        maxLines: 1,
        style: glassText(size: 16),
        textAlign: TextAlign.center,
      );
      if (labelOnScene) {
        text = GlassPanel(
          radius: 10,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: text,
        );
      }
      // ป้ายกว้างไม่เกินปุ่ม + 28 (ย่อแทนการดันปุ่มหลักให้แคบ เช่น ฟอนต์ใหญ่ของเครื่อง)
      text = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: d + 28),
        child: FittedBox(fit: BoxFit.scaleDown, child: text),
      );
    }
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        if (text != null) ...[const SizedBox(height: 4), text],
      ],
    );
    return Tooltip(
      message: tooltip ?? label,
      child: Pressable(
        label: tooltip ?? label,
        onTap: onPressed,
        child: Opacity(opacity: enabled ? 1 : .45, child: body),
      ),
    );
  }
}

/// ถาดปุ่มล่างจอ: ปุ่มหลักใหญ่ 1 ปุ่มตรงกลาง + ปุ่มกลมรองซ้าย/ขวา (กดด้วยนิ้วโป้ง)
/// ปุ่มลอยบนฉากโดยตรง (ไม่มีแผงพื้นหลัง) ให้เห็นฉากมากที่สุด
/// ปุ่มกลมรองควรตั้ง [RoundAction.labelOnScene] ให้ป้ายมีแผงโปร่งรองหลัง
class ActionTray extends StatelessWidget {
  const ActionTray({
    super.key,
    required this.primary,
    this.leading,
    this.trailing,
  });

  final Widget primary;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Padding(
              // ปุ่มหลักตรงกับวงกลมของปุ่มรอง (ป้ายของปุ่มรองอยู่ด้านล่าง)
              padding: const EdgeInsets.only(bottom: 10),
              child: primary,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// ป้ายบนฉาก: ไอคอน + ข้อความใหญ่ 1 บรรทัด (+ แถบ) แตะแล้วเปิดรายละเอียด
class SceneChip extends StatelessWidget {
  const SceneChip({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
    this.color = DsColors.glass,
    this.below,
    this.semanticLabel,
  });

  final Widget icon;
  final String text;
  final VoidCallback? onTap;
  final Color color;

  /// แถบ/ข้อความรองใต้ข้อความหลัก
  final Widget? below;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final panel = GlassPanel(
      color: color,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (below != null) ...[const SizedBox(height: 4), below!],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const PixelGlyph(
                Glyph.arrowRight,
                size: 16,
                color: DsColors.onGlass,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return panel;
    return Pressable(label: semanticLabel ?? text, onTap: onTap, child: panel);
  }
}

/// กล่องคำพูดของตัวละคร: บอกสิ่งที่ควรทำต่อ ตัวใหญ่ 1 บรรทัด แตะแล้วพาไป
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.onTap,
    this.urgent = false,
    this.face = 'face',
    this.textKey,
    this.action,
    this.semanticPrefix = '',
  });

  final String text;
  final VoidCallback? onTap;

  /// เรื่องด่วน (ภัย) → กล่องสีแดงอ่อน
  final bool urgent;
  final String face;
  final Key? textKey;

  /// ปุ่มท้ายกล่อง (เช่น "เข้าใจแล้ว")
  final Widget? action;
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFE3DF) : DsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DsColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: DsColors.ink, offset: Offset(0, 3))],
      ),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              key: textKey,
              // มีปุ่มท้ายกล่อง (คำแนะนำครั้งแรก) → พื้นที่แคบลง ให้ขึ้นได้ 3 บรรทัด
              maxLines: action == null ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: DsText.font,
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: DsColors.text,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
          if (onTap != null && action == null) ...[
            const SizedBox(width: 6),
            const PixelGlyph(Glyph.arrowRight, size: 18, color: DsColors.ink),
          ],
        ],
      ),
    );
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Bob(
          dy: 2,
          period: const Duration(milliseconds: 1800),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: urgent ? DsColors.danger : DsColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: DsColors.ink, width: 3),
            ),
            child: Center(child: PixelIcon(face, size: 40)),
          ),
        ),
        // หางกล่องคำพูด
        CustomPaint(
          size: const Size(10, 16),
          painter: _TailPainter(
            urgent ? const Color(0xFFFFE3DF) : DsColors.surface,
          ),
        ),
        Expanded(child: bubble),
      ],
    );
    if (onTap == null) {
      return Semantics(
        liveRegion: true,
        label: '$semanticPrefix$text',
        child: ExcludeSemantics(excluding: action == null, child: row),
      );
    }
    return Pressable(
      label: '$semanticPrefix$text',
      onTap: onTap,
      child: ExcludeSemantics(child: row),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.fill);
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width + 3, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width + 3, size.height)
      ..close();
    canvas
      ..drawPath(p, Paint()..color = fill)
      ..drawPath(
        Path()
          ..moveTo(size.width + 3, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width + 3, size.height),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = DsColors.ink,
      );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.fill != fill;
}

/// แผ่นรายละเอียดด้านล่าง (ข้อมูลเชิงลึกที่ซ่อนจากหน้าหลัก)
Future<T?> showDetailSheet<T>(
  BuildContext context, {
  required String title,
  Widget? icon,
  required WidgetBuilder builder,
}) {
  final h = MediaQuery.sizeOf(context).height;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DsColors.background,
    barrierColor: DsColors.scrim,
    constraints: BoxConstraints(
      maxWidth: Responsive.maxColumn,
      maxHeight: h * .88,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(DsRadius.sheet)),
      side: BorderSide(color: DsColors.ink, width: 3),
    ),
    builder: (c) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 6),
            child: Row(
              children: [
                if (icon != null) ...[icon, const SizedBox(width: 10)],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DsText.title.copyWith(fontSize: 22),
                  ),
                ),
                RoundAction(
                  key: const ValueKey('sheet-close'),
                  icon: const PixelGlyph(
                    Glyph.cross,
                    size: 18,
                    color: DsColors.ink,
                  ),
                  label: 'ปิด',
                  showLabel: false,
                  diameter: 48,
                  onPressed: () => Navigator.pop(c),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: builder(c),
            ),
          ),
        ],
      ),
    ),
  );
}

/// โครงหน้าแบบฉากเต็มจอ (ฉากวาดเป็นพื้นหลังของหน้าเกม): ป้ายบนฉากแถวบน · ถาดปุ่มล่าง
/// จอกว้าง/แนวนอน: คอลัมน์ควบคุมชิดขวา ฉากเห็นเต็มด้านซ้าย
/// มือถือแนวนอน (จอเตี้ย): ไม่แสดงป้าย ให้ฉากเหลือมากพอ (ข้อมูลอยู่ในแผ่นรายละเอียด)
class ScenePage extends StatelessWidget {
  const ScenePage({super.key, this.chips = const [], required this.tray});

  /// ป้ายบนฉาก (วางเรียงกว้างเท่ากัน)
  final List<Widget> chips;
  final Widget tray;

  /// จอเตี้ย (มือถือแนวนอน) → ปุ่มเล็กลงเล็กน้อย ป้ายซ่อน
  static bool short(BuildContext context) => context.rs.isLandscapePhone;

  /// เส้นผ่านศูนย์กลางปุ่มกลมในถาดตามขนาดจอ
  static double round(BuildContext context) => short(context) ? 52 : 60;

  @override
  Widget build(BuildContext context) {
    final showChips = chips.isNotEmpty && !short(context);
    final column = Padding(
      padding: const EdgeInsets.all(Gap.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showChips)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: Gap.s),
                  Expanded(child: chips[i]),
                ],
              ],
            ),
          const Spacer(),
          tray,
        ],
      ),
    );
    if (!context.rs.useSideNav) return column;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: column,
      ),
    );
  }
}

/// ปุ่มหลักในถาด: ใหญ่ + บรรทัดรองใต้ชื่อ (จอเตี้ย: ปุ่มปกติบรรทัดเดียว)
class TrayPrimary extends StatelessWidget {
  const TrayPrimary({
    super.key,
    required this.label,
    required this.icon,
    this.note,
    this.onPressed,
  });

  final String label;
  final Widget icon;

  /// บรรทัดรองสั้น ๆ ใต้ชื่อปุ่ม
  final String? note;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final short = ScenePage.short(context);
    return PixelButton(
      label: label,
      size: short ? PixelButtonSize.normal : PixelButtonSize.large,
      icon: icon,
      below: short || note == null
          ? null
          : Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DsColors.onAccent.withValues(alpha: .85),
              ),
            ),
      tooltip: note == null ? label : '$label · $note',
      expand: true,
      onPressed: onPressed,
    );
  }
}
