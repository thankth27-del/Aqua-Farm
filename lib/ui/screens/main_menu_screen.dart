import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart' show DsColors;

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../story_provider.dart';
import '../scenes/pixel_scene.dart';
import '../theme/theme.dart';
import 'design_preview_screen.dart';
import 'slots_screen.dart';

/// โลโก้เกม AQUA FARM (ใช้หน้าเมนูหลักและช่องบันทึก)
class AquaLogo extends StatelessWidget {
  const AquaLogo({super.key, this.size = 54});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BounceIn(
            child: Bob(
              dy: 3,
              period: const Duration(milliseconds: 2400),
              child: OutlinedText('AQUA FARM', size: size, stroke: size / 5),
            ),
          ),
          const SizedBox(height: Gap.xs),
          BounceIn(
            delay: const Duration(milliseconds: 180),
            child: PixelBox(
              fill: AquaColors.leaf,
              depth: 4,
              depthColor: AquaColors.grassDark,
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
              child: const Text(
                'From Farm to Food',
                style: TextStyle(
                  color: AquaColors.paper,
                  fontWeight: FontWeight.w700,
                  fontSize: FontSize.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ฉากฟาร์มเต็มพื้นที่ + โลโก้ลอยบนท้องฟ้า (หน้าเริ่มเกม)
class TitleBackdrop extends StatelessWidget {
  const TitleBackdrop({super.key, this.logoSize = 54});
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PixelScene(
          painterBuilder: (t) => FarmPainter(t, const FarmSceneData()),
          cover: true,
          framed: false,
          // ให้เห็นบ้าน ลังไม้ และร้านค้าเต็ม ๆ บนจอแนวตั้ง
          alignment: const Alignment(-.42, 0),
        ),
        Align(
          alignment: const Alignment(0, -.78),
          child: AquaLogo(size: logoSize),
        ),
      ],
    );
  }
}

/// เมนูหลัก: เนื้อเรื่อง / เอาชีวิตรอด (ล็อกจนกว่าจะเล่นเนื้อเรื่องจบ) / เครดิต
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  void _continue(BuildContext context, WidgetRef ref) {
    try {
      if (!ref.read(gameProvider.notifier).continueLatest()) {
        toast(context, 'ยังไม่มีเซฟ', bad: true);
      }
    } on SaveException catch (e) {
      toast(context, e.message, bad: true);
    }
  }

  /// เนื้อเรื่อง: มีเซฟค้าง → เลือกเล่นต่อ/เริ่มใหม่, ไม่มี → เริ่มบท 1
  Future<void> _story(BuildContext context, WidgetRef ref) async {
    final story = ref.read(storyProvider.notifier);
    final saved = ref.read(saveRepositoryProvider).loadStory();
    if (saved == null) return story.startNew();
    final ch = saved.$1.chapter;
    final choice = await _sheet(context, 'เนื้อเรื่อง', [
      ('continue', 'เล่นต่อ บทที่ $ch', PixelButtonStyle.green),
      ('restart', 'เริ่มเนื้อเรื่องใหม่', PixelButtonStyle.wood),
    ]);
    if (!context.mounted) return;
    if (choice == 'continue') {
      if (!story.resume()) toast(context, 'โหลดเนื้อเรื่องไม่ได้', bad: true);
    } else if (choice == 'restart' &&
        await confirmDialog(context, 'เริ่มเนื้อเรื่องใหม่ตั้งแต่บทที่ 1?')) {
      await story.startNew();
    }
  }

  /// เอาชีวิตรอด: ล็อก → บอกวิธีปลดล็อก, ปลดล็อกแล้ว → เกมใหม่/เล่นต่อ/โหลดเกม
  Future<void> _survival(BuildContext context, WidgetRef ref) async {
    if (!ref.read(survivalUnlockedProvider)) {
      toast(context, 'เล่นเนื้อเรื่องให้จบก่อน เพื่อปลดล็อกโหมดนี้', bad: true);
      return;
    }
    final choice = await _sheet(context, 'เอาชีวิตรอด', [
      ('new', 'เกมใหม่', PixelButtonStyle.gold),
      ('continue', 'เล่นต่อ', PixelButtonStyle.green),
      ('load', 'โหลดเกม', PixelButtonStyle.water),
    ]);
    if (!context.mounted) return;
    if (choice == 'continue') {
      _continue(context, ref);
    } else if (choice != null) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SlotsScreen()));
    }
  }

  Future<String?> _sheet(
    BuildContext context,
    String title,
    List<(String, String, PixelButtonStyle)> items,
  ) => showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: DsColors.scrim,
    // จอกว้าง: แผงเลือกไม่ยืดเต็มจอ
    constraints: const BoxConstraints(maxWidth: Responsive.maxPanel),
    // จอเตี้ย (มือถือแนวนอน): แผงสูงเกินจอได้ จึงเลื่อนได้
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.m),
        child: WoodPanel(
          margin: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(title),
              for (final (id, label, style) in items) ...[
                const SizedBox(height: Gap.s),
                PixelButton(
                  key: ValueKey('sheet-$id'),
                  label: label,
                  style: style,
                  expand: true,
                  onPressed: () => Navigator.pop(c, id),
                ),
              ],
              const SizedBox(height: Gap.s),
              PixelButton(
                label: 'ปิด',
                style: PixelButtonStyle.wood,
                expand: true,
                onPressed: () => Navigator.pop(c),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(survivalUnlockedProvider);
    final saved = ref.watch(storySavedProvider);
    final panel = WoodPanel(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(Gap.m),
      child: Column(
        children: [
          PixelButton(
            key: const ValueKey('menu-story'),
            label: 'เนื้อเรื่อง',
            icon: const PixelIcon('scroll', size: 28),
            size: PixelButtonSize.large,
            expand: true,
            below: Text(
              saved ? 'เล่นต่อจากบทที่ค้างไว้' : 'เรียนรู้ทีละบท 7 บท',
              style: const TextStyle(
                color: AquaColors.ink,
                fontSize: FontSize.small,
              ),
            ),
            onPressed: () => _story(context, ref),
          ),
          const SizedBox(height: Gap.m),
          Opacity(
            opacity: unlocked ? 1 : .55,
            child: PixelButton(
              key: const ValueKey('menu-survival'),
              label: 'เอาชีวิตรอด',
              icon: unlocked
                  ? const PixelIcon('f_nila', size: 28)
                  : const PixelGlyph(
                      Glyph.lock,
                      size: 22,
                      color: AquaColors.paper,
                    ),
              style: unlocked ? PixelButtonStyle.green : PixelButtonStyle.wood,
              size: PixelButtonSize.large,
              expand: true,
              below: Text(
                unlocked
                    ? '20 / 30 / 60 วัน'
                    : 'ล็อกอยู่ · เล่นเนื้อเรื่องจบเพื่อปลดล็อก',
                style: const TextStyle(
                  color: AquaColors.paper,
                  fontSize: FontSize.small,
                ),
              ),
              onPressed: () => _survival(context, ref),
            ),
          ),
          const SizedBox(height: Gap.m),
          PixelButton(
            label: 'เครดิต',
            icon: const PixelGlyph(
              Glyph.star,
              size: 20,
              color: AquaColors.gold,
            ),
            style: PixelButtonStyle.wood,
            expand: true,
            onPressed: () => infoDialog(context, 'Credits', const [
              'AQUA FARM: From Farm to Food',
              'โปรเจกต์ต้นแบบเกมจำลองฟาร์มปลา',
              'ค่าน้ำ ปลา และโภชนาการเป็นแบบจำลองเพื่อการเรียนรู้',
              'ฟอนต์ Mali และ Sarabun (SIL Open Font License)',
            ], icon: const PixelIcon('f_nila', size: 72)),
          ),
          // หน้า debug ระบบดีไซน์: เฉพาะโหมด debug หรือเว็บที่มี ?ds ใน URL
          if (kDebugMode || Uri.base.queryParameters.containsKey('ds')) ...[
            const SizedBox(height: Gap.m),
            PixelButton(
              key: const ValueKey('menu-design'),
              label: 'ตัวอย่างระบบดีไซน์',
              style: PixelButtonStyle.wood,
              expand: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DesignPreviewScreen(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    // แผงปุ่มไม่ยืดเกินขนาดโทรศัพท์บนจอกว้าง
    final buttons = Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxPanel),
        child: panel,
      ),
    );
    // แนวนอน: ฉาก | ปุ่ม ไม่ต้องเลื่อนจอ
    if (context.rs.useSplit) {
      return Scaffold(
        body: GrassBackground(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(flex: 5, child: TitleBackdrop()),
              Expanded(
                flex: 4,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Gap.l),
                    child: buttons,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: GrassBackground(
        child: Column(
          children: [
            const Expanded(child: TitleBackdrop()),
            Transform.translate(
              offset: const Offset(0, -26),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                child: buttons,
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
