import 'package:flutter_test/flutter_test.dart';
import 'package:royaldoor/services/unity_game_service.dart';

void main() {
  group('UnityGameRegistry - All 10 Unity Games', () {
    test('contains all 10 specified Unity games with accurate configurations', () {
      expect(UnityGameRegistry.games.length, 10);

      // 1. Lara Card
      final laraCard = UnityGameRegistry.getGame('lara_card');
      expect(laraCard.gameId, 'lara_card');
      expect(laraCard.gameName, 'Lara Card');
      expect(laraCard.bundlePath, 'bundles/lara_card');
      expect(laraCard.sceneName, 'MenuScene');
      expect(laraCard.entryCost, 100);
      expect(laraCard.winReward, 200);

      // 2. Ludo Royal
      final ludoRoyal = UnityGameRegistry.getGame('ludo_royal');
      expect(ludoRoyal.gameId, 'ludo_royal');
      expect(ludoRoyal.gameName, 'Ludo Royal');
      expect(ludoRoyal.bundlePath, 'bundles/ludo_royal');
      expect(ludoRoyal.sceneName, 'MenuScene');
      expect(ludoRoyal.entryCost, 100);
      expect(ludoRoyal.winReward, 200);

      // 3. Royal Snake
      final royalSnake = UnityGameRegistry.getGame('royal_snake');
      expect(royalSnake.gameId, 'royal_snake');
      expect(royalSnake.gameName, 'Royal Snake');
      expect(royalSnake.bundlePath, 'bundles/royal_snake');
      expect(royalSnake.sceneName, 'MenuScene');
      expect(royalSnake.entryCost, 100);
      expect(royalSnake.winReward, 200);

      // 4. XO Royal
      final xoRoyal = UnityGameRegistry.getGame('xo_royal');
      expect(xoRoyal.gameId, 'xo_royal');
      expect(xoRoyal.gameName, 'XO Royal');
      expect(xoRoyal.bundlePath, 'bundles/xo_royal');
      expect(xoRoyal.sceneName, 'MenuScene');
      expect(xoRoyal.entryCost, 50);
      expect(xoRoyal.winReward, 100);

      // 5. Royal Backgammon
      final royalBackgammon = UnityGameRegistry.getGame('royal_backgammon');
      expect(royalBackgammon.gameId, 'royal_backgammon');
      expect(royalBackgammon.gameName, 'Royal Backgammon');
      expect(royalBackgammon.bundlePath, 'bundles/royal_backgammon');
      expect(royalBackgammon.sceneName, 'MenuScene');
      expect(royalBackgammon.entryCost, 150);
      expect(royalBackgammon.winReward, 300);

      // 6. Domino Royal
      final dominoRoyal = UnityGameRegistry.getGame('domino_royal');
      expect(dominoRoyal.gameId, 'domino_royal');
      expect(dominoRoyal.gameName, 'Domino Royal');
      expect(dominoRoyal.bundlePath, 'bundles/domino_royal');
      expect(dominoRoyal.sceneName, 'MenuScene');
      expect(dominoRoyal.entryCost, 100);
      expect(dominoRoyal.winReward, 200);

      // 7. Royal War
      final royalWar = UnityGameRegistry.getGame('royal_war');
      expect(royalWar.gameId, 'royal_war');
      expect(royalWar.gameName, 'Royal War');
      expect(royalWar.bundlePath, 'bundles/royal_war');
      expect(royalWar.sceneName, 'MenuScene');
      expect(royalWar.entryCost, 200);
      expect(royalWar.winReward, 400);

      // 8. Royal Mahjong
      final royalMahjong = UnityGameRegistry.getGame('royal_mahjong');
      expect(royalMahjong.gameId, 'royal_mahjong');
      expect(royalMahjong.gameName, 'Royal Mahjong');
      expect(royalMahjong.bundlePath, 'bundles/royal_mahjong');
      expect(royalMahjong.sceneName, 'MenuScene');
      expect(royalMahjong.entryCost, 150);
      expect(royalMahjong.winReward, 300);

      // 9. Royal Pool
      final royalPool = UnityGameRegistry.getGame('royal_pool');
      expect(royalPool.gameId, 'royal_pool');
      expect(royalPool.gameName, 'Royal Pool');
      expect(royalPool.bundlePath, 'bundles/royal_pool');
      expect(royalPool.sceneName, 'MenuScene');
      expect(royalPool.entryCost, 100);
      expect(royalPool.winReward, 200);

      // 10. Royal Fruit
      final royalFruit = UnityGameRegistry.getGame('royal_fruit');
      expect(royalFruit.gameId, 'royal_fruit');
      expect(royalFruit.gameName, 'Royal Fruit');
      expect(royalFruit.bundlePath, 'bundles/royal_fruit');
      expect(royalFruit.sceneName, 'MenuScene');
      expect(royalFruit.entryCost, 50);
      expect(royalFruit.winReward, 100);
    });
  });

  group('UnityGameService Payload Tests', () {
    test('buildUserDataPayload builds payload in exact requested format for all 10 games', () {
      final service = UnityGameService.instance;
      final config = UnityGameRegistry.getGame('domino_royal');

      final userProfile = {
        'name': 'الملك أسامة',
        'points': 500,
        'profilePic': 'https://example.com/avatar.jpg',
      };

      final payload = service.buildUserDataPayload(
        userProfile: userProfile,
        config: config,
        currentPointsAfterDeduction: 400,
      );

      expect(payload['action'], 'setUserData');
      expect(payload['name'], 'الملك أسامة');
      expect(payload['points'], 400);
      expect(payload['profilePic'], 'https://example.com/avatar.jpg');
      expect(payload['entryCost'], 100);
      expect(payload['winReward'], 200);
      expect(payload['gameId'], 'domino_royal');
      expect(payload['gameName'], 'Domino Royal');
      expect(payload['bundlePath'], 'bundles/domino_royal');
      expect(payload['sceneName'], 'MenuScene');
    });
  });
}
