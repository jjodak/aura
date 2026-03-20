import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/gestures.dart';

// --- 🎨 1. 앱 전체 색상 (Figma 디자인 시스템 적용) ---
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

void main() {
  runApp(const AuraApp());
}

// 배경 글로우 효과 위젯
class GlowBackground extends StatelessWidget {
  final Color color;
  final double size;
  const GlowBackground({super.key, required this.color, this.size = 300});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return MaterialApp(
          title: 'Aura',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
            },
          ),
          theme: ThemeData(
            scaffoldBackgroundColor: theme.bg,
            colorScheme: ColorScheme.fromSeed(
              seedColor: theme.primary,
              primary: theme.primary,
              secondary: theme.accent1,
              brightness: theme.name.contains('다크')
                  ? Brightness.dark
                  : Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
          body: IndexedStack(index: _selectedIndex, children: _pages),
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
              onTap: (index) => setState(() => _selectedIndex = index),
            ),
          ),
        );
      },
    );
  }
}

// --- 2. 메인 메모 화면 ---
class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final List<String> _hintTexts = [
    '번뜩이는 아이디어, 잊기 전에 메모하세요 💡',
    '할 일, 일정, 스쳐가는 생각... 무엇이든 적어두세요 📌',
    '지금 떠오르는 것들을 가볍게 남겨보세요 🌿',
    '오늘의 핵심 메모를 여기에 보관할게요 📝',
    '간단한 메모부터 중요한 일정까지 ✍️',
  ];

  late String _currentHint;
  final TextEditingController _controller = TextEditingController();
  bool _isToastVisible = false;
  String _toastMessage = '';
  Color _toastColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)];
  }

  void _showTopToast(String message, Color color) {
    if (_isToastVisible) return;
    setState(() {
      _toastMessage = message;
      _toastColor = color;
      _isToastVisible = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isToastVisible = false);
    });
  }

  void _saveMemo() {
    final theme = appThemeNotifier.value;
    if (_controller.text.trim().isEmpty) {
      _showTopToast('메모 내용을 먼저 입력해 주세요! ✍️', theme.accent2);
      return;
    }
    FocusScope.of(context).unfocus();
    _showTopToast('메모가 저장되었습니다. 🌿', theme.primary);
    _controller.clear();
    setState(
      () => _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: GlowBackground(color: theme.accent1, size: 250),
              ),
              Positioned(
                bottom: -100,
                right: -100,
                child: GlowBackground(color: theme.primaryLight, size: 350),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.accent1,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 이야기',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.textHeader,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '당신만의 특별한 순간을 기록해보세요',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: theme.name.contains('다크')
                                  ? Colors.black.withOpacity(0.4)
                                  : theme.primaryLight.withOpacity(0.2),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                            ),
                          ],
                          border: Border.all(
                            color: theme.primaryLight.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          style: TextStyle(
                            color: theme.textHeader,
                            fontSize: 17,
                            height: 1.8,
                          ),
                          decoration: InputDecoration(
                            hintText: _currentHint,
                            hintStyle: TextStyle(
                              color: theme.textBody.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          _buildHoverIconButton(
                            theme.accent1,
                            Icons.camera_alt_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildHoverIconButton(
                            theme.accent2,
                            Icons.mic_rounded,
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _saveMemo,
                            icon: const Icon(
                              Icons.save_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: const Text(
                              '저장하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              elevation: 2,
                              shadowColor: theme.primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatCard(theme, '이번 주 메모', '0개'),
                        const SizedBox(width: 16),
                        _buildStatCard(theme, '작성 일수', '0일'),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                top: _isToastVisible ? 20.0 : -100.0,
                left: 24.0,
                right: 24.0,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(100),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _toastColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _toastMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHoverIconButton(Color color, IconData icon) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        elevation: 0,
        shadowColor: color.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: EdgeInsets.zero,
        minimumSize: const Size(56, 56),
      ),
      child: Icon(icon, size: 24),
    );
  }

  Widget _buildStatCard(AppThemeColor theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textBody.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. 메모 저장 폴더 화면 ---
class FolderPage extends StatelessWidget {
  const FolderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        final List<Map<String, dynamic>> folders = [
          {'name': '번뜩이는 아이디어 ✨', 'color': theme.accent1, 'count': 0},
          {'name': '일상 기록 🌿', 'color': theme.primaryLight, 'count': 0},
          {'name': '여행 계획 ✈️', 'color': theme.accent2, 'count': 0},
          {'name': '중요한 일정 📌', 'color': theme.primary, 'count': 0},
        ];

        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 80,
                right: -50,
                child: GlowBackground(color: theme.primary, size: 320),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.accent1,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Collection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textBody.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '나만의 공간',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.textHeader,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '소중한 기억들을 카테고리별로 정리해요',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: folders.length + 1,
                        itemBuilder: (context, index) {
                          if (index == folders.length) {
                            return Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryLight.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: theme.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(24),
                                  hoverColor: theme.primaryLight.withOpacity(
                                    0.1,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.primaryLight.withOpacity(
                                          0.5,
                                        ),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: theme.primaryLight
                                                .withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add_rounded,
                                            color: theme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '새 폴더 만들기',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: theme.textHeader,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final f = folders[index];
                          final Color c = f['color'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.name.contains('다크')
                                      ? Colors.black.withOpacity(0.3)
                                      : c.withOpacity(0.15),
                                  blurRadius: 32,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: theme.surface.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(24),
                                hoverColor: c.withOpacity(0.05),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: c.withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: c.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.folder_rounded,
                                          color: c,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              f['name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: theme.textHeader,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '${f['count']}개의 메모',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme.textBody,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.trending_up_rounded,
                                                  size: 16,
                                                  color: c,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: c.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: c,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 4. 캘린더 화면 ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _isPickerExpanded = false;

  void _previousMonth() {
    setState(() {
      int y = _focusedDay.year;
      int m = _focusedDay.month - 1;
      if (m == 0) {
        y--;
        m = 12;
      }
      if (y >= 1900) _focusedDay = DateTime(y, m, 1);
      _isPickerExpanded = false;
    });
  }

  void _nextMonth() {
    setState(() {
      int y = _focusedDay.year;
      int m = _focusedDay.month + 1;
      if (m == 13) {
        y++;
        m = 1;
      }
      if (y <= 2080) _focusedDay = DateTime(y, m, 1);
      _isPickerExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: GlowBackground(color: theme.accent1, size: 300),
              ),
              Positioned(
                bottom: -50,
                right: -50,
                child: GlowBackground(color: theme.primaryLight, size: 400),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: theme.accent1,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Time Flow',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textBody.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '이달의 기록',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.textHeader,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '날짜를 선택해 그날의 이야기를 확인하세요',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: theme.name.contains('다크')
                                ? Colors.black.withOpacity(0.4)
                                : theme.primaryLight.withOpacity(0.2),
                            blurRadius: 60,
                            offset: const Offset(0, 20),
                          ),
                        ],
                        border: Border.all(
                          color: theme.primaryLight.withOpacity(0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => _isPickerExpanded = !_isPickerExpanded,
                                ),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    children: [
                                      Text(
                                        '${_focusedDay.year}년 ${_focusedDay.month}월',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: theme.textHeader,
                                        ),
                                      ),
                                      Icon(
                                        _isPickerExpanded
                                            ? Icons.arrow_drop_up_rounded
                                            : Icons.arrow_drop_down_rounded,
                                        color: theme.textHeader,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _previousMonth,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 28,
                                    ),
                                    color: theme.primaryLight,
                                  ),
                                  IconButton(
                                    onPressed: _nextMonth,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 28,
                                    ),
                                    color: theme.primaryLight,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isPickerExpanded)
                            SizedBox(
                              height: 150,
                              child: CupertinoTheme(
                                data: CupertinoThemeData(
                                  textTheme: CupertinoTextThemeData(
                                    dateTimePickerTextStyle: TextStyle(
                                      color: theme.textHeader,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.monthYear,
                                  initialDateTime: _focusedDay,
                                  minimumYear: 1900,
                                  maximumYear: 2080,
                                  onDateTimeChanged: (newDate) => setState(
                                    () => _focusedDay = DateTime(
                                      newDate.year,
                                      newDate.month,
                                      1,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            TableCalendar(
                              firstDay: DateTime.utc(1900, 1, 1),
                              lastDay: DateTime.utc(2080, 12, 31),
                              focusedDay: _focusedDay,
                              rowHeight: 48,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selectedDay, focusedDay) =>
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  }),
                              onPageChanged: (focusedDay) =>
                                  setState(() => _focusedDay = focusedDay),
                              headerVisible: false,
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: theme.accent1.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.accent1,
                                    width: 2,
                                  ),
                                ),
                                todayTextStyle: TextStyle(
                                  color: theme.textHeader,
                                  fontWeight: FontWeight.bold,
                                ),
                                selectedDecoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [theme.primary, theme.primaryLight],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primary.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                defaultTextStyle: TextStyle(
                                  color: theme.textHeader,
                                  fontWeight: FontWeight.w500,
                                ),
                                weekendTextStyle: TextStyle(
                                  color: theme.accent2,
                                  fontWeight: FontWeight.w500,
                                ),
                                outsideDaysVisible: false,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    if (_selectedDay != null)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.surface.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: theme.name.contains('다크')
                                    ? Colors.black.withOpacity(0.3)
                                    : theme.primaryLight.withOpacity(0.2),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: theme.primaryLight.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: theme.accent1,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SELECTED DATE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: theme.textBody.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_selectedDay!.month}월 ${_selectedDay!.day}일',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDay!.year}년',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textBody.withOpacity(0.7),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: theme.primaryLight.withOpacity(
                                        0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: theme.primary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '0',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '이날의 메모',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: theme.textBody,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- ✨ 새로 추가된 [계정 설정] 페이지 ---
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  void _showPasswordDialog(BuildContext context, AppThemeColor theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '비밀번호 변경',
            style: TextStyle(
              color: theme.textHeader,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '현재 비밀번호',
                  hintStyle: TextStyle(color: theme.textBody.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: theme.textHeader),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '새 비밀번호',
                  hintStyle: TextStyle(color: theme.textBody.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: theme.textHeader),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: theme.textBody)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('비밀번호가 변경되었습니다.'),
                    backgroundColor: theme.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '변경하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AppThemeColor theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '회원 탈퇴',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '정말로 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
            style: TextStyle(color: theme.textBody, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소', style: TextStyle(color: theme.textBody)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // 임시 동작
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '탈퇴하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: GlowBackground(color: theme.primary, size: 320),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: theme.textHeader,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '계정 설정',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.textHeader,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          // 내 정보 표시 칸
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.surface.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.primaryLight.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: theme.primaryLight
                                      .withOpacity(0.2),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: theme.primary,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '작성자님',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textHeader,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'user@email.com',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textBody.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 설정 리스트
                          _buildSettingsRow(
                            theme,
                            Icons.lock_reset_rounded,
                            '비밀번호 변경',
                            theme.textHeader,
                            () => _showPasswordDialog(context, theme),
                          ),
                          _buildSettingsRow(
                            theme,
                            Icons.logout_rounded,
                            '로그아웃',
                            theme.textHeader,
                            () {},
                          ),
                          const SizedBox(height: 24),
                          Divider(
                            color: theme.name.contains('다크')
                                ? Colors.white24
                                : const Color(0xFFE8E8E8),
                            thickness: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildSettingsRow(
                            theme,
                            Icons.person_off_rounded,
                            '회원 탈퇴',
                            Colors.redAccent,
                            () => _showDeleteAccountDialog(context, theme),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsRow(
    AppThemeColor theme,
    IconData icon,
    String title,
    Color textColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크')
                ? Colors.black.withOpacity(0.2)
                : theme.primaryLight.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          hoverColor: theme.primaryLight.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryLight.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor.withOpacity(0.8), size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textBody.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 5. 마이페이지 (프로필 화면) ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showThemePicker(BuildContext context, AppThemeColor currentTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: currentTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테마 선택하기 🎨',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.textHeader,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: availableThemes.map((t) {
                  final isSelected = currentTheme.name == t.name;
                  return GestureDetector(
                    onTap: () {
                      appThemeNotifier.value = t;
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.primary.withOpacity(0.15)
                            : (currentTheme.name.contains('다크')
                                  ? const Color(0xFF2A2A2A)
                                  : const Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? t.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textHeader,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: t.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: GlowBackground(color: theme.primary, size: 320),
              ),
              Positioned(
                bottom: 50,
                left: -50,
                child: GlowBackground(color: theme.accent1, size: 250),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: theme.accent1,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Space',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textBody.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '마이페이지',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.textHeader,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '나만의 설정과 정보를 관리하세요',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 프로필 카드
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primary.withOpacity(0.15),
                            theme.accent1.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: theme.name.contains('다크')
                                ? Colors.black.withOpacity(0.4)
                                : theme.primaryLight.withOpacity(0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: theme.primaryLight.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.primary, theme.primaryLight],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '반가워요, 작성자님! 👋',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textHeader,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '오늘도 멋진 하루를 기록해봐요',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.textBody.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '총 메모',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textBody.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '0개',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '활동일',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textBody.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '0일',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // 🔥 새로 추가된 계정 설정 연결 버튼
                          _buildMenuRow(
                            theme,
                            Icons.manage_accounts_rounded,
                            '계정 설정',
                            theme.primary,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AccountSettingsPage(),
                                ),
                              );
                            },
                          ),
                          _buildMenuRow(
                            theme,
                            Icons.notifications_rounded,
                            '알림 설정',
                            theme.accent1,
                            () {},
                          ),
                          _buildMenuRow(
                            theme,
                            Icons.palette_rounded,
                            '테마 및 색상',
                            theme.primaryLight,
                            () => _showThemePicker(context, theme),
                          ),
                          _buildMenuRow(
                            theme,
                            Icons.cloud_sync_rounded,
                            '데이터 백업 / 복원',
                            theme.accent2,
                            () {},
                          ),
                          const SizedBox(height: 24),
                          Divider(
                            color: theme.name.contains('다크')
                                ? Colors.white24
                                : const Color(0xFFE8E8E8),
                            thickness: 1,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            theme,
                            Icons.help_outline_rounded,
                            '도움말 및 문의',
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.info_outline_rounded,
                            '앱 버전 정보 (v1.0.0)',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuRow(
    AppThemeColor theme,
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크')
                ? Colors.black.withOpacity(0.3)
                : theme.primaryLight.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          hoverColor: theme.primaryLight.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textHeader,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.textBody.withOpacity(0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(AppThemeColor theme, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryLight.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.textBody, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textBody,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.textBody.withOpacity(0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}
