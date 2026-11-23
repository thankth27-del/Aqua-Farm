/// หน้ายืนยัน ช่องใส่ชื่อ และ toast (ใช้หน้าต่างจากชุดดีไซน์กลาง)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../game/game_engine.dart';
import 'sound.dart';
import 'theme/theme.dart';

/// หน้ายืนยัน — คืน true เมื่อกด "ตกลง" (ใช้กับทุกการซื้อ ขาย ทิ้ง)
Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String ok = 'ตกลง',
  Widget? icon,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xAA1B120B),
    builder: (c) =>
        ConfirmDialog(message: message, ok: ok, icon: icon, danger: danger),
  );
  return r ?? false;
}

/// กล่องข้อความที่มีปุ่มเดียว
Future<void> infoDialog(
  BuildContext context,
  String title,
  List<String> lines, {
  Widget? icon,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xAA1B120B),
    builder: (c) => PixelDialog(
      title: title,
      icon: icon,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.xs),
              child: Muted(
                l,
                size: FontSize.body,
                color: AquaColors.text,
                align: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        PixelButton(
          label: 'กลับ',
          style: PixelButtonStyle.gold,
          onPressed: () => Navigator.pop(c),
        ),
      ],
    ),
  );
}

/// ช่องใส่ชื่อ (เซฟใหม่ / เปลี่ยนชื่อ) — คืน null เมื่อยกเลิก
Future<String?> nameDialog(BuildContext context, String title, String initial) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xAA1B120B),
    builder: (c) => _NameDialog(title: title, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctl = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _ok() {
    final v = _ctl.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'กรุณาใส่ชื่อ');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return PixelDialog(
      title: widget.title,
      icon: const PixelIcon('house', size: 56),
      body: TextField(
        controller: _ctl,
        maxLength: 16,
        textAlign: TextAlign.center,
        autofocus: true,
        style: const TextStyle(
          fontSize: FontSize.label,
          fontWeight: FontWeight.w700,
          color: AquaColors.text,
        ),
        decoration: InputDecoration(errorText: _error, counterText: ''),
        onSubmitted: (_) => _ok(),
      ),
      actions: [
        PixelButton(
          label: 'ยกเลิก',
          style: PixelButtonStyle.wood,
          onPressed: () => Navigator.pop(context),
        ),
        PixelButton(label: 'ตกลง', onPressed: _ok),
      ],
    );
  }
}

/// toast (แจ้งผลการกระทำ) ด้านบนจอใต้แถบบน — สีแดงเมื่อไม่สำเร็จหรือเป็นคำเตือน
/// พร้อมเสียงบี๊บเหมือนต้นแบบ (สำเร็จเสียงสูง ไม่สำเร็จเสียงต่ำ)
void toast(BuildContext context, String message, {bool bad = false}) {
  ToastHost.show(context, message, bad: bad);
  beepFor(ProviderScope.containerOf(context, listen: false), bad: bad);
}

void showResult(BuildContext context, ActionResult r) =>
    toast(context, r.message, bad: r.warning);
