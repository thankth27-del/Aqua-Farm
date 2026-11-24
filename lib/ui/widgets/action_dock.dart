import 'package:material_ui/material_ui.dart';

import '../layout/responsive.dart';
import '../theme/theme.dart';

/// แถบปุ่มหลักของหน้า ปักไว้เหนือเมนู (ไม่เลื่อนตามรายการ)
/// ผู้เล่นเห็นงานหลักของหน้านี้ทันทีโดยไม่ต้องเลื่อนหา
class ActionDock extends StatelessWidget {
  const ActionDock({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final r = context.rs;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s, 0, Gap.s, Gap.xs),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: r.isCompact ? double.infinity : Responsive.maxColumn,
          ),
          child: WoodPanel(
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
