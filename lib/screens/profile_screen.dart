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

const _avatarColors = [
  '#FF4500', '#0091FF', '#FF0080', '#B44DFF', '#00BCD4', '#69F0AE',
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _soundEnabled = true;
  int _navIndex = 3;

  bool _editing = false;
  late TextEditingController _nameController;
  String? _selectedColor;
  String? _pendingImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    _nameController.text = user.name;
    setState(() {
      _editing = true;
      _selectedColor = user.avatarColor;
      _pendingImagePath = user.avatarImagePath;
    });
  }

  void _cancelEditing() =>
      setState(() { _editing = false; _pendingImagePath = null; });

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
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
      if (mounted) setState(() => _editing = false);
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

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _pendingImagePath = picked.path);
  }

  void _showImageSourceSheet() {
    final ac = context.ac;
    showModalBottomSheet(
      context: context,
      backgroundColor: ac.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ac.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primaryLight, size: 20),
                ),
                title: Text('Camera',
                    style: TextStyle(
                        color: ac.textPrimary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primaryLight, size: 20),
                ),
                title: Text('Gallery',
                    style: TextStyle(
                        color: ac.textPrimary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_pendingImagePath != null ||
                  ref.read(authProvider).valueOrNull?.avatarImagePath != null)
                ListTile(
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.wrongRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppColors.wrongRed, size: 20),
                  ),
                  title: const Text('Remove Photo',
                      style: TextStyle(
                          color: AppColors.wrongRed,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _pendingImagePath = '');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    switch (index) {
      case 0: context.go('/home');        break;
      case 1: context.go('/daily');       break;
      case 2: context.go('/leaderboard'); break;
    }
  }

  String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '×××× ×××× ${phone.substring(phone.length - 4)}';
  }

  String _formatWinRate(double rate) => '${(rate * 100).toStringAsFixed(1)}%';

  Color _parseColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return AppColors.primary; }
  }

  void _logout() {
    final ac = context.ac;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ac.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout?',
            style: TextStyle(
                color: ac.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(
                color: ac.textSecondary, fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: ac.textSecondary, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              context.go('/register');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wrongRed),
            child: const Text('Logout',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final ac   = context.ac;

    if (user == null) {
      return Scaffold(
        backgroundColor: ac.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryLight),
          ),
        ),
      );
    }

    final displayImagePath = _editing ? _pendingImagePath : user.avatarImagePath;
    final displayColor     = _editing
        ? (_selectedColor ?? user.avatarColor)
        : user.avatarColor;

    return Scaffold(
      backgroundColor: ac.background,
      extendBody: true,
      bottomNavigationBar: AppNavBar(currentIndex: _navIndex, onTap: _onNavTap),
      body: Stack(
        children: [
          // Top glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              child: Column(
                children: [
                  // ── Avatar section ───────────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 116, height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _parseColor(displayColor).withValues(alpha: 0.25),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                      GestureDetector(
                        onTap: _editing ? _showImageSourceSheet : null,
                        child: AvatarWidget(
                          name: user.name,
                          avatarColor: displayColor,
                          imagePath: displayImagePath,
                          radius: 48,
                        ),
                      ),
                      if (_editing)
                        Positioned(
                          right: 0, bottom: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: ac.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  )
                      .animate()
                      .scaleXY(begin: 0.7, end: 1.0, duration: 500.ms,
                          curve: Curves.elasticOut),

                  const SizedBox(height: 14),

                  // Name
                  if (_editing)
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: ac.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      user.name,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.3,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 4),
                  Text(
                    _maskPhone(user.phone),
                    style: TextStyle(
                      color: ac.textSecondary,
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 12),
                  CoinDisplay(coins: user.coins, fontSize: 20),

                  if (user.winStreak > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppColors.gold.withValues(alpha: 0.15),
                          AppColors.gold.withValues(alpha: 0.05),
                        ]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '🔥 ${user.winStreak} Win Streak',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Color picker (edit mode) ──────────────────────────────
                  if (_editing) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Avatar Color',
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _avatarColors.map((hex) {
                        final isSelected =
                            (_selectedColor ?? user.avatarColor) == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: _parseColor(hex),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2.5)
                                  : Border.all(color: Colors.transparent),
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                      color: _parseColor(hex).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    )]
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _cancelEditing,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ac.textSecondary,
                              side: BorderSide(color: ac.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _saving ? null : _saveProfile,
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: _saving
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ))
                                    : const Text('Save',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profile',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Stats card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: ac.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR STATS',
                          style: TextStyle(
                            color: ac.textMuted,
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatCard(
                              label: 'Matches',
                              value: '${user.totalMatches}',
                              icon: Icons.sports_esports_rounded,
                              color: AppColors.accent,
                            ),
                            _StatCard(
                              label: 'Wins',
                              value: '${user.wins}',
                              icon: Icons.emoji_events_rounded,
                              color: AppColors.gold,
                            ),
                            _StatCard(
                              label: 'Win Rate',
                              value: _formatWinRate(user.winRate),
                              icon: Icons.show_chart_rounded,
                              color: AppColors.correctGreen,
                            ),
                            _StatCard(
                              label: 'Best Streak',
                              value: '${user.bestStreak}🔥',
                              icon: Icons.local_fire_department_rounded,
                              color: AppColors.highlight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // ── Settings card ────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: ac.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: ac.border),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: Text('Sound Effects',
                              style: TextStyle(
                                  color: ac.textPrimary,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text('Toggle in-game sounds',
                              style: TextStyle(
                                  color: ac.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 12)),
                          secondary: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.volume_up_rounded,
                                color: AppColors.accent, size: 20),
                          ),
                          value: _soundEnabled,
                          onChanged: (v) => setState(() => _soundEnabled = v),
                        ),
                        Divider(color: ac.border, height: 1),
                        _SettingsTile(
                          icon: Icons.leaderboard_rounded,
                          iconColor: AppColors.primaryLight,
                          title: 'View Leaderboard',
                          onTap: () => context.go('/leaderboard'),
                        ),
                        Divider(color: ac.border, height: 1),
                        _SettingsTile(
                          icon: Icons.today_rounded,
                          iconColor: AppColors.correctGreen,
                          title: 'Daily Challenge',
                          onTap: () => context.go('/daily'),
                        ),
                        Divider(color: ac.border, height: 1),
                        _SettingsTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.wrongRed,
                          title: 'Logout',
                          onTap: _logout,
                          destructive: true,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 20),
                  Text(
                    'Gyaan Guru v1.0.0',
                    style: TextStyle(
                        color: ac.textMuted,
                        fontFamily: 'Poppins',
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: ac.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: ac.textSecondary,
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.ac;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: destructive ? AppColors.wrongRed : ac.textPrimary,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: destructive
          ? null
          : Icon(Icons.arrow_forward_ios_rounded,
              color: ac.textMuted, size: 14),
      onTap: onTap,
    );
  }
}
