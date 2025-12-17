import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Discord-inspired color palette with WhatsApp-like feel
class AppColors {
  // Primary Discord colors
  static const Color blurple = Color(0xFF5865F2);
  static const Color blurpleDark = Color(0xFF4752C4);
  static const Color blurpleLight = Color(0xFF7289DA);

  // Background colors (Discord dark theme)
  static const Color backgroundDark = Color(0xFF202225);
  static const Color backgroundMedium = Color(0xFF2F3136);
  static const Color backgroundLight = Color(0xFF36393F);
  static const Color backgroundLighter = Color(0xFF40444B);
  static const Color backgroundHover = Color(0xFF32353B);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFDCDDDE);
  static const Color textMuted = Color(0xFF96989D);
  static const Color textDark = Color(0xFF72767D);

  // Status colors
  static const Color online = Color(0xFF43B581);
  static const Color idle = Color(0xFFFAA61A);
  static const Color dnd = Color(0xFFED4245);
  static const Color offline = Color(0xFF747F8D);

  // Accent colors
  static const Color success = Color(0xFF57F287);
  static const Color warning = Color(0xFFFEE75C);
  static const Color error = Color(0xFFED4245);
  static const Color pink = Color(0xFFEB459E);

  // Message bubble colors
  static const Color myMessageBubble = Color(0xFF5865F2);
  static const Color otherMessageBubble = Color(0xFF40444B);

  // Gradient for special effects
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [blurple, Color(0xFF7289DA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF5865F2), Color(0xFFEB459E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Custom typography inspired by Discord's clean look
class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

/// Animation durations and curves
class AppAnimations {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve snappyCurve = Curves.easeOutBack;
  static const Curve gentleCurve = Curves.easeOut;
}

/// Main app theme
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.blurple,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blurple,
        secondary: AppColors.blurpleLight,
        surface: AppColors.backgroundMedium,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textSecondary,
        onError: AppColors.textPrimary,
      ),

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundMedium,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: IconThemeData(color: AppColors.textMuted),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundMedium,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundLight,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: AppTypography.headlineLarge,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundMedium,
        modalBackgroundColor: AppColors.backgroundMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLighter,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDark),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blurple,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTypography.titleMedium,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blurple,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.titleMedium,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.textMuted, size: 24),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blurple,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        contentTextStyle: AppTypography.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.backgroundDark,
        thickness: 1,
        space: 1,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minLeadingWidth: 24,
        iconColor: AppColors.textMuted,
        textColor: AppColors.textSecondary,
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.backgroundMedium,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: AppTypography.bodyMedium,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blurple,
        linearTrackColor: AppColors.backgroundLighter,
        circularTrackColor: AppColors.backgroundLighter,
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
