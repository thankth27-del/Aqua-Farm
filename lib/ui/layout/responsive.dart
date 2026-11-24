import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// ระบบเลย์เอาต์กลางของทั้งเกม — ทุกหน้าใช้ไฟล์นี้ ห้ามกำหนดขนาดพิกเซลตายตัวเฉพาะหน้า
///
/// ประเภทจอ (ตามความกว้างหน้าต่าง):
///   compact  < 600       โทรศัพท์แนวตั้ง → เมนูล่าง
///   medium   600–1000    แท็บเล็ต/โทรศัพท์แนวนอน → เมนูข้าง
///   expanded > 1000      แท็บเล็ตแนวนอน/คอม → เมนูข้าง + จำกัดความกว้างเนื้อหา
enum ScreenClass { compact, medium, expanded }

/// จุดแบ่งประเภทจอ
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 1000;

  /// เนื้อหากว้างสุดบนจอใหญ่ (จัดกลาง ไม่ยืดเต็มจอ)
  static const double maxContent = 1100;

  /// จอเตี้ยกว่านี้ตอนแนวนอน = โทรศัพท์แนวนอน (แบ่งซ้าย-ขวา)
  static const double phoneLandscapeHeight = 500;
}

ScreenClass classifyWidth(double width) {
  if (width < Breakpoints.medium) return ScreenClass.compact;
  if (width <= Breakpoints.expanded) return ScreenClass.medium;
  return ScreenClass.expanded;
}

/// ข้อมูลเลย์เอาต์ของหน้าจอปัจจุบัน: ประเภทจอ + ตัวคูณขนาดกลาง
///
/// ตัวคูณ [scale] ถูกใช้ครั้งเดียวที่ราก ([ScaledApp]) กับทั้งแอป — ฟอนต์ ปุ่ม ไอคอน
/// ระยะห่าง และหน้าต่าง/ป๊อปอัปทุกอันขยายเท่ากันหมด หน้าไม่ต้องคูณเอง
@immutable
class Responsive {
  const Responsive._(
    this.window,
    this.size,
    this.screen,
    this.scale,
    this.applied,
  );

  /// คำนวณจากขนาดหน้าต่างจริง (ใช้ตรงในเทสต์ได้)
  factory Responsive.fromSize(Size window) {
    final screen = classifyWidth(window.width);
    return Responsive._(
      window,
      window,
      screen,
      _scaleFor(screen, window),
      false,
    );
  }

  /// อ่านค่าที่ [ScaledApp] คำนวณไว้ (ถ้าไม่มี คำนวณจาก MediaQuery)
  static Responsive of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ResponsiveScope>()?.data ??
      Responsive.fromSize(MediaQuery.sizeOf(context));

  /// ขนาดหน้าต่างจริง (ใช้แบ่งประเภทจอ)
  final Size window;

  /// ขนาดพื้นที่วาง (หน่วย logical หลังขยายกลางแล้ว)
  final Size size;
  final ScreenClass screen;

  /// ตัวคูณกลางของฟอนต์/ปุ่ม/ไอคอน/ระยะห่าง
  final double scale;

  /// ตัวคูณถูกใช้ที่รากแล้ว (ฟังก์ชันขนาดด้านล่างจึงไม่คูณซ้ำ)
  final bool applied;

  bool get isCompact => screen == ScreenClass.compact;
  bool get isMedium => screen == ScreenClass.medium;
  bool get isExpanded => screen == ScreenClass.expanded;

  /// โทรศัพท์แนวนอน: จอเตี้ย → แบ่งฉาก | แผงควบคุม ไม่ต้องเลื่อนจอ
  bool get isLandscapePhone =>
      window.width > window.height &&
      window.height < Breakpoints.phoneLandscapeHeight;

  /// แนวนอน (กว้าง > สูง)
  bool get isLandscape => window.width > window.height;

  /// เมนูข้างแทนเมนูล่าง
  bool get useSideNav => !isCompact;

  /// วางแผงเป็นสองคอลัมน์ (ฉาก | แผงควบคุม)
  bool get useSplit => isLandscape && !isCompact;

  /// ตัวอักษรต่ำสุดที่ยังอ่านได้บนจอเล็ก (เช่น 360x740)
  static const double minFont = 13;

  /// ปุ่มกดได้ขั้นต่ำ (กติกาโปรเจกต์ 48dp — มากกว่า 44 ที่สเปกกำหนด)
  static const double minTap = 48;

