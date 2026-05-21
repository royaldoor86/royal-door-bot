import 'package:audioplayers/audioplayers.dart';
import '../constants/domino_sounds.dart';

class DominoSoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      print('Error playing sound: $e');
    }
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
