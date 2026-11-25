/// ปลาชุดใหม่ (`assets/fish/<id>_strip.png`): แถบ 8 เฟรม เฟรมละ 128x128 หันหัวไปทางขวา
///
/// - ตัดเฟรมจากแถบแล้วสลับประมาณ 11 เฟรม/วินาที (นาฬิกากลางตัวเดียวทั้งแอป)
/// - ภาพไม่เบลอ: FilterQuality.none เสมอ ถ้าแสดงเล็กกว่า 128 พิกเซลจริง
///   จะถอดรหัสภาพให้พอดีขนาดจริงครั้งเดียว (ไม่ต้องย่อทุกเฟรม) ถ้าใหญ่กว่าจะขยายแบบพิกเซล
/// - ปิดแอนิเมชันได้ผ่าน sceneAnimationProvider (ใช้ในเทสต์)
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../providers.dart';

/// จำนวนเฟรมในแถบ และขนาดเฟรมต้นฉบับ
const int kFishFrames = 8;
const double kFishFramePx = 128;

/// ขนาดมาตรฐาน (จำนวนเต็มเท่าของ/ส่วนของเฟรม 128)
abstract final class FishSize {
  static const double small = 64;
  static const double medium = 128;
  static const double large = 256;
}

/// ไฟล์แถบของปลาแต่ละชนิด (id ตาม lib/data/fish_data.dart)
String fishStripAsset(String type) => 'assets/fish/${type}_strip.png';

/// เฟรมที่ต้องแสดงที่จังหวะ [tick] โดยเริ่มที่เฟรม [start] (ปลาแต่ละตัวไม่ขยับพร้อมกัน)
int fishFrameAt(int tick, int start) => (tick + start) % kFishFrames;

/// นาฬิกากลาง: เดินเฉพาะตอนมีปลาบนจออย่างน้อย 1 ตัว
abstract final class FishClock {
  static const Duration interval = Duration(milliseconds: 90); // ~11 fps
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
  static Timer? _timer;
  static int _users = 0;

  static void _add() {
    if (_users++ == 0) {
      _timer = Timer.periodic(interval, (_) => tick.value++);
    }
  }

  static void _remove() {
    if (--_users <= 0) {
      _users = 0;
      _timer?.cancel();
      _timer = null;
    }
  }

  @visibleForTesting
  static bool get running => _timer != null;
}

final _startRng = math.Random();

/// ปลา 1 ตัวจากแถบเฟรม
///
/// [frame] ส่งมาจากภายนอกได้ (เช่น ฉากบ่อที่มีนาฬิกาของตัวเอง) ถ้าไม่ส่ง
/// และ [animate] เป็นจริง จะใช้นาฬิกากลาง เริ่มที่เฟรม [startFrame] (สุ่มถ้าไม่ระบุ)
class FishSprite extends StatefulWidget {
  const FishSprite(
    this.type, {
    super.key,
    this.size = FishSize.small,
    this.animate = true,
    this.frame,
    this.startFrame,
    this.flipX = false,
    this.semanticLabel,
  });

  /// id ของปลา เช่น 'nila'
  final String type;

  /// ความกว้าง = ความสูงของเฟรม (หน่วย logical)
  final double size;
  final bool animate;
  final int? frame;
  final int? startFrame;

  /// กลับด้านให้หัวไปทางซ้าย (ภาพต้นฉบับหัวไปทางขวา)
  final bool flipX;
  final String? semanticLabel;

  @override
  State<FishSprite> createState() => _FishSpriteState();
}

class _FishSpriteState extends State<FishSprite> {
  late final int _start = widget.startFrame ?? _startRng.nextInt(kFishFrames);
  bool _ticking = false;

  bool get _wantsClock => widget.frame == null && widget.animate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(FishSprite old) {
    super.didUpdateWidget(old);
    _syncClock();
  }

