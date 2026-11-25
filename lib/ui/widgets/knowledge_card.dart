/// การ์ดความรู้ "ลุงรู้มา" (ท้ายบท และในสมุดบันทึกลุงทอง)
/// ตัวเลขจากเกมติดป้าย "ค่าในเกม" ให้รู้ว่าไม่ใช่ตัวเลขจริงในชีวิตจริง
library;

import 'package:material_ui/material_ui.dart';

import '../../data/story_script.dart';
import '../design/design_system.dart' show DsColors, DsText;
import '../theme/theme.dart';

class KnowledgeCardView extends StatelessWidget {
  const KnowledgeCardView({
    super.key,
    required this.card,
    required this.chapter,
    this.action,
  });

  final KnowledgeCard card;

  /// บทที่ได้การ์ด (1-7)
  final int chapter;

  /// ปุ่มท้ายการ์ด (เช่น "เก็บลงสมุดบันทึก")
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final facts = card.facts();
    return Container(
      key: ValueKey('card-${card.id}'),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DsColors.ink, width: 3),
        boxShadow: const [BoxShadow(color: DsColors.ink, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: DsColors.accent,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                const PixelIcon('scroll', size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ลุงรู้มา',
                    style: DsText.strong.copyWith(
                      fontSize: 18,
                      color: DsColors.onAccent,
                    ),
                  ),
                ),
                Text(
                  'บทที่ $chapter',
                  style: DsText.strong.copyWith(
                    fontSize: 16,
                    color: DsColors.onAccent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(card.title, style: DsText.title.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text(card.body, style: DsText.body.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                for (final f in facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _FactRow(fact: f),
                  ),
                if (action != null) ...[const SizedBox(height: 6), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});
  final CardFact fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: DsColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DsColors.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fact.label, style: DsText.strong.copyWith(fontSize: 16)),
                Text(fact.value, style: DsText.body.copyWith(fontSize: 16)),
              ],
            ),
          ),
          if (fact.inGame) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: DsColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DsColors.primary, width: 1.5),
              ),
              child: Text(
                'ค่าในเกม',
                style: DsText.caption.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DsColors.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
