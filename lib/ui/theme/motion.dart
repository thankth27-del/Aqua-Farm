import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// เปิด/ปิดแอนิเมชันที่วนซ้ำ (ปลาว่าย ไฮไลต์กะพริบ) — ปิดในเทสต์
/// แอนิเมชันครั้งเดียว (ปุ่มเด้ง ตัวเลขนับ เหรียญลอย) ทำงานเสมอ
class MotionSettings extends InheritedWidget {
  const MotionSettings({super.key, required this.loops, required super.child});

  final bool loops;

  static bool loopsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MotionSettings>()?.loops ??
      true;

  @override
  bool updateShouldNotify(MotionSettings old) => old.loops != loops;
}

/// ตัวเลขที่นับขึ้น/ลงเมื่อค่าเปลี่ยน (แสดงค่าสุดท้ายตรงตัวเมื่อจบ)
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 650),
  });

  final int value;
  final Widget Function(BuildContext context, int shown) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (c, v, _) => builder(c, v.round()),
    );
  }
}

/// เด้งเข้ามาครั้งเดียวตอนแสดง (ใช้กับหน้าต่าง ป้ายเกรด ฯลฯ)
class BounceIn extends StatefulWidget {
  const BounceIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.from = .6,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final double from;
  final Duration duration;

  @override
  State<BounceIn> createState() => _BounceInState();
}

class _BounceInState extends State<BounceIn>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  )..forward();

  // หน่วงเวลาด้วย Interval (ไม่ใช้ Timer เพื่อให้เทสต์ไม่มี timer ค้าง)
  late final double _start =
      widget.delay.inMicroseconds /
      (widget.delay + widget.duration).inMicroseconds;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween(begin: widget.from, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: Interval(_start, 1, curve: Curves.elasticOut),
      ),
    );
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _c,
        curve: Interval(_start, _start + (1 - _start) * .35),
      ),
      child: ScaleTransition(scale: scale, child: widget.child),
    );
  }
}

/// ลอยขึ้นลงเบา ๆ แบบพิกเซล (ปลาว่าย ไอคอนที่เลือกอยู่)
class Bob extends StatefulWidget {
  const Bob({
    super.key,
    required this.child,
    this.dy = 3,
    this.dx = 0,
    this.period = const Duration(milliseconds: 1400),
    this.phase = 0,
  });

  final Widget child;
  final double dy;
  final double dx;
  final Duration period;

  /// 0-1 เลื่อนจังหวะ เพื่อให้หลายตัวไม่ขยับพร้อมกัน
  final double phase;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends State<Bob> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loops = MotionSettings.loopsOf(context);
    if (loops && _c == null) {
      _c = AnimationController(vsync: this, duration: widget.period)
        ..repeat();
    } else if (!loops && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      builder: (_, child) {
        final a = (c.value + widget.phase) * 2 * math.pi;
        // ขยับทีละพิกเซล (ปัดเศษ) ให้ดูเป็นเกมพิกเซล
        return Transform.translate(
          offset: Offset(
            (math.cos(a) * widget.dx).roundToDouble(),
            (math.sin(a) * widget.dy).roundToDouble(),
          ),
          child: child,
        );
      },
    );
  }
}

/// กะพริบช้า ๆ (ป้ายเตือนภัย)
class Blink extends StatefulWidget {
  const Blink({super.key, required this.child, this.low = .55});
  final Widget child;
  final double low;

  @override
  State<Blink> createState() => _BlinkState();
}

class _BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionSettings.loopsOf(context) && _c == null) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      // steps(2) แบบต้นแบบ
      builder: (_, child) =>
          Opacity(opacity: c.value < .5 ? 1 : widget.low, child: child),
    );
  }
}

/// ข้อความ/ไอคอนที่ลอยขึ้นแล้วจางหาย (เหรียญลอยตอนได้/เสียเงิน)
class FloatAway extends StatefulWidget {
  const FloatAway({
    super.key,
    required this.child,
    required this.onDone,
    this.rise = 34,
    this.drift = 0,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1100),
  });

  final Widget child;
  final VoidCallback onDone;

  /// ระยะลอย (บวก = ขึ้น ลบ = ลง)
  final double rise;
  final double drift;
  final Duration delay;
  final Duration duration;

  @override
  State<FloatAway> createState() => _FloatAwayState();
}

class _FloatAwayState extends State<FloatAway>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final double _start =
      widget.delay.inMicroseconds /
      (widget.delay + widget.duration).inMicroseconds;

  @override
  void initState() {
    super.initState();
    _c
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        final v = _c.value <= _start
            ? 0.0
            : (_c.value - _start) / (1 - _start);
        final t = Curves.easeOut.transform(v);
        final pop = v < .15 ? v / .15 : 1.0;
        return Opacity(
          opacity: v == 0 ? 0 : (1 - math.max(0, (v - .55) / .45)),
          child: Transform.translate(
            offset: Offset(
              (widget.drift * t).roundToDouble(),
              (-widget.rise * t).roundToDouble(),
            ),
            child: Transform.scale(scale: .6 + .4 * pop, child: child),
          ),
        );
      },
    );
  }
}
