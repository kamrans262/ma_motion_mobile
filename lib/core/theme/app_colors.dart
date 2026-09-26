import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF9A5BFF);
  static const Color splashBackground = Color(0xFF0B1A12);
  static const Color splashDot = Color(0xFF4F378C);
  static const Color artworkBackground = Color(0xFF020101);
  static const Color savedBackground = Color(0xFF0F2519);
  static const Color artworkNavBackground = Color(0xFF0B1A12);

  static const Color inputFill = Color(0xFF1C2830);
  static const Color filterInputFill = Color(0xFF0E071A);
  static const Color mutedText = Color(0xFFA3A3A3);
  static const Color darkGray = Color(0xFF686868);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFFF6B6B);

  static Color get primary50 => primary.withValues(alpha: 0.50);
}
