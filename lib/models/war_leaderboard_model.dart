import 'package:cloud_firestore/cloud_firestore.dart';

class WarLeaderboardModel {
  final String id;
  final String familyId;
  final String familyName;
  final String? familyLogo;
  final int totalWars;
  final int warsWon;
  final int warsLost;
  final int totalPoints;
  final int currentStreak;
  final int bestStreak;
  final Timestamp lastWarDate;
  final int rank;
  final double winRate;

  WarLeaderboardModel({
    required this.id,
    required this.familyId,
    required this.familyName,
    this.familyLogo,
    required this.totalWars,
    required this.warsWon,
    required this.warsLost,
    required this.totalPoints,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastWarDate,
    required this.rank,
    required this.winRate,
  });

  factory WarLeaderboardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final totalWars = data['totalWars'] ?? 0;
    final warsWon = data['warsWon'] ?? 0;
    final warsLost = data['warsLost'] ?? 0;
    final winRate = totalWars > 0 ? (warsWon / totalWars) * 100 : 0.0;

    return WarLeaderboardModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      familyLogo: data['familyLogo'],
      totalWars: totalWars,
      warsWon: warsWon,
      warsLost: warsLost,
      totalPoints: data['totalPoints'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      bestStreak: data['bestStreak'] ?? 0,
      lastWarDate: data['lastWarDate'] ?? Timestamp.now(),
      rank: data['rank'] ?? 0,
      winRate: winRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'familyLogo': familyLogo,
      'totalWars': totalWars,
      'warsWon': warsWon,
      'warsLost': warsLost,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastWarDate': lastWarDate,
      'rank': rank,
      'winRate': winRate,
    };
  }

  // حساب النقاط للتصنيف
  static int calculateLeaderboardPoints(int warsWon, int warsLost, int totalPoints) {
    return (warsWon * 100) - (warsLost * 50) + totalPoints;
  }

  // تحديث التصنيف بعد حرب
  static WarLeaderboardModel updateAfterWar(
    WarLeaderboardModel current,
    bool won,
    int pointsEarned,
  ) {
    final newTotalWars = current.totalWars + 1;
    final newWarsWon = won ? current.warsWon + 1 : current.warsWon;
    final newWarsLost = won ? current.warsLost : current.warsLost + 1;
    final newTotalPoints = current.totalPoints + pointsEarned;
    final newCurrentStreak = won ? current.currentStreak + 1 : 0;
    final newBestStreak = newCurrentStreak > current.bestStreak ? newCurrentStreak : current.bestStreak;
    final newWinRate = newTotalWars > 0 ? (newWarsWon / newTotalWars) * 100 : 0.0;

    return WarLeaderboardModel(
      id: current.id,
      familyId: current.familyId,
      familyName: current.familyName,
      familyLogo: current.familyLogo,
      totalWars: newTotalWars,
      warsWon: newWarsWon,
      warsLost: newWarsLost,
      totalPoints: newTotalPoints,
      currentStreak: newCurrentStreak,
      bestStreak: newBestStreak,
      lastWarDate: Timestamp.now(),
      rank: current.rank,
      winRate: newWinRate,
    );
  }

  // الحصول على الرتبة بناءً على النقاط
  String getRankTitle() {
    if (totalPoints >= 10000) return '👑 إمبراطوري';
    if (totalPoints >= 5000) return '💎 ملكي';
    if (totalPoints >= 2500) return '🏆 بلاتيني';
    if (totalPoints >= 1000) return '🥇 ذهبي';
    if (totalPoints >= 500) return '🥈 فضي';
    if (totalPoints >= 100) return '🥉 برونزي';
    return '⭐ مبتدئ';
  }

  // الحصول على لون الرتبة
  String getRankColor() {
    if (totalPoints >= 10000) return '#FFD700'; // ذهبي
    if (totalPoints >= 5000) return '#E5E4E2'; // بلاتيني
    if (totalPoints >= 2500) return '#C0C0C0'; // فضي
    if (totalPoints >= 1000) return '#CD7F32'; // برونزي
    return '#808080'; // رمادي
  }
}
