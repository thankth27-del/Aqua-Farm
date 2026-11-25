import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../design/design_system.dart' show DsColors, DsRadius, DsText;

import '../../data/difficulty.dart';
import '../../data/disaster_data.dart';
import '../../game/hints.dart';
import '../../game/story.dart';
import '../../game/story_talk.dart';
import '../../data/story_script.dart';
import '../../game/tutorial.dart';
import '../build_info.dart';
import '../dialogs.dart';
import '../layout/responsive.dart';
import '../providers.dart';
import '../sound.dart';
import '../story_provider.dart';
import '../theme/theme.dart';
import '../widgets/game_hud.dart';
import '../widgets/guide_bars.dart';
import '../widgets/story_gate.dart';
import '../widgets/knowledge_card.dart';
import '../widgets/story_talk_layer.dart';
import '../widgets/tutorial_panel.dart';
import 'farm_tab.dart';
import 'fish_tab.dart';
import 'kitchen_tab.dart';
import 'market_tab.dart';
import 'event_screen.dart';
import 'report_screen.dart';
import 'storage_tab.dart';

/// โครงหน้าเกมแบบเกมมือถือ: ฉากของหน้าเต็มจอเป็นพื้นหลัง
/// ทับด้วย HUD แถบเดียว (บน) + ปุ่มกลมมุมจอ + กล่องคำพูด "ตอนนี้ควรทำ"
/// + เนื้อหาของแท็บ + เมนูล่าง (มือถือ) หรือเมนูข้างแคบ (แนวนอน/คอม)
class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key});

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  int _tab = 0;

  /// แท็บปลากำลังเปิดร้านปลาอยู่ไหม (แยก "บ่อปลา" กับ "ร้านปลา" ให้บทเรียน)
  bool _fishShop = false;

  /// เพิ่มทุกครั้งที่แถบ "ตอนนี้ควรทำ" สั่งเปิดแท็บปลา (สร้างแท็บใหม่ตามหน้าบ่อ/ร้าน)
  int _fishOpen = 0;

  static const tabs = [
    ('ฟาร์ม', 'house'),
    ('ปลา', 'f_nila'),
    ('ตลาด', 'garlic'),
    ('ครัว', 'tomyum'),
    ('คลัง', 'crate'),
  ];

  /// แท็บที่บทเรียนชี้
  static int tabOf(TutorialTarget t) => switch (t) {
    TutorialTarget.status || TutorialTarget.home || TutorialTarget.prepare => 0,
    TutorialTarget.pond || TutorialTarget.shop => 1,
    TutorialTarget.kitchen => 3,
    TutorialTarget.storage => 4,
  };

  GameScreen get _screen => switch (_tab) {
    0 => GameScreen.farm,
    1 => _fishShop ? GameScreen.shop : GameScreen.pond,
    2 => GameScreen.market,
    3 => GameScreen.kitchen,
    _ => GameScreen.storage,
  };

  void _select(int i) => setState(() {
    _tab = i;
    _fishShop = false;
  });

  /// แถบ "ตอนนี้ควรทำ" → เปิดหน้าที่ต้องไป
  void _go(NextPlace p) {
    final tab = tabOfPlace(p);
    if (tab == null) return;
    setState(() {
      _tab = tab;
      _fishShop = p == NextPlace.shop;
      _fishOpen++;
    });
  }

  /// เนื้อเรื่องเปลี่ยนบท → เปิดแท็บของสิ่งที่ต้องทำต่อ
  void _followStory() {
    final story = watchStory(ref);
    if (story == null) return;
    final (p, e) = story;
    final next = Story.nextTarget(p, e);
    final tab = next == null ? null : storyTabOf(next);
    if (tab != null && Story.tabOpen(p, tab)) _select(tab);
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(gameProvider)!.engine.tutorialStep?.target;
    final story = watchStory(ref);
    Set<int>? locked;
    int? storyTab;
    if (story != null) {
      final (p, e) = story;
      locked = {
        for (var i = 0; i < tabs.length; i++)
          if (!Story.tabOpen(p, i)) i,
      };
      // แท็บที่เปิดอยู่ถูกล็อกในบทนี้ → ไปแท็บแรกที่เปิดได้
      if (locked.contains(_tab) && locked.length < tabs.length) {
        _tab = [for (var i = 0; i < tabs.length; i++) i]
            .firstWhere((i) => !locked!.contains(i));
        _fishShop = false;
      }
      final next = Story.nextTarget(p, e);
      storyTab = next == null ? null : storyTabOf(next);
      // ไม่มีเมนูล่าง: สิ่งที่ต้องทำต่อไปอยู่หน้าอื่น → ลุงพาไปหน้านั้น
      // (รอลุงพูดจบก่อน: บรรทัดที่ลุงชี้หน้าอื่น เช่น "ลองตากปลาดู" จะได้ไม่ถูกดึงกลับ)
      final go = storyTab;
      final talking = StoryTalk.next(p, e) != null;
      if (go != null && go != _tab && !talking && Story.tabOpen(p, go)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tab != go) _select(go);
        });
      }
    }
    final body = switch (_tab) {
      0 => FarmTab(onOpenTab: _select),
      1 => FishTab(
        key: ValueKey('fish-$_fishOpen'),
        initialShop: _fishShop,
        onShopChanged: (v) => setState(() => _fishShop = v),
      ),
      2 => const MarketTab(),
      3 => KitchenTab(onOpenTab: _select),
      _ => const StorageTab(),
    };
    // ฉากเต็มจอของแท็บ (แท็บที่ยังไม่มีฉาก ใช้พื้นใต้น้ำกลาง)
    final backdrop = switch (_tab) {
      0 => const FarmBackdrop(),
      1 when !_fishShop => const PondBackdrop(),
      2 => const MarketBackdrop(),
      3 => const KitchenBackdrop(),
      4 => const StorageBackdrop(),
      _ => const GrassBackground(child: SizedBox.expand()),
    };
    // จอแคบ: เมนูล่าง · จอกว้าง/แนวนอน: เมนูข้างแคบ (ระบบเลย์เอาต์กลาง)
    final side = context.rs.useSideNav;
    // โหมดเอาชีวิตรอด (นอกบทเรียน): ป้ายงานค้างบนเมนู + คำแนะนำ + แถบ "ตอนนี้ควรทำ"
    final guide = guideOn(ref);
    final tipOn = tipActive(ref, _screen);
    final nav = GameNavBar(
      selected: _tab,
      items: tabs,
      vertical: side,
      highlight: story != null
          ? storyTab
          : (target == null ? null : tabOf(target)),
      locked: locked ?? const {},
      badges: guide ? tabBadges(ref.read(gameProvider)!.engine) : null,
      onSelect: _select,
    );
    final guides = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StoryGoalBar(onChapterChanged: _followStory),
        TutorialPanel(screen: _screen),
        // คำแนะนำครั้งแรกของหน้า แทนที่ "ตอนนี้ควรทำ" จนกด "เข้าใจแล้ว"
        if (guide) tipOn ? TipBar(screen: _screen) : NextStepBar(onGo: _go),
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ข้อความแจ้งเตือนแสดงใต้ HUD นี้
        ToastAnchor(
          child: TopBar(
            onReplayTutorial: () => _select(0),
            endDayTip: tipOn && _screen == GameScreen.farm,
            onHelp: guide
                ? () => ref.read(tipsProvider.notifier).replay(_screen.name)
                : null,
          ),
        ),
        // จอกว้าง: แผงคำแนะนำชิดซ้าย ไม่ยืดเต็มจอ (เห็นฉากด้านขวา)
        if (side)
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.maxColumn),
              child: guides,
            ),
          )
        else
          guides,
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(key: ValueKey(_tab), child: body),
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: DsColors.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          backdrop,
          // เนื้อเรื่อง: ไม่มีเมนูหลัก ลุงทองพาไปหน้าที่ต้องใช้เอง (เหลือปุ่มพักมุมจอ)
          if (story != null)
            content
          else if (side)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                nav,
                Expanded(child: content),
              ],
            )
          else
            Column(
              children: [
                Expanded(child: content),
                nav,
              ],
            ),
          // เนื้อเรื่อง: ลุงทองเล่า/ถาม/ให้การ์ดความรู้ ทับหน้าเกม
          if (story != null) StoryTalkLayer(onOpenTab: _select),
        ],
      ),
    );
  }
}

