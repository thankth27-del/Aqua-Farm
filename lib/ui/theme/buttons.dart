import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'colors.dart';
import 'frames.dart';

/// สีปุ่ม: ทอง (การกระทำหลัก) / เขียว / ฟ้าน้ำ / ไม้ (รอง) / แดง (ลบ ทิ้ง)
enum PixelButtonStyle { gold, green, water, wood, danger }

/// ขนาดปุ่ม (ทุกขนาดสูงไม่ต่ำกว่า 48dp)
enum PixelButtonSize { normal, large }

(Color fill, Color text, Color depth) _colors(PixelButtonStyle s) =>
    switch (s) {
      PixelButtonStyle.gold => (
        AquaColors.gold,
        AquaColors.ink,
        AquaColors.goldDark,
      ),
      PixelButtonStyle.green => (
        AquaColors.grass,
        Colors.white,
        AquaColors.grassDark,
      ),
      PixelButtonStyle.water => (
        AquaColors.water,
        Colors.white,
        AquaColors.waterDeep,
      ),
      PixelButtonStyle.wood => (
        AquaColors.woodLight,
        AquaColors.paper,
        AquaColors.woodDark,
      ),
      PixelButtonStyle.danger => (
        AquaColors.red,
        Colors.white,
        AquaColors.redDark,
      ),
    };

/// ปุ่มพิกเซล: มีเงาด้านล่าง กดแล้วยุบลง ปล่อยแล้วเด้ง
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailing,
    this.style = PixelButtonStyle.gold,
    this.size = PixelButtonSize.normal,
    this.expand = false,
    this.tooltip,
    this.below,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  /// บรรทัดที่สองใต้ชื่อปุ่ม (เช่นราคา)
  final Widget? below;

  /// วิดเจ็ตท้ายปุ่ม (เช่นป้ายราคา)
  final Widget? trailing;
  final PixelButtonStyle style;
  final PixelButtonSize size;
  final bool expand;
  final String? tooltip;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

const double _kDepth = 5;

class _PixelButtonState extends State<PixelButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.07), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.07, end: .97), weight: 30),
    TweenSequenceItem(tween: Tween(begin: .97, end: 1), weight: 35),
  ]).animate(_bounce);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (fill, fg, depthColor) = _colors(widget.style);
    final large = widget.size == PixelButtonSize.large;
    final depth = _down ? 1.0 : _kDepth;
    final minH = (large ? 64.0 : 52.0);

    Widget content = DefaultTextStyle.merge(
      style: TextStyle(
        color: fg,
        fontWeight: FontWeight.w700,
        fontSize: large ? 22 : FontSize.label,
        height: 1.2,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?widget.icon,
          if (widget.icon != null && widget.label.isNotEmpty)
            const SizedBox(width: 8),
          if (widget.label.isNotEmpty)
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
    if (widget.below != null) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [content, const SizedBox(height: 3), widget.below!],
      );
    }

    Widget btn = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minH, minWidth: kMinTap),
      child: Padding(
        // กดแล้วตัวปุ่มเลื่อนลงแทนที่เงา
        padding: EdgeInsets.only(top: _kDepth - depth),
        child: CustomPaint(
          painter: PixelBoxPainter(
            fill: fill,
            border: AquaColors.ink,
            px: 3,
            depth: depth,
            depthColor: depthColor,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              large ? 18 : 12,
              large ? 10 : 7,
              large ? 18 : 12,
              (large ? 10 : 7) + depth,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: content),
          ),
        ),
      ),
    );

    btn = ScaleTransition(scale: _scale, child: btn);
    if (!enabled) btn = Opacity(opacity: .45, child: btn);

    btn = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapCancel: () => _set(false),
          onTapUp: enabled
              ? (_) {
                  _set(false);
                  _bounce.forward(from: 0);
                }
              : null,
          onTap: widget.onPressed,
          child: btn,
        ),
      ),
    );
    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip, child: btn);
    }
    return widget.expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// ห่อการ์ดให้กดได้: กดแล้วยุบเล็กน้อย ปล่อยแล้วเด้ง (การ์ดสินค้า ฯลฯ)
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  bool _down = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _down
        ? const AlwaysStoppedAnimation(.95)
        : TweenSequence<double>([
            TweenSequenceItem(tween: Tween(begin: .95, end: 1.04), weight: 50),
            TweenSequenceItem(tween: Tween(begin: 1.04, end: 1), weight: 50),
          ]).animate(_c);
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) {
            setState(() => _down = false);
            _c.forward(from: 0);
          },
          onTap: widget.onTap,
          child: ScaleTransition(scale: scale, child: widget.child),
        ),
      ),
    );
  }
}

/// ปุ่มสี่เหลี่ยมจัตุรัสมีแต่ไอคอน (48x48 ขึ้นไป) — ต้องมี tooltip บอกความหมาย
class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.style = PixelButtonStyle.wood,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final PixelButtonStyle style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: SizedBox(
          width: 56,
          child: PixelButton(
            label: '',
            icon: icon,
            style: style,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
