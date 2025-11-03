import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Material Design 3 Color Scheme - Style 06 Theme
  // Palette: Pink, Blue, Yellow-Green
  
  // Base colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF1F1F1F);
  
  // Light theme colors
  static const Color primary = Color(0xFF5A66D0);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE3E6FF);
  static const Color onPrimaryContainer = Color(0xFF1B2468);
  
  static const Color secondary = Color(0xFFC246A0);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFD9F1);
  static const Color onSecondaryContainer = Color(0xFF4E0F3B);
  
  static const Color tertiary = Color(0xFF779000);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFF2FFC2);
  static const Color onTertiaryContainer = Color(0xFF262E00);
  
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  
  static const Color background = Color(0xFFFFF7EE);
  static const Color onBackground = Color(0xFF1F1F1F);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F1F1F);
  static const Color surfaceVariant = Color(0xFFF2F2F2);
  static const Color onSurfaceVariant = Color(0xFF4D4D4D);
  
  static const Color outline = Color(0xFF8A8A8A);
  static const Color outlineVariant = Color(0xFFD3D3D3);
  
  static const Color shadow = Colors.black;
  static const Color scrim = Colors.black;
  
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFFBF7);
  static const Color surfaceContainer = Color(0xFFFFF9F4);
  static const Color surfaceContainerHigh = Color(0xFFFFF8F1);
  static const Color surfaceContainerHighest = Color(0xFFFFF7EE);
  
  // Dark theme colors
  // static const Color darkPrimary = Color(0xFF8100DB);
  static const Color darkPrimary = Color(0xFF6E33E6);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkPrimaryContainer = Color(0xFF6B00B5);
  static const Color darkOnPrimaryContainer = Color(0xFFF0D6FF);
  
  static const Color darkSecondary = Color(0xFFFF95DD);
  static const Color darkOnSecondary = Color(0xFF1F1F1F);
  static const Color darkSecondaryContainer = Color(0xFF7A3D66);
  static const Color darkOnSecondaryContainer = Color(0xFFFFE7F6);
  
  static const Color darkTertiary = Color(0xFFF6FF7F);
  static const Color darkOnTertiary = Color(0xFF1F1F1F);
  static const Color darkTertiaryContainer = Color(0xFF7E8538);
  static const Color darkOnTertiaryContainer = Color(0xFFFDFFDE);
  
  static const Color darkError = Color(0xFFB3261E);
  static const Color darkOnError = Color(0xFFFFFFFF);
  static const Color darkErrorContainer = Color(0xFF8C1D18);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  
  static const Color darkBackground = Color(0xFF10182C);
  static const Color darkOnBackground = Color(0xFFF5F5F5);
  static const Color darkSurface = Color(0xFF10182C);
  static const Color darkOnSurface = Color(0xFFF5F5F5);
  static const Color darkSurfaceVariant = Color(0xFF1C293D);
  static const Color darkOnSurfaceVariant = Color(0xFFC8C8C8);
  
  static const Color darkOutline = Color(0xFF8A8A8A);
  static const Color darkOutlineVariant = Color(0xFF5A5A5A);
  
  static const Color darkSurfaceContainerLowest = Color(0xFF0C1320);
  static const Color darkSurfaceContainerLow = Color(0xFF10182C);
  static const Color darkSurfaceContainer = Color(0xFF141D2F);
  static const Color darkSurfaceContainerHigh = Color(0xFF182235);
  static const Color darkSurfaceContainerHighest = Color(0xFF1C293D);
  
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
  static const Color successColor = Color(0xFF4CAF50);
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
        inverseSurface: darkGrey,
        onInverseSurface: white,
        inversePrimary: Color(0xFF4B83C3),
      ),
      
      // App bar theme - Material Design 3
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
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
      
      // Text theme - Material Design 3 with Outfit & Lato (2025 Elegant)
      textTheme: TextTheme(
        // Display styles - Outfit for headlines (Reduced sizes for elegance)
        displayLarge: GoogleFonts.outfit(
          fontSize: 42.sp,
          fontWeight: FontWeight.w300,
          color: onBackground,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 36.sp,
          fontWeight: FontWeight.w300,
          color: onBackground,
          letterSpacing: -0.25,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 28.sp,
          fontWeight: FontWeight.w400,
          color: onBackground,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: onBackground,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          color: onBackground,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: onBackground,
          letterSpacing: 0.1,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.outfit(
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
        backgroundColor: surface,
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
        inverseSurface: white,
        onInverseSurface: darkGrey,
        inversePrimary: Color(0xFFA4CEFF),
      ),
      
      // App bar theme - Material Design 3 Dark
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
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
        displayLarge: GoogleFonts.outfit(
          fontSize: 42.sp,
          fontWeight: FontWeight.w300,
          color: darkOnBackground,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 36.sp,
          fontWeight: FontWeight.w300,
          color: darkOnBackground,
          letterSpacing: -0.25,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 28.sp,
          fontWeight: FontWeight.w400,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24.sp,
          fontWeight: FontWeight.w500,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.35,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: darkOnBackground,
          letterSpacing: 0.1,
          height: 1.45,
        ),
        titleSmall: GoogleFonts.outfit(
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
        backgroundColor: darkSurface,
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
