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

  static const _categories = [
    'cricket', 'bollywood', 'gk', 'math', 'science', 'hindi'
  ];
  static const _categoryNames = {
    'cricket': 'Cricket', 'bollywood': 'Bollywood', 'gk': 'GK',
    'math': 'Math', 'science': 'Science', 'hindi': 'Hindi',
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
    switch (_tabController.index) {
      case 0: ref.read(leaderboardProvider.notifier).fetchGlobal();              break;
      case 1: ref.read(leaderboardProvider.notifier).fetchWeekly();              break;
      case 2: ref.read(leaderboardProvider.notifier).fetchCategory(_selectedCategory); break;
    }
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: context.go('/home');    break;
      case 1: context.go('/daily');   break;
      case 3: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lbState = ref.watch(leaderboardProvider);
    final user    = ref.watch(authProvider).valueOrNull;
    final ac      = context.ac;

    return Scaffold(
      backgroundColor: ac.background,
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [ac.textPrimary, AppColors.primaryLight],
                    ).createShader(b),
                    child: const Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD97706), AppColors.gold],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // ── Tab bar ─────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ac.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ac.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: ac.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'All-Time'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Category'),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Category dropdown (tab 2 only) ───────────────────────────
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index != 2) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    dropdownColor: ac.surfaceVariant,
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ac.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ac.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(_categoryNames[c] ?? c),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedCategory = v);
                        ref.read(leaderboardProvider.notifier).fetchCategory(v);
                      }
                    },
                  ),
                );
              },
            ),

            // ── Player list ──────────────────────────────────────────────
            Expanded(
              child: lbState.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primaryLight),
                  ),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64, height: 64,
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
                          fontFamily: 'Poppins',
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
                      ((data['players'] ?? data['leaderboard'] ?? []) as List)
                          .cast<Map<String, dynamic>>();
                  final myRank  = (data['my_rank'] as num?)?.toInt();
                  final myEntry = data['my_entry'] as Map<String, dynamic>?;
                  final showMyEntry =
                      myRank != null && myRank > 50 && myEntry != null;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: players.length + (showMyEntry ? 2 : 0),
                    itemBuilder: (context, i) {
                      if (showMyEntry && i == players.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(child: Divider(color: ac.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Your Rank',
                                  style: TextStyle(
                                    color: ac.textMuted,
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                  )),
                            ),
                            Expanded(child: Divider(color: ac.border)),
                          ]),
                        );
                      }
                      if (showMyEntry && i == players.length + 1) {
                        return _PlayerTile(
                          player: myEntry,
                          rank: myRank,
                          isMe: true,
                          isTop3: false,
                        );
                      }
                      final p    = players[i];
                      final rank = (p['rank'] as num?)?.toInt() ?? (i + 1);
                      final isMe = p['id']?.toString() == user?.id;
                      return _PlayerTile(
                        player: p,
                        rank: rank,
                        isMe: isMe,
                        isTop3: rank <= 3,
                      )
                          .animate(delay: (i * 35).ms)
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
    );
  }
}

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
    final ac          = context.ac;
    final name        = player['name']?.toString() ?? 'Player';
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
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.05),
              ])
            : null,
        color: isMe ? null : ac.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.4)
              : isTop3
                  ? _medalColor.withValues(alpha: 0.25)
                  : ac.border,
          width: 1,
        ),
        boxShadow: isTop3 && !isMe
            ? [
                BoxShadow(
                  color: _medalColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 38,
            child: isTop3
                ? Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        _medalColor.withValues(alpha: 0.8),
                        _medalColor,
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _medalColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
          AvatarWidget(name: name, avatarColor: avatarColor, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (You)' : name,
                  style: TextStyle(
                    color: isMe ? AppColors.primaryLight : ac.textPrimary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (coins != null) CoinDisplay(coins: coins, fontSize: 11),
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
                fontFamily: 'Poppins',
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
