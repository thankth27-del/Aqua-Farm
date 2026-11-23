import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../save/save_repository.dart';
import '../dialogs.dart';
import '../providers.dart';
import '../theme.dart';

/// Game Over — สุขภาพหมด (เกมที่จบไม่ถูกบันทึก จึงโหลดเซฟล่าสุดได้)
class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(gameProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PixelPanel(
              color: AquaColors.panel,
              edge: AquaColors.primary,
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Game Over',
                    style: TextStyle(
                      color: AquaColors.bad,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Muted('สุขภาพหมดเพราะขาดอาหารเป็นเวลานาน', size: 15),
                  const Muted(
                    'บทเรียน: เตรียมเสบียงถนอมอาหารไว้ก่อนภัยพิบัติ',
                    size: 15,
                  ),
                  const SizedBox(height: 16),
                  PixelButton(
                    label: 'โหลดเซฟล่าสุด',
                    style: PixelButtonStyle.gold,
                    expand: true,
                    onPressed: () {
                      try {
                        if (!ctl.continueLatest()) {
                          toast(context, 'ยังไม่มีเซฟ', bad: true);
                        }
                      } on SaveException catch (e) {
                        toast(context, e.message, bad: true);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  PixelButton(
                    label: 'กลับเมนูหลัก',
                    style: PixelButtonStyle.dark,
                    expand: true,
                    onPressed: ctl.close,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
