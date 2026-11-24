import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../game/story.dart';
import 'layout/responsive.dart';
import 'providers.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_shell.dart';
import 'screens/main_menu_screen.dart';
import 'screens/story_summary_screen.dart';
import 'screens/win_screen.dart';
import 'story_provider.dart';
import 'theme/theme.dart';

class AquaFarmApp extends ConsumerWidget {
  const AquaFarmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loops = ref.watch(sceneAnimationProvider);
    return MaterialApp(
      title: 'AQUA FARM',
      debugShowCheckedModeBanner: false,
      theme: buildAquaTheme(),
      home: const _Root(),
      // ระบบเลย์เอาต์กลาง: จำกัดความกว้าง ~1100 จัดกลาง แล้วขยายทั้งแอปตามประเภทจอ
      builder: (context, child) => MotionSettings(
        loops: loops,
        child: AppFrame(
          background: const ColoredBox(
            color: AquaColors.bgGreenDeep,
            child: GrassBackground(child: SizedBox.expand()),
          ),
          child: ScaledApp(child: ToastHost(child: child!)),
        ),
      ),
    );
  }
}

/// สลับหน้าตามสถานะ: ไม่มีเกม → เมนูหลัก / เกมจบ → Game Over / ชนะ → หน้าชนะ / อื่น ๆ → หน้าเกม
class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameProvider);
    if (session == null) return const MainMenuScreen();
    // เนื้อเรื่องบทที่ 7: หน้าสรุป
    final story = ref.watch(storyProvider);
    if (session.slot == kStorySlot && (story?.finished ?? false)) {
      return const StorySummaryScreen();
    }
    if (session.state.over) return const GameOverScreen();
    if (session.state.won) return const WinScreen();
    return const GameShell();
  }
}
