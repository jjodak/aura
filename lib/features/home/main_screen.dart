// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_background.dart';
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: theme.name.contains('다크')
                      ? Colors.black.withOpacity(0.3)
                      : theme.primaryLight.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note_rounded),
                  label: '메모',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_open_rounded),
                  label: '폴더',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: '캘린더',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: '프로필',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: theme.primary,
              unselectedItemColor: theme.primaryLight.withOpacity(0.6),
              backgroundColor: theme.surface,
              elevation: 0,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                setState(() => _selectedIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
