import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton sound service.
/// Place real .mp3 files in assets/sounds/ to enable in-game audio.
/// All methods are no-ops if files are missing or muted.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  bool muted = false;

  Future<void> _play(String asset) async {
    if (muted) return;
    try {
      final player = AudioPlayer();
      await player.play(AssetSource(asset));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (e) {
      debugPrint('SoundService: $e');
    }
  }

  Future<void> correct()      => _play('sounds/correct.mp3');
  Future<void> wrong()        => _play('sounds/wrong.mp3');
  Future<void> click()        => _play('sounds/click.mp3');
  Future<void> matchFound()   => _play('sounds/match_found.mp3');
  Future<void> victory()      => _play('sounds/victory.mp3');
  Future<void> defeat()       => _play('sounds/defeat.mp3');
  Future<void> timerWarning() => _play('sounds/timer_warning.mp3');
  Future<void> countdown()    => _play('sounds/countdown.mp3');
}