  /// ความกว้างสูงสุดของรายการแผงคอลัมน์เดียวบนจอกว้าง (ไม่ยืดเต็มจอ)
  static const double maxColumn = 640;

  /// ความกว้างสูงสุดของแผงกลางจอ/หน้าต่าง (เมนู ชนะ แพ้ สรุป)
  static const double maxPanel = 520;

  double get _unit => applied ? 1 : scale;

  /// ขนาดตัวอักษร: ค่าออกแบบ × ตัวคูณ แต่ไม่ต่ำกว่า [minFont]
  double font(double base) => math.max(minFont, _round(base * _unit));

  /// ขนาดไอคอน/ภาพ
  double icon(double base) => _round(base * _unit);

  /// ระยะห่าง/ขอบ
  double space(double base) => _round(base * _unit);

  /// ความสูงปุ่ม: ค่าออกแบบ × ตัวคูณ แต่ไม่ต่ำกว่า [minTap]
  double tap(double base) => math.max(minTap, _round(base * _unit));

  /// พิกเซลจริงต่อ 1 หน่วย logical ในต้นไม้นี้ (รวมตัวคูณกลาง)
  double physicalPerLogical(double devicePixelRatio) =>
      devicePixelRatio * (applied ? scale : 1);

  /// ความกว้างเนื้อหาที่ใช้จริง (จำกัดบนจอใหญ่)
  double get contentWidth => math.min(window.width, Breakpoints.maxContent);

  Responsive _scaled(Size logical) =>
      Responsive._(window, logical, screen, scale, true);

  static double _round(double v) => (v * 2).roundToDouble() / 2;

  static double _scaleFor(ScreenClass c, Size s) {
    // โทรศัพท์แนวนอน: จอเตี้ย ใช้ขนาดเท่าโทรศัพท์ ไม่ขยาย
    if (s.width > s.height && s.height < Breakpoints.phoneLandscapeHeight) {
      return 1.0;
    }
    return switch (c) {
      ScreenClass.compact => 1.0,
      ScreenClass.medium => 1.15,
      // คอม: ขยายตามความสูงจอ (1366x768 ≈ 1, 1920x1080 ≈ 1.4, 2560x1440 = 1.6)
      ScreenClass.expanded => (s.height / 760).clamp(1.0, 1.6),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Responsive &&
      other.window == window &&
      other.size == size &&
      other.applied == applied;

  @override
  int get hashCode => Object.hash(window, size, applied);
}

extension ResponsiveContext on BuildContext {
  Responsive get rs => Responsive.of(this);
}

class _ResponsiveScope extends InheritedWidget {
  const _ResponsiveScope({required this.data, required super.child});
  final Responsive data;

  @override
  bool updateShouldNotify(_ResponsiveScope old) => old.data != data;
}

/// ตัวอักษรไม่เล็กกว่า [min] ทั้งแอป (รวมกับขนาดตัวอักษรที่ผู้ใช้ตั้งในเครื่อง)
class MinFontScaler extends TextScaler {
  const MinFontScaler(this.base, this.min);
  final TextScaler base;
  final double min;

  @override
  double scale(double fontSize) => math.max(min, base.scale(fontSize));

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is MinFontScaler && other.base == base && other.min == min;

  @override
  int get hashCode => Object.hash(base, min);
}

/// ใช้ตัวคูณกลางกับทั้งแอปครั้งเดียว: วางเนื้อหาในพื้นที่ logical (ขนาดจริง ÷ ตัวคูณ)
/// แล้วขยายกลับเต็มพื้นที่ — ทุกหน้า ทุกป๊อปอัป ได้ขนาดฟอนต์/ปุ่ม/ไอคอนตามประเภทจอ
/// โดยไม่ต้องแก้เลขในแต่ละหน้า พร้อมกันขอบซ้าย-ขวาจากรอยบาก (SafeArea)
class ScaledApp extends StatelessWidget {
  const ScaledApp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final r = Responsive.fromSize(mq.size);
    final s = r.scale;
    return LayoutBuilder(
      builder: (context, box) {
        final logical = Size(box.maxWidth / s, box.maxHeight / s);
        final data = mq.copyWith(
          size: logical,
          padding: mq.padding / s,
          viewPadding: mq.viewPadding / s,
          viewInsets: mq.viewInsets / s,
          textScaler: MinFontScaler(mq.textScaler, Responsive.minFont),
        );
        Widget inner = MediaQuery(
          data: data,
          child: _ResponsiveScope(
            data: r._scaled(logical),
            child: SafeArea(top: false, bottom: false, child: child),
          ),
        );
        if (s == 1) return inner;
        // กล่องเต็มพื้นที่ (ข้อจำกัดหลวมจะทำให้ FittedBox ไม่ขยาย)
        return SizedBox(
          width: box.maxWidth,
          height: box.maxHeight,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox.fromSize(size: logical, child: inner),
            ),
          ),
        );
      },
    );
  }
}

