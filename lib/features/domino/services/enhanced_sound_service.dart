import 'package:audioplayers/audioplayers.dart';

/// Enhanced sound manager for professional audio effects
class EnhancedDominoSoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool soundEnabled = true;

  // Sound file paths
  static const String soundTilePlaced = 'assets/sounds/tile_placed.mp3';
  static const String soundTileHover = 'assets/sounds/tile_hover.mp3';
  static const String soundGameStart = 'assets/sounds/game_start.mp3';
  static const String soundGameWin = 'assets/sounds/game_win.mp3';
  static const String soundGameLose = 'assets/sounds/game_lose.mp3';
  static const String soundInvalidMove = 'assets/sounds/invalid_move.mp3';
  static const String soundTick = 'assets/sounds/tick.mp3';
  static const String soundScorePoints = 'assets/sounds/score_points.mp3';
  static const String soundBoardComplete = 'assets/sounds/board_complete.mp3';

  /// Play tile placement sound with volume control
  static Future<void> playTilePlaced({double volume = 0.8}) async {
    if (!soundEnabled) return;
    try {
      await _audioPlayer.play(
        AssetSource('sounds/tile_placed.mp3'),
        volume: volume,
      );
    } catch (e) {
      print('Error playing tile placed sound: $e');
    }
  }

  /// Play tile hover sound (quieter)
  static Future<void> playTileHover({double volume = 0.4}) async {
    if (!soundEnabled) return;
    try {
      // Shorter beep for hover effect
      await _playTone(frequency: 1000, duration: 50, volume: volume);
    } catch (e) {
      print('Error playing tile hover: $e');
    }
  }

  /// Play game start sound
  static Future<void> playGameStart({double volume = 1.0}) async {
    if (!soundEnabled) return;
    try {
      await _audioPlayer.play(
        AssetSource('sounds/game_start.mp3'),
        volume: volume,
      );
    } catch (e) {
      print('Error playing game start: $e');
    }
  }

  /// Play win celebration sound
  static Future<void> playGameWin({double volume = 1.0}) async {
    if (!soundEnabled) return;
    try {
      await _audioPlayer.play(
        AssetSource('sounds/game_win.mp3'),
        volume: volume,
      );
    } catch (e) {
      print('Error playing win sound: $e');
    }
  }

  /// Play lose sound
  static Future<void> playGameLose({double volume = 0.9}) async {
    if (!soundEnabled) return;
    try {
      await _audioPlayer.play(
        AssetSource('sounds/game_lose.mp3'),
        volume: volume,
      );
    } catch (e) {
      print('Error playing lose sound: $e');
    }
  }

  /// Play invalid move sound (error beep)
  static Future<void> playInvalidMove({double volume = 0.7}) async {
    if (!soundEnabled) return;
    try {
      // Double beep pattern for error
      await _playTone(frequency: 800, duration: 100, volume: volume);
      await Future.delayed(const Duration(milliseconds: 150));
      await _playTone(frequency: 600, duration: 100, volume: volume);
    } catch (e) {
      print('Error playing invalid move: $e');
    }
  }

  /// Play score points sound
  static Future<void> playScorePoints(int points, {double volume = 0.8}) async {
    if (!soundEnabled) return;
    try {
      // Variable pitch based on points
      final frequency = 1000 + (points * 10).toDouble();
      await _playTone(frequency: frequency, duration: 200, volume: volume);
    } catch (e) {
      print('Error playing score points: $e');
    }
  }

  /// Play board complete celebration sound
  static Future<void> playBoardComplete({double volume = 0.9}) async {
    if (!soundEnabled) return;
    try {
      // Ascending tone pattern
      for (int i = 0; i < 3; i++) {
        await _playTone(
            frequency: 1000 + (i * 200), duration: 150, volume: volume);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print('Error playing board complete: $e');
    }
  }

  /// Play tick/clock sound for timer
  static Future<void> playTick({double volume = 0.5}) async {
    if (!soundEnabled) return;
    try {
      await _playTone(frequency: 1200, duration: 80, volume: volume);
    } catch (e) {
      print('Error playing tick: $e');
    }
  }

  /// Generate and play a tone programmatically
  static Future<void> _playTone({
    required double frequency,
    required int duration,
    required double volume,
  }) async {
    // This is a fallback - actual tone generation would require a different approach
    // You can integrate a tone generation package like
    // flutter_sound or just use pre-recorded audio files
  }

  /// Stop all audio
  static Future<void> stopAll() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  /// Toggle sound on/off
  static void toggleSound(bool enabled) {
    soundEnabled = enabled;
  }

  /// Set global volume
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Release resources
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
    } catch (e) {
      print('Error disposing audio: $e');
    }
  }
}

/// Background music manager for game
class EnhancedGameMusicService {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static bool musicEnabled = true;
  static double currentVolume = 0.5;

  static const String backgroundMusic = 'assets/music/domino_background.mp3';

  /// Start background music loop
  static Future<void> startBackgroundMusic({double volume = 0.3}) async {
    if (!musicEnabled) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource(backgroundMusic),
        volume: volume,
      );
      currentVolume = volume;
    } catch (e) {
      print('Error starting background music: $e');
    }
  }

  /// Stop background music
  static Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  /// Fade out background music
  static Future<void> fadeOutMusic(
      {Duration duration = const Duration(seconds: 2)}) async {
    try {
      double step = currentVolume / (duration.inMilliseconds / 50);
      while (currentVolume > 0) {
        currentVolume = (currentVolume - step).clamp(0, 1);
        await _musicPlayer.setVolume(currentVolume);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _musicPlayer.stop();
    } catch (e) {
      print('Error fading out music: $e');
    }
  }

  /// Set music volume
  static Future<void> setMusicVolume(double volume) async {
    try {
      currentVolume = volume.clamp(0, 1);
      await _musicPlayer.setVolume(currentVolume);
    } catch (e) {
      print('Error setting music volume: $e');
    }
  }

  /// Toggle music on/off
  static void toggleMusic(bool enabled) {
    musicEnabled = enabled;
    if (!enabled) {
      stopBackgroundMusic();
    }
  }

  /// Release resources
  static Future<void> dispose() async {
    try {
      await _musicPlayer.dispose();
    } catch (e) {
      print('Error disposing music: $e');
    }
  }
}
