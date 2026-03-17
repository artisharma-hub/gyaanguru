import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/coin_display.dart';
import '../widgets/vs_card.dart';
import '../widgets/app_nav_bar.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'cricket';
  int _navIndex = 2;
  int _activeTab = 0;

  static const _categories = [
    'cricket', 'bollywood', 'gk', 'math', 'science', 'hindi'
  ];
  static const _categoryNames = {
    'cricket': 'Cricket',
    'bollywood': 'Bollywood',
    'gk': 'GK',
    'math': 'Math',
    'science': 'Science',
    'hindi': 'Hindi',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaderboardProvider.notifier).fetchGlobal();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() => _activeTab = _tabController.index);
    switch (_tabController.index) {
      case 0:
        ref.read(leaderboardProvider.notifier).fetchGlobal();
        break;
      case 1:
        ref.read(leaderboardProvider.notifier).fetchWeekly();
        break;
      case 2:
        ref
            .read(leaderboardProvider.notifier)
            .fetchCategory(_selectedCategory);
        break;
    }
  }

  void _switchTab(int index) {
    _tabController.animateTo(index);
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/daily');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lbState = ref.watch(leaderboardProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final ac = context.ac;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Colors.white, AppColors.primaryLight],
                      ).createShader(b),
                      child: const Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 26,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), AppColors.gold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.28),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),

              // ── 3-tab pill selector ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ac.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ac.border),
                  ),
                  child: Row(
                    children: [
                      _PillTab(
                        label: 'All-Time',
                        active: _activeTab == 0,
                        onTap: () => _switchTab(0),
                      ),
                      _PillTab(
                        label: 'Weekly',
                        active: _activeTab == 1,
                        onTap: () => _switchTab(1),
                      ),
                      _PillTab(
                        label: 'Category',
                        active: _activeTab == 2,
                        onTap: () => _switchTab(2),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Category dropdown (tab 2 only) ───────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _activeTab == 2
                    ? Padding(
                        key: const ValueKey('cat-dropdown'),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _CategoryDropdown(
                          value: _selectedCategory,
                          categories: _categories,
                          categoryNames: _categoryNames,
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedCategory = v);
                              ref
                                  .read(leaderboardProvider.notifier)
                                  .fetchCategory(v);
                            }
                          },
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-dropdown')),
              ),

              // ── Player list ──────────────────────────────────────────────
              Expanded(
                child: lbState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.primaryLight),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.wrongRed.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              color: AppColors.wrongRed, size: 32),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Failed to load',
                          style: TextStyle(
                            color: ac.textPrimary,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _onTabChanged,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (data) {
                    if (data == null) return const SizedBox.shrink();
                    final players =
                        ((data['players'] ?? data['leaderboard'] ?? [])
                                as List)
                            .cast<Map<String, dynamic>>();
                    final myRank = (data['my_rank'] as num?)?.toInt();
                    final myEntry =
                        data['my_entry'] as Map<String, dynamic>?;
                    final showMyEntry =
                        myRank != null && myRank > 50 && myEntry != null;

                    // Split top-3 from rest
                    final top3 = players
                        .where((p) =>
                            ((p['rank'] as num?)?.toInt() ??
                                players.indexOf(p) + 1) <=
                            3)
                        .toList();
                    final rest = players
                        .where((p) =>
                            ((p['rank'] as num?)?.toInt() ??
                                players.indexOf(p) + 1) >
                            3)
                        .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: 1 +
                          rest.length +
                          (showMyEntry ? 2 : 0),
                      itemBuilder: (context, i) {
                        // Item 0: podium
                        if (i == 0) {
                          return top3.isEmpty
                              ? const SizedBox.shrink()
                              : _PodiumRow(players: top3)
                                  .animate()
                                  .fadeIn(duration: 350.ms)
                                  .slideY(begin: -0.06);
                        }

                        final listIndex = i - 1;

                        if (showMyEntry && listIndex == rest.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(children: [
                              Expanded(child: Divider(color: ac.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  'Your Rank',
                                  style: TextStyle(
                                    color: ac.textMuted,
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: ac.border)),
                            ]),
                          );
                        }
                        if (showMyEntry && listIndex == rest.length + 1) {
                          return _PlayerTile(
                            player: myEntry,
                            rank: myRank,
                            isMe: true,
                            isTop3: false,
                          );
                        }

                        final p = rest[listIndex];
                        final rank =
                            (p['rank'] as num?)?.toInt() ??
                                (listIndex + 4);
                        final isMe = p['id']?.toString() == user?.id;
                        return _PlayerTile(
                          player: p,
                          rank: rank,
                          isMe: isMe,
                          isTop3: false,
                        )
                            .animate(delay: (listIndex * 35).ms)
                            .fadeIn(duration: 240.ms)
                            .slideX(begin: 0.08, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pill Tab ─────────────────────────────────────────────────────────────────
class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          height: 38,
          decoration: active
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                    ),
                  ],
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : AppColors.textSecondary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Dropdown ────────────────────────────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final Map<String, String> categoryNames;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.categoryNames,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: ac.surfaceVariant,
      style: TextStyle(
        color: ac.textPrimary,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.primaryLight),
      decoration: InputDecoration(
        filled: true,
        fillColor: ac.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ac.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: ac.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      items: categories
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(categoryNames[c] ?? c),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Podium Row (top 3) ───────────────────────────────────────────────────────
class _PodiumRow extends StatelessWidget {
  final List<Map<String, dynamic>> players;

  const _PodiumRow({required this.players});

  Map<String, dynamic>? _playerAt(int rank) {
    try {
      return players.firstWhere(
        (p) => (p['rank'] as num?)?.toInt() == rank,
        orElse: () => players.length >= rank ? players[rank - 1] : {},
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = _playerAt(1);
    final second = _playerAt(2);
    final third = _playerAt(3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (second != null)
            Expanded(
              child: _PodiumCard(
                player: second,
                rank: 2,
                medalColor: const Color(0xFFCBD5E1),
                medalLabel: '2nd',
                avatarRadius: 28,
                height: 140,
              ),
            ),

          const SizedBox(width: 8),

          // 1st place — taller + gold crown
          if (first != null)
            Expanded(
              flex: 1,
              child: _PodiumCard(
                player: first,
                rank: 1,
                medalColor: AppColors.gold,
                medalLabel: '1st',
                avatarRadius: 34,
                height: 168,
                showCrown: true,
              ),
            ),

          const SizedBox(width: 8),

          // 3rd place
          if (third != null)
            Expanded(
              child: _PodiumCard(
                player: third,
                rank: 3,
                medalColor: const Color(0xFFCD7F32),
                medalLabel: '3rd',
                avatarRadius: 26,
                height: 128,
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final Color medalColor;
  final String medalLabel;
  final double avatarRadius;
  final double height;
  final bool showCrown;

  const _PodiumCard({
    required this.player,
    required this.rank,
    required this.medalColor,
    required this.medalLabel,
    required this.avatarRadius,
    required this.height,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final name = player['name']?.toString() ?? 'Player';
    final avatarColor = player['avatar_color']?.toString() ?? '#6C63FF';
    final score = ((player['wins'] ??
                player['weekly_score'] ??
                player['score'] ??
                0) as num)
        .toInt();

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            medalColor.withValues(alpha: 0.18),
            ac.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: medalColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: medalColor.withValues(alpha: 0.28),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showCrown)
            const Text('👑', style: TextStyle(fontSize: 18))
          else
            const SizedBox(height: 4),
          const SizedBox(height: 4),
          AvatarWidget(
            name: name,
            avatarColor: avatarColor,
            radius: avatarRadius,
          ),
          const SizedBox(height: 6),
          // Medal badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  medalColor.withValues(alpha: 0.8),
                  medalColor,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: medalColor.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Text(
              medalLabel,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              style: TextStyle(
                color: ac.textPrimary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.goldDark, AppColors.gold, AppColors.goldLight],
            ).createShader(b),
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Player Tile (rank 4+) ────────────────────────────────────────────────────
class _PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final bool isMe;
  final bool isTop3;

  const _PlayerTile({
    required this.player,
    required this.rank,
    required this.isMe,
    required this.isTop3,
  });

  Color get _medalColor {
    if (rank == 1) return AppColors.gold;
    if (rank == 2) return const Color(0xFFCBD5E1);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final name = player['name']?.toString() ?? 'Player';
    final avatarColor = player['avatar_color']?.toString() ?? '#FF4500';
    final score = ((player['wins'] ??
                player['weekly_score'] ??
                player['score'] ??
                0) as num)
        .toInt();
    final coins = (player['coins'] as num?)?.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isMe
            ? LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.primary.withValues(alpha: 0.05),
              ])
            : null,
        color: isMe ? null : ac.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.5)
              : isTop3
                  ? _medalColor.withValues(alpha: 0.28)
                  : ac.border,
          width: isMe ? 1.5 : 1,
        ),
        boxShadow: isMe
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 16,
                ),
              ]
            : isTop3
                ? [
                    BoxShadow(
                      color: _medalColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                    ),
                  ]
                : [],
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 40,
            child: isTop3
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _medalColor.withValues(alpha: 0.8),
                        _medalColor,
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _medalColor.withValues(alpha: 0.28),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      color: isMe ? AppColors.primaryLight : ac.textMuted,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
          AvatarWidget(
              name: name, avatarColor: avatarColor, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (You)' : name,
                  style: TextStyle(
                    color:
                        isMe ? AppColors.primaryLight : ac.textPrimary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (coins != null)
                  CoinDisplay(coins: coins, fontSize: 11),
              ],
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [AppColors.gold, AppColors.goldLight],
            ).createShader(b),
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
