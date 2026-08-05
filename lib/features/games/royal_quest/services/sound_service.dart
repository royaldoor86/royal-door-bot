import 'package:just_audio/just_audio.dart';

class SoundService {
  static AudioPlayer? _audioPlayer;
  static AudioPlayer? _timerPlayer;

  static AudioPlayer get _player {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  static AudioPlayer get _timer {
    _timerPlayer ??= AudioPlayer();
    return _timerPlayer!;
  }

  static Future<void> playWinSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/Win.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  static Future<void> playLossSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/game over.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing loss sound: $e');
    }
  }

  static Future<void> playCorrectAnswerSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/answer win.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  static Future<void> playWrongAnswerSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/rong quest.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing wrong sound: $e');
    }
  }

  static Future<void> playClickSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/click.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }

  static Future<void> playTimerSound() async {
    try {
      await _timer.stop();
      await _timer.setAsset('assets/sounds/timer.mp3');
      await _timer.play();
    } catch (e) {
      print('Error playing timer sound: $e');
    }
  }

  static Future<void> stopTimerSound() async {
    try {
      await _timer.stop();
    } catch (e) {
      print('Error stopping timer sound: $e');
    }
  }

  static Future<void> playNextLevelSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/next level.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing next level sound: $e');
    }
  }

  static Future<void> playEnterSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/enter.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing enter sound: $e');
    }
  }

  static Future<void> playCoinSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/coin.wav');
      await _player.play();
    } catch (e) {
      print('Error playing coin sound: $e');
    }
  }

  static Future<void> playMicSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/mic.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing mic sound: $e');
    }
  }

  static Future<void> playLifelineSound() async {
    try {
      await _player.stop();
      await _player.setAsset('assets/sounds/SafeHouseAudio.mp3');
      await _player.play();
    } catch (e) {
      print('Error playing lifeline sound: $e');
    }
  }

  static Future<void> stopAll() async {
    try {
      await _player.stop();
      await _timer.stop();
    } catch (e) {
      print('Error stopping all sounds: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      await _player.stop();
      await _timer.stop();
      await _player.dispose();
      await _timer.dispose();
      _audioPlayer = null;
      _timerPlayer = null;
    } catch (e) {
      print('Error disposing sound service: $e');
    }
  }
}
