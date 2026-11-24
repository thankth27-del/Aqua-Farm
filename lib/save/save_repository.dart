/// เซฟเกม 3 ช่อง (ตรงกับต้นแบบ: เก็บทุกช่องเป็น JSON ก้อนเดียวในคีย์ aquafarm_slots_v3)
/// รูปแบบ: { "1": {v, name, ts, S}, "2": ..., "3": ... }
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/constants.dart';
import '../data/difficulty.dart';
import '../game/game_state.dart';
import '../game/story.dart';

/// ข้อมูลย่อของช่องเซฟ (ใช้แสดงในหน้าเลือกช่อง)
class SlotInfo {
  const SlotInfo({
    required this.slot,
    required this.name,
    required this.version,
    required this.timestamp,
    required this.day,
    required this.money,
    required this.pondCount,
    this.mode = Difficulty.normal,
  });

  final int slot;
  final String name;
  final int version;
  final int timestamp;
  final int day;
  final int money;
  final int pondCount;

  /// โหมดความยาก (เซฟเก่าที่ไม่มีโหมด = ปานกลาง)
  final Difficulty mode;
}

class SaveException implements Exception {
  const SaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SaveRepository {
  SaveRepository(this._prefs, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final SharedPreferences _prefs;
  final int Function() _clock;

  static Future<SaveRepository> open() async =>
      SaveRepository(await SharedPreferences.getInstance());

  /// เปิดเสียงอยู่ไหม (ต่อเครื่อง ไม่ผูกกับช่องเซฟ — คีย์ aq_snd เหมือนต้นแบบ)
  bool get soundOn => _prefs.getString(kSoundKey) != '0';

  Future<void> setSoundOn(bool on) =>
      _prefs.setString(kSoundKey, on ? '1' : '0');

  /// เล่นเนื้อเรื่องจบแล้ว = ปลดล็อกโหมดเอาชีวิตรอด
  /// (เครื่องที่มีเซฟโหมดเอาชีวิตรอดอยู่แล้วก่อนมีเนื้อเรื่อง ถือว่าปลดล็อก จะได้ไม่เสียเซฟเดิม)
  bool get survivalUnlocked =>
      _prefs.getString(kSurvivalUnlockKey) == '1' ||
      listSlots().values.any((s) => s != null);

  Future<void> setSurvivalUnlocked(bool on) =>
      _prefs.setString(kSurvivalUnlockKey, on ? '1' : '0');

  /// หน้าที่ผู้เล่นกด "เข้าใจแล้ว" ที่คำแนะนำครั้งแรกไปแล้ว (ต่อเครื่อง)
  Set<String> get tipsSeen => {
    for (final s in (_prefs.getString(kTipsKey) ?? '').split(','))
      if (s.isNotEmpty) s,
  };

  Future<void> setTipsSeen(Set<String> ids) =>
      _prefs.setString(kTipsKey, ids.join(','));

  /// มีเนื้อเรื่องที่เล่นค้างไว้ไหม
  bool get hasStory => _prefs.getString(kStoryKey) != null;

  /// บันทึกเนื้อเรื่อง (ความคืบหน้าบท + สถานะเกม)
  Future<void> saveStory(StoryProgress p, GameState state) async {
    final ok = await _prefs.setString(
      kStoryKey,
      jsonEncode({'v': kSaveVersion, 'p': p.toJson(), 'S': state.toJson()}),
    );
    if (!ok) throw const SaveException('บันทึกไม่ได้');
  }

  /// โหลดเนื้อเรื่อง — null ถ้ายังไม่มีหรือเซฟเสีย
  (StoryProgress, GameState)? loadStory() {
    final raw = _prefs.getString(kStoryKey);
    if (raw == null) return null;
    try {
      final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if ((m['v'] as num).toInt() != kSaveVersion) return null;
      return (
        StoryProgress.fromJson(Map<String, dynamic>.from(m['p'] as Map)),
        GameState.fromJson(Map<String, dynamic>.from(m['S'] as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteStory() => _prefs.remove(kStoryKey);

  Map<String, dynamic> _all() {
    final raw = _prefs.getString(kSaveKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _put(Map<String, dynamic> all) async {
    final ok = await _prefs.setString(kSaveKey, jsonEncode(all));
    if (!ok) throw const SaveException('บันทึกไม่ได้');
  }

  void _checkSlot(int slot) {
    if (!kSaveSlots.contains(slot)) throw SaveException('ไม่มีช่องเซฟ $slot');
  }

  /// รายการช่อง 1-3 (null = ว่าง)
  Map<int, SlotInfo?> listSlots() {
    final all = _all();
    return {
      for (final i in kSaveSlots)
        i: () {
          final d = all['$i'];
          if (d == null) return null;
          final m = Map<String, dynamic>.from(d as Map);
          final st = Map<String, dynamic>.from(m['S'] as Map);
          return SlotInfo(
            slot: i,
            name: m['name'] as String,
            version: (m['v'] as num).toInt(),
            timestamp: (m['ts'] as num).toInt(),
            day: (st['day'] as num).toInt(),
            money: (st['money'] as num).toInt(),
            pondCount: (st['pond'] as List).length,
            mode: difficultyFromName(st['mode'] as String?),
          );
        }(),
    };
  }

  /// บันทึกเกม — ไม่บันทึกถ้าเกมจบแล้ว (เหมือนต้นแบบ) คืน false ถ้าข้าม
  Future<bool> save(int slot, GameState state) async {
    _checkSlot(slot);
    // เกมที่จบแล้ว (แพ้หรือชนะ) ไม่บันทึกทับเซฟเดิม
    if (state.finished) return false;
    final all = _all();
    all['$slot'] = {
      'v': kSaveVersion,
      'name': state.slotName,
      'ts': _clock(),
      'S': state.toJson(),
    };
    await _put(all);
    return true;
  }

  /// โหลดเกม — รองรับเฉพาะเซฟ v4
  GameState load(int slot) {
    _checkSlot(slot);
    final d = _all()['$slot'];
    if (d == null) throw const SaveException('ช่องนี้ว่าง');
    final m = Map<String, dynamic>.from(d as Map);
    final v = (m['v'] as num).toInt();
    if (v != kSaveVersion) throw const SaveException('เวอร์ชันเซฟไม่รองรับ');
    final s = GameState.fromJson(Map<String, dynamic>.from(m['S'] as Map));
    s.slotName = m['name'] as String;
    return s;
  }

  /// ช่องที่เซฟล่าสุด (สำหรับปุ่ม Continue) — null ถ้ายังไม่มีเซฟ
  int? latestSlot() {
    int? best;
    var bestTs = -1;
    listSlots().forEach((i, info) {
      if (info != null && info.timestamp > bestTs) {
        best = i;
        bestTs = info.timestamp;
      }
    });
    return best;
  }

  Future<void> rename(int slot, String name) async {
    _checkSlot(slot);
    final all = _all();
    final d = all['$slot'];
    if (d == null) return;
    final m = Map<String, dynamic>.from(d as Map)..['name'] = name;
    all['$slot'] = m;
    await _put(all);
  }

  Future<void> delete(int slot) async {
    _checkSlot(slot);
    final all = _all()..remove('$slot');
    await _put(all);
  }
}
