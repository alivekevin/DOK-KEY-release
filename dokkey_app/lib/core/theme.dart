import 'package:flutter/material.dart';

/// DOK-KEY Adaptive Theme (v3.0.0)
/// 다크(墨色) / 라이트(白磁) 팔레트를 조도 감지 키로 전환한다.
class DokkeyTheme {
  static bool _isLight = false;

  static bool get isLight => _isLight;

  static void applyBrightness(bool light) {
    _isLight = light;
  }

  // Background surfaces
  static Color get bgDark => _isLight ? const Color(0xFFF7F3E8) : const Color(0xFF101216);
  static Color get cardDark => _isLight ? const Color(0xFFFFFDF7) : const Color(0xFF191D24);
  static Color get surfaceDark => _isLight ? const Color(0xFFEFE8D8) : const Color(0xFF222731);
  static Color get borderDark => _isLight ? const Color(0xFFE0D6C1) : const Color(0xFF2E3440);

  // Brand Accent Colors
  static Color get gold => _isLight ? const Color(0xFFB8860B) : const Color(0xFFF5BD42);
  static Color get goldLight => _isLight ? const Color(0xFF8A6420) : const Color(0xFFFFE29A);
  static Color get dokFire => _isLight ? const Color(0xFFC94A2E) : const Color(0xFFFF6647);
  static Color get mintCalm => _isLight ? const Color(0xFF2E7D6B) : const Color(0xFF4E9F8E);
  static Color get textMain => _isLight ? const Color(0xFF23262D) : const Color(0xFFF4F5F7);
  static Color get textMuted => _isLight ? const Color(0xFF6E7480) : const Color(0xFF9AA0AC);

  static Color parseHex(String hexString) {
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return gold;
    }
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: const Color(0xFFF5BD42),
            secondary: const Color(0xFFFF6647),
            surface: const Color(0xFF191D24),
            onSurface: const Color(0xFFF4F5F7),
          )
        : ColorScheme.light(
            primary: const Color(0xFFB8860B),
            secondary: const Color(0xFFC94A2E),
            surface: const Color(0xFFFFFDF7),
            onSurface: const Color(0xFF23262D),
          );
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bgDark,
      primaryColor: gold,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: gold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData get currentTheme => _build(_isLight ? Brightness.light : Brightness.dark);
}