/// กรอบรากของแอป: พื้นหลังเต็มจอ + จำกัดความกว้างเนื้อหา ~1100 จัดกลาง
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.background, required this.child});

  /// พื้นที่นอกเนื้อหา (ไม่ใช่แถบดำ)
  final Widget background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// รายการแผงของแท็บ: จอแคบเรียงลงเหมือนเดิม จอแนวนอนแบ่งซ้าย (ฉาก [header] ตัวแรก)
/// | ขวา (แผงควบคุม) แต่ละฝั่งเลื่อนเอง จอกว้างคอลัมน์เดียวจำกัดความกว้างจัดกลาง
class TabScroll extends StatelessWidget {
  const TabScroll({
    super.key,
    required this.children,
    this.header = 0,
    this.listKey,
    this.lazy = true,
    this.decorative = false,
  });

  final List<Widget> children;

  /// จำนวนรายการแรกที่เป็นฉาก/หัวหน้า (ไปอยู่ฝั่งซ้ายตอนแนวนอน)
  final int header;
  final Key? listKey;

  /// false = สร้างทุกแผงไว้ (ให้ปุ่มลัด ensureVisible เลื่อนไปหาแผงที่อยู่นอกจอได้)
  final bool lazy;

  /// [header] เป็นของตกแต่ง (ฉากห้อง) — แสดงเฉพาะตอนแบ่งซ้าย-ขวา
  /// จอแคบไม่แสดง ให้ปุ่มหลักขึ้นมาอยู่บนจอโดยไม่ต้องเลื่อน
  final bool decorative;

  Widget _list(List<Widget> items, EdgeInsets padding, {Key? key}) =>
      ScrollHint(
        child: lazy
            ? ListView(key: key, padding: padding, children: items)
            : SingleChildScrollView(
                key: key,
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
      );

  @override
  Widget build(BuildContext context) {
    final r = context.rs;
    const gap = 14.0;
    if (r.useSplit && header > 0 && header < children.length) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _list(
              children.sublist(0, header),
              const EdgeInsets.fromLTRB(gap, gap, gap / 2, gap),
            ),
          ),
          Expanded(
            flex: 5,
            child: _list(
              children.sublist(header),
              const EdgeInsets.fromLTRB(gap / 2, gap, gap, gap),
              key: listKey,
            ),
          ),
        ],
      );
    }
    final items = decorative ? children.sublist(header) : children;
    final list = _list(items, const EdgeInsets.all(gap), key: listKey);
    if (r.isCompact) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxColumn),
        child: list,
      ),
    );
  }
}

/// บอกว่ายังมีเนื้อหาด้านล่าง: ไล่สีจางที่ขอบล่าง + ลูกศรลง
/// (หายไปเมื่อเลื่อนถึงท้ายรายการ)
class ScrollHint extends StatefulWidget {
  const ScrollHint({super.key, required this.child, this.color});
  final Widget child;

  /// สีขอบล่าง (ค่าเริ่มต้น: เขียวพื้นหลังเกม)
  final Color? color;

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint> {
  bool _more = false;

  bool _update(ScrollMetrics m) {
    if (m.axis != Axis.vertical) return false;
    final more = m.extentAfter > 8;
    if (more == _more) return false;
    // ข้อมูลขนาดรายการมาระหว่างจัดเลย์เอาต์ → อัปเดตหลังเฟรมนี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && more != _more) setState(() => _more = more);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? const Color(0xFF244A2C);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => n.depth == 0 && _update(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _update(n.metrics),
        child: Stack(
          children: [
            widget.child,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _more ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    key: _more ? const ValueKey('scroll-more') : null,
                    height: 34,
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.withValues(alpha: 0),
                          c.withValues(alpha: .85),
                        ],
                      ),
                    ),
                    child: const CustomPaint(
                      size: Size(18, 12),
                      painter: _DownArrow(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ลูกศรลงแบบพิกเซล (สามเหลี่ยมขอบเข้ม)
class _DownArrow extends CustomPainter {
  const _DownArrow();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFFFF3D6));
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF1B120B),
    );
  }

  @override
  bool shouldRepaint(_DownArrow old) => false;
}

