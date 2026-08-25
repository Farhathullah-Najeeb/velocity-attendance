import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'velocity_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: VelocityColors.primaryRed,
        primary: VelocityColors.primaryRed,
        secondary: VelocityColors.secondaryBlack,
        surface: VelocityColors.baseWhite,
        error: VelocityColors.error,
        onPrimary: VelocityColors.baseWhite,
        onSecondary: VelocityColors.baseWhite,
        onSurface: VelocityColors.secondaryBlack,
        onError: VelocityColors.baseWhite,
      ),
      scaffoldBackgroundColor: VelocityColors.background,
      
      // Typography (Scaled down per Bug 4)
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 53, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 42, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: 33, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontSize: 29, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: VelocityColors.secondaryBlack),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: VelocityColors.secondaryBlack),
        titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: VelocityColors.secondaryBlack),
        titleSmall: baseTextTheme.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: VelocityColors.secondaryBlack),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: VelocityColors.secondaryBlack),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: VelocityColors.secondaryBlack),
        bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, color: VelocityColors.textDark),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: VelocityColors.secondaryBlack),
        labelMedium: baseTextTheme.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: VelocityColors.secondaryBlack),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: VelocityColors.textSecondary),
      ),

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: VelocityColors.baseWhite,
        foregroundColor: VelocityColors.secondaryBlack,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: VelocityColors.secondaryBlack),
        titleTextStyle: GoogleFonts.inter(
          color: VelocityColors.secondaryBlack,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VelocityColors.primaryRed,
          foregroundColor: VelocityColors.baseWhite,
          disabledBackgroundColor: VelocityColors.divider,
          disabledForegroundColor: VelocityColors.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48), // 48px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VelocityColors.primaryRed,
          backgroundColor: VelocityColors.baseWhite,
          side: const BorderSide(color: VelocityColors.primaryRed, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(64, 48), // 48px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VelocityColors.secondaryBlack,
          minimumSize: const Size(64, 48), // 48px touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: VelocityColors.baseWhite,
        elevation: 2,
        shadowColor: VelocityColors.secondaryBlack.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: VelocityColors.surfaceLight),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // Forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VelocityColors.baseWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: VelocityColors.secondaryBlack),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VelocityColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VelocityColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VelocityColors.primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VelocityColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: VelocityColors.error, width: 2),
        ),
        errorStyle: const TextStyle(color: VelocityColors.error),
      ),

      // Dialogs
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        elevation: 12,
        backgroundColor: VelocityColors.baseWhite,
      ),

      // Navigation Bar (BottomNav)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VelocityColors.baseWhite,
        indicatorColor: VelocityColors.baseWhite, // We will use custom indicator logic (red pill/dot)
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: VelocityColors.primaryRed);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: VelocityColors.textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: VelocityColors.primaryRed, size: 24);
          }
          return const IconThemeData(color: VelocityColors.textSecondary, size: 24);
        }),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: VelocityColors.surfaceLight,
        disabledColor: VelocityColors.background,
        selectedColor: VelocityColors.primaryRed.withValues(alpha: 0.1),
        secondarySelectedColor: VelocityColors.primaryRed,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(color: VelocityColors.secondaryBlack),
        secondaryLabelStyle: const TextStyle(color: VelocityColors.primaryRed),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: VelocityColors.surfaceLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
