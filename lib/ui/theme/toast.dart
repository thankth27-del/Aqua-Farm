import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'dialog_frame.dart';

/// ที่แสดงข้อความแจ้งเตือน (toast) ด้านบนจอ ใต้แถบบน — ไม่บังเมนูล่าง
/// วางครอบทั้งแอป (ใน MaterialApp.builder) แล้วเรียก [ToastHost.show]
class ToastHost extends StatefulWidget {
  const ToastHost({super.key, required this.child});
  final Widget child;

  /// แสดงข้อความ — สีแดงเมื่อไม่สำเร็จหรือเป็นคำเตือน
  static void show(BuildContext context, String message, {bool bad = false}) =>
      context.findAncestorStateOfType<ToastHostState>()?.show(message, bad: bad);

  @override
  State<ToastHost> createState() => ToastHostState();
}

class ToastHostState extends State<ToastHost>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2600);

  // ใช้ AnimationController คุมเวลาแสดง (ไม่ใช้ Timer เพื่อให้เทสต์ไม่มี timer ค้าง)
  late final _c = AnimationController(vsync: this, duration: _total)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _message = null);
      }
    });

  String? _message;
  bool _bad = false;
  int _id = 0;

  /// ระยะจากขอบบนของแอปถึงใต้แถบบน (ตั้งโดย [ToastAnchor])
  double? _anchor;

  void show(String message, {bool bad = false}) {
    setState(() {
      _message = message;
      _bad = bad;
      _id++;
    });
    _c.forward(from: 0);
  }

  void _setAnchor(double? y) {
    if (_anchor != y && mounted) setState(() => _anchor = y);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = _anchor ?? MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        widget.child,
        if (_message != null)
          Positioned(
            left: Gap.m,
            right: Gap.m,
            top: top + Gap.s,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, child) {
                  // เลื่อนลงมาตอนแรก แล้วจางหายช่วงท้าย
                  final v = _c.value;
                  final drop = v < .08 ? (1 - v / .08) : 0.0;
                  final fade = v > .85 ? (1 - (v - .85) / .15) : 1.0;
                  return Opacity(
                    opacity: fade.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(0, (-16 * drop).roundToDouble()),
                      child: child,
                    ),
                  );
                },
                child: Semantics(
                  liveRegion: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ToastBubble(
                      _message!,
                      key: ValueKey(_id),
                      bad: _bad,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// ห่อแถบบนของหน้าเกม: บอก [ToastHost] ว่าให้แสดงข้อความใต้วิดเจ็ตนี้
class ToastAnchor extends StatefulWidget {
  const ToastAnchor({super.key, required this.child});
  final Widget child;

  @override
  State<ToastAnchor> createState() => _ToastAnchorState();
}

class _ToastAnchorState extends State<ToastAnchor> {
  ToastHostState? _host;

  void _report(Duration _) {
    if (!mounted) return;
    final host = _host;
    final box = context.findRenderObject() as RenderBox?;
    final hostBox = host?.context.findRenderObject() as RenderBox?;
    if (host == null || box == null || hostBox == null || !box.hasSize) return;
    final bottom = hostBox
        .globalToLocal(box.localToGlobal(Offset(0, box.size.height)))
        .dy;
    host._setAnchor(bottom);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _host = context.findAncestorStateOfType<ToastHostState>();
  }

  @override
  void dispose() {
    final host = _host;
    if (host != null && host.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (host.mounted) host._setAnchor(null);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_report);
    return widget.child;
  }
}
