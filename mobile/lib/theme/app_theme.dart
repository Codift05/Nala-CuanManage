import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color primaryColor = Color(0xFFF5961A);
  static const Color secondaryColor = Color(0xFFDB1E09);
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F6);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111318);
  static const Color textSecondary = Color(0xFF747B87);

  static const Color errorColor = secondaryColor;
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9F0A);
  static const Color infoColor = Color(0xFFF5961A);
  static const Color neutralColor = Color(0xFFE5E7EB);

  static const double cardRadius = 16;
  static const double controlRadius = 14;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      surface: surfaceColor,
      error: errorColor,
    );
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      colorScheme: colorScheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: borderColor,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        iconTheme: const IconThemeData(color: textPrimary, size: 23),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF9AA0AA),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFD6DAE1),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          elevation: 0,
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          highlightColor: surfaceMuted,
          shape: const CircleBorder(),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        modalBackgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: Color(0xFFD1D5DB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceMuted,
        circularTrackColor: surfaceMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEAF2FF),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
