import 'package:flame_audio/flame_audio.dart';

import '../utils/assets.dart';

class AudioManager {
  bool _isBgmMuted = false;
  bool _isSfxMuted = false;
  String? _lastBgmFile;
  double? _lastBgmVolume;

  double bgmVolume = 0.2;
  double sfxVolume = 0.5;

  Future<void> init() async {
    await FlameAudio.audioCache.loadAll(<String>[
      GameAudio.intro,
      GameAudio.background,
      GameAudio.pee,
    ]);
  }

  Future<AudioPlayer?> playBgm(String fileName, {bool loop = true, double? volume}) async {
    _lastBgmFile = fileName;
    _lastBgmVolume = volume;

    if (_isBgmMuted) return null;

    if (loop) {
      await FlameAudio.bgm.play(fileName, volume: volume ?? bgmVolume);
      return null;
    } else {
      return await FlameAudio.play(fileName, volume: volume ?? bgmVolume);
    }
  }

  void setMusicEnabled(bool enabled) {
    if (_isBgmMuted == !enabled) return;

    _isBgmMuted = !enabled;
    if (_isBgmMuted) {
      stopBgm();
    } else if (_lastBgmFile != null) {
      playBgm(_lastBgmFile!, volume: _lastBgmVolume);
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
