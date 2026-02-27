import 'package:flutter/material.dart';

class AppColors {
  // Professional Agriculture Theme
  static const Color cyberBlack = Color(0xFF121212);
  static const Color neonGreen = Color(0xFF2E7D32); // Deep Forest Green
  static const Color lightBlue = Color(0xFF1565C0);
  static const Color cyberBorder = Color(0xFFE0E0E0); 
  static const Color textMuted = Color(0xFF757575);
  
  // Light Mode Overrides
  static const Color lightBg = Color(0xFFF0F4F2);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF05070A);
  static const Color lightBorder = Color(0xFFD1D8D5);

  static const Color errorRed = Color(0xFFFF4444);
  static const Color warningOrange = Color(0xFFFFBB33);

  // Helper to get theme-aware colors
  static Color getBg(bool isDark) => isDark ? cyberBlack : lightBg;
  static Color getCard(bool isDark) => isDark ? cyberBlack.withOpacity(0.6) : lightCard.withOpacity(0.8);
  static Color getText(bool isDark) => isDark ? neonGreen : Color(0xFF1B4D4B);
  static Color getMutedText(bool isDark) => isDark ? textMuted : Colors.black54;
  static Color getBorder(bool isDark) => isDark ? cyberBorder : lightBorder;
}