/// เมนูหลัก: มือถือ = แถบล่างไอคอนใหญ่ ป้ายสั้น / แนวนอน-คอม = แถบข้างแคบ
/// ช่องที่เลือกเป็นป้ายสีเด่น ช่องอื่นตัวขาวบนพื้นเข้ม (คอนทราสต์ชัด)
class GameNavBar extends StatelessWidget {
  const GameNavBar({
    super.key,
    required this.selected,
    required this.items,
    required this.onSelect,
    this.highlight,
    this.locked = const {},
    this.vertical = false,
    this.badges,
  });

  final int selected;

  /// ป้ายงานค้างต่อแท็บ: null = ไม่มี · 0 = จุดแดง · n = ตัวเลข
  final List<int?>? badges;

  /// เมนูข้าง (จอกว้าง/แนวนอน) แทนเมนูล่าง
  final bool vertical;
  final List<(String, String)> items;
  final ValueChanged<int> onSelect;

  /// ช่องที่บทเรียนชี้ (กะพริบ) — ไม่ชี้ช่องที่เปิดอยู่แล้ว
  final int? highlight;

  /// ช่องที่ยังไม่เปิดในบทนี้ของเนื้อเรื่อง (จาง กดไม่ได้)
  final Set<int> locked;

  /// ความกว้างแถบข้าง
  static const double sideWidth = 70;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    Widget badge(int i, Widget w) {
      final b = badges == null || i >= badges!.length ? null : badges![i];
      if (b == null || i == selected || locked.contains(i)) return w;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          w,
          Positioned(
            top: 2,
            right: 4,
            child: NavBadge(key: ValueKey('nav-badge-$i'), count: b),
          ),
        ],
      );
    }

    Widget cell(int i) => Spotlight(
      on: i == highlight && i != selected,
      pad: 0,
      child: locked.contains(i)
          ? Semantics(
              enabled: false,
              child: IgnorePointer(
                child: Opacity(
                  key: ValueKey('nav-locked-$i'),
                  opacity: .35,
                  child: _NavItem(
                    label: items[i].$1,
                    icon: items[i].$2,
                    selected: false,
                    onTap: () {},
                  ),
                ),
              ),
            )
          : _NavItem(
              label: items[i].$1,
              icon: items[i].$2,
              selected: i == selected,
              onTap: () => onSelect(i),
            ),
    );
    Widget item(int i) => badge(i, cell(i));
    const edge = BorderSide(color: DsColors.glassEdge, width: 1.5);
    if (vertical) {
      // แถบข้างแคบ: เรียงลงกลางแนวตั้ง ย่อพอดีถ้าจอเตี้ย
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: DsColors.glass,
          border: Border(right: edge),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            4 + pad.left,
            6 + pad.top,
            4,
            6 + pad.bottom,
          ),
          child: SizedBox(
            width: sideWidth,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: sideWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: item(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DsColors.ink,
        border: Border(top: edge),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, 5, 4, 5 + pad.bottom),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) Expanded(child: item(i)),
          ],
        ),
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
    final iconW = PixelIcon(icon, size: selected ? 38 : 34);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 38,
          child: Center(
            child: selected
                ? BounceIn(key: ValueKey('nav-$label'), from: .7, child: iconW)
                : iconW,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: 16,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: selected ? DsColors.ink : DsColors.onGlass,
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
          constraints: const BoxConstraints(minHeight: 66, minWidth: kMinTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
              decoration: BoxDecoration(
                color: selected ? DsColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? DsColors.ink : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Center(heightFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// HUD แถบเดียว: เงิน · วัน · อาหารพอกี่วัน · คุณภาพน้ำ (ไอคอน + ตัวเลขใหญ่)
/// และปุ่มกลมมุมจอ: คำแนะนำ (?) · เมนู/ตั้งค่า · จบวัน
class TopBar extends ConsumerWidget {
  const TopBar({
    super.key,
    this.onReplayTutorial,
    this.onHelp,
    this.endDayTip = false,
  });

  /// ปุ่ม "?" แสดงคำแนะนำของหน้านี้อีกครั้ง (null = ไม่มีปุ่ม)
  final VoidCallback? onHelp;

  /// คำแนะนำหน้าฟาร์มชี้ปุ่ม "จบวัน"
  final bool endDayTip;

  /// หลังกด "เล่นบทเรียนซ้ำ" (ให้หน้าเกมกลับไปหน้าฟาร์ม)
  final VoidCallback? onReplayTutorial;

  Future<void> _endDay(BuildContext context, WidgetRef ref) async {
    final r = await ref.read(gameProvider.notifier).endDay();
    // เกมจบ (แพ้หรือชนะ): หน้าหลักสลับไปหน้าจบเกมเอง ไม่ต้องเปิดรายงาน
    if (!context.mounted || r.gameOver || r.won) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            r.event != null ? const EventScreen() : const ReportScreen(),
      ),
    );
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final ctl = ref.read(gameProvider.notifier);
    final isStory = ctl.isStory;
    final choice = await showDialog<String>(
      context: context,
      barrierColor: DsColors.scrim,
      builder: (c) => _PauseMenu(isStory: isStory),
    );
    if (!context.mounted) return;
    if (choice == 'save') {
      await ctl.save();
      if (context.mounted) toast(context, 'บันทึกเกมแล้ว');
    } else if (choice == 'notebook') {
      // เนื้อเรื่อง: การ์ดที่เก็บแล้ว · โหมดเอาชีวิตรอด (จบเนื้อเรื่องแล้ว): ครบทุกใบ
      final p = ref.read(storyProvider);
      final have = isStory
          ? <String>{...?p?.cards}
          : ref.read(saveRepositoryProvider).survivalUnlocked
          ? {for (final c in kKnowledgeCards) c.id}
          : <String>{};
      await showUncleNotebook(context, have);
    } else if (choice == 'tutorial') {
      ctl.update((e) => e.tutorialRestart());
      onReplayTutorial?.call();
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
    final ws = e.pondStatus;
    final w = e.warnDays;
    final a = s.active;
    String? alert;
    if (a != null) {
      alert =
          '${kDisasters[a.type]!.name} วันที่ ${a.dayIndex + 1}/${a.duration}';
    } else if (w > 0) {
      alert = '${kDisasters[s.upcoming!.type]!.name}ในอีก $w วัน';
    }
    final r = context.rs;

    final stats = GlassPanel(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(child: MoneyChip(money: s.money)),
            Expanded(
              child: HudStat(
                key: const ValueKey('day-chip'),
                icon: const PixelIcon('cal', size: 32),
                label: 'วันที่',
                // เนื้อเรื่องไม่มีวันเป้าหมาย (จบเมื่อผ่านบท)
                value: session.slot == kStorySlot
                    ? '${s.day}'
                    : '${s.day}/${e.targetDays}',
                tooltip:
                    'วันที่ ${s.day} จาก ${e.targetDays} '
                    '(โหมด${kDifficulties[s.mode]!.name} '
                    'ความยากขั้น ${e.stage + 1}/$kDifficultyStages)',
              ),
            ),
            Expanded(
              child: HudStat(
                key: const ValueKey('supply-chip'),
                icon: const PixelIcon('crate', size: 32),
                label: 'อาหารพอกิน',
                value: '${fmtNum(e.supplyDays)} วัน',
                tooltip: 'อาหารในคลังพอกินอีกกี่วัน',
              ),
            ),
            Expanded(
              child: HudStat(
                key: const ValueKey('water-chip'),
                icon: const PixelIcon('drop', size: 32),
                label: 'คุณภาพน้ำ',
                value: waterWord(ws),
                dot: Color(ws.color),
                tooltip: 'คุณภาพน้ำ ${s.water}% · ออกซิเจน ${s.o2.round()}%',
              ),
            ),
          ],
        ),
      ),
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onHelp != null) ...[
          RoundAction(
            key: const ValueKey('tip-help'),
            icon: const OutlinedText('?', size: 24),
            label: 'คำแนะนำหน้านี้',
            showLabel: false,
            diameter: 48,
            onPressed: onHelp,
          ),
          const SizedBox(width: Gap.s),
        ],
        RoundAction(
          key: const ValueKey('open-menu'),
          icon: const PixelIcon('gear', size: 30),
          label: 'เมนู / พัก',
          showLabel: false,
          diameter: 48,
          onPressed: () => _menu(context, ref),
        ),
        const SizedBox(width: Gap.s),
        StoryGate(
          target: StoryTarget.endDay,
          child: Spotlight(
            on: endDayTip,
            child: _EndDayButton(onPressed: () => _endDay(context, ref)),
          ),
        ),
      ],
    );

    final alerts = [
      if (alert != null) _AlertChip(text: alert),
      if (!s.power) const _AlertChip(text: 'ไฟดับ', icon: false),
    ];
    final top = MediaQuery.paddingOf(context).top;

    // จอกว้าง/แนวนอน: HUD กับปุ่มมุมจออยู่แถวเดียว ป้ายภัยแถวถัดไป
    if (r.useSideNav) {
      return Padding(
        padding: EdgeInsets.fromLTRB(Gap.s, Gap.s + top, Gap.s, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // HUD ใช้ที่ว่างทั้งหมดที่เหลือจากปุ่มมุมจอ (กว้างสุด 620 ชิดซ้าย)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: stats,
                    ),
                  ),
                ),
                const SizedBox(width: Gap.s),
                buttons,
              ],
            ),
            if (alerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Gap.xs),
                child: Wrap(spacing: Gap.s, children: alerts),
              ),
          ],
        ),
      );
    }
    // มือถือแนวตั้ง: แถว HUD + แถวป้ายภัย (ซ้าย) กับปุ่มมุมจอ (ขวา)
    return Padding(
      padding: EdgeInsets.fromLTRB(Gap.s, Gap.s + top, Gap.s, 0),
      child: Column(
        children: [
          stats,
          const SizedBox(height: Gap.xs),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: Gap.xs,
                    runSpacing: Gap.xs,
                    children: alerts,
                  ),
                ),
              ),
              const SizedBox(width: Gap.xs),
              buttons,
            ],
          ),
        ],
      ),
    );
  }
}

