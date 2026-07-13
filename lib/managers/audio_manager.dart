import 'package:flame_audio/flame_audio.dart';

import '../utils/assets.dart';

class AudioManager {
  bool _isBgmMuted = false;
  bool _isSfxMuted = false;

  double bgmVolume = 0.2;
  double sfxVolume = 0.5;

  Future<void> init() async {
    await FlameAudio.audioCache.loadAll(<String>[
      GameAudio.intro,
    ]);
  }

  Future<AudioPlayer?> playBgm(String fileName, {bool loop = true}) async {
    if (_isBgmMuted) return null;

    if (loop) {
      await FlameAudio.bgm.play(fileName, volume: bgmVolume);
      return null;
    } else {
      return await FlameAudio.play(fileName, volume: bgmVolume);
    }
  }

  void stopBgm() {
    if (FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.stop();
    }
  }

  Future<void> playSfx(String fileName) async {
    if (_isSfxMuted) return;
    await FlameAudio.play(fileName, volume: sfxVolume);
  }

  void toggleBgm() {
    _isBgmMuted = !_isBgmMuted;
    if (_isBgmMuted) {
      stopBgm();
    }
  }

  void toggleSfx() {
    _isSfxMuted = !_isSfxMuted;
  }
}
