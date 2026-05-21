import 'package:audioplayers/audioplayers.dart';
import '../constants/domino_sounds.dart';

class DominoSoundService {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> play(String assetPath) async {
    try {
      // Use a pool of players or a dedicated player per sound to avoid state conflicts
      if (!_players.containsKey(assetPath)) {
        _players[assetPath] = AudioPlayer();
      }
      final player = _players[assetPath]!;
      
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing sound ($assetPath): $e');
    }
  }

  static void dispose() {
    for (var player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }

  static Future<void> playPlaceTile() => play(DominoSounds.placeTile);
  static Future<void> playDrawTile() => play(DominoSounds.drawTile);
  static Future<void> playWin() => play(DominoSounds.win);
  static Future<void> playLose() => play(DominoSounds.lose);
  static Future<void> playTurn() => play(DominoSounds.turn);
  static Future<void> playError() => play(DominoSounds.error);
  static Future<void> playCoins() => play(DominoSounds.coins);
  static Future<void> playStart() => play(DominoSounds.start);
}
