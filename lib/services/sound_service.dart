import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton sound service.
/// WAV files are in assets/sounds/ — all generated tones.
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

  Future<void> correct()      => _play('sounds/correct.wav');
  Future<void> wrong()        => _play('sounds/wrong.wav');
  Future<void> click()        => _play('sounds/click.wav');
  Future<void> matchFound()   => _play('sounds/match_found.wav');
  Future<void> victory()      => _play('sounds/victory.wav');
  Future<void> defeat()       => _play('sounds/defeat.wav');
  Future<void> timerWarning() => _play('sounds/timer_warning.wav');
  Future<void> countdown()    => _play('sounds/countdown.wav');
}
