import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/sound_tap.dart';
import '../widgets/vs_card.dart';

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
    'cricket': 'Cricket',   'bollywood': 'Bollywood',
    'gk': 'GK',             'math': 'Math',
    'science': 'Science',   'hindi': 'Hindi',
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
      case 0: ref.read(leaderboardProvider.notifier).fetchGlobal();  break;
      case 1: ref.read(leaderboardProvider.notifier).fetchWeekly(); break;
      case 2: ref.read(leaderboardProvider.notifier).fetchCategory(_selectedCategory); break;
    }
  }

  void _switchTab(int index) => _tabController.animateTo(index);

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

    return BackButtonListener(
      onBackButtonPressed: () async {
        context.go('/home');
        return true;
      },
      child: Scaffold(
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Column(
        children: [
          // ── Teal gradient header ───────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.leaderboardGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/home'),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Leaderboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 36),
                      ],
                    ),
                  ),

                  // Pill tabs
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _PillTab(label: 'All time',  active: _activeTab == 0, onTap: () => _switchTab(0)),
                          _PillTab(label: 'This week', active: _activeTab == 1, onTap: () => _switchTab(1)),
                          _PillTab(label: 'Category',  active: _activeTab == 2, onTap: () => _switchTab(2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category dropdown (tab 2 only)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _activeTab == 2
                ? Padding(
                    key: const ValueKey('cat'),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _CategoryDropdown(
                      value: _selectedCategory,
                      categories: _categories,
                      categoryNames: _categoryNames,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedCategory = v);
                          ref.read(leaderboardProvider.notifier).fetchCategory(v);
                        }
                      },
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-cat')),
          ),

          // Player list
          Expanded(
            child: lbState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.wrongRed, size: 40),
                    const SizedBox(height: 12),
                    const Text('Failed to load',
                        style: TextStyle(color: AppColors.textSecondary,
                            fontFamily: 'Nunito')),
                    const SizedBox(height: 12),
                    SoundTap(
                      onTap: _onTabChanged,
                      child: ElevatedButton(
                          onPressed: _onTabChanged,
                          child: const Text('Retry')),
                    ),
                  ],
                ),
              ),
              data: (data) {
                if (data == null) return const SizedBox.shrink();
                final players = ((data['players'] ?? data['leaderboard'] ?? []) as List)
                    .cast<Map<String, dynamic>>();
                final myRank  = (data['my_rank'] as num?)?.toInt();
                final myEntry = data['my_entry'] as Map<String, dynamic>?;
                final showMyEntry = myRank != null && myRank > 50 && myEntry != null;

                final top3 = players
                    .where((p) => ((p['rank'] as num?)?.toInt() ?? players.indexOf(p) + 1) <= 3)
                    .toList();
                final rest = players
                    .where((p) => ((p['rank'] as num?)?.toInt() ?? players.indexOf(p) + 1) > 3)
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: 1 + rest.length + (showMyEntry ? 2 : 0),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return top3.isEmpty
                          ? const SizedBox.shrink()
                          : _PodiumRow(players: top3)
                              .animate().fadeIn(duration: 350.ms);
                    }
                    final idx = i - 1;
                    if (showMyEntry && idx == rest.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Your Rank',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ]),
                      );
                    }
                    if (showMyEntry && idx == rest.length + 1) {
                      return _PlayerRow(player: myEntry, rank: myRank, isMe: true);
                    }
                    final p    = rest[idx];
                    final rank = (p['rank'] as num?)?.toInt() ?? (idx + 4);
                    final isMe = p['id']?.toString() == user?.id;
                    return _PlayerRow(player: p, rank: rank, isMe: isMe)
                        .animate(delay: (idx * 30).ms)
                        .fadeIn(duration: 220.ms)
                        .slideX(begin: 0.06, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill Tab ──────────────────────────────────────────────────────────────────
class _PillTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoundTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF0A7C72) : Colors.white.withValues(alpha: 0.80),
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

