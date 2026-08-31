import 'package:flutter/material.dart';

/// Velocity Design Tokens: 60% Red, 40% Black/Dark Obsidian
class VelocityColors {
  // 60% Red Foundation (Vibrant Crimson & Scarlet Gradients)
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryRedDark = Color(0xFFC62828);
  static const Color primaryRedLight = Color(0x1FE53935); // 12% Red
  static const Color primaryRedBorder = Color(0x40E53935); // 25% Red
  static const Color primaryRedHover = Color(0xFFD32F2F);
  static const Color primaryRedBright = Color(0xFFEF4444);

  // 40% Black & Deep Obsidian Slate Foundation
  static const Color secondaryBlack = Color(0xFF0F172A);
  static const Color obsidianBlack = Color(0xFF0A0D14);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF141A28);
  static const Color darkBorder = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redAccentGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redFireGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkNavyGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkObsidianGradient = LinearGradient(
    colors: [Color(0xFF0A0D14), Color(0xFF141A28)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backgrounds & Neutrals
  static const Color baseWhite = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundAlt = Color(0xFFF1F5F9);
  static const Color surfaceAlt = Color(0xFFF8FAFC);
  static const Color surfaceHover = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Status & Utility Accents
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0x1A10B981);
  static const Color successBorder = Color(0x3310B981);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0x1ADC2626);
  static const Color dangerBorder = Color(0x33DC2626);
  static const Color error = Color(0xFFDC2626);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0x1AF59E0B);
  static const Color warningBorder = Color(0x33F59E0B);
  static const Color accentGold = Color(0xFFF59E0B);

  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0x1A2563EB);
  static const Color infoBorder = Color(0x332563EB);

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0x1A7C3AED);
  static const Color purpleBorder = Color(0x337C3AED);

  // Box Shadows
  static List<BoxShadow> get redGlowShadow => [
        BoxShadow(
          color: primaryRed.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get darkGlowShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
