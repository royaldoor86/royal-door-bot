class DominoTile {
  final String id;
  int left;
  int right;
  final bool isDouble;
  double rotation;

  DominoTile({
    required this.id,
    required this.left,
    required this.right,
    required this.isDouble,
    this.rotation = 0,
  });

  void flip() {
    int temp = left;
    left = right;
    right = temp;
  }

  DominoTile copy() => DominoTile(
        id: id,
        left: left,
        right: right,
        isDouble: isDouble,
        rotation: rotation,
      );
}

class DominoPlayer {
  final String id;
  final String username;
  final String? avatarUrl;
  List<DominoTile> hand;
  bool isCurrentPlayer;
  int score;

  DominoPlayer({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.hand,
    this.isCurrentPlayer = false,
    this.score = 0,
  });
}
