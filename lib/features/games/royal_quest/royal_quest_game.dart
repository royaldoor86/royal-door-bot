import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class RoyalQuestGame extends StatelessWidget {
  const RoyalQuestGame({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: GameProvider is provided by the caller in games_page.dart
    return const HomeScreen();
  }
}
