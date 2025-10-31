import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Material Design 3 Color Scheme based on style_03.json
  // Primary colors (Blue-Purple theme - Elegant & Modern)
  static const Color primary = Color(0xFF555A92);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE0E0FF);
  static const Color onPrimaryContainer = Color(0xFF3D4278);
  
  // Secondary colors (Golden/Yellow theme)
  static const Color secondary = Color(0xFF6C5E10);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF6E388);
  static const Color onSecondaryContainer = Color(0xFF524700);
  
  // Tertiary colors (Teal/Cyan theme)
  static const Color tertiary = Color(0xFF046B5C);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFA0F2DF);
  static const Color onTertiaryContainer = Color(0xFF005045);
  
  // Error colors
  static const Color error = Color(0xFF904A47);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD7);
  static const Color onErrorContainer = Color(0xFF733331);
  
  // Background colors
  static const Color background = Color(0xFFFBF8FF);
  static const Color onBackground = Color(0xFF1B1B21);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF191C20);
  static const Color surfaceVariant = Color(0xFFDFE2EB);
  static const Color onSurfaceVariant = Color(0xFF43474E);
  
  // Outline colors
  static const Color outline = Color(0xFF73777F);
  static const Color outlineVariant = Color(0xFFC3C6CF);
  
  // Shadow and scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  
  // Surface container colors
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FA);
  static const Color surfaceContainer = Color(0xFFEDEDF4);
  static const Color surfaceContainerHigh = Color(0xFFE7E8EE);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E9);
  
  // Dark theme colors
  static const Color darkPrimary = Color(0xFFBEC2FF);
  static const Color darkOnPrimary = Color(0xFF272B60);
  static const Color darkPrimaryContainer = Color(0xFF3D4278);
  static const Color darkOnPrimaryContainer = Color(0xFFE0E0FF);
  
  static const Color darkSecondary = Color(0xFFD9C76F);
  static const Color darkOnSecondary = Color(0xFF393000);
  static const Color darkSecondaryContainer = Color(0xFF524700);
  static const Color darkOnSecondaryContainer = Color(0xFFF6E388);
  
  static const Color darkTertiary = Color(0xFF84D6C3);
  static const Color darkOnTertiary = Color(0xFF00382F);
  static const Color darkTertiaryContainer = Color(0xFF005045);
  static const Color darkOnTertiaryContainer = Color(0xFFA0F2DF);
  
  static const Color darkError = Color(0xFFFFB3AE);
  static const Color darkOnError = Color(0xFF571D1C);
  static const Color darkErrorContainer = Color(0xFF733331);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD7);
  
  static const Color darkBackground = Color(0xFF131318);
  static const Color darkOnBackground = Color(0xFFE4E1E9);
  static const Color darkSurface = Color(0xFF111318);
  static const Color darkOnSurface = Color(0xFFE1E2E9);
  static const Color darkSurfaceVariant = Color(0xFF43474E);
  static const Color darkOnSurfaceVariant = Color(0xFFC3C6CF);
  
  static const Color darkOutline = Color(0xFF8D9199);
  static const Color darkOutlineVariant = Color(0xFF43474E);
  
  static const Color darkSurfaceContainerLowest = Color(0xFF0C0E13);
  static const Color darkSurfaceContainerLow = Color(0xFF191C20);
  static const Color darkSurfaceContainer = Color(0xFF1D2024);
  static const Color darkSurfaceContainerHigh = Color(0xFF282A2F);
  static const Color darkSurfaceContainerHighest = Color(0xFF32353A);
  
  // Legacy color support
  static const Color primaryColor = primary;
  static const Color primaryLightColor = primaryContainer;
  static const Color primaryDarkColor = onPrimaryContainer;
  static const Color secondaryColor = secondary;
  static const Color accentColor = tertiary;
  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color errorColor = error;
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = tertiary;
  static const Color textPrimaryColor = onBackground;
  static const Color textSecondaryColor = onSurfaceVariant;
  static const Color textHintColor = outline;
  static const Color borderColor = outlineVariant;
  static const Color dividerColor = outlineVariant;
  static const Color inputFillColor = surfaceContainerLow;
  
  // Gradient colors for special elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceContainerLow],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme - Material Design 3
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        background: background,
        onBackground: onBackground,
        surface: surface,
        onSurface: onSurface,
        surfaceVariant: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        shadow: shadow,
        scrim: scrim,
        surfaceTint: primary,
        inverseSurface: Color(0xFF2E3035),
        onInverseSurface: Color(0xFFF0F0F7),
        inversePrimary: Color(0xFFBEC2FF),
      ),
      
      // App bar theme - Material Design 3
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLow,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: onSurface,
          size: 24.sp,
        ),
        actionsIconTheme: IconThemeData(
          color: onSurface,
          size: 24.sp,
        ),
      ),
      
      // Card theme - Material Design 3
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shadowColor: shadow.withOpacity(0.1),
        surfaceTintColor: primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: outlineVariant,
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Elevated button theme - 2025 Elegant Design
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shadowColor: primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),
      
      // Outlined button theme - 2025 Elegant Design
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),
      
      // Text button theme - 2025 Elegant Design
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(64.w, 40.h),
        ),
      ),
      
      // Input decoration theme - Material Design 3
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: TextStyle(
          color: onSurfaceVariant,
          fontSize: 16.sp,
        ),
        labelStyle: TextStyle(
          color: onSurfaceVariant,
          fontSize: 16.sp,
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontSize: 16.sp,
        ),
      ),
      
      // Text theme - Material Design 3 with Montserrat & Lato (2025 Elegant)
      textTheme: TextTheme(
        // Display styles - Montserrat for headlines (Reduced sizes for elegance)
        displayLarge: GoogleFonts.montserrat(
          fontSize: 42.sp,
          fontWeight: FontWeight.w300,
          color: onBackground,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 36.sp,
          fontWeight: FontWeight.w300,
          color: onBackground,
          letterSpacing: -0.25,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 28.sp,
          fontWeight: FontWeight.w400,
          color: onBackground,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: onBackground,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          color: onBackground,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0.1,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.montserrat(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        // Body styles - Lato for normal text
        bodyLarge: GoogleFonts.lato(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: onBackground,
          letterSpacing: 0.5,
          height: 1.50,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: onBackground,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        // Label styles - Lato for labels
        labelLarge: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: onBackground,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: GoogleFonts.lato(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: GoogleFonts.lato(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
      
      // Icon theme - Material Design 3
      iconTheme: IconThemeData(
        color: onSurfaceVariant,
        size: 24.sp,
      ),
      
      // Divider theme - Material Design 3
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: 1,
        indent: 16,
        endIndent: 16,
      ),
      
      // Bottom navigation bar theme - Material Design 3
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerHighest,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Floating action button theme - Material Design 3
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      
      // Chip theme - Material Design 3
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        selectedColor: primaryContainer,
        labelStyle: TextStyle(
          color: onSurface,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(color: outline),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        side: BorderSide(color: outline),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme - Material Design 3 Dark
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: darkPrimaryContainer,
        onPrimaryContainer: darkOnPrimaryContainer,
        secondary: darkSecondary,
        onSecondary: darkOnSecondary,
        secondaryContainer: darkSecondaryContainer,
        onSecondaryContainer: darkOnSecondaryContainer,
        tertiary: darkTertiary,
        onTertiary: darkOnTertiary,
        tertiaryContainer: darkTertiaryContainer,
        onTertiaryContainer: darkOnTertiaryContainer,
        error: darkError,
        onError: darkOnError,
        errorContainer: darkErrorContainer,
        onErrorContainer: darkOnErrorContainer,
        background: darkBackground,
        onBackground: darkOnBackground,
        surface: darkSurface,
        onSurface: darkOnSurface,
        surfaceVariant: darkSurfaceVariant,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        outlineVariant: darkOutlineVariant,
        shadow: shadow,
        scrim: scrim,
        surfaceTint: darkPrimary,
        inverseSurface: Color(0xFFE1E2E9),
        onInverseSurface: Color(0xFF2E3035),
        inversePrimary: Color(0xFF555A92),
      ),
      
      // App bar theme - Material Design 3 Dark
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceContainerLow,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: darkOnSurface,
          size: 24.sp,
        ),
        actionsIconTheme: IconThemeData(
          color: darkOnSurface,
          size: 24.sp,
        ),
      ),
      
      // Card theme - Material Design 3 Dark
      cardTheme: CardThemeData(
        color: darkSurfaceContainerLowest,
        elevation: 0,
        shadowColor: shadow.withOpacity(0.3),
        surfaceTintColor: darkPrimary.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: darkOutlineVariant,
            width: 0.5,
          ),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Elevated button theme - Dark
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: darkOnPrimary,
          elevation: 0,
          shadowColor: darkPrimary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),
      
      // Outlined button theme - Dark
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: BorderSide(color: darkPrimary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(double.infinity, 48.h),
        ),
      ),
      
      // Text button theme - Dark
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          textStyle: GoogleFonts.lato(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          minimumSize: Size(64.w, 40.h),
        ),
      ),
      
      // Input decoration theme - Dark
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.r),
          borderSide: BorderSide(color: darkError, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        hintStyle: TextStyle(
          color: darkOnSurfaceVariant,
          fontSize: 16.sp,
        ),
        labelStyle: TextStyle(
          color: darkOnSurfaceVariant,
          fontSize: 16.sp,
        ),
        floatingLabelStyle: TextStyle(
          color: darkPrimary,
          fontSize: 16.sp,
        ),
      ),
      
      // Text theme - Dark
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 42.sp,
          fontWeight: FontWeight.w300,
          color: darkOnBackground,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 36.sp,
          fontWeight: FontWeight.w300,
          color: darkOnBackground,
          letterSpacing: -0.25,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 28.sp,
          fontWeight: FontWeight.w400,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0.1,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.montserrat(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        bodyLarge: GoogleFonts.lato(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: darkOnBackground,
          letterSpacing: 0.5,
          height: 1.50,
        ),
        bodyMedium: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: darkOnBackground,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: GoogleFonts.lato(
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: darkOnSurfaceVariant,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        labelLarge: GoogleFonts.lato(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: darkOnBackground,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: GoogleFonts.lato(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceVariant,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: GoogleFonts.lato(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceVariant,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
      
      // Icon theme - Dark
      iconTheme: IconThemeData(
        color: darkOnSurfaceVariant,
        size: 24.sp,
      ),
      
      // Divider theme - Dark
      dividerTheme: DividerThemeData(
        color: darkOutlineVariant,
        thickness: 1,
        space: 1,
        indent: 16,
        endIndent: 16,
      ),
      
      // Bottom navigation bar theme - Dark
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceContainerHighest,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkOnSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Floating action button theme - Dark
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: darkOnPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      
      // Chip theme - Dark
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceContainerHigh,
        selectedColor: darkPrimaryContainer,
        labelStyle: TextStyle(
          color: darkOnSurface,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
          side: BorderSide(color: darkOutline),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        side: BorderSide(color: darkOutline),
      ),
    );
  }
}
