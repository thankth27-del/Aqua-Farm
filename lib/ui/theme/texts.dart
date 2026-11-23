import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'colors.dart';
import 'frames.dart';
import 'pixel_icon.dart';

/// ตัวอักษรมีขอบ + เงาพิกเซล (หัวข้อ โลโก้ ตัวเลขเด่น)
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    this.size = FontSize.title,
    this.color = AquaColors.gold,
    this.outline = AquaColors.ink,
    this.stroke,
    this.shadow = true,
    this.align = TextAlign.center,
    this.weight = FontWeight.w700,
    this.maxLines,
  });

  final String text;
  final double size;
  final Color color;
  final Color outline;
  final double? stroke;
  final bool shadow;
  final TextAlign align;
  final FontWeight weight;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final sw = stroke ?? (size / 7).clamp(3.0, 9.0);
    final base = TextStyle(
      fontFamily: kFont,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
    );
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    return Stack(
      children: [
        // ขอบ — ใช้ RichText เพื่อไม่ให้นับเป็นข้อความซ้ำ (ทั้ง semantics และเทสต์)
        ExcludeSemantics(
          child: RichText(
            textAlign: align,
            maxLines: maxLines,
            overflow: overflow ?? TextOverflow.clip,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              text: text,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = sw
                  ..strokeJoin = StrokeJoin.miter
                  ..color = outline,
                shadows: shadow
                    ? [
                        Shadow(
                          offset: Offset(0, (size / 10).clamp(2, 5)),
                          color: outline,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        Text(
          text,
          textAlign: align,
          maxLines: maxLines,
          overflow: overflow,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}

/// หัวข้อสีทองมีขอบ
class GoldTitle extends StatelessWidget {
  const GoldTitle(this.text, {super.key, this.size = FontSize.title});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => OutlinedText(text, size: size);
}

/// ข้อความรอง (บนพื้นครีม)
class Muted extends StatelessWidget {
  const Muted(
    this.text, {
    super.key,
    this.color = AquaColors.textSoft,
    this.size = FontSize.small,
    this.align,
  });
  final String text;
  final Color color;
  final double size;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(color: color, fontSize: size, height: 1.35),
  );
}

/// ข้อความหนาบนพื้นครีม
class Bold extends StatelessWidget {
  const Bold(
    this.text, {
    super.key,
    this.size = FontSize.body,
    this.color = AquaColors.text,
    this.align,
    this.maxLines,
  });
  final String text;
  final double size;
  final Color color;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    maxLines: maxLines,
    overflow: maxLines == null ? null : TextOverflow.ellipsis,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
  );
}

/// ป้ายไม้แขวน มีชื่อหน้าสีทอง
class WoodSign extends StatelessWidget {
  const WoodSign(this.text, {super.key, this.icon, this.size = FontSize.title});
  final String text;
  final Widget? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      fill: AquaColors.woodLight,
      grain: AquaColors.wood,
      depth: 4,
      px: 3,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Flexible(child: OutlinedText(text, size: size, maxLines: 1)),
        ],
      ),
    );
  }
}

/// หัวหน้า: ภาพฉาก (บ่อ ครัว ฟาร์ม) + ป้ายชื่อหน้าซ้อนด้านล่าง
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.scene,
    required this.title,
    this.icon,
    this.trailing,
    this.titleSize = FontSize.title,
  });

  /// ฉากพิกเซล (มักเป็น PixelScene)
  final Widget scene;
  final String title;
  final Widget? icon;
  final double titleSize;

  /// วิดเจ็ตเสริมมุมขวาล่างของฉาก (เช่นปุ่มช่วยเหลือ)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(padding: const EdgeInsets.only(bottom: 22), child: scene),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: WoodSign(title, icon: icon, size: titleSize),
            ),
          ),
          if (trailing != null)
            Positioned(right: 8, bottom: 30, child: trailing!),
        ],
      ),
    );
  }
}

/// หัวข้อย่อยในแผง: ไอคอน + ชื่อ
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: Row(
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: Gap.s)],
          Expanded(child: Bold(text, size: FontSize.label)),
          ?trailing,
        ],
      ),
    );
  }
}

/// ป้ายเล็ก (ชิป) พื้นสี ตัวอักษรหนา
class Tag extends StatelessWidget {
  const Tag(
    this.text, {
    super.key,
    this.color = AquaColors.creamDark,
    this.textColor = AquaColors.text,
    this.icon,
    this.size = FontSize.small,
  });

  final String text;
  final Color color;
  final Color textColor;
  final Widget? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PixelBox(
      fill: color,
      border: AquaColors.ink,
      px: 2,
      bevel: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 4)],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ไอคอนตรวจผ่าน/ไม่ผ่าน
Widget passGlyph(bool ok, {double size = 18}) => ok
    ? PixelGlyph(
        Glyph.check,
        size: size,
        color: AquaColors.leafLight,
        semanticLabel: 'พร้อม',
      )
    : PixelGlyph(
        Glyph.cross,
        size: size,
        color: AquaColors.red,
        semanticLabel: 'ยังไม่พอ',
      );
