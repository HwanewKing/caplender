import 'package:flutter/material.dart';

/// Palette taken verbatim from the design's `data.jsx` THEME object.
/// Cream paper base + teal/coral accents for the warm planner aesthetic.
class AppColors {
  static const Color cream = Color(0xFFF8F5EE);
  static const Color paper = Color(0xFFF1ECE0);
  static const Color ink = Color(0xFF1F1B16);
  static const Color inkSoft = Color(0xFF3E382E);
  static const Color inkMuted = Color(0xFF7A736A);
  static const Color inkFaint = Color(0xFFB5AE9F);
  static const Color border = Color(0xFFE5DDC9);
  static const Color borderSoft = Color(0xFFEFE9DA);

  static const Color teal = Color(0xFF0E8576);
  static const Color tealSoft = Color(0xFFCFE4DF);
  static const Color coral = Color(0xFFF57E58);
  static const Color coralSoft = Color(0xFFFFD9CC);
  static const Color peach = Color(0xFFF2C19F);
  static const Color peachSoft = Color(0xFFFBE6CF);
  static const Color mint = Color(0xFFC7E0E2);
  static const Color mintSoft = Color(0xFFE5F1F2);
  static const Color pink = Color(0xFFF4B5B0);
  static const Color pinkSoft = Color(0xFFFDE2DF);

  /// Sunday column header
  static const Color sun = Color(0xFFD4574B);
  /// Saturday column header
  static const Color sat = Color(0xFF3D7BB8);

  /// Background gradient used by the design body (radial blobs over olive).
  static const Color bgBase = Color(0xFFB7BEB1);
  static const Color bgBlob1 = Color(0xFFC5CCC0);
  static const Color bgBlob2 = Color(0xFFABB3A6);

  /// Pre-mixed accent options offered in Settings + Tweaks.
  static const List<Color> accentChoices = [
    teal,
    Color(0xFFA4654A),
    Color(0xFF6E5BA8),
    Color(0xFF3D7BB8),
  ];
}
