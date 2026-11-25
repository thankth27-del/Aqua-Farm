import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/difficulty.dart';
import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../theme/theme.dart';
import '../widgets/mode_dialog.dart';
import 'main_menu_screen.dart';

/// เลือกช่องบันทึก 3 ช่อง: เกมใหม่ / โหลด / เปลี่ยนชื่อ / ลบ
class SlotsScreen extends ConsumerWidget {
  const SlotsScreen({super.key});

  Future<void> _new(BuildContext context, WidgetRef ref, int slot) async {
    final mode = await modeDialog(context);
    if (mode == null || !context.mounted) return;
    final name = await nameDialog(context, 'ตั้งชื่อ Save', 'ฟาร์มของฉัน');
    if (name == null || !context.mounted) return;
    await ref.read(gameProvider.notifier).newGame(slot, name, mode: mode);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    toast(context, 'สร้างเกมใหม่: $name (${kDifficulties[mode]!.name})');
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
      danger: true,
      icon: const PixelIcon('warn', size: 48),
    )) {
      return;
    }
    await ref.read(slotsProvider.notifier).delete(info.slot);
    if (context.mounted) toast(context, 'ลบเซฟแล้ว');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(slotsProvider);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: GrassBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.maxColumn),
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + Gap.l,
              ),
              children: [
                SizedBox(
                  height: 230 + top,
                  child: const TitleBackdrop(logoSize: 40),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: const Center(
                    child: WoodSign(
                      'เลือกช่องบันทึก',
                      icon: PixelIcon('scroll', size: 28),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.m),
                  child: Column(
                    children: [
                      for (final e in slots.entries)
                        _SlotCard(
                          slot: e.key,
                          info: e.value,
                          onNew: () => _new(context, ref, e.key),
                          onLoad: () => _load(context, ref, e.value!),
                          onRename: () => _rename(context, ref, e.value!),
                          onDelete: () => _delete(context, ref, e.value!),
                        ),
                      PixelButton(
                        label: 'กลับ',
                        icon: const PixelGlyph(
                          Glyph.arrowRight,
                          flipX: true,
                          size: 20,
                          color: AquaColors.paper,
                        ),
                        style: PixelButtonStyle.wood,
                        expand: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.info,
    required this.onNew,
    required this.onLoad,
    required this.onRename,
    required this.onDelete,
  });

  final int slot;
  final SlotInfo? info;
  final VoidCallback onNew;
  final VoidCallback onLoad;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final d = info;
    return WoodPanel(
      padding: const EdgeInsets.all(Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                label: 'ช่อง $slot',
                child: ExcludeSemantics(
                  child: PixelBox(
                    fill: d == null ? AquaColors.creamDark : AquaColors.gold,
                    depth: 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: OutlinedText(
                      '$slot',
                      size: 30,
                      color: d == null ? AquaColors.paper : AquaColors.goldPale,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Gap.m),
              PixelIcon(d == null ? 'crate' : 'house', size: 44),
              const SizedBox(width: Gap.m),
              Expanded(
                child: Bold(
                  d?.name ?? 'ช่องว่าง',
                  size: FontSize.label + 2,
                  color: d == null ? AquaColors.textSoft : AquaColors.text,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (d != null) ...[
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.xs,
              children: [
                Tag(
                  'วัน ${d.day}/${kDifficulties[d.mode]!.targetDays}',
                  icon: const PixelIcon('cal', size: 18),
                ),
                Tag(
                  kDifficulties[d.mode]!.name,
                  color: modeColor(d.mode),
                  textColor: AquaColors.paper,
                ),
                CoinTag(d.money, boxed: true, size: FontSize.small),
                Tag(
                  '${d.pondCount}',
                  icon: const PixelIcon('f_nila', size: 22),
                ),
              ],
            ),
          ],
          const SizedBox(height: Gap.m),
          if (d == null)
            PixelButton(
              label: 'เกมใหม่',
              icon: const PixelGlyph(
                Glyph.plus,
                size: 20,
                color: AquaColors.paper,
              ),
              style: PixelButtonStyle.water,
              expand: true,
              onPressed: onNew,
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PixelButton(label: 'โหลด', onPressed: onLoad),
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  flex: 2,
                  child: PixelButton(
                    label: 'ชื่อ',
                    style: PixelButtonStyle.water,
                    onPressed: onRename,
                  ),
                ),
                const SizedBox(width: Gap.s),
                Expanded(
                  flex: 2,
                  child: PixelButton(
                    label: 'ลบ',
                    style: PixelButtonStyle.danger,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
