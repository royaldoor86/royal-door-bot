
enum GameMode { solo, duo, trio, quad }
enum PlayType { offline, online }

class DominoTile {
  final String id;
  int left;
  int right;
  final bool isDouble;
  double rotation;
  double x;
  double y;

  DominoTile({
    required this.id,
    required this.left,
    required this.right,
    required this.isDouble,
    this.rotation = 0,
    this.x = 0,
    this.y = 0,
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
        x: x,
        y: y,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'left': left,
    'right': right,
    'isDouble': isDouble,
    'rotation': rotation,
    'x': x,
    'y': y,
  };

  factory DominoTile.fromJson(Map<String, dynamic> json) => DominoTile(
    id: json['id'],
    left: json['left'],
    right: json['right'],
    isDouble: json['isDouble'],
    rotation: (json['rotation'] as num).toDouble(),
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatarUrl': avatarUrl,
    'hand': hand.map((e) => e.toJson()).toList(),
    'isCurrentPlayer': isCurrentPlayer,
    'score': score,
  };

  factory DominoPlayer.fromJson(Map<String, dynamic> json) => DominoPlayer(
    id: json['id'],
    username: json['username'],
    avatarUrl: json['avatarUrl'],
    hand: (json['hand'] as List).map((e) => DominoTile.fromJson(e)).toList(),
    isCurrentPlayer: json['isCurrentPlayer'],
    score: json['score'],
  );
}
