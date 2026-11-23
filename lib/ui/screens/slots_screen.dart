import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../theme.dart';

/// เลือกช่องบันทึก 3 ช่อง: เกมใหม่ / โหลด / เปลี่ยนชื่อ / ลบ
class SlotsScreen extends ConsumerWidget {
  const SlotsScreen({super.key});

  Future<void> _new(BuildContext context, WidgetRef ref, int slot) async {
    final name = await nameDialog(context, 'ตั้งชื่อ Save', 'ฟาร์มของฉัน');
    if (name == null || !context.mounted) return;
    await ref.read(gameProvider.notifier).newGame(slot, name);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    toast(context, 'สร้างเกมใหม่: $name');
  }

  void _load(BuildContext context, WidgetRef ref, SlotInfo info) {
    try {
      ref.read(gameProvider.notifier).load(info.slot);
      Navigator.of(context).popUntil((r) => r.isFirst);
      toast(context, 'โหลดเกมแล้ว: ${info.name}');
    } on SaveException catch (e) {
      toast(context, e.message, bad: true);
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    SlotInfo info,
  ) async {
    final name = await nameDialog(context, 'ตั้งชื่อใหม่', info.name);
    if (name == null) return;
    await ref.read(slotsProvider.notifier).rename(info.slot, name);
    if (context.mounted) toast(context, 'เปลี่ยนชื่อแล้ว');
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    SlotInfo info,
  ) async {
    if (!await confirmDialog(
      context,
      'ลบเซฟ ${info.name}? ย้อนกลับไม่ได้',
      ok: 'ลบ',
    )) {
      return;
    }
    await ref.read(slotsProvider.notifier).delete(info.slot);
    if (context.mounted) toast(context, 'ลบเซฟแล้ว');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(slotsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const GoldTitle('เลือกช่องบันทึก'),
            const Muted('เมนูหลัก → ช่องบันทึก → ฟาร์ม'),
            const SizedBox(height: 12),
            for (final e in slots.entries)
              _slotCard(context, ref, e.key, e.value),
            const SizedBox(height: 8),
            PixelButton(
              label: 'กลับ',
              style: PixelButtonStyle.dark,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotCard(BuildContext context, WidgetRef ref, int slot, SlotInfo? d) {
    return PixelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PixelIcon(d == null ? 'crate' : 'house', size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ช่อง $slot: ${d?.name ?? 'ว่าง'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Muted(
                      d == null
                          ? 'ยังไม่มีข้อมูล'
                          : 'วันที่ ${d.day} · ${d.money}฿ · ปลา ${d.pondCount} · เซฟ v${d.version}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (d == null)
            PixelButton(
              label: 'เกมใหม่',
              style: PixelButtonStyle.gold,
              expand: true,
              onPressed: () => _new(context, ref, slot),
            )
          else
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'โหลด',
                    style: PixelButtonStyle.gold,
                    onPressed: () => _load(context, ref, d),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PixelButton(
                    label: 'ชื่อ',
                    onPressed: () => _rename(context, ref, d),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PixelButton(
                    label: 'ลบ',
                    style: PixelButtonStyle.dark,
                    onPressed: () => _delete(context, ref, d),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
