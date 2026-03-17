import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Static brand colors — Soft Dark Neon theme
// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // Primary — Electric Violet
  static const primary      = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B84FF);
  static const primaryDark  = Color(0xFF4A42CC);

  // Accent — Neon Cyan
  static const accent      = Color(0xFF00D4FF);
  static const accentLight = Color(0xFF4DE0FF);
  static const accentDark  = Color(0xFF00A8CC);

  // Gold — Warm Amber
  static const gold      = Color(0xFFF5A623);
  static const goldLight = Color(0xFFFFCC60);
  static const goldDark  = Color(0xFFD98C00);

  // Feedback
  static const correctGreen = Color(0xFF2ECC71);
  static const correctLight = Color(0xFF55D98D);
  static const wrongRed     = Color(0xFFE74C3C);
  static const wrongLight   = Color(0xFFFF6B5E);

  // Timer
  static const timerSafe   = Color(0xFF2ECC71);
  static const timerDanger = Color(0xFFE74C3C);

  // Highlight / Hot Pink
  static const highlight = Color(0xFFFF4DA8);

  // ── Soft Dark Neon static values (used in const contexts) ─────────────
  static const background     = Color(0xFF15172E);
  static const surface        = Color(0xFF1C1F3A);
  static const surfaceVariant = Color(0xFF20244A);
  static const surfaceBright  = Color(0xFF282C58);
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFA0A3C0);
  static const textMuted      = Color(0xFF6A6D8E);
  static const border         = Color(0xFF252848);
  static const border2        = Color(0xFF2F3360);

  // Category brand colors
  static const cricket   = Color(0xFF00B4FF);
  static const bollywood = Color(0xFFFF4DA8);
  static const gk        = Color(0xFFF5A623);
  static const math      = Color(0xFF6C63FF);
  static const science   = Color(0xFF2ECC71);
  static const hindi     = Color(0xFF00D4FF);

  // ── Gradient helpers ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentDark, accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldDark, gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [primaryDark, primary, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft background gradient for screens
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF15172E), Color(0xFF1A1D38)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient categoryGradient(Color c) => LinearGradient(
        colors: [c.withValues(alpha: 0.85), c.withValues(alpha: 0.50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient categoryGradientRich(Color c) {
    final hsl = HSLColor.fromColor(c);
    return LinearGradient(
      colors: [
        hsl.withLightness((hsl.lightness - 0.10).clamp(0.0, 1.0)).toColor(),
        c,
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Soft neon glow shadows ───────────────────────────────────────────────
  static List<BoxShadow> softGlow(Color color, {double blur = 16, double spread = 0}) => [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: blur, spreadRadius: spread),
        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: blur * 2.0, spreadRadius: spread),
      ];

  static List<BoxShadow> primaryGlow({double blur = 18}) => softGlow(primary, blur: blur);
  static List<BoxShadow> correctGlow({double blur = 18}) => softGlow(correctGreen, blur: blur);
  static List<BoxShadow> wrongGlow({double blur = 18})   => softGlow(wrongRed, blur: blur);
  static List<BoxShadow> goldGlowShadow({double blur = 18}) => softGlow(gold, blur: blur);

  // Legacy alias
  static List<BoxShadow> neonGlow(Color color, {double blur = 16, double spread = 0}) =>
      softGlow(color, blur: blur, spread: spread);
}

// ═══════════════════════════════════════════════════════════════════════════
// Adaptive theme colors
// ═══════════════════════════════════════════════════════════════════════════
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceBright;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color border2;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceBright,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.border2,
  });

  // Light mode (kept for completeness)
  static const light = AppThemeColors(
    background:     Color(0xFFF4F5FF),
    surface:        Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEEFFF),
    surfaceBright:  Color(0xFFE3E4FF),
    textPrimary:    Color(0xFF0E0E24),
    textSecondary:  Color(0xFF55577A),
    textMuted:      Color(0xFF9698B8),
    border:         Color(0xFFE4E5FF),
    border2:        Color(0xFFCACAFF),
  );

  // Soft Dark Neon — primary theme
  static const dark = AppThemeColors(
    background:     Color(0xFF15172E),
    surface:        Color(0xFF1C1F3A),
    surfaceVariant: Color(0xFF20244A),
    surfaceBright:  Color(0xFF282C58),
    textPrimary:    Color(0xFFFFFFFF),
    textSecondary:  Color(0xFFA0A3C0),
    textMuted:      Color(0xFF6A6D8E),
    border:         Color(0xFF252848),
    border2:        Color(0xFF2F3360),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceBright,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? border2,
  }) =>
      AppThemeColors(
        background:     background     ?? this.background,
        surface:        surface        ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        surfaceBright:  surfaceBright  ?? this.surfaceBright,
        textPrimary:    textPrimary    ?? this.textPrimary,
        textSecondary:  textSecondary  ?? this.textSecondary,
        textMuted:      textMuted      ?? this.textMuted,
        border:         border         ?? this.border,
        border2:        border2        ?? this.border2,
      );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background:     Color.lerp(background,     other.background,     t)!,
      surface:        Color.lerp(surface,        other.surface,        t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceBright:  Color.lerp(surfaceBright,  other.surfaceBright,  t)!,
      textPrimary:    Color.lerp(textPrimary,    other.textPrimary,    t)!,
      textSecondary:  Color.lerp(textSecondary,  other.textSecondary,  t)!,
      textMuted:      Color.lerp(textMuted,      other.textMuted,      t)!,
      border:         Color.lerp(border,         other.border,         t)!,
      border2:        Color.lerp(border2,        other.border2,        t)!,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BuildContext helpers
// ═══════════════════════════════════════════════════════════════════════════
extension AppThemeX on BuildContext {
  AppThemeColors get ac => Theme.of(this).extension<AppThemeColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

// ═══════════════════════════════════════════════════════════════════════════
// Responsive size helpers
// ═══════════════════════════════════════════════════════════════════════════
class AppSizes {
  AppSizes._();

  static double sp(BuildContext context, double size) {
    final w = MediaQuery.sizeOf(context).width;
    return size * (w / 375.0).clamp(0.85, 1.25);
  }

  static double hp(BuildContext context, double size) {
    final h = MediaQuery.sizeOf(context).height;
    return size * (h / 812.0).clamp(0.85, 1.25);
  }

  static double hPad(BuildContext context) => sp(context, 20);

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  static const double rSm   = 8.0;
  static const double rMd   = 12.0;
  static const double rLg   = 16.0;
  static const double rXl   = 20.0;
  static const double rXxl  = 24.0;
  static const double rPill = 100.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// Decoration helpers (context-aware)
// ═══════════════════════════════════════════════════════════════════════════
BoxDecoration glassCard(BuildContext context, {double radius = 20, Color? borderColor}) {
  final ac = context.ac;
  return BoxDecoration(
    color: ac.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? ac.border, width: 1.0),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.07),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// Soft neon-bordered card — subtle glow, no harsh contrast
BoxDecoration neonCard({required Color color, double radius = 20, Color? bg}) => BoxDecoration(
      color: bg ?? AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.40), width: 1.5),
      boxShadow: AppColors.softGlow(color, blur: 14),
    );

/// Gradient category card with soft glow
BoxDecoration glowCard({required Color color, double radius = 20}) => BoxDecoration(
      gradient: AppColors.categoryGradientRich(color),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 6)),
        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 10)),
      ],
    );

