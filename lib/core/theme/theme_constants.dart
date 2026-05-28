import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF0A84FF); // azul vibrante
  static const Color primaryVariant = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF5AC8FA); // cian claro
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFFF3B30);
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Colors.black;
  static const Color onSurface = Colors.black;
  static const Color onError = Colors.white;
}

class AppTextStyles {
  static TextStyle headline1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );
  static TextStyle headline2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.onBackground,
  );
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
  );
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
  ];
}
