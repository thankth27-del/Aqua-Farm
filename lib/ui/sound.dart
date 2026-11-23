/// เสียงบี๊บตอนข้อความแจ้งผลเด้งขึ้น — beep() ของต้นแบบ:
/// คลื่นสี่เหลี่ยม ความดัง .04 ยาว 80ms, สำเร็จ 620Hz / ไม่สำเร็จ 180Hz
/// เปิด/ปิดได้ในเมนู จำค่าไว้ในเครื่อง (localStorage 'aq_snd' ของต้นแบบ)
library;

import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

const double kBeepOk = 620;
const double kBeepBad = 180;

/// สร้างไฟล์ WAV (PCM 16 บิต โมโน) ของคลื่นสี่เหลี่ยม
Uint8List squareWaveWav(
  double freq, {
  int ms = 80,
  double gain = .04,
  int rate = 22050,
}) {
  final n = rate * ms ~/ 1000;
  final data = n * 2;
  final b = ByteData(44 + data);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      b.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  b.setUint32(4, 36 + data, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  b.setUint32(16, 16, Endian.little); // ขนาดส่วน fmt
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, 1, Endian.little); // โมโน
  b.setUint32(24, rate, Endian.little);
  b.setUint32(28, rate * 2, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  str(36, 'data');
  b.setUint32(40, data, Endian.little);
  final amp = (gain * 32767).round();
  for (var i = 0; i < n; i++) {
    final high = (i * freq / rate) % 1 < .5;
    b.setInt16(44 + i * 2, high ? amp : -amp, Endian.little);
  }
  return b.buffer.asUint8List();
}

/// ตัวเล่นเสียง (เปลี่ยนเป็นตัวปลอมได้ในเทสต์)
abstract class Beeper {
  void beep(double freq);
  void dispose() {}
}

/// เล่นเสียงจริงผ่าน audioplayers — เล่นไม่ได้ก็เงียบไป (เหมือน try/catch ของต้นแบบ)
class AudioBeeper implements Beeper {
  final _cache = <double, Uint8List>{};
  AudioPlayer? _player;

  @override
  void beep(double freq) {
    try {
      final p = _player ??= AudioPlayer();
      final bytes = _cache.putIfAbsent(freq, () => squareWaveWav(freq));
      p
          .stop()
          .then((_) => p.play(BytesSource(bytes, mimeType: 'audio/wav')))
          .catchError((Object _) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _player?.dispose().catchError((Object _) {});
    _player = null;
  }
}

final beeperProvider = Provider<Beeper>((ref) {
  final b = AudioBeeper();
  ref.onDispose(b.dispose);
  return b;
});

/// เปิด/ปิดเสียง (ค่าเริ่มต้น: เปิด)
class SoundController extends Notifier<bool> {
  @override
  bool build() => ref.read(saveRepositoryProvider).soundOn;

  void toggle() {
    state = !state;
    ref.read(saveRepositoryProvider).setSoundOn(state);
  }
}

final soundProvider = NotifierProvider<SoundController, bool>(
  SoundController.new,
);

/// บี๊บตามผลลัพธ์ (ถ้าเปิดเสียงอยู่)
void beepFor(ProviderContainer c, {required bool bad}) {
  if (!c.read(soundProvider)) return;
  c.read(beeperProvider).beep(bad ? kBeepBad : kBeepOk);
}
