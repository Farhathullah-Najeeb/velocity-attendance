import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'velocity_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VelocityColors.primaryRed,
        primary: VelocityColors.primaryRed,
        secondary: VelocityColors.secondaryBlack,
        surface: VelocityColors.baseWhite,
        error: VelocityColors.danger,
        onPrimary: VelocityColors.baseWhite,
        onSecondary: VelocityColors.baseWhite,
        onSurface: VelocityColors.textPrimary,
        onError: VelocityColors.baseWhite,
      ),
      scaffoldBackgroundColor: VelocityColors.background,

      // Typography
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: VelocityColors.textPrimary,
          letterSpacing: -0.8,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: VelocityColors.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textPrimary,
          letterSpacing: -0.3,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: VelocityColors.textPrimary,
          letterSpacing: -0.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textPrimary,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: VelocityColors.textPrimary,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: VelocityColors.textSecondary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: VelocityColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: VelocityColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: VelocityColors.textSubtle,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textPrimary,
          letterSpacing: 0.2,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textSecondary,
          letterSpacing: 0.5,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: VelocityColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: VelocityColors.baseWhite,
        foregroundColor: VelocityColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: VelocityColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: VelocityColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Buttons with Rounded 14-16px Corners and Velocity Red Gradient
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VelocityColors.primaryRed,
          foregroundColor: VelocityColors.baseWhite,
          disabledBackgroundColor: VelocityColors.divider,
          disabledForegroundColor: VelocityColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VelocityColors.textPrimary,
          backgroundColor: VelocityColors.baseWhite,
          side: const BorderSide(color: VelocityColors.borderStrong, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VelocityColors.primaryRed,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: VelocityColors.baseWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: VelocityColors.border, width: 1.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),

      // Forms & Inputs with 14px rounded corners
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VelocityColors.baseWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: VelocityColors.textSecondary, fontSize: 13.5),
        hintStyle: const TextStyle(color: VelocityColors.textMuted, fontSize: 13.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VelocityColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VelocityColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VelocityColors.primaryRed, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VelocityColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: VelocityColors.danger, width: 1.8),
        ),
        errorStyle: const TextStyle(color: VelocityColors.danger, fontSize: 11.5),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VelocityColors.border, width: 1.2),
        ),
        elevation: 12,
        backgroundColor: VelocityColors.baseWhite,
        titleTextStyle: GoogleFonts.inter(
          color: VelocityColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),

      // Navigation Bar (BottomNav)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VelocityColors.baseWhite,
        indicatorColor: VelocityColors.primaryRedLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: VelocityColors.primaryRed,
            );
          }
          return GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: VelocityColors.textSubtle,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: VelocityColors.primaryRed, size: 22);
          }
          return const IconThemeData(color: VelocityColors.textSubtle, size: 22);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: VelocityColors.surfaceAlt,
        disabledColor: VelocityColors.background,
        selectedColor: VelocityColors.primaryRedLight,
        secondarySelectedColor: VelocityColors.primaryRed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: const TextStyle(
          color: VelocityColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: VelocityColors.primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VelocityColors.border),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: VelocityColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VelocityColors.primaryRed,
        brightness: Brightness.dark,
        primary: VelocityColors.primaryRed,
        secondary: VelocityColors.secondaryBlack,
        surface: const Color(0xFF141A28),
        error: VelocityColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0D14),
      textTheme: baseTextTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF141A28),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
    );
  }
}