  /// เปิดแอนิเมชันเมื่ออนุญาต (ไม่มี ProviderScope = ถือว่าปิด)
  bool _allowed() {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(sceneAnimationProvider);
    } catch (_) {
      return false;
    }
  }

  void _syncClock() {
    final want = _wantsClock && _allowed();
    if (want && !_ticking) {
      FishClock._add();
      _ticking = true;
    } else if (!want && _ticking) {
      FishClock._remove();
      _ticking = false;
    }
  }

  @override
  void dispose() {
    if (_ticking) FishClock._remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fixed = widget.frame ?? (_ticking ? null : _start);
    final Widget sprite = fixed != null
        ? _FishFrame(
            type: widget.type,
            size: widget.size,
            frame: fixed % kFishFrames,
          )
        : ValueListenableBuilder<int>(
            valueListenable: FishClock.tick,
            builder: (_, t, _) => _FishFrame(
              type: widget.type,
              size: widget.size,
              frame: fishFrameAt(t, _start),
            ),
          );
    final flipped = widget.flipX
        ? Transform.flip(flipX: true, child: sprite)
        : sprite;
    if (widget.semanticLabel == null) return ExcludeSemantics(child: flipped);
    return Semantics(label: widget.semanticLabel, image: true, child: flipped);
  }
}

/// วาด 1 เฟรม: เลื่อนแถบให้เหลือแค่ช่องที่ต้องการ
class _FishFrame extends StatelessWidget {
  const _FishFrame({
    required this.type,
    required this.size,
    required this.frame,
  });
  final String type;
  final double size;
  final int frame;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final phys = (size * dpr).round();
    ImageProvider image = AssetImage(fishStripAsset(type));
    var draw = size;
    if (phys > 0 && phys < kFishFramePx) {
      // เล็กกว่าต้นฉบับ: ถอดรหัสให้พอดีพิกเซลจริงครั้งเดียว แล้ววาด 1:1 แบบไม่กรอง
      image = ResizeImage(
        image,
        width: phys * kFishFrames,
        height: phys,
        policy: ResizeImagePolicy.exact,
      );
    } else if (phys >= kFishFramePx) {
      // ใหญ่กว่า: ขยายเป็นจำนวนเต็มเท่าของพิกเซลต้นฉบับ (1 พิกเซลภาพ = n พิกเซลจอ)
      draw = (phys ~/ kFishFramePx) * kFishFramePx / dpr;
    }
    return SizedBox.square(
      dimension: size,
      child: Center(child: _strip(image, draw)),
    );
  }

  Widget _strip(ImageProvider image, double size) {
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size * kFishFrames,
          maxWidth: size * kFishFrames,
          minHeight: size,
          maxHeight: size,
          child: Transform.translate(
            offset: Offset(-frame * size, 0),
            child: Image(
              image: image,
              width: size * kFishFrames,
              height: size,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// ไอคอนปลา: ตัดขอบว่างของเฟรมออกให้ตัวปลากว้างประมาณ [size]
/// ไอคอนเล็ก (ปุ่ม ป้าย) เป็นภาพนิ่ง ไอคอนตั้งแต่ [animateFrom] ขึ้นไป (การ์ด รายละเอียด) ว่ายขยับ
class FishIcon extends StatelessWidget {
  const FishIcon(
    this.type, {
    super.key,
    this.size = 28,
    this.animate,
    this.semanticLabel,
  });

  final String type;

  /// ความกว้างของตัวปลา (หน่วย logical)
  final double size;

  /// null = ขยับเมื่อใหญ่ตั้งแต่ [animateFrom]
  final bool? animate;
  final String? semanticLabel;

  static const double animateFrom = 56;

  /// ตัวปลากินพื้นที่ราว 80% ของความกว้างเฟรม และ 60% ของความสูง
  static const double frameScale = 1.25;
  static const double heightRatio = .75;

  @override
  Widget build(BuildContext context) {
    final frame = size * frameScale;
    return SizedBox(
      width: size,
      height: size * heightRatio,
      child: ClipRect(
        child: OverflowBox(
          minWidth: frame,
          maxWidth: frame,
          minHeight: frame,
          maxHeight: frame,
          child: FishSprite(
            type,
            size: frame,
            animate: animate ?? size >= animateFrom,
            startFrame: animate == false || size < animateFrom ? 0 : null,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
