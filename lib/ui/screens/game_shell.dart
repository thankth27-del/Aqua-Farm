import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/disaster_data.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../theme/theme.dart';
import 'farm_tab.dart';
import 'fish_tab.dart';
import 'market_tab.dart';
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

  static const tabs = [
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
      2 => const MarketTab(),
      3 => const PlaceholderTab(
        title: 'ครัว',
        icon: 'tomyum',
        items: ['tomyum', 'fry', 'hsoup', 'dry'],
        note: 'ทำอาหาร 5 เมนู และถนอมอาหาร 4 วิธี',
      ),
      _ => const PlaceholderTab(
        title: 'คลังสินค้า',
        icon: 'crate',
        items: ['crate', 'jar', 'fridge', 'can'],
        note: 'เสบียงฉุกเฉิน อาหาร และวันหมดอายุ',
      ),
    };
    return Scaffold(
      body: GrassBackground(
        child: Column(
          children: [
            // ข้อความแจ้งเตือนแสดงใต้แถบบนนี้
            const ToastAnchor(child: TopBar()),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(key: ValueKey(_tab), child: body),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GameNavBar(
        selected: _tab,
        items: tabs,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// เมนูล่างแบบเกม: แผ่นไม้ ไอคอนใหญ่ ชื่อสั้น ช่องที่เลือกยกขึ้นเป็นป้ายทอง
class GameNavBar extends StatelessWidget {
  const GameNavBar({
    super.key,
    required this.selected,
    required this.items,
    required this.onSelect,
  });

  final int selected;
  final List<(String, String)> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return WoodPlank(
      padding: EdgeInsets.fromLTRB(
        6,
        6,
        6,
        6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _NavItem(
                label: items[i].$1,
                icon: items[i].$2,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconW = PixelIcon(icon, size: selected ? 40 : 34);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: Center(
            child: selected
                ? BounceIn(
                    key: ValueKey('nav-$label'),
                    from: .7,
                    child: iconW,
                  )
                : iconW,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? AquaColors.ink : AquaColors.paper,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72, minWidth: kMinTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: selected
                ? PixelBox(
                    fill: AquaColors.gold,
                    depth: 4,
                    depthColor: AquaColors.goldDark,
                    padding: const EdgeInsets.fromLTRB(2, 3, 2, 3),
                    child: Center(heightFactor: 1, child: content),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 7),
                    child: Center(heightFactor: 1, child: content),
                  ),
          ),
        ),
      ),
    );
  }
}

/// แถบบน: เงิน วัน เสบียง คุณภาพน้ำ เตือนภัย ปุ่มเมนู และปุ่ม "จบวัน"
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
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xAA1B120B),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: WoodPanel(
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OutlinedText('เมนู / พัก'),
                const SizedBox(height: Gap.m),
                PixelButton(
                  label: 'เล่นต่อ',
                  icon: const PixelGlyph(
                    Glyph.arrowRight,
                    size: 20,
                    color: AquaColors.paper,
                  ),
                  expand: true,
                  onPressed: () => Navigator.pop(c),
                ),
                const SizedBox(height: Gap.s),
                PixelButton(
                  label: 'บันทึกเกม',
                  icon: const PixelIcon('scroll', size: 24),
                  style: PixelButtonStyle.water,
                  expand: true,
                  onPressed: () => Navigator.pop(c, 'save'),
                ),
                const SizedBox(height: Gap.s),
                PixelButton(
                  label: 'กลับเมนูหลัก',
                  icon: const PixelIcon('house', size: 24),
                  style: PixelButtonStyle.wood,
                  expand: true,
                  onPressed: () => Navigator.pop(c, 'exit'),
                ),
              ],
            ),
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
        icon: const PixelIcon('house', size: 48),
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

    return WoodPlank(
      padding: EdgeInsets.fromLTRB(
        8,
        8 + MediaQuery.paddingOf(context).top,
        8,
        10,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 5, child: MoneyChip(money: s.money)),
              Expanded(
                flex: 5,
                child: _Chip(
                  icon: const PixelIcon('cal', size: 22),
                  text: 'วันที่ ${s.day}',
                  tooltip: 'วันในเกม',
                ),
              ),
              Expanded(
                flex: 4,
                child: _Chip(
                  icon: const PixelIcon('crate', size: 22),
                  text: '${fmtNum(e.supplyDays)} วัน',
                  tooltip: 'เสบียงอยู่ได้กี่วัน',
                ),
              ),
              Expanded(
                flex: 6,
                child: _Chip(
                  icon: const PixelIcon('drop', size: 22),
                  text: ws.label,
                  dot: Color(ws.color),
                  tooltip: 'คุณภาพน้ำ ${s.water}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
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
              const SizedBox(width: Gap.s),
              PixelIconButton(
                icon: const PixelIcon('gear', size: 28),
                tooltip: 'เมนู / พัก',
                onPressed: () => _menu(context, ref),
              ),
              const SizedBox(width: Gap.s),
              PixelButton(
                label: 'จบวัน',
                icon: const PixelGlyph(
                  Glyph.moon,
                  size: 22,
                  color: AquaColors.goldPale,
                ),
                trailing: const PixelGlyph(
                  Glyph.arrowRight,
                  size: 18,
                  color: AquaColors.paper,
                ),
                onPressed: () => _endDay(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ช่องเงิน: ตัวเลขนับขึ้น/ลง และเหรียญลอยเมื่อได้/เสียเงิน
class MoneyChip extends StatefulWidget {
  const MoneyChip({super.key, required this.money});
  final int money;

  @override
  State<MoneyChip> createState() => _MoneyChipState();
}

class _MoneyChipState extends State<MoneyChip> {
  final _floats = <(int id, int delta)>[];
  int _next = 0;

  @override
  void didUpdateWidget(MoneyChip old) {
    super.didUpdateWidget(old);
    final d = widget.money - old.money;
    if (d != 0) _floats.add((_next++, d));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedCount(
          value: widget.money,
          builder: (_, v) => _Chip(
            icon: const PixelIcon('coin', size: 22),
            text: '$v฿',
            tooltip: 'เงิน',
            highlight: true,
          ),
        ),
        for (final f in _floats)
          Positioned(
            left: 10,
            top: 30,
            child: IgnorePointer(
              child: FloatAway(
                key: ValueKey(f.$1),
                rise: f.$2 > 0 ? 26 : -26,
                onDone: () => setState(() => _floats.remove(f)),
                child: _Delta(f.$2),
              ),
            ),
          ),
      ],
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta(this.delta);
  final int delta;

  @override
  Widget build(BuildContext context) {
    final gain = delta > 0;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < (gain ? 3 : 1); i++)
            Transform.translate(
              offset: Offset(i * -6.0, i * -5.0),
              child: const PixelIcon('coin', size: 18),
            ),
          OutlinedText(
            gain ? '+$delta' : '-${-delta}',
            size: 18,
            color: gain ? AquaColors.goldLight : AquaColors.redPale,
            outline: gain ? AquaColors.ink : AquaColors.redDark,
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
    this.dot,
    this.highlight = false,
  });
  final Widget icon;
  final String text;
  final String tooltip;
  final Color? dot;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: PixelBox(
          fill: highlight ? AquaColors.goldPale : AquaColors.cream,
          px: 3,
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 4),
              if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dot,
                    border: Border.all(color: AquaColors.ink, width: 2),
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AquaColors.text,
                      fontSize: 16,
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
    return Blink(
      low: .7,
      child: PixelBox(
        fill: AquaColors.red,
        depth: 3,
        depthColor: AquaColors.redDark,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon) ...[
              const PixelIcon('warn', size: 22),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
