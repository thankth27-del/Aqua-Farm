import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'providers.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_shell.dart';
import 'screens/main_menu_screen.dart';
import 'screens/win_screen.dart';
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
      // เกมแนวตั้งเท่านั้น: บนจอกว้าง (เช่นเปิดเว็บบนคอม) จำกัดความกว้างเท่ามือถือแล้ววางกลางจอ
      builder: (context, child) => MotionSettings(
        loops: loops,
        child: ColoredBox(
          color: AquaColors.bgGreenDeep,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxPhoneWidth),
              child: ToastHost(child: child!),
            ),
          ),
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
    if (session.state.over) return const GameOverScreen();
    if (session.state.won) return const WinScreen();
    return const GameShell();
  }
}