/// ปุ่ม "จบวัน": ปุ่มกลมรูปพระจันทร์ + ป้ายชื่อด้านซ้าย (ปุ่มมุมจอที่สำคัญที่สุด)
class _EndDayButton extends StatelessWidget {
  const _EndDayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: const ValueKey('end-day'),
      label: 'จบวัน',
      onTap: onPressed,
      child: Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
        decoration: BoxDecoration(
          color: DsColors.primaryDark,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: DsColors.ink, width: 3),
          boxShadow: const [
            BoxShadow(color: DsColors.ink, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('จบวัน', style: glassText(size: 17)),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF1C2B4A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: PixelGlyph(Glyph.moon, size: 24, color: AquaColors.gold),
              ),
            ),
          ],
        ),
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
          builder: (_, v) => HudStat(
            icon: const PixelIcon('coin', size: 32),
            label: 'เงิน',
            value: '$v฿',
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

class _AlertChip extends StatelessWidget {
  const _AlertChip({required this.text, this.icon = true});
  final String text;
  final bool icon;

  @override
  Widget build(BuildContext context) {
    return Blink(
      low: .75,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        decoration: BoxDecoration(
          color: DsColors.danger,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DsColors.ink, width: 2.5),
        ),
        // ย่อทั้งไอคอนและข้อความเมื่อแถบแคบ — ไม่ล้นขอบ
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon) ...[
                const PixelIcon('warn', size: 28),
                const SizedBox(width: 6),
              ],
              Text(text, maxLines: 1, style: glassText(size: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

/// เมนูพัก: การ์ดกลางจอ ปุ่มใหญ่ "เล่นต่อ" 1 ปุ่ม + ปุ่มรอง (บันทึก/เสียง/บทเรียน/ออก)
/// จอกว้างพอ: ปุ่มรองเรียง 2 คอลัมน์ ให้การ์ดเตี้ย (มือถือแนวนอนไม่ต้องเลื่อน)
class _PauseMenu extends StatelessWidget {
  const _PauseMenu({required this.isStory});
  final bool isStory;

  @override
  Widget build(BuildContext context) {
    final short = Responsive.of(context).isLandscapePhone;
    final items = <Widget>[
      PixelButton(
        label: 'บันทึกเกม',
        icon: const PixelIcon('scroll', size: 26),
        style: PixelButtonStyle.water,
        expand: true,
        onPressed: () => Navigator.pop(context, 'save'),
      ),
      // เปิด/ปิดเสียง (กดแล้วสลับทันที ไม่ปิดเมนู เหมือนต้นแบบ)
      Consumer(
        builder: (context, ref, _) {
          final on = ref.watch(soundProvider);
          return PixelButton(
            key: const ValueKey('sound-toggle'),
            label: on ? 'เสียง: เปิด' : 'เสียง: ปิด',
            icon: PixelGlyph(
              on ? Glyph.wave : Glyph.cross,
              size: 20,
              color: AquaColors.paper,
            ),
            style: on ? PixelButtonStyle.green : PixelButtonStyle.wood,
            expand: true,
            onPressed: () => ref.read(soundProvider.notifier).toggle(),
          );
        },
      ),
      PixelButton(
        key: const ValueKey('menu-notebook'),
        label: 'สมุดบันทึกลุงทอง',
        icon: const PixelIcon('scroll', size: 26),
        style: PixelButtonStyle.water,
        expand: true,
        onPressed: () => Navigator.pop(context, 'notebook'),
      ),
      if (!isStory)
        PixelButton(
          label: 'เล่นบทเรียนซ้ำ',
          icon: const PixelIcon('scroll', size: 26),
          style: PixelButtonStyle.water,
          expand: true,
          onPressed: () => Navigator.pop(context, 'tutorial'),
        ),
      PixelButton(
        label: 'กลับเมนูหลัก',
        icon: const PixelIcon('house', size: 26),
        style: PixelButtonStyle.wood,
        expand: true,
        onPressed: () => Navigator.pop(context, 'exit'),
      ),
    ];
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(Gap.m),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxPanel),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: DsColors.background,
            borderRadius: BorderRadius.circular(DsRadius.sheet),
            border: Border.all(color: DsColors.ink, width: 3),
            boxShadow: const [
              BoxShadow(color: DsColors.ink, offset: Offset(0, 4)),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.m),
            child: LayoutBuilder(
              builder: (context, box) {
                final twoCols = box.maxWidth >= 420;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const PixelIcon('gear', size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'เมนู / พัก',
                            style: DsText.title.copyWith(fontSize: 24),
                          ),
                        ),
                        // เวอร์ชันที่เปิดอยู่ (commit + เวลา build) เช็กได้ว่าเว็บอัปเดตแล้วหรือยัง
                        Text(
                          buildLabel,
                          key: const ValueKey('build-version'),
                          textAlign: TextAlign.right,
                          style: DsText.caption.copyWith(
                            color: DsColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    // มือถือแนวนอน (จอเตี้ย): ซ่อนคำอธิบาย ให้ทุกปุ่มอยู่บนจอโดยไม่ต้องเลื่อน
                    if (!short) ...[
                      const SizedBox(height: 2),
                      Text(
                        'เกมหยุดไว้ก่อน กด "เล่นต่อ" เพื่อกลับไปที่ฟาร์ม',
                        style: DsText.body.copyWith(color: DsColors.textMuted),
                      ),
                    ],
                    const SizedBox(height: Gap.m),
                    PixelButton(
                      key: const ValueKey('menu-resume'),
                      label: 'เล่นต่อ',
                      icon: const PixelGlyph(
                        Glyph.arrowRight,
                        size: 22,
                        color: DsColors.onAccent,
                      ),
                      size: PixelButtonSize.large,
                      expand: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: Gap.m),
                    if (twoCols)
                      for (var i = 0; i < items.length; i += 2) ...[
                        if (i > 0) const SizedBox(height: Gap.s),
                        Row(
                          children: [
                            Expanded(child: items[i]),
                            const SizedBox(width: Gap.s),
                            Expanded(
                              child: i + 1 < items.length
                                  ? items[i + 1]
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ]
                    else
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: Gap.s),
                        items[i],
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
