import 'package:flutter/material.dart';

// --- 🎨 앱 전체 색상 (Figma 디자인 시스템 적용) ---
class AppThemeColor {
  final String name;
  final String emoji;
  final Color bg;
  final Color surface;
  final Color textHeader;
  final Color textBody;
  final Color primary;
  final Color primaryLight;
  final Color accent1;
  final Color accent2;

  const AppThemeColor({
    required this.name,
    required this.emoji,
    required this.bg,
    required this.surface,
    required this.textHeader,
    required this.textBody,
    required this.primary,
    required this.primaryLight,
    required this.accent1,
    required this.accent2,
  });
}

const themeEarth = AppThemeColor(
  name: '어스 톤',
  emoji: '🌿',
  bg: Color(0xFFFCF9F2),
  surface: Colors.white,
  textHeader: Color(0xFF344E41),
  textBody: Color(0xFF5E503F),
  primary: Color(0xFF588157),
  primaryLight: Color(0xFFA3B18A),
  accent1: Color(0xFFE9C46A),
  accent2: Color(0xFFD4A373),
);

const themeOcean = AppThemeColor(
  name: '오션 블루',
  emoji: '🌊',
  bg: Color(0xFFF4F9F9),
  surface: Colors.white,
  textHeader: Color(0xFF1D3557),
  textBody: Color(0xFF457B9D),
  primary: Color(0xFF219EBC),
  primaryLight: Color(0xFF8ECAE6),
  accent1: Color(0xFF48CAE4),
  accent2: Color(0xFF0077B6),
);

const themeSunset = AppThemeColor(
  name: '선셋 핑크',
  emoji: '🌸',
  bg: Color(0xFFFFF5F5),
  surface: Colors.white,
  textHeader: Color(0xFF6D597A),
  textBody: Color(0xFFB56576),
  primary: Color(0xFFE56B6F),
  primaryLight: Color(0xFFFFB5A7),
  accent1: Color(0xFFE8A598),
  accent2: Color(0xFFD98A94),
);

const themeDark = AppThemeColor(
  name: '미드나잇 다크',
  emoji: '🌙',
  bg: Color(0xFF121212),
  surface: Color(0xFF1E1E1E),
  textHeader: Color(0xFFE0E0E0),
  textBody: Color(0xFFA0A0A0),
  primary: Color(0xFF81B29A),
  primaryLight: Color(0xFF3D5A50),
  accent1: Color(0xFFE07A5F),
  accent2: Color(0xFFF2CC8F),
);

final ValueNotifier<AppThemeColor> appThemeNotifier = ValueNotifier(themeEarth);
final List<AppThemeColor> availableThemes = [
  themeEarth,
  themeOcean,
  themeSunset,
  themeDark,
];
