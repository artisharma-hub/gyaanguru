import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Backgrounds — clean light ─────────────────────────────────────────────
  static const background     = Color(0xFFF5F7FD);  // soft cool white
  static const surface        = Color(0xFFFFFFFF);  // pure white cards
  static const surfaceVariant = Color(0xFFEDF0FA);  // light blue-grey
  static const surfaceBright  = Color(0xFFE6EAFF);  // slightly deeper

  // ── Primary — Vivid Orange-Red ────────────────────────────────────────────
  static const primary      = Color(0xFFFF4500);
  static const primaryLight = Color(0xFFFF6B35);

  // ── Accent — Cerulean Blue ────────────────────────────────────────────────
  static const accent     = Color(0xFF0088CC);
  static const accentDark = Color(0xFF0066AA);

  // ── Highlight — Deep Magenta ──────────────────────────────────────────────
  static const highlight = Color(0xFFD60075);

  // ── Gold — Amber ──────────────────────────────────────────────────────────
  static const gold      = Color(0xFFD97706);
  static const goldLight = Color(0xFFF59E0B);

  // ── Feedback ──────────────────────────────────────────────────────────────
  static const correctGreen = Color(0xFF16A34A);
  static const wrongRed     = Color(0xFFDC2626);

  // ── Timer ─────────────────────────────────────────────────────────────────
  static const timerSafe   = Color(0xFF0088CC);
  static const timerDanger = Color(0xFFDC2626);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0D1121);
  static const textSecondary = Color(0xFF5A6480);
  static const textMuted     = Color(0xFF8F97B2);

  // ── Borders ───────────────────────────────────────────────────────────────
  static const border  = Color(0xFFDDE2EF);
  static const border2 = Color(0xFFCDD4E6);

  // ── Category — vivid, readable on white ───────────────────────────────────
  static const cricket   = Color(0xFF0078D4);
  static const bollywood = Color(0xFFD6006E);
  static const gk        = Color(0xFFD97706);
  static const math      = Color(0xFF7C3AED);
  static const science   = Color(0xFF0891B2);
  static const hindi     = Color(0xFF059669);

  // ── Gradient helpers ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFCC3700), primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentDark, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB45309), gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFCC3700), primary, Color(0xFFFF7C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient categoryGradient(Color c) => LinearGradient(
    colors: [c.withValues(alpha: 0.80), c],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Responsive size helper ────────────────────────────────────────────────────
class AppSizes {
  /// Scales [size] proportionally to screen width (baseline 375 px — iPhone SE).
  static double sp(BuildContext context, double size) {
    final w = MediaQuery.sizeOf(context).width;
    return size * (w / 375.0).clamp(0.85, 1.25);
  }

  /// Scales [size] proportionally to screen height (baseline 812 px).
  static double hp(BuildContext context, double size) {
    final h = MediaQuery.sizeOf(context).height;
    return size * (h / 812.0).clamp(0.85, 1.25);
  }

  /// Responsive horizontal page padding.
  static double hPad(BuildContext context) => sp(context, 20);
}

// ── Glass card decoration ─────────────────────────────────────────────────────
BoxDecoration glassCard({
  Color borderColor = AppColors.border,
  double radius = 20,
  Color bg = AppColors.surface,
}) =>
    BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ── Glow card decoration ──────────────────────────────────────────────────────
BoxDecoration glowCard({required Color color, double radius = 20}) =>
    BoxDecoration(
      gradient: AppColors.categoryGradient(color),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
    );

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      surface: AppColors.surface,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      secondary: AppColors.accent,
      tertiary: AppColors.gold,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      const TextTheme(
        displayLarge:   TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 24),
        titleLarge:     TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 18),
        bodyLarge:      TextStyle(color: AppColors.textPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        bodyMedium:     TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w400, fontSize: 14),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border2, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border2, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.wrongRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.wrongRed, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle:  const TextStyle(color: AppColors.textMuted),
      errorStyle: const TextStyle(color: AppColors.wrongRed, fontSize: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      dividerColor: Colors.transparent,
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: 0.35)
            : AppColors.surfaceVariant,
      ),
    ),
  );
}
