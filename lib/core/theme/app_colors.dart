import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF904AFF);
  static const Color splashBackground = Color(0xFF0F2419);
  static const Color splashDot = Color(0xFF4F378C);
  static const Color artworkBackground = Color(0xFF020101);
  static const Color artworkNavBackground = Color(0xFF0F2419);

  static const Color inputFill = Color(0xFF1C2830);
  static const Color mutedText = Color(0xFFA3A3A3);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFFF6B6B);

  static Color get primary50 => primary.withValues(alpha: 0.50);
}
