import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/coin_display.dart';
import '../widgets/vs_card.dart';
import '../widgets/sound_tap.dart';
import '../services/sound_service.dart';

const _avatarColors = [
  '#FF4500', '#0091FF', '#FF0080', '#B44DFF', '#00BCD4', '#69F0AE',
];

// ─── helpers ──────────────────────────────────────────────────────────────────
Color _parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  } catch (_) {
    return AppColors.primary;
  }
}

String _maskPhone(String phone) {
  if (phone.length <= 4) return phone;
  return '×××× ×××× ${phone.substring(phone.length - 4)}';
}

String _fmtWinRate(double rate) => '${(rate * 100).toStringAsFixed(1)}%';

// ══════════════════════════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _soundEnabled = true;
  int _navIndex = 3;

  // edit state
  late final TextEditingController _nameCtrl;
  String? _selectedColor;
  String? _pendingImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── edit bottom sheet ────────────────────────────────────────────────────
  void _openEditSheet() {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    _nameCtrl.text = user.name;
    setState(() {
      _selectedColor = user.avatarColor;
      _pendingImagePath = user.avatarImagePath;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditBottomSheet(
        nameCtrl: _nameCtrl,
        initialColor: user.avatarColor,
        onColorSelected: (hex) => setState(() => _selectedColor = hex),
        getSelectedColor: () => _selectedColor ?? user.avatarColor,
        onPickImage: _pickImage,
        saving: _saving,
        onSave: () => _saveProfile(ctx),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // close image-source sub-sheet
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _pendingImagePath = picked.path);
  }

  Future<void> _saveProfile(BuildContext sheetCtx) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            name: name,
            avatarColor: _selectedColor,
            imagePath: _pendingImagePath,
          );
      if (mounted && sheetCtx.mounted) Navigator.pop(sheetCtx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── nav ──────────────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/daily');
        break;
      case 2:
        context.go('/leaderboard');
        break;
    }
  }

  // ── logout ───────────────────────────────────────────────────────────────
  void _logout() {
    final ac = context.ac;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log out?',
          style: TextStyle(
            color: ac.textPrimary,
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            color: ac.textSecondary,
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: ac.textSecondary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrongRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final ac = context.ac;

    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF15172E), Color(0xFF1A1D38)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ambient top glow
            Positioned(
              top: -80,
              left: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── header card ─────────────────────────────────────
                    _HeaderCard(
                      user: user,
                      onEditTap: _openEditSheet,
                    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05),

                    const SizedBox(height: 22),

                    // ── stats grid ──────────────────────────────────────
                    _StatsGrid(
                      matches: user.totalMatches,
                      wins: user.wins,
                      winRate: _fmtWinRate(user.winRate),
                      bestStreak: user.bestStreak,
                    ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08),

                    const SizedBox(height: 16),

                    // ── settings card ────────────────────────────────────
                    _SettingsCard(
                      soundEnabled: _soundEnabled,
                      onSoundChanged: (v) => setState(() => _soundEnabled = v),
                      onLeaderboard: () => context.go('/leaderboard'),
                      onDaily: () => context.go('/daily'),
                      onLogout: _logout,
                    ).animate().fadeIn(delay: 250.ms, duration: 350.ms),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: ac.textMuted,
                          fontFamily: 'Nunito',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Header Card
// ══════════════════════════════════════════════════════════════════════════════
class _HeaderCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onEditTap;

  const _HeaderCard({required this.user, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final glowColor = _parseColor(user.avatarColor as String);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── edit pencil ──────────────────────────────────────────────
          Positioned(
            top: 0,
            right: 0,
            child: SoundTap(
              onTap: onEditTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
              ),
            ),
          ),

          // ── centered content ─────────────────────────────────────────
          Column(
            children: [
              // avatar glow ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        glowColor.withValues(alpha: 0.20),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: glowColor.withValues(alpha: 0.45),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.30),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                  AvatarWidget(
                    name: user.name as String,
                    avatarColor: user.avatarColor as String,
                    imagePath: user.avatarImagePath as String?,
                    radius: 48,
                  ),
                ],
              ).animate().scaleXY(
                    begin: 0.75,
                    end: 1.0,
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 14),

              // name
              Text(
                user.name as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(delay: 80.ms),

              const SizedBox(height: 4),

              // masked phone
              Text(
                _maskPhone(user.phone as String),
                style: TextStyle(
                  color: ac.textSecondary,
                  fontFamily: 'Nunito',
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 12),

              // coins
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.28),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: CoinDisplay(coins: user.coins as int, fontSize: 18),
              ),

              // win streak badge
              if ((user.winStreak as int) > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.gold.withValues(alpha: 0.18),
                      AppColors.gold.withValues(alpha: 0.06),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.22),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    '${user.winStreak} streak',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Stats Grid
// ══════════════════════════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final int matches;
  final int wins;
  final String winRate;
  final int bestStreak;

  const _StatsGrid({
    required this.matches,
    required this.wins,
    required this.winRate,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR STATS',
          style: TextStyle(
            color: ac.textMuted,
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Icons.sports_esports_rounded,
              value: '$matches',
              label: 'Matches',
              iconColor: AppColors.accent,
            ),
            _StatCard(
              icon: Icons.emoji_events_rounded,
              value: '$wins',
              label: 'Wins',
              iconColor: AppColors.gold,
            ),
            _StatCard(
              icon: Icons.show_chart_rounded,
              value: winRate,
              label: 'Win Rate',
              iconColor: AppColors.correctGreen,
            ),
            _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '$bestStreak',
              label: 'Best Streak',
              iconColor: AppColors.highlight,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ac.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // icon badge — primary-tinted circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ac.textPrimary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 26,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Settings Card
// ═════════════════════════════════════���════════════════════════════════════════
class _SettingsCard extends StatelessWidget {
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onLeaderboard;
  final VoidCallback onDaily;
  final VoidCallback onLogout;

  const _SettingsCard({
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onLeaderboard,
    required this.onDaily,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Container(
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ac.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              'Settings',
              style: TextStyle(
                color: ac.textSecondary,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
          ),

          // sound row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const _IconBadge(
                  icon: Icons.volume_up_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sound Effects',
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(
                  value: soundEnabled,
                  onChanged: onSoundChanged,
                ),
              ],
            ),
          ),

          Divider(color: ac.border, height: 1),

          _SettingsTile(
            icon: Icons.leaderboard_rounded,
            iconColor: AppColors.primaryLight,
            title: 'View Leaderboard',
            onTap: onLeaderboard,
          ),

          Divider(color: ac.border, height: 1),

          _SettingsTile(
            icon: Icons.today_rounded,
            iconColor: AppColors.correctGreen,
            title: 'Daily Challenge',
            onTap: onDaily,
          ),

          Divider(color: ac.border, height: 1),

          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.wrongRed,
            title: 'Logout',
            titleColor: AppColors.wrongRed,
            onTap: onLogout,
            showChevron: true,
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: _IconBadge(icon: icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? ac.textPrimary,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: showChevron
          ? Icon(Icons.arrow_forward_ios_rounded,
              color: ac.textMuted, size: 14)
          : null,
      onTap: () { SoundService().click(); onTap(); },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Edit Bottom Sheet
// ══════════════════════════════════════════════════════════════════════════════
class _EditBottomSheet extends StatefulWidget {
  final TextEditingController nameCtrl;
  final String initialColor;
  final ValueChanged<String> onColorSelected;
  final String Function() getSelectedColor;
  final Future<void> Function(ImageSource) onPickImage;
  final bool saving;
  final VoidCallback onSave;

  const _EditBottomSheet({
    required this.nameCtrl,
    required this.initialColor,
    required this.onColorSelected,
    required this.getSelectedColor,
    required this.onPickImage,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  late String _selectedHex;

  @override
  void initState() {
    super.initState();
    _selectedHex = widget.initialColor;
  }

  void _selectColor(String hex) {
    setState(() => _selectedHex = hex);
    widget.onColorSelected(hex);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: ac.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: ac.border2, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ac.border2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Edit Profile',
            style: TextStyle(
              color: ac.textPrimary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 18),

          // name field
          TextField(
            controller: widget.nameCtrl,
            style: TextStyle(
              color: ac.textPrimary,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline_rounded,
                  color: AppColors.primaryLight, size: 20),
            ),
          ),
          const SizedBox(height: 20),

          // color swatches label
          Text(
            'AVATAR COLOR',
            style: TextStyle(
              color: ac.textMuted,
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // 6 color swatches
          Row(
            children: _avatarColors.map((hex) {
              final isSelected = _selectedHex == hex;
              final c = _parseColor(hex);
              return SoundTap(
                onTap: () => _selectColor(hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2.5)
                        : Border.all(color: Colors.transparent),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.45),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // camera / gallery buttons
          Row(
            children: [
              _PhotoButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context); // close sheet; _pickImage re-opens via parent
                  widget.onPickImage(ImageSource.camera);
                },
              ),
              const SizedBox(width: 10),
              _PhotoButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // save gradient button
          SoundTap(
            onTap: widget.saving ? null : widget.onSave,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoundTap(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

