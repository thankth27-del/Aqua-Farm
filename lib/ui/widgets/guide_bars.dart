import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/hints.dart';
import '../../game/tutorial.dart';
import '../providers.dart';
import '../theme/theme.dart';
import 'game_hud.dart';

/// คำแนะนำครั้งแรกของแต่ละหน้า (1 บรรทัด ชี้ปุ่มสำคัญของหน้านั้น)
const Map<GameScreen, String> kPageTips = {
  GameScreen.farm: 'ดูภัยที่จะมา ซื้ออุปกรณ์กันภัย แล้วกด "จบวัน"',
  GameScreen.pond: 'ให้อาหารที่แถบล่างวันละครั้ง ปลาโตครบแล้วกด "จับปลา"',
  GameScreen.shop: 'แตะการ์ดปลาเพื่อดูรายละเอียดและซื้อ',
  GameScreen.market: 'สลับ "ซื้อ" กับ "ขาย" ที่ปุ่มด้านบน',
  GameScreen.kitchen: 'กด "ทำอาหาร" ที่สูตร อาหารจะเข้าคลัง',
  GameScreen.storage: 'หิวแล้วกด "กิน" อาหารใกล้เสียให้กินก่อน',
};

/// ใช้คำแนะนำ/แถบ "ตอนนี้ควรทำ" ได้ไหม (โหมดเอาชีวิตรอด ไม่อยู่ในบทเรียน)
bool guideOn(WidgetRef ref) {
  final session = ref.watch(gameProvider);
  if (session == null) return false;
  return !ref.read(gameProvider.notifier).isStory &&
      session.engine.tutorialStep == null;
}

/// คำแนะนำของหน้านี้กำลังแสดงอยู่ไหม (ยังไม่เคยกด "เข้าใจแล้ว")
bool tipActive(WidgetRef ref, GameScreen screen) =>
    guideOn(ref) && !ref.watch(tipsProvider).contains(screen.name);

/// กรอบกะพริบรอบปุ่มสำคัญ ขณะคำแนะนำของหน้านั้นแสดงอยู่
class TipSpot extends ConsumerWidget {
  const TipSpot({
    super.key,
    required this.screen,
    required this.child,
    this.enabled = true,
  });
  final GameScreen screen;
  final Widget child;

  /// false = ไม่ใช่ปุ่มที่คำแนะนำชี้ (ใช้ในรายการที่ชี้แค่อันแรก)
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Spotlight(on: enabled && tipActive(ref, screen), child: child);
}

/// คำแนะนำครั้งแรก: ตัวละครพูด 1 บรรทัด + ปุ่ม "เข้าใจแล้ว"
class TipBar extends ConsumerWidget {
  const TipBar({super.key, required this.screen});
  final GameScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = kPageTips[screen];
    if (text == null || !tipActive(ref, screen)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s, Gap.xs, Gap.s, 0),
      child: SpeechBubble(
        key: const ValueKey('tip-bar'),
        text: text,
        textKey: const ValueKey('tip-text'),
        action: PixelButton(
          key: const ValueKey('tip-ok'),
          label: 'เข้าใจแล้ว',
          style: PixelButtonStyle.green,
          onPressed: () => ref.read(tipsProvider.notifier).dismiss(screen.name),
        ),
      ),
    );
  }
}

/// "ตอนนี้ควรทำ": ตัวละครบอกสิ่งที่ต้องทำต่อ ตัวใหญ่ แตะแล้วพาไปหน้านั้น
class NextStepBar extends ConsumerWidget {
  const NextStepBar({super.key, required this.onGo});
  final ValueChanged<NextPlace> onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(gameProvider)!.engine;
    final step = nextStep(e);
    if (step == null) return const SizedBox.shrink();
    final urgent = step.place == NextPlace.farm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.s, Gap.xs, Gap.s, 0),
      child: SpeechBubble(
        key: const ValueKey('next-step'),
        text: step.text,
        textKey: const ValueKey('next-step-text'),
        urgent: urgent,
        semanticPrefix: 'ตอนนี้ควรทำ: ',
        onTap: step.place == NextPlace.endDay ? null : () => onGo(step.place),
      ),
    );
  }
}

/// ป้ายบนเมนู: จุดแดง (0) หรือตัวเลข (มีงานรอที่หน้านั้น)
class NavBadge extends StatelessWidget {
  const NavBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: PixelBox(
        fill: AquaColors.red,
        px: 2,
        padding: count > 0
            ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1)
            : const EdgeInsets.all(5),
        child: count > 0
            ? Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
