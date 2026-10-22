import 'package:flutter_test/flutter_test.dart';
import 'package:royaldoor/services/unity_game_service.dart';

void main() {
  group('UnityGameConfig Tests', () {
    test('creates UnityGameConfig with correct default and custom values', () {
      const config = UnityGameConfig(
        gameId: 'ludo',
        gameName: 'Royal Ludo',
        bundlePath: 'bundles/ludo',
        entryCost: 150,
        winReward: 300,
      );

      expect(config.gameId, 'ludo');
      expect(config.gameName, 'Royal Ludo');
      expect(config.bundlePath, 'bundles/ludo');
      expect(config.entryCost, 150);
      expect(config.winReward, 300);
    });
  });

  group('UnityGameService Payload Tests', () {
    test('buildUserDataPayload builds payload in exact required format', () {
      final service = UnityGameService.instance;
      const config = UnityGameConfig(
        gameId: 'domino',
        gameName: 'Royal Domino',
        bundlePath: 'bundles/domino',
        sceneName: 'DominoScene',
        entryCost: 100,
        winReward: 200,
      );

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
      expect(payload['gameId'], 'domino');
      expect(payload['gameName'], 'Royal Domino');
      expect(payload['bundlePath'], 'bundles/domino');
      expect(payload['sceneName'], 'DominoScene');
    });
  });
}
