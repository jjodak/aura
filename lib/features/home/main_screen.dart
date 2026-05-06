// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../memo/memo_page.dart';
import '../folder/folder_page.dart';
import '../calendar/calendar_page.dart';
import '../profile/profile_page.dart';

// --- 3. 메인 화면 ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const List<Widget> _pages = <Widget>[
    MemoPage(),
    FolderPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            physics: const BouncingScrollPhysics(),
            children: _pages,
          ),
          bottomNavigationBar: _buildTabBar(theme),
        );
      },
    );
  }

  Widget _buildTabBar(AppThemeColor theme) {
    final isDark = theme.name.contains('다크');

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: isDark ? 0.72 : 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : theme.primaryLight.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.34)
                      : theme.primaryLight.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_outlined),
                  activeIcon: Icon(Icons.edit_note_rounded),
                  label: '메모',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_open_outlined),
                  activeIcon: Icon(Icons.folder_open_rounded),
                  label: '폴더',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month_rounded),
                  label: '캘린더',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: '프로필',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: theme.primary,
              unselectedItemColor: theme.textBody.withValues(alpha: 0.52),
              backgroundColor: Colors.transparent,
              elevation: 0,
              showUnselectedLabels: true,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
