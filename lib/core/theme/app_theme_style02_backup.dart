import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Material Design 3 Color Scheme based on style_02.json
  // Primary colors (Purple theme - Elegant & Modern)
  static const Color primary = Color(0xFF5A5892);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE2DFFF);
  static const Color onPrimaryContainer = Color(0xFF424178);
  
  // Secondary colors
  static const Color secondary = Color(0xFF5E5C71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE3E0F9);
  static const Color onSecondaryContainer = Color(0xFF464559);
  
  // Tertiary colors
  static const Color tertiary = Color(0xFF7A5368);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8EA);
  static const Color onTertiaryContainer = Color(0xFF603C50);
  
  // Error colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  // Background colors
  static const Color background = Color(0xFFFCF8FF);
  static const Color onBackground = Color(0xFF1B1B21);
  static const Color surface = Color(0xFFFCF8FF);
  static const Color onSurface = Color(0xFF1B1B21);
  static const Color surfaceVariant = Color(0xFFE4E1EC);
  static const Color onSurfaceVariant = Color(0xFF47464F);
  
  // Outline colors
  static const Color outline = Color(0xFF787680);
  static const Color outlineVariant = Color(0xFFC8C5D0);
  
  // Shadow and scrim
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  
  // Surface container colors
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F2FA);
  static const Color surfaceContainer = Color(0xFFF0ECF4);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EF);
  static const Color surfaceContainerHighest = Color(0xFFE5E1E9);
  
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
        inverseSurface: Color(0xFF2F312A),
        onInverseSurface: Color(0xFFF1F2E6),
        inversePrimary: Color(0xFFB1D18A),
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
}
