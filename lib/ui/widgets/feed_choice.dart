/// เลือกปริมาณอาหารปลา: น้อย / พอดี / มาก พร้อมบอกผลของแต่ละแบบ
///
/// ตัวเลขทั้งหมดมาจากค่าในเกม ([kFeedGrowth], [kFeedAmmonia], [GameEngine.feedCost])
/// ตามต้นแบบ: มาก = โตเท่าพอดี แต่น้ำเสียไวกว่าราว 3 เท่า และแพงกว่า 2 เท่า
library;

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/constants.dart';
import '../../game/game_engine.dart';
import '../../game/story.dart';
import '../design/design_system.dart' show DsColors, DsText;
import '../dialogs.dart';
import '../providers.dart';
import '../theme/theme.dart';
import 'game_hud.dart' show showDetailSheet;
import 'story_gate.dart';

/// ปริมาณอาหาร (ระดับตามต้นแบบ 1-3)
const List<(int, String, String)> kFeedChoices = [
  (1, 'น้อย', 'ประหยัด น้ำเสียน้อย แต่ปลาโตช้า'),
  (2, 'พอดี', 'ปลาโตเต็มที่ น้ำเสียปานกลาง (แนะนำ)'),
  (3, 'มาก', 'ปลาโตเท่าพอดี แต่น้ำเสียไวมาก และแพงกว่า'),
];

/// แผ่นเลือกปริมาณอาหาร (เปิดจากปุ่ม "ให้อาหาร" ในบ่อ) — เลือกแล้วให้อาหารทันที
Future<void> showFeedPicker(BuildContext context) {
  return showDetailSheet<void>(
    context,
    title: 'ให้อาหารปลา',
    icon: const PixelIcon('fry', size: 32),
    builder: (c) => FeedChoices(onFed: () => Navigator.of(c).pop()),
  );
}

/// รายการตัวเลือกปริมาณอาหาร (ใช้ทั้งในแผ่นเลือก และแผ่น "ดูแลบ่อ")
class FeedChoices extends ConsumerWidget {
  const FeedChoices({super.key, this.onFed});

  /// เรียกหลังให้อาหารสำเร็จ (เช่น ปิดแผ่น)
  final VoidCallback? onFed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final fed = session.state.fed > 0;
    // เงินไม่พอแม้แต่ "น้อย" → ลุงทองช่วยให้ฟรี
    final free = !fed && e.freeFeed;
    final ctl = ref.read(gameProvider.notifier);

    void feed(int lv) {
      final r = ctl.run((e) => e.feed(lv));
      if (r.ok) onFed?.call();
      showResult(context, r);
    }

    return Column(
      key: const ValueKey('feed-choices'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          fed
              ? 'วันนี้ให้อาหารแล้ว พรุ่งนี้ให้ได้อีกครั้ง'
              : 'ปลาในบ่อกิน ${e.feedUnit} หน่วย/วัน · เลือกปริมาณ:',
          style: DsText.body.copyWith(color: DsColors.textMuted),
        ),
        const SizedBox(height: Gap.s),
        StoryGate(
          target: StoryTarget.feed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (lv, name, note) in kFeedChoices) ...[
                if (lv > 1) const SizedBox(height: Gap.s),
                _FeedOption(
                  level: lv,
                  name: name,
                  note: lv == 1 && free
                      ? 'เงินหมด ลุงทองแบ่งอาหารให้ฟรี ปลาโตช้าแต่ไม่อด'
                      : note,
                  cost: e.feedCost(lv),
                  free: lv == 1 && free,
                  onPressed: fed ? null : () => feed(lv),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Gap.xs),
        Text(
          'ค่าในเกม: ให้มากไม่ได้ทำให้ปลาโตเร็วขึ้น แต่ของเสียสะสมในน้ำเร็วกว่า',
          style: DsText.caption.copyWith(color: DsColors.textMuted),
        ),
      ],
    );
  }
}

class _FeedOption extends StatelessWidget {
  const _FeedOption({
    required this.level,
    required this.name,
    required this.note,
    required this.cost,
    required this.onPressed,
    this.free = false,
  });

  final int level;
  final String name;
  final String note;
  final int cost;
  final VoidCallback? onPressed;

  /// ลุงทองช่วยให้ฟรี (เงินหมด)
  final bool free;

  @override
  Widget build(BuildContext context) {
    final best = level == 2;
    // เทียบกับค่ามากสุดในเกม → 5 ช่อง
    final grow = kFeedGrowth[level] / kFeedGrowth.reduce(max);
    final dirty = kFeedAmmonia[level] / kFeedAmmonia.reduce(max);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: best ? DsColors.primarySoft : DsColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: best ? DsColors.primary : DsColors.border,
          width: best ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DsText.strong.copyWith(fontSize: 18)),
                Text(note, style: DsText.body.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                _Meter(
                  key: ValueKey('feed-grow-$level'),
                  label: 'ปลาโต',
                  value: grow,
                  color: DsColors.success,
                ),
                const SizedBox(height: 2),
                _Meter(
                  key: ValueKey('feed-dirty-$level'),
                  label: 'น้ำเสีย',
                  value: dirty,
                  color: DsColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.s),
          PixelButton(
            key: ValueKey('feed-$level'),
            label: 'ให้$name',
            style: best ? PixelButtonStyle.gold : PixelButtonStyle.water,
            below: free
                ? Text(
                    'ฟรี',
                    key: ValueKey('feed-free-$level'),
                    style: DsText.strong.copyWith(color: DsColors.success),
                  )
                : CoinTag(cost, boxed: true, size: FontSize.small),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

/// แถบ 5 ช่อง (0-1)
class _Meter extends StatelessWidget {
  const _Meter({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  /// จำนวนช่องที่เต็ม (อย่างน้อย 1 ถ้ามีค่า)
  int get filled => value <= 0 ? 0 : max(1, (value * 5).round());

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $filled จาก 5',
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(label, style: DsText.caption.copyWith(fontSize: 14)),
            ),
            for (var i = 0; i < 5; i++)
              Container(
                width: 14,
                height: 10,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: i < filled ? color : DsColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
