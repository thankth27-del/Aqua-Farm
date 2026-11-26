/// กล่องบทสนทนาของ "ลุงทอง": รูปตามอารมณ์ + ข้อความทีละ 1-2 ประโยค
/// - ตัวอักษรขึ้นทีละตัว (พิมพ์) · แตะระหว่างพิมพ์ = แสดงทั้งบรรทัดทันที
/// - แตะเมื่อพิมพ์ครบ = บรรทัดถัดไป · ครบทุกบรรทัด = [UncleTalk.onDone]
/// - มีตัวเลือก ([UncleTalk.options]) → แสดงปุ่มหลังบรรทัดสุดท้าย แทนการแตะไปต่อ
library;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/story_script.dart';
import '../design/design_system.dart' show DsColors, DsText;
import '../layout/responsive.dart';
import '../theme/theme.dart';

/// ความเร็วพิมพ์ (มิลลิวินาทีต่อตัวอักษร)
const kUncleTypeMs = 28;

/// ตัวเลือก 1 ปุ่มในกล่องบทสนทนา
class UncleOption {
  const UncleOption(this.label, {this.detail});

  final String label;
  final String? detail;
}

class UncleTalk extends StatefulWidget {
  const UncleTalk({
    super.key,
    required this.lines,
    this.onDone,
    this.options = const [],
    this.onOption,
    this.onLine,
  });

  final List<ScriptLine> lines;

  /// แตะผ่านบรรทัดสุดท้าย (ไม่มีตัวเลือก)
  final VoidCallback? onDone;

  /// ตัวเลือกหลังบรรทัดสุดท้าย (ว่าง = แตะไปต่อ)
  final List<UncleOption> options;
  final ValueChanged<int>? onOption;

  /// เปลี่ยนบรรทัด (ให้หน้าเกมไฮไลต์สิ่งที่ลุงพูดถึง)
  final ValueChanged<ScriptLine>? onLine;

  @override
  State<UncleTalk> createState() => _UncleTalkState();
}

class _UncleTalkState extends State<UncleTalk>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  int _index = 0;
  int _shown = 0;
  List<String> _chars = const [];

  ScriptLine get _line => widget.lines[_index];
  bool get _typed => _shown >= _chars.length;
  bool get _last => _index >= widget.lines.length - 1;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(UncleTalk old) {
    super.didUpdateWidget(old);
    // บทพูดชุดใหม่ (เช่น ลุงตอบหลังเลือก) → เริ่มบรรทัดแรก
    if (!identical(old.lines, widget.lines)) {
      _index = 0;
      _start();
    }
  }

  void _start() {
    _chars = _line.text.characters.toList();
    _shown = 0;
    _ticker
      ..stop()
      ..start();
    final line = _line;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLine?.call(line);
    });
  }

  void _onTick(Duration t) {
    final n = (t.inMilliseconds ~/ kUncleTypeMs).clamp(0, _chars.length);
    if (n != _shown) setState(() => _shown = n);
    if (_typed) _ticker.stop();
  }

  void _tap() {
    if (!_typed) {
      _ticker.stop();
      setState(() => _shown = _chars.length);
      return;
    }
    if (!_last) {
      setState(() => _index++);
      _start();
      return;
    }
    if (widget.options.isEmpty) widget.onDone?.call();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final short = rs.isLandscapePhone;
    final portrait = short ? 64.0 : 88.0;
    final showOptions = _last && _typed && widget.options.isNotEmpty;
    final text = _chars.take(_shown).join();

    final box = Container(
      decoration: BoxDecoration(
        color: DsColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DsColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: DsColors.ink, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnclePortrait(mood: _line.mood, size: portrait),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DsColors.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DsColors.ink, width: 2),
                      ),
                      child: Text(
                        Uncle.name,
                        style: DsText.strong.copyWith(
                          fontSize: 16,
                          color: DsColors.onAccent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.lines.length > 1)
                      Text(
                        '${_index + 1}/${widget.lines.length}',
                        style: DsText.caption.copyWith(fontSize: 14),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // จองพื้นที่เท่าข้อความเต็ม: กล่องไม่ยืด/หดระหว่างพิมพ์
                Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: Text(_line.text, style: _textStyle),
                    ),
                    Text(
                      text,
                      key: const ValueKey('uncle-text'),
                      style: _textStyle,
                    ),
                  ],
                ),
                if (!showOptions) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _typed ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Bob(
                        dy: 2,
                        period: const Duration(milliseconds: 900),
                        child: Text(
                          _last ? 'แตะเพื่อปิด ▼' : 'แตะเพื่อไปต่อ ▼',
                          style: DsText.caption.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: DsColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      label: '${Uncle.name}: ${_line.text}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            key: const ValueKey('uncle-talk'),
            label: _typed ? 'แตะเพื่อไปต่อ' : 'แสดงข้อความทั้งหมด',
            onTap: showOptions ? null : _tap,
            child: ExcludeSemantics(child: box),
          ),
          if (showOptions) ...[
            const SizedBox(height: Gap.s),
            _Options(
              options: widget.options,
              onPick: (i) => widget.onOption?.call(i),
            ),
          ],
        ],
      ),
    );
  }

  static const _textStyle = TextStyle(
    fontFamily: DsText.font,
    fontSize: 18,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: DsColors.text,
  );
}

/// รูปลุงตามอารมณ์ (ภาพพิกเซล ไม่เบลอ) — ไม่มีไฟล์ภาพ = กรอบสีพร้อมอักษร "ท"
class UnclePortrait extends StatelessWidget {
  const UnclePortrait({super.key, required this.mood, required this.size});

  final UncleMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bg = switch (mood) {
      UncleMood.smile => const Color(0xFFFFE7B0),
      UncleMood.think => const Color(0xFFD5EFEB),
      UncleMood.worry => const Color(0xFFFDE0DC),
    };
    return Container(
      key: ValueKey('uncle-${mood.name}'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DsColors.ink, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        Uncle.asset(mood),
        filterQuality: FilterQuality.none,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Center(
          child: Text('ท', style: DsText.title.copyWith(fontSize: size * .45)),
        ),
      ),
    );
  }
}

/// ปุ่มตัวเลือก: จอแคบเรียงแถวเดียว · จอกว้างเรียง 2 คอลัมน์
class _Options extends StatelessWidget {
  const _Options({required this.options, required this.onPick});

  final List<UncleOption> options;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    Widget button(int i) {
      final o = options[i];
      return PixelButton(
        key: ValueKey('uncle-option-$i'),
        label: o.label,
        style: PixelButtonStyle.water,
        expand: true,
        below: o.detail == null
            ? null
            : Text(
                o.detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DsColors.textMuted,
                ),
              ),
        onPressed: () => onPick(i),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth >= 520 ? 2 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < options.length; i += cols) ...[
              if (i > 0) const SizedBox(height: Gap.s),
              Row(
                children: [
                  for (var j = i; j < i + cols; j++) ...[
                    if (j > i) const SizedBox(width: Gap.s),
                    Expanded(
                      child: j < options.length
                          ? button(j)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// ชั้นบทสนทนาเต็มจอ: ฉากหรี่ลงเล็กน้อย กล่องลุงชิดล่าง (จอกว้าง: กว้างไม่เกิน 640 จัดกลาง)
class UncleTalkLayer extends StatelessWidget {
  const UncleTalkLayer({super.key, required this.talk});

  final UncleTalk talk;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // กันกดของข้างหลังระหว่างลุงพูด
        const ModalBarrier(dismissible: false, color: Color(0x660B2623)),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxColumn),
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: SingleChildScrollView(reverse: true, child: talk),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
