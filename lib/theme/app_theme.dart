import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MacLikePageTransitionBuilder extends PageTransitionsBuilder {
  const MacLikePageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    );
    final secondaryScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic),
    );

    return ScaleTransition(
      scale: secondaryScale,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }
}

class AppTheme {
  // Obsidian Neon Fintech Palette
  static const Color primaryMint = Color(0xFF00FFA3);
  static const Color secondaryEmerald = Color(0xFF10B981);
  static const Color tertiarySky = Color(0xFF38BDF8);
  static const Color neutralObsidian = Color(0xFF080B0F);
  static const Color surfaceCard = Color(0xFF121620);
  static const Color surfaceElevated = Color(0xFF181E2C);
  static const Color borderMetallic = Color(0xFF1E2536);
  static const Color borderHighlight = Color(0xFF283146);

  static const Color textPlatinum = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: neutralObsidian,
      colorScheme: const ColorScheme.dark(
        primary: primaryMint,
        secondary: secondaryEmerald,
        tertiary: tertiarySky,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPlatinum,
        outline: borderMetallic,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
        // Headlines -> Outfit
        headlineLarge: GoogleFonts.outfit(textStyle: baseTextTheme.headlineLarge?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        headlineMedium: GoogleFonts.outfit(textStyle: baseTextTheme.headlineMedium?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        headlineSmall: GoogleFonts.outfit(textStyle: baseTextTheme.headlineSmall?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleLarge: GoogleFonts.outfit(textStyle: baseTextTheme.titleLarge?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleMedium: GoogleFonts.outfit(textStyle: baseTextTheme.titleMedium?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleSmall: GoogleFonts.outfit(textStyle: baseTextTheme.titleSmall?.copyWith(color: textPlatinum, fontWeight: FontWeight.w600)),

        // Body -> Plus Jakarta Sans
        bodyLarge: GoogleFonts.plusJakartaSans(textStyle: baseTextTheme.bodyLarge?.copyWith(color: textPlatinum)),
        bodyMedium: GoogleFonts.plusJakartaSans(textStyle: baseTextTheme.bodyMedium?.copyWith(color: textPlatinum)),
        bodySmall: GoogleFonts.plusJakartaSans(textStyle: baseTextTheme.bodySmall?.copyWith(color: textMuted)),

        // Labels -> Space Grotesk
        labelLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.labelLarge?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        labelMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.labelMedium?.copyWith(color: textMuted, fontWeight: FontWeight.bold)),
        labelSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.labelSmall?.copyWith(color: textMuted)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: neutralObsidian,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPlatinum,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: textPlatinum),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderMetallic, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: MacLikePageTransitionBuilder(),
          TargetPlatform.iOS: MacLikePageTransitionBuilder(),
        },
      ),
    );
  }
}
