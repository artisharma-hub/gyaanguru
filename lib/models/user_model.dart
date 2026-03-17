class UserModel {
  final String id;
  final String name;
  final String phone;
  final String avatarColor;
  final int coins;
  final int totalMatches;
  final int wins;
  final int winStreak;
  final int bestStreak;
  final int weeklyScore;
  // Device-local only — not stored on server
  final String? avatarImagePath;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarColor = '#FF4500',
    this.coins = 0,
    this.totalMatches = 0,
    this.wins = 0,
    this.winStreak = 0,
    this.bestStreak = 0,
    this.weeklyScore = 0,
    this.avatarImagePath,
  });

  double get winRate => totalMatches > 0 ? wins / totalMatches : 0.0;
  int get losses => totalMatches - wins;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        avatarColor: json['avatar_color']?.toString() ?? '#FF4500',
        coins: (json['coins'] as num?)?.toInt() ?? 0,
        totalMatches: (json['total_matches'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        winStreak: (json['win_streak'] as num?)?.toInt() ?? 0,
        bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
        weeklyScore: (json['weekly_score'] as num?)?.toInt() ?? 0,
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? avatarColor,
    int? coins,
    int? totalMatches,
    int? wins,
    int? winStreak,
    int? bestStreak,
    int? weeklyScore,
    String? avatarImagePath,
    bool clearAvatarImagePath = false,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        avatarColor: avatarColor ?? this.avatarColor,
        coins: coins ?? this.coins,
        totalMatches: totalMatches ?? this.totalMatches,
        wins: wins ?? this.wins,
        winStreak: winStreak ?? this.winStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        weeklyScore: weeklyScore ?? this.weeklyScore,
        avatarImagePath: clearAvatarImagePath
            ? null
            : (avatarImagePath ?? this.avatarImagePath),
      );
}