/// โครงหน้าเกม: compact = แถบบน / เนื้อหา / เมนูล่าง
/// medium-expanded = เมนูข้าง | (แถบบน / เนื้อหา)
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.top,
    required this.body,
    required this.bottomNav,
    required this.sideNav,
  });

  final Widget top;
  final Widget body;
  final Widget bottomNav;
  final Widget sideNav;

  @override
  Widget build(BuildContext context) {
    if (!context.rs.useSideNav) {
      return Column(
        children: [
          top,
          Expanded(child: body),
          bottomNav,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sideNav,
        Expanded(
          child: Column(
            children: [
              top,
              Expanded(child: body),
            ],
          ),
        ),
      ],
    );
  }
}

/// แบ่งหน้าเป็นซ้าย-ขวาเมื่อจอแนวนอน (ฉาก | แผงควบคุม) ไม่งั้นเรียงบนลงล่าง
///
/// แนวนอน: ฉากอยู่กับที่ ส่วนแผงควบคุมเลื่อนได้ในคอลัมน์ของตัวเอง
/// แนวตั้ง: คืน [scene] ตามด้วย [controls] ให้หน้านั้นวางใน ScrollView เดิม
class SplitLayout extends StatelessWidget {
  const SplitLayout({
    super.key,
    required this.scene,
    required this.controls,
    this.sceneFlex = 5,
    this.controlsFlex = 6,
  });

  final Widget scene;
  final Widget controls;
  final int sceneFlex;
  final int controlsFlex;

  @override
  Widget build(BuildContext context) {
    final r = context.rs;
    if (!r.useSplit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [scene, controls],
      );
    }
    final gap = r.space(14);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: sceneFlex,
          child: Padding(padding: EdgeInsets.all(gap), child: scene),
        ),
        Expanded(
          flex: controlsFlex,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(0, gap, gap, gap),
            child: controls,
          ),
        ),
      ],
    );
  }
}

/// คำนวณขนาดฉากพิกเซลแบบจำนวนเต็มเท่า (nearest-neighbor ไม่เบลอ)
///
/// [logical] = พื้นที่ที่มี (หน่วย logical px), [dpr] = devicePixelRatio
/// คืนขนาดฉาก (logical px) ที่ใหญ่สุดซึ่งพิกเซลจริงของจอเป็นจำนวนเต็มเท่าของ [art]
Size integerSceneSize(Size logical, double dpr, Size art) {
  final physW = logical.width * dpr;
  final physH = logical.height * dpr;
  final k = math.min(physW / art.width, physH / art.height).floor();
  // เล็กกว่าภาพต้นฉบับ: ย่อตามสัดส่วน (ยังคม เพราะไม่มีการกรองภาพ)
  if (k < 1) {
    final s = math.min(logical.width / art.width, logical.height / art.height);
    return Size(art.width * s, art.height * s);
  }
  return Size(art.width * k / dpr, art.height * k / dpr);
}

/// เวทีฉากพิกเซล 16:9: ขยายเป็นจำนวนเต็มเท่า จัดกลาง ที่เหลือเติมด้วย [fill]
///
/// [child] ต้องวาดเต็มกล่องที่ได้รับ (เช่น PixelScene(cover: true))
class PixelStage extends StatelessWidget {
  const PixelStage({
    super.key,
    required this.child,
    required this.fill,
    this.art = const Size(320, 180),
    this.maxHeightFraction = 1,
  });

  final Widget child;

  /// พื้นหลังรอบฉาก (สีหรือลายที่เข้ากับฉาก ไม่ใช่แถบดำ)
  final Widget fill;

  /// ขนาดภาพต้นฉบับ (หน่วยพิกเซลศิลป์)
  final Size art;

  /// สูงได้ไม่เกินสัดส่วนนี้ของจอ (กันฉากกินพื้นที่ปุ่มบนจอเตี้ย)
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final dpr = context.rs.physicalPerLogical(
      MediaQuery.devicePixelRatioOf(context),
    );
    final screenH = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        var h = c.hasBoundedHeight ? c.maxHeight : w * art.height / art.width;
        h = math.min(h, screenH * maxHeightFraction);
        final scene = integerSceneSize(Size(w, h), dpr, art);
        // กล่องนอกเต็มความกว้าง สูงเท่าฉาก (ไม่มีแถบว่างบนล่างในแนวตั้ง)
        final boxH = c.hasBoundedHeight ? h : scene.height;
        return SizedBox(
          width: w,
          height: boxH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              fill,
              Center(
                child: SizedBox.fromSize(size: scene, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}