// ═══════════════════════════════════════════════════════════════════════════
// AppTheme
// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        colors: AppThemeColors.light,
        scheme: const ColorScheme.light(
          primary:                 AppColors.primary,
          onPrimary:               Colors.white,
          primaryContainer:        Color(0xFFE8E6FF),
          onPrimaryContainer:      AppColors.primaryDark,
          secondary:               AppColors.accent,
          onSecondary:             Colors.white,
          tertiary:                AppColors.gold,
          onTertiary:              Colors.white,
          surface:                 Color(0xFFFFFFFF),
          onSurface:               Color(0xFF0E0E24),
          surfaceContainerHighest: Color(0xFFEEEFFF),
          outline:                 Color(0xFFE4E5FF),
          outlineVariant:          Color(0xFFCACAFF),
          error:                   AppColors.wrongRed,
          onError:                 Colors.white,
        ),
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        colors: AppThemeColors.dark,
        scheme: const ColorScheme.dark(
          primary:                 AppColors.primary,
          onPrimary:               Colors.white,
          primaryContainer:        Color(0xFF20204A),
          onPrimaryContainer:      AppColors.primaryLight,
          secondary:               AppColors.accent,
          onSecondary:             Color(0xFF15172E),
          secondaryContainer:      Color(0xFF00334A),
          onSecondaryContainer:    AppColors.accentLight,
          tertiary:                AppColors.gold,
          onTertiary:              Color(0xFF1A0E00),
          surface:                 Color(0xFF1C1F3A),
          onSurface:               Color(0xFFFFFFFF),
          surfaceContainerHighest: Color(0xFF20244A),
          outline:                 Color(0xFF252848),
          outlineVariant:          Color(0xFF2F3360),
          error:                   AppColors.wrongRed,
          onError:                 Colors.white,
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppThemeColors colors,
    required ColorScheme scheme,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],

      textTheme: GoogleFonts.nunitoTextTheme(TextTheme(
        displayLarge:   TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 36, letterSpacing: -0.5, height: 1.1),
        displayMedium:  TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.3, height: 1.15),
        headlineLarge:  TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 26),
        headlineMedium: TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 22),
        headlineSmall:  TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 18),
        titleLarge:     TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium:    TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.1),
        titleSmall:     TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
        bodyLarge:      TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w500, fontSize: 16, height: 1.5),
        bodyMedium:     TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
        bodySmall:      TextStyle(color: colors.textMuted,     fontWeight: FontWeight.w400, fontSize: 12, height: 1.5),
        labelLarge:     TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3),
        labelMedium:    TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.2),
        labelSmall:     TextStyle(color: colors.textMuted,     fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5),
      )),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rLg)),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rLg)),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),

      cardTheme: CardThemeData(
        color: colors.surface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.rXxl),
          side: BorderSide(color: colors.border, width: 1),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          borderSide: BorderSide(color: colors.border2, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          borderSide: BorderSide(color: colors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          borderSide: const BorderSide(color: AppColors.wrongRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rLg),
          borderSide: const BorderSide(color: AppColors.wrongRed, width: 2),
        ),
        labelStyle: GoogleFonts.nunito(color: colors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14),
        hintStyle:  GoogleFonts.nunito(color: colors.textMuted,      fontWeight: FontWeight.w500, fontSize: 14),
        errorStyle: GoogleFonts.nunito(color: AppColors.wrongRed,    fontWeight: FontWeight.w600, fontSize: 12),
        prefixIconColor: AppColors.primaryLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
        titleTextStyle: GoogleFonts.nunito(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: colors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: Colors.transparent,
        labelStyle:           GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceBright : const Color(0xFF1A1D38),
        contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rLg)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      dividerTheme: DividerThemeData(color: colors.border, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rXxl + 4)),
        elevation: 8,
        titleTextStyle:   GoogleFonts.nunito(color: colors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 18),
        contentTextStyle: GoogleFonts.nunito(color: colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.38)
              : colors.surfaceVariant,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primary),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rPill)),
        labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
