/// Riverpod: ครอบ GameEngine และ SaveRepository
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/difficulty.dart';
import '../game/game_engine.dart';
import '../game/game_state.dart';
import '../game/story.dart';
import '../game/tutorial.dart';
import '../save/save_repository.dart';

/// ต้อง override ใน ProviderScope ด้วย SaveRepository ที่เปิดแล้ว
final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => throw UnimplementedError(
    'override saveRepositoryProvider ใน ProviderScope',
  ),
);

/// เปิด/ปิดแอนิเมชันฉากพิกเซล (ปิดในเทสต์)
final sceneAnimationProvider = Provider<bool>((ref) => true);

/// เกมที่กำลังเล่น — engine แก้สถานะภายใน จึงเพิ่ม revision ทุกครั้งเพื่อให้ UI วาดใหม่
class GameSession {
  const GameSession(this.engine, this.slot, this.revision);
  final GameEngine engine;
  final int slot;
  final int revision;
  GameState get state => engine.state;
}

class GameController extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  SaveRepository get _repo => ref.read(saveRepositoryProvider);

  GameEngine get engine => state!.engine;

  void _bump() {
    final s = state;
    if (s != null) state = GameSession(s.engine, s.slot, s.revision + 1);
  }

  /// สร้างเกมใหม่ในช่องที่เลือก แล้วบันทึกทันที (newSlot)
  Future<void> newGame(
    int slot,
    String name, {
    Difficulty mode = Difficulty.normal,
  }) async {
    final e = GameEngine.newGame(name, mode: mode);
    // บทเรียน 9 ขั้นเดิมปิดในโหมดเอาชีวิตรอด (สอนในโหมดเนื้อเรื่องแทน)
    e.state.tut = kTutorialSteps;
    await _repo.save(slot, e.state);
    state = GameSession(e, slot, 0);
    ref.invalidate(slotsProvider);
  }

  /// เนื้อเรื่อง: StoryController ตัดสินบทหลังจบวัน และจัดการตอนออกเมนู
  Future<void> Function(DayReport r)? _storyDay;
  Future<void> Function()? _storyExit;

  /// ใช้ engine ที่สร้างไว้แล้วในช่องเนื้อเรื่อง [kStorySlot]
  void attachStory(
    GameEngine e, {
    required Future<void> Function(DayReport r) afterDay,
    required Future<void> Function() onExit,
  }) {
    _storyDay = afterDay;
    _storyExit = onExit;
    state = GameSession(e, kStorySlot, 0);
  }

  /// เล่นเนื้อเรื่องอยู่ไหม
  bool get isStory => state?.slot == kStorySlot;

  /// โหลดเกม — โยน SaveException ถ้าโหลดไม่ได้
  void load(int slot) {
    final s = _repo.load(slot);
    final e = GameEngine(s)..calcWater();
    state = GameSession(e, slot, 0);
  }

  /// โหลดช่องที่เซฟล่าสุด (Continue) คืน false ถ้ายังไม่มีเซฟ
  bool continueLatest() {
    final slot = _repo.latestSlot();
    if (slot == null) return false;
    load(slot);
    return true;
  }

  /// ทำการกระทำกับ engine แล้วแจ้ง UI
  ActionResult run(ActionResult Function(GameEngine e) action) {
    final r = action(engine);
    _bump();
    return r;
  }

  /// เปลี่ยนสถานะที่ไม่มีข้อความแจ้ง (เช่น บทเรียน) แล้วแจ้ง UI
  void update(void Function(GameEngine e) change) {
    if (state == null) return;
    change(engine);
    _bump();
  }

  /// จบวัน แล้วบันทึกอัตโนมัติ (ยกเว้นเกมจบ: Game Over หรือชนะ)
  Future<DayReport> endDay() async {
    final r = engine.endDay();
    if (isStory) {
      // เนื้อเรื่อง: ตัดสินผ่าน/แพ้บทและเซฟแยก (ไม่ Game Over ไม่ชนะด้วยจำนวนวัน)
      await _storyDay?.call(r);
    } else if (!r.gameOver && !r.won) {
      await _repo.save(state!.slot, engine.state);
    }
    _bump();
    ref.invalidate(slotsProvider);
    return r;
  }

  Future<bool> save() async {
    final s = state;
    if (s == null) return false;
    if (isStory) {
      _bump(); // StoryController เซฟเมื่อเกมเปลี่ยน
      return true;
    }
    final ok = await _repo.save(s.slot, s.state);
    ref.invalidate(slotsProvider);
    return ok;
  }

  /// กลับเมนูหลัก (บันทึกให้อัตโนมัติ)
  Future<void> exitToMenu() async {
    if (isStory) return _storyExit?.call();
    await save();
    state = null;
  }

  /// ออกจากเกมโดยไม่บันทึก (ใช้หลัง Game Over / ชนะ)
  void close() => state = null;
}

final gameProvider = NotifierProvider<GameController, GameSession?>(
  GameController.new,
);

/// รายการช่องเซฟ 1-3
class SlotsController extends Notifier<Map<int, SlotInfo?>> {
  @override
  Map<int, SlotInfo?> build() => ref.read(saveRepositoryProvider).listSlots();

  Future<void> rename(int slot, String name) async {
    await ref.read(saveRepositoryProvider).rename(slot, name);
    ref.invalidateSelf();
  }

  Future<void> delete(int slot) async {
    await ref.read(saveRepositoryProvider).delete(slot);
    ref.invalidateSelf();
  }
}

final slotsProvider = NotifierProvider<SlotsController, Map<int, SlotInfo?>>(
  SlotsController.new,
);

/// คำแนะนำครั้งแรกของแต่ละหน้า: ชุดหน้าที่เห็นแล้ว (บันทึกในเครื่อง)
class TipsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(saveRepositoryProvider).tipsSeen;

  /// กด "เข้าใจแล้ว" → ไม่แสดงอีก
  Future<void> dismiss(String id) async {
    state = {...state, id};
    await ref.read(saveRepositoryProvider).setTipsSeen(state);
  }

  /// ปุ่ม "?" → แสดงคำแนะนำของหน้านี้อีกครั้ง
  void replay(String id) => state = {...state}..remove(id);
}

final tipsProvider = NotifierProvider<TipsController, Set<String>>(
  TipsController.new,
);
