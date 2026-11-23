/// หน้ายืนยัน ช่องใส่ชื่อ และ toast
library;

import 'package:material_ui/material_ui.dart';

import '../game/game_engine.dart';
import 'theme.dart';

/// หน้ายืนยัน — คืน true เมื่อกด "ตกลง" (ใช้กับทุกการซื้อ ขาย ทิ้ง)
Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String ok = 'ตกลง',
}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        PixelButton(
          label: ok,
          style: PixelButtonStyle.gold,
          onPressed: () => Navigator.pop(c, true),
        ),
        PixelButton(
          label: 'ยกเลิก',
          style: PixelButtonStyle.dark,
          onPressed: () => Navigator.pop(c, false),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// กล่องข้อความที่มีปุ่มเดียว
Future<void> infoDialog(
  BuildContext context,
  String title,
  List<String> lines,
) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: GoldTitle(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (final l in lines) Muted(l, size: 14)],
      ),
      actionsAlignment: MainAxisAlignment.center,
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
    return AlertDialog(
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _ctl,
        maxLength: 16,
        textAlign: TextAlign.center,
        autofocus: true,
        decoration: InputDecoration(errorText: _error, counterText: ''),
        onSubmitted: (_) => _ok(),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        PixelButton(
          label: 'ตกลง',
          style: PixelButtonStyle.gold,
          onPressed: _ok,
        ),
        PixelButton(
          label: 'ยกเลิก',
          style: PixelButtonStyle.dark,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

/// toast (แจ้งผลการกระทำ) — สีแดงเมื่อไม่สำเร็จหรือเป็นคำเตือน
void toast(BuildContext context, String message, {bool bad = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: bad ? const TextStyle(color: Colors.white) : null,
        ),
        backgroundColor: bad ? AquaColors.red : null,
        duration: const Duration(milliseconds: 2600),
      ),
    );
}

void showResult(BuildContext context, ActionResult r) =>
    toast(context, r.message, bad: r.warning);
