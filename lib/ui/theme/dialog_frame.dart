import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'buttons.dart';
import '../design/design_system.dart';
import '../layout/responsive.dart';
import 'colors.dart';
import 'frames.dart';
import 'motion.dart';

/// หน้าต่างพิกเซล (กรอบไม้ เด้งเข้ามา) — ใช้กับหน้ายืนยัน/ข้อมูล/ใส่ชื่อ
class PixelDialog extends StatelessWidget {
  const PixelDialog({
    super.key,
    this.title,
    this.icon,
    required this.body,
    required this.actions,
  });

  final String? title;
  final Widget? icon;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      // จอกว้างไม่ยืดเต็มจอ: กว้างสุดเท่าแผงมาตรฐาน จัดกลาง
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxPanel),
        child: BounceIn(
          from: .8,
          child: WoodPanel(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(height: Gap.s)],
                if (title != null) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: DsText.title,
                  ),
                  const SizedBox(height: Gap.s),
                ],
                Flexible(child: SingleChildScrollView(child: body)),
                const SizedBox(height: Gap.l),
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: Gap.m),
                      Expanded(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// หน้ายืนยันมาตรฐาน: ข้อความ + ปุ่ม ตกลง/ยกเลิก
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.message,
    this.ok = 'ตกลง',
    this.icon,
    this.danger = false,
  });

  final String message;
  final String ok;
  final Widget? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return PixelDialog(
      icon: icon,
      body: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: FontSize.label,
          color: AquaColors.text,
          height: 1.4,
        ),
      ),
      actions: [
        PixelButton(
          label: 'ยกเลิก',
          style: PixelButtonStyle.wood,
          onPressed: () => Navigator.pop(context, false),
        ),
        PixelButton(
          label: ok,
          style: danger ? PixelButtonStyle.danger : PixelButtonStyle.gold,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

/// กล่องแจ้งผลการกระทำ (ใช้ใน SnackBar)
class ToastBubble extends StatelessWidget {
  const ToastBubble(this.message, {super.key, this.bad = false});
  final String message;
  final bool bad;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bad ? DsColors.danger : DsColors.success,
        borderRadius: BorderRadius.circular(DsRadius.card),
        boxShadow: DsShadow.raised,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: kFont,
            color: DsColors.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: FontSize.body,
          ),
        ),
      ),
    );
  }
}
