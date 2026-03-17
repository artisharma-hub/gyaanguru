import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Static brand colors — identical in light and dark modes
// ═══════════════════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  // Primary — Saffron Orange
  static const primary      = Color(0xFFF04E23);
  static const primaryLight = Color(0xFFFF6B43);
  static const primaryDark  = Color(0xFFD03D14);

  // Accent — Electric Violet
  static const accent      = Color(0xFF7C5CFF);
  static const accentLight = Color(0xFF9E83FF);
  static const accentDark  = Color(0xFF5A3CE0);

  // Gold — Warm Amber
  static const gold      = Color(0xFFFFB020);
  static const goldLight = Color(0xFFFFCC60);
  static const goldDark  = Color(0xFFD9920A);

  // Feedback
  static const correctGreen = Color(0xFF00C48C);
  static const correctLight = Color(0xFF33D4A4);
  static const wrongRed     = Color(0xFFFF3B5C);
  static const wrongLight   = Color(0xFFFF6B85);

  // Timer
  static const timerSafe   = Color(0xFF0EA5E9);
  static const timerDanger = Color(0xFFFF3B5C);

  // Highlight
  static const highlight = Color(0xFFFF4DA8);

  // ── Light-mode static fallbacks ─────────────────────────────────────────
  // Used in `const` TextStyle/Widget contexts that can't take context.ac.
  // For adaptive (dark-mode-aware) colors, use context.ac.xxx instead.
  static const background     = Color(0xFFF8F9FF);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F1FF);
  static const surfaceBright  = Color(0xFFE5E7FF);
  static const textPrimary    = Color(0xFF0E0E24);
  static const textSecondary  = Color(0xFF55577A);
  static const textMuted      = Color(0xFF9698B8);
  static const border         = Color(0xFFE4E5FF);
  static const border2        = Color(0xFFCACAFF);

  // Category brand colors (same in both modes)
  static const cricket   = Color(0xFF0078D4);
  static const bollywood = Color(0xFFC51B7D);
  static const gk        = Color(0xFFD97706);
  static const math      = Color(0xFF7C3AED);
  static const science   = Color(0xFF0891B2);
  static const hindi     = Color(0xFF059669);

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

  static const LinearGradient fireGradient = LinearGradient(
    colors: [primaryDark, primary, Color(0xFFFF8C40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient categoryGradient(Color c) => LinearGradient(
        colors: [c, c.withValues(alpha: 0.72)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient categoryGradientRich(Color c) {
    final hsl = HSLColor.fromColor(c);
    return LinearGradient(
      colors: [
        hsl.withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0)).toColor(),
        c,
        hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Adaptive theme colors — switch between light and dark
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

  static const light = AppThemeColors(
    background:     Color(0xFFF8F9FF),
    surface:        Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F1FF),
    surfaceBright:  Color(0xFFE5E7FF),
    textPrimary:    Color(0xFF0E0E24),
    textSecondary:  Color(0xFF55577A),
    textMuted:      Color(0xFF9698B8),
    border:         Color(0xFFE4E5FF),
    border2:        Color(0xFFCACAFF),
  );

  static const dark = AppThemeColors(
    background:     Color(0xFF0C0C1D),
    surface:        Color(0xFF131328),
    surfaceVariant: Color(0xFF1B1B38),
    surfaceBright:  Color(0xFF232348),
    textPrimary:    Color(0xFFEAEAFF),
    textSecondary:  Color(0xFF8889BB),
    textMuted:      Color(0xFF5A5B7E),
    border:         Color(0xFF1E1E40),
    border2:        Color(0xFF28284E),
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
  final isDark = context.isDark;
  return BoxDecoration(
    color: ac.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? ac.border, width: 1.0),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.05),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

BoxDecoration glowCard({required Color color, double radius = 20}) => BoxDecoration(
      gradient: AppColors.categoryGradientRich(color),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.40), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 6)),
        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 12)),
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
          primaryContainer:        Color(0xFFFFDDD5),
          onPrimaryContainer:      AppColors.primaryDark,
          secondary:               AppColors.accent,
          onSecondary:             Colors.white,
          secondaryContainer:      Color(0xFFEAE5FF),
          onSecondaryContainer:    AppColors.accentDark,
          tertiary:                AppColors.gold,
          onTertiary:              Colors.white,
          surface:                 Color(0xFFFFFFFF),
          onSurface:               Color(0xFF0E0E24),
          surfaceContainerHighest: Color(0xFFF0F1FF),
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
          primary:                 AppColors.primaryLight,
          onPrimary:               Colors.white,
          primaryContainer:        Color(0xFF5A1A08),
          onPrimaryContainer:      AppColors.primaryLight,
          secondary:               AppColors.accentLight,
          onSecondary:             Colors.white,
          secondaryContainer:      Color(0xFF2A1A60),
          onSecondaryContainer:    AppColors.accentLight,
          tertiary:                AppColors.goldLight,
          onTertiary:              Color(0xFF3A2600),
          surface:                 Color(0xFF131328),
          onSurface:               Color(0xFFEAEAFF),
          surfaceContainerHighest: Color(0xFF1B1B38),
          outline:                 Color(0xFF1E1E40),
          outlineVariant:          Color(0xFF28284E),
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

      textTheme: GoogleFonts.poppinsTextTheme(TextTheme(
        displayLarge:   TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 36, letterSpacing: -1.0, height: 1.1),
        displayMedium:  TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: -0.8, height: 1.15),
        headlineLarge:  TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 26, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.3),
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
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rLg)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
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
        labelStyle: GoogleFonts.poppins(color: colors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle:  GoogleFonts.poppins(color: colors.textMuted,      fontWeight: FontWeight.w400, fontSize: 14),
        errorStyle: GoogleFonts.poppins(color: AppColors.wrongRed,    fontWeight: FontWeight.w500, fontSize: 12),
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
        titleTextStyle: GoogleFonts.poppins(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.2,
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
        labelStyle:           GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceBright : const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
        titleTextStyle:   GoogleFonts.poppins(color: colors.textPrimary,   fontWeight: FontWeight.w700, fontSize: 18),
        contentTextStyle: GoogleFonts.poppins(color: colors.textSecondary, fontWeight: FontWeight.w400, fontSize: 14),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : colors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.35)
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
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.rPill)),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
