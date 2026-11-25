import 'package:material_ui/material_ui.dart';

import 'buttons.dart';
import 'colors.dart';
import 'fish_sprite.dart';

/// ภาพพิกเซลจาก assets/pixel/ — ขยายแบบไม่เบลอ
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.name, {super.key, this.size = 28, this.semanticLabel});

  /// ชื่อไฟล์ (ไม่รวม .png) เช่น 'coin' — `f_<id>` คือปลาชุดใหม่ ([FishIcon])
  final String name;

  /// ความกว้าง (ความสูงคำนวณตามสัดส่วนภาพ)
  final double size;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (name.startsWith('f_')) {
      return FishIcon(
        name.substring(2),
        size: size,
        semanticLabel: semanticLabel,
      );
    }
    return Image.asset(
      'assets/pixel/$name.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// ไอคอนพิกเซลขนาดเล็กที่วาดด้วยโค้ด (ใช้แทนสัญลักษณ์ข้อความ เช่น ★ ▶ + −)
/// o = เส้นขอบ, # = สีหลัก, + = สีไฮไลต์
enum Glyph {
  heart([
    '.oo...oo.',
    'o++o.o##o',
    'o+######o',
    'o#######o',
    '.o#####o.',
    '..o###o..',
    '...o#o...',
    '....o....',
  ]),
  bolt([
    '....oooo',
    '...o##o.',
    '..o##o..',
    '.o##ooo.',
    'o######o',
    '.ooo##o.',
    '..o##o..',
    '.o##o...',
    'o#oo....',
    'oo......',
  ]),
  smile([
    '..ooooo..',
    '.o#####o.',
    'o##o#o##o',
    'o#######o',
    'o#o###o#o',
    'o##ooo##o',
    '.o#####o.',
    '..ooooo..',
  ]),
  star([
    '....o....',
    '...o+o...',
    'ooo###ooo',
    'o+######o',
    '.o#####o.',
    '..o###o..',
    '.o##o##o.',
    '.o#o.o#o.',
    '.oo...oo.',
  ]),
  arrowRight([
    '...o....',
    '...oo...',
    'oooo#o..',
    'o+####o.',
    'o######o',
    'o#####o.',
    'oooo#o..',
    '...oo...',
    '...o....',
  ]),
  plus([
    '..ooo..',
    '..o#o..',
    'ooo#ooo',
    'o#####o',
    'ooo#ooo',
    '..o#o..',
    '..ooo..',
  ]),
  minus([
    '.......',
    '.......',
    'ooooooo',
    'o#####o',
    'ooooooo',
    '.......',
    '.......',
  ]),
  check([
    '.......oo',
    '......o#o',
    'o....o#o.',
    'oo..o#o..',
    'o#oo#o...',
    '.o##o....',
    '..oo.....',
  ]),
  cross([
    'oo...oo',
    'o#o.o#o',
    '.o#o#o.',
    '..o#o..',
    '.o#o#o.',
    'o#o.o#o',
    'oo...oo',
  ]),
  moon([
    '...oooo.',
    '..o++o..',
    '.o##o...',
    'o##o....',
    'o##o....',
    'o##o....',
    '.o##o...',
    '..o##oo.',
    '...oooo.',
  ]),
  sun([
    '....o....',
    '.o..o..o.',
    '..ooooo..',
    '..o+##o..',
    'ooo###ooo',
    '..o###o..',
    '..ooooo..',
    '.o..o..o.',
    '....o....',
  ]),
  question([
    '.ooooo.',
    'o#####o',
    'o#oo##o',
    '.o.o##o',
    '..o##o.',
    '..o#o..',
    '..ooo..',
    '..o#o..',
    '..ooo..',
  ]),
  wave([
    '..........',
    '.ooo...oo.',
    'o###o.o##o',
    '#o+##o###.',
    'o.o######o',
    '...oooooo.',
  ]),
  lock([
    '..ooo..',
    '.o...o.',
    '.o...o.',
    'ooooooo',
    'o#####o',
    'o##o##o',
    'o##o##o',
    'o#####o',
    'ooooooo',
  ]);

  const Glyph(this.rows);
  final List<String> rows;
}

class PixelGlyph extends StatelessWidget {
  const PixelGlyph(
    this.glyph, {
    super.key,
    this.size = 22,
    this.color = AquaColors.gold,
    this.outline = AquaColors.ink,
    this.flipX = false,
    this.semanticLabel,
  });

  final Glyph glyph;

  /// ความสูงโดยประมาณ (ขยายเป็นจำนวนเต็มเท่าของพิกเซล ภาพจึงคม)
  final double size;
  final Color color;
  final Color outline;
  final bool flipX;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final rows = glyph.rows;
    // สี paper = "สีบนปุ่ม": อยู่ในปุ่มให้ใช้สีตัวอักษรของปุ่ม
    final color = this.color == AquaColors.paper
        ? (ButtonForeground.of(context) ?? this.color)
        : this.color;
    final h = rows.length, w = rows.first.length;
    final px = (size / h).floorToDouble().clamp(1.0, 40.0);
    final painted = CustomPaint(
      size: Size(w * px, h * px),
      painter: _GlyphPainter(rows, px, color, outline, flipX),
    );
    final box = SizedBox(width: w * px, height: h * px, child: painted);
    if (semanticLabel == null) return ExcludeSemantics(child: box);
    return Semantics(label: semanticLabel, image: true, child: box);
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.rows, this.px, this.color, this.outline, this.flipX);
  final List<String> rows;
  final double px;
  final Color color;
  final Color outline;
  final bool flipX;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = false;
    final light = Color.lerp(color, Colors.white, .55)!;
    final w = rows.first.length;
    for (var y = 0; y < rows.length; y++) {
      final r = rows[y];
      for (var x = 0; x < r.length; x++) {
        final c = switch (r[x]) {
          'o' => outline,
          '#' => color,
          '+' => light,
          _ => null,
        };
        if (c == null) continue;
        p.color = c;
        final dx = flipX ? (w - 1 - x) : x;
        canvas.drawRect(Rect.fromLTWH(dx * px, y * px, px, px), p);
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.color != color || old.px != px || old.rows != rows;
}