// ── Category Dropdown ─────────────────────────────────────────────────────────
class _CategoryDropdown extends StatelessWidget {
  final String value;
  final List<String> categories;
  final Map<String, String> categoryNames;
  final ValueChanged<String?> onChanged;
  const _CategoryDropdown({required this.value, required this.categories,
      required this.categoryNames, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: AppColors.surfaceVariant,
      style: const TextStyle(
          color: AppColors.textPrimary, fontFamily: 'Nunito',
          fontWeight: FontWeight.w600, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryLight),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      items: categories
          .map((c) => DropdownMenuItem(value: c, child: Text(categoryNames[c] ?? c)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Podium Row (top 3) ────────────────────────────────────────────────────────
class _PodiumRow extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  const _PodiumRow({required this.players});

  Map<String, dynamic>? _at(int rank) {
    try {
      return players.firstWhere(
        (p) => (p['rank'] as num?)?.toInt() == rank,
        orElse: () => players.length >= rank ? players[rank - 1] : {},
      );
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final first  = _at(1);
    final second = _at(2);
    final third  = _at(3);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            Expanded(child: _PodiumItem(player: second, rank: 2, avatarRadius: 28, nameSize: 12)),
          const SizedBox(width: 6),
          if (first != null)
            Expanded(child: _PodiumItem(player: first,  rank: 1, avatarRadius: 36, nameSize: 13, showCrown: true)),
          const SizedBox(width: 6),
          if (third != null)
            Expanded(child: _PodiumItem(player: third,  rank: 3, avatarRadius: 26, nameSize: 12)),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final double avatarRadius;
  final double nameSize;
  final bool showCrown;

  static const _rankColors = {
    1: Color(0xFFFFB800),
    2: Color(0xFFB0BEC5),
    3: Color(0xFFCD7F32),
  };

  const _PodiumItem({
    required this.player, required this.rank,
    required this.avatarRadius, required this.nameSize,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final name        = player['name']?.toString() ?? 'Player';
    final avatarColor = player['avatar_color']?.toString() ?? '#6C63FF';
    final score       = ((player['wins'] ?? player['weekly_score'] ?? player['score'] ?? 0) as num).toInt();
    final rankColor   = _rankColors[rank] ?? AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCrown)
          const Text('👑', style: TextStyle(fontSize: 20))
        else
          const SizedBox(height: 24),
        const SizedBox(height: 4),
        // Avatar with rank-colored ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: 2.5),
          ),
          child: AvatarWidget(name: name, avatarColor: avatarColor, radius: avatarRadius),
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            fontSize: nameSize,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        // Score
        Text(
          _formatScore(score),
          style: TextStyle(
            color: rankColor,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: nameSize,
          ),
        ),
        const SizedBox(height: 10),
        // Step base — rank 1 is tallest
        Container(
          height: rank == 1 ? 52 : rank == 2 ? 38 : 28,
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: rankColor.withValues(alpha: 0.40), width: 1),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: rankColor,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatScore(int s) {
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(3).replaceAll('.', ',')}';
    return s.toString();
  }
}

// ── Player Row (rank 4+) ──────────────────────────────────────────────────────
class _PlayerRow extends StatelessWidget {
  final Map<String, dynamic> player;
  final int rank;
  final bool isMe;
  const _PlayerRow({required this.player, required this.rank, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name        = player['name']?.toString() ?? 'Player';
    final avatarColor = player['avatar_color']?.toString() ?? '#FF4500';
    final score       = ((player['wins'] ?? player['weekly_score'] ?? player['score'] ?? 0) as num).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: isMe ? AppColors.primaryLight : AppColors.textSecondary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          AvatarWidget(name: name, avatarColor: avatarColor, radius: 19),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              isMe ? '$name (You)' : name,
              style: TextStyle(
                color: isMe ? AppColors.primaryLight : AppColors.textPrimary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score in teal
          Text(
            _formatScore(score),
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int s) {
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(3).replaceAll('.', ',')}';
    return s.toString();
  }
}
