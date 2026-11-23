import 'dart:typed_data';

import 'package:aqua_farm/save/save_repository.dart';
import 'package:aqua_farm/ui/providers.dart';
import 'package:aqua_farm/ui/sound.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fake implements Beeper {
  final beeps = <double>[];
  @override
  void beep(double freq) => beeps.add(freq);
  @override
  void dispose() {}
}

void main() {
  test('คลื่นสี่เหลี่ยม 80ms ความดัง .04 เป็นไฟล์ WAV ถูกต้อง', () {
    final w = squareWaveWav(620);
    final b = ByteData.sublistView(w);
    expect(String.fromCharCodes(w.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(w.sublist(8, 12)), 'WAVE');
    expect(String.fromCharCodes(w.sublist(36, 40)), 'data');
    const n = 22050 * 80 ~/ 1000;
    expect(b.getUint32(40, Endian.little), n * 2);
    expect(w.length, 44 + n * 2);
    final amp = (.04 * 32767).round();
    final samples = [
      for (var i = 0; i < n; i++) b.getInt16(44 + i * 2, Endian.little),
    ];
    expect(samples.toSet(), {amp, -amp});
    // นับรอบคลื่น ≈ 620Hz x 0.08s
    var rises = 0;
    for (var i = 1; i < n; i++) {
      if (samples[i - 1] < 0 && samples[i] > 0) rises++;
    }
    expect(rises, inInclusiveRange(48, 50));
  });

  test('เปิด/ปิดเสียง: ค่าเริ่มต้นเปิด จำค่าไว้ และไม่บี๊บตอนปิด', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = SaveRepository(await SharedPreferences.getInstance());
    final fake = _Fake();
    ProviderContainer make() => ProviderContainer(
      overrides: [
        saveRepositoryProvider.overrideWithValue(repo),
        beeperProvider.overrideWithValue(fake),
      ],
    );
    final c = make();
    expect(c.read(soundProvider), isTrue);
    beepFor(c, bad: false);
    beepFor(c, bad: true);
    expect(fake.beeps, [kBeepOk, kBeepBad]);

    c.read(soundProvider.notifier).toggle();
    beepFor(c, bad: true);
    expect(fake.beeps, [kBeepOk, kBeepBad]);
    c.dispose();

    // เปิดแอปใหม่: ยังปิดอยู่
    final c2 = make();
    expect(c2.read(soundProvider), isFalse);
    expect(repo.soundOn, isFalse);
    c2.dispose();
  });
}
