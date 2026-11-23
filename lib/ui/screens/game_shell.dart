import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../theme.dart';
import 'farm_tab.dart';
import 'fish_tab.dart';
import 'placeholder_tab.dart';
import 'report_screen.dart';

/// โครงหน้าเกม: แถบบน + เมนูล่าง 5 แท็บ
class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  int _tab = 0;

  static const _tabs = [
    ('ฟาร์ม', 'house'),
    ('ปลา', 'f_nila'),
    ('ตลาด', 'garlic'),
    ('ครัว', 'tomyum'),
    ('คลัง', 'crate'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => FarmTab(onOpenTab: (i) => setState(() => _tab = i)),
      1 => const FishTab(),
      2 => const PlaceholderTab(
        title: 'ตลาด',
        icon: 'garlic',
        note: 'ซื้อวัตถุดิบ ขายปลา และอุปกรณ์ครัว',
      ),
      3 => const PlaceholderTab(
        title: 'ครัว',
        icon: 'tomyum',
        note: 'ทำอาหาร 5 เมนู และถนอมอาหาร 4 วิธี',
      ),
      _ => const PlaceholderTab(
        title: 'คลังสินค้า',
        icon: 'crate',
        note: 'เสบียงฉุกเฉิน อาหาร และวันหมดอายุ',
      ),
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopBar(),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: PixelIcon(t.$2, size: 28), label: t.$1),
        ],
      ),
    );
  }
}

/// แถบบน: เงิน วัน เสบียง คุณภาพน้ำ ปุ่ม "จบวัน"
class TopBar extends ConsumerWidget {
  const TopBar({super.key});

  Future<void> _endDay(BuildContext context, WidgetRef ref) async {
    final r = await ref.read(gameProvider.notifier).endDay();
    if (!context.mounted || r.gameOver) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const ReportScreen(),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final ctl = ref.read(gameProvider.notifier);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AquaColors.panel,
      shape: const RoundedRectangleBorder(),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GoldTitle('เมนู / พัก'),
              const SizedBox(height: 10),
              PixelButton(
                label: 'บันทึกเกม',
                expand: true,
                onPressed: () => Navigator.pop(c, 'save'),
              ),
              const SizedBox(height: 8),
              PixelButton(
                label: 'กลับเมนูหลัก',
                style: PixelButtonStyle.dark,
                expand: true,
                onPressed: () => Navigator.pop(c, 'exit'),
              ),
              const SizedBox(height: 8),
              PixelButton(
                label: 'เล่นต่อ',
                style: PixelButtonStyle.gold,
                expand: true,
                onPressed: () => Navigator.pop(c),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == 'save') {
      await ctl.save();
      if (context.mounted) toast(context, 'บันทึกเกมแล้ว');
    } else if (choice == 'exit') {
      if (await confirmDialog(
        context,
        'กลับสู่เมนูหลัก? (ระบบจะบันทึกให้อัตโนมัติ)',
      )) {
        await ctl.exitToMenu();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider)!;
    final e = session.engine;
    final s = session.state;
    final ws = e.waterStatus;
    final w = e.warnDays;
    final a = s.active;
    String? alert;
    if (a != null) {
      alert = '${kDisasters[a.type]!.name} ${a.dayIndex + 1}/${a.duration}';
    } else if (w > 0) {
      alert = '${kDisasters[s.upcoming!.type]!.name} $w วัน';
    }

    return Container(
      color: AquaColors.panel,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        children: [
          Row(
            children: [
              _Chip(icon: 'coin', text: '${s.money}฿', tooltip: 'เงิน'),
              _Chip(icon: 'cal', text: 'วันที่ ${s.day}', tooltip: 'วันในเกม'),
              _Chip(
                icon: 'crate',
                text: '${fmtNum(e.supplyDays)} วัน',
                tooltip: 'เสบียงอยู่ได้กี่วัน',
              ),
              _Chip(
                icon: 'drop',
                text: ws.label,
                color: Color(ws.color),
                tooltip: 'คุณภาพน้ำ ${s.water}%',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (alert != null)
                Expanded(child: _AlertChip(text: alert))
              else
                const Spacer(),
              if (!s.power)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: _AlertChip(text: 'ไฟดับ', icon: false),
                ),
              SizedBox(
                width: kMinTap,
                height: kMinTap,
                child: IconButton(
                  tooltip: 'เมนู / พัก',
                  onPressed: () => _menu(context, ref),
                  icon: const PixelIcon('gear', size: 28),
                ),
              ),
              const SizedBox(width: 4),
              PixelButton(
                label: 'จบวัน ▶',
                style: PixelButtonStyle.gold,
                onPressed: () => _endDay(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    required this.tooltip,
    this.color = Colors.white,
  });
  final String icon;
  final String text;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AquaColors.ink,
            border: Border.all(color: AquaColors.primary, width: 2),
          ),
          child: Row(
            children: [
              PixelIcon(icon, size: 18),
              const SizedBox(width: 3),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.text, this.icon = true});
  final String text;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kMinTap - 8,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1620),
        border: Border.all(color: AquaColors.red, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon) ...[
            const PixelIcon('warn', size: 20),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AquaColors.bad,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
