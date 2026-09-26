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
  // Metro Pulse Design System Palette
  static const Color primaryBlue = Color(0xFF0078D7);
  static const Color secondaryGreen = Color(0xFF008A00);
  static const Color tertiaryAmber = Color(0xFFF09609);
  static const Color neutralObsidian = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1E1E1E);
  static const Color surfaceElevated = Color(0xFF262626);
  static const Color borderMetallic = Color(0xFF2D2D2D);
  static const Color borderHighlight = Color(0xFF383838);

  static const Color textPlatinum = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFFA0A0A0);

  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: neutralObsidian,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryGreen,
        tertiary: tertiaryAmber,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPlatinum,
        outline: borderMetallic,
      ),
      textTheme: GoogleFonts.workSansTextTheme(baseTextTheme).copyWith(
        // Headlines -> Space Grotesk
        headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineLarge?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        headlineMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineMedium?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.headlineSmall?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleLarge?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleMedium: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleMedium?.copyWith(color: textPlatinum, fontWeight: FontWeight.bold)),
        titleSmall: GoogleFonts.spaceGrotesk(textStyle: baseTextTheme.titleSmall?.copyWith(color: textPlatinum, fontWeight: FontWeight.w600)),

        // Body -> Work Sans
        bodyLarge: GoogleFonts.workSans(textStyle: baseTextTheme.bodyLarge?.copyWith(color: textPlatinum)),
        bodyMedium: GoogleFonts.workSans(textStyle: baseTextTheme.bodyMedium?.copyWith(color: textPlatinum)),
        bodySmall: GoogleFonts.workSans(textStyle: baseTextTheme.bodySmall?.copyWith(color: textMuted)),

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
        titleTextStyle: GoogleFonts.spaceGrotesk(
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
