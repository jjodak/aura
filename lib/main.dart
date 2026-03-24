// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

// 🔥 파이어베이스 핵심 패키지
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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

// 🚀 메인 시동부
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AuraApp());
}

// 💡 추가된 부분: 날짜를 'YYYY-MM-DD' 문자열로 변환하는 유틸 함수
String dateToYMD(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ✨ CustomToast 시스템
class CustomToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message, Color color) {
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        color: color,
        onDismissed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.color,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDismissing = false; // 💡 중복 닫힘 방지 플래그

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 💡 원래대로 상단에서 내려오도록 설정 (-100에서 20으로)
    _animation = Tween<double>(
      begin: -100.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // 2.5초 뒤 자동 닫힘
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  // 💡 즉시 닫기 함수 (위로 부드럽게 올라가며 사라짐)
  void _dismiss() {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          // 💡 상단 배치 유지 (안전 영역 고려)
          top: _animation.value + MediaQuery.of(context).padding.top,
          left: 24,
          right: 24,
          child: GestureDetector(
            // 💡 탭하거나 위로 스와이프하면 즉시 닫힘
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // 속도가 0보다 작으면 위로 스와이프한 것
                _dismiss();
              }
            },
            child: Material(
              elevation: 15,
              borderRadius: BorderRadius.circular(100),
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.95),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// --- 🔐 인증 상태 관리 래퍼 ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginPage();
      },
    );
  }
}

// --- ✨ 1. 로그인 페이지 ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      CustomToast.show(context, '이메일과 비밀번호를 입력해주세요.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 10));

      CustomToast.show(context, '환영합니다! ✨', appThemeNotifier.value.primary);
    } on FirebaseAuthException catch (e) {
      String errorMessage = '로그인에 실패했습니다.';
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        errorMessage = '가입되지 않은 이메일이거나 비밀번호가 틀렸습니다.';
      }
      CustomToast.show(context, errorMessage, Colors.redAccent);
    } on TimeoutException catch (_) {
      CustomToast.show(context, '서버 응답 시간이 초과되었습니다.', Colors.redAccent);
    } catch (e) {
      CustomToast.show(context, '알 수 없는 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: -100,
                left: -50,
                child: GlowBackground(color: theme.primary, size: 400),
              ),
              Positioned(
                bottom: -50,
                right: -100,
                child: GlowBackground(color: theme.accent1, size: 300),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.accent1,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '당신만의 특별한 공간,',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textBody.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          'Aura',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.textHeader,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.surface.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: theme.name.contains('다크')
                                    ? Colors.black.withOpacity(0.4)
                                    : theme.primaryLight.withOpacity(0.2),
                                blurRadius: 40,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: theme.primaryLight.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                theme,
                                '이메일 주소',
                                Icons.email_outlined,
                                controller: _emailController,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                theme,
                                '비밀번호',
                                Icons.lock_outline_rounded,
                                isPassword: true,
                                controller: _passwordController,
                              ),
                              const SizedBox(height: 32),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  minimumSize: const Size(double.infinity, 56),
                                  elevation: 2,
                                  shadowColor: theme.primary.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                '비밀번호 찾기',
                                style: TextStyle(
                                  color: theme.textBody.withOpacity(0.6),
                                ),
                              ),
                            ),
                            Text(
                              '|',
                              style: TextStyle(
                                color: theme.textBody.withOpacity(0.3),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpPage(),
                                ),
                              ),
                              child: Text(
                                '회원가입',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildTextField(
    AppThemeColor theme,
    String hint,
    IconData icon, {
    bool isPassword = false,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: theme.textHeader),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textBody.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: theme.primaryLight),
        filled: true,
        fillColor: theme.bg.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// --- ✨ 2. 회원가입 페이지 ---
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _idController = TextEditingController();
  final _nicknameController = TextEditingController();

  String _generatedOtp = "";
  bool _isOtpSent = false;
  bool _isEmailVerified = false;
  bool _isLoading = false;

  Future<void> _sendVerificationEmail() async {
    FocusScope.of(context).unfocus();
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      CustomToast.show(context, '올바른 이메일 주소를 입력해주세요.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    _generatedOtp = (Random().nextInt(900000) + 100000).toString();

    const serviceId = 'service_0kg1egk';
    const templateId = 'template_a3aimju';
    const publicKey = 'qB5sTKurzqvVg4WCZ';

    try {
      final response = await http
          .post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': publicKey,
              'template_params': {
                'to_email': _emailController.text.trim(),
                'auth_code': _generatedOtp,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() => _isOtpSent = true);
        CustomToast.show(
          context,
          '인증번호가 발송되었습니다.\n메일함에서 6자리 숫자를 확인해주세요! 💌',
          Colors.blueAccent,
        );
      } else {
        CustomToast.show(context, '발송 실패: ${response.body}', Colors.redAccent);
      }
    } on TimeoutException catch (_) {
      CustomToast.show(context, '이메일 서버 응답이 지연되고 있습니다.', Colors.redAccent);
    } catch (e) {
      CustomToast.show(context, '네트워크 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    if (_otpController.text.trim() == _generatedOtp &&
        _generatedOtp.isNotEmpty) {
      setState(() => _isEmailVerified = true);
      CustomToast.show(context, '이메일 인증 완료! 🎉\n나머지 정보를 입력해주세요.', Colors.green);
    } else {
      CustomToast.show(context, '인증번호가 일치하지 않습니다.', Colors.redAccent);
    }
  }

  Future<void> _completeSignUp() async {
    FocusScope.of(context).unfocus();
    if (_passwordController.text != _confirmPasswordController.text) {
      CustomToast.show(context, '비밀번호가 서로 일치하지 않습니다.', Colors.orange);
      return;
    }
    if (_idController.text.trim().isEmpty ||
        _nicknameController.text.trim().isEmpty) {
      CustomToast.show(context, '아이디와 닉네임을 모두 입력해주세요.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 15));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': _emailController.text.trim(),
            'userId': _idController.text.trim(),
            'nickname': _nicknameController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(
          context,
          '가입이 완벽하게 끝났습니다!\n이제 직접 로그인해주세요 🎉',
          appThemeNotifier.value.primary,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = '가입 중 오류가 발생했습니다.';
      if (e.code == 'email-already-in-use') msg = '이미 가입된 이메일입니다.';
      if (e.code == 'weak-password') msg = '비밀번호는 6자리 이상이어야 합니다.';
      CustomToast.show(context, msg, Colors.redAccent);
    } on TimeoutException catch (_) {
      CustomToast.show(context, '서버 응답 시간이 초과되었습니다.', Colors.redAccent);
    } catch (e) {
      CustomToast.show(context, '정보 저장 중 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '회원가입',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                right: -50,
                child: GlowBackground(color: theme.accent1, size: 300),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileAvatar(theme),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: theme.primaryLight.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.name.contains('다크')
                                ? Colors.black.withOpacity(0.2)
                                : theme.primaryLight.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel(theme, '이메일'),
                          _buildTextField(
                            theme,
                            '예) aura@email.com',
                            Icons.email_outlined,
                            controller: _emailController,
                            enabled: !_isEmailVerified,
                          ),

                          if (_isOtpSent && !_isEmailVerified) ...[
                            const SizedBox(height: 24),
                            _buildInputLabel(theme, '인증번호'),
                            _buildTextField(
                              theme,
                              '6자리 숫자 입력',
                              Icons.mark_email_read_rounded,
                              controller: _otpController,
                            ),
                          ],

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isOtpSent
                                      ? null
                                      : _sendVerificationEmail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryLight,
                                    minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '인증 발송',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isOtpSent && !_isEmailVerified
                                      ? _verifyOtp
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isEmailVerified
                                        ? Colors.grey
                                        : theme.primary,
                                    minimumSize: const Size(0, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isEmailVerified ? '인증 완료' : '인증 확인',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Opacity(
                      opacity: _isEmailVerified ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: theme.primaryLight.withOpacity(0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.name.contains('다크')
                                  ? Colors.black.withOpacity(0.2)
                                  : theme.primaryLight.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel(theme, '비밀번호'),
                            _buildTextField(
                              theme,
                              '비밀번호 입력 (6자리 이상)',
                              Icons.lock_outline_rounded,
                              isPassword: true,
                              controller: _passwordController,
                              enabled: _isEmailVerified,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              theme,
                              '비밀번호 재확인',
                              Icons.lock_reset_rounded,
                              isPassword: true,
                              controller: _confirmPasswordController,
                              enabled: _isEmailVerified,
                            ),
                            const SizedBox(height: 24),
                            _buildInputLabel(theme, '아이디'),
                            _buildTextField(
                              theme,
                              '영문, 숫자 조합 4~12자리',
                              Icons.badge_outlined,
                              controller: _idController,
                              enabled: _isEmailVerified,
                            ),
                            const SizedBox(height: 24),
                            _buildInputLabel(theme, '닉네임'),
                            _buildTextField(
                              theme,
                              '앱에서 사용할 멋진 이름',
                              Icons.face_rounded,
                              controller: _nicknameController,
                              enabled: _isEmailVerified,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: (_isEmailVerified && !_isLoading)
                          ? _completeSignUp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 2,
                        shadowColor: theme.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              '가입 완료하기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(AppThemeColor theme) => Center(
    child: Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.primaryLight.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.person_rounded,
            size: 50,
            color: theme.primaryLight.withOpacity(0.5),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.bg, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInputLabel(AppThemeColor theme, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: theme.textHeader,
      ),
    ),
  );

  Widget _buildTextField(
    AppThemeColor theme,
    String hint,
    IconData icon, {
    bool isPassword = false,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      style: TextStyle(color: theme.textHeader),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.textBody.withOpacity(0.4),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: theme.primaryLight, size: 20),
        filled: true,
        fillColor: theme.bg.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

// --- 3. 메인 화면 ---
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

// --- 4. 메인 메모 화면 ---
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
  ];
  late String _currentHint;
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)];
  }

  void _showFolderSelectionSheet(BuildContext context, AppThemeColor theme) {
    if (_controller.text.trim().isEmpty) {
      CustomToast.show(context, '메모 내용을 먼저 입력해 주세요! ✍️', theme.accent2);
      return;
    }
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext sheetContext) {
        final user = FirebaseAuth.instance.currentUser;

        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어디에 보관할까요? 📁',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textHeader,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('folders')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // 💡 1. 가져온 모든 폴더 문서 목록
                    final allFolders = snapshot.data?.docs ?? [];

                    // 💡 2. '임시 폴더'를 제외한 진짜 사용자의 폴더만 필터링
                    final visibleFolders = allFolders
                        .where((doc) => doc['name'] != '임시 폴더')
                        .toList();

                    // 💡 3. 필터링 후 남은 폴더가 없다면 안내 메시지 출력
                    if (visibleFolders.isEmpty) {
                      return Center(
                        child: Text(
                          '아직 폴더가 없어요!\n폴더 탭에서 먼저 만들어주세요. 📁',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textBody.withOpacity(0.6),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      );
                    }

                    // 💡 4. 사용자가 만든 폴더가 있다면 목록 렌더링
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleFolders.length,
                      itemBuilder: (context, index) {
                        final doc = visibleFolders[index];
                        final Color folderColor = Color(doc['colorValue']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryLight.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: folderColor.withOpacity(0.2),
                              child: Icon(
                                Icons.folder_rounded,
                                color: folderColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              doc['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textHeader,
                              ),
                            ),
                            onTap: () => _saveMemoToDatabase(
                              sheetContext,
                              theme,
                              doc.id,
                              doc['name'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMemoToDatabase(
    BuildContext sheetContext,
    AppThemeColor theme,
    String folderId,
    String folderName,
  ) async {
    setState(() => _isSaving = true);
    Navigator.pop(sheetContext);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final memoContent = _controller.text.trim();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('memos')
          .add({
            'content': memoContent,
            'folderId': folderId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(folderId)
          .update({'count': FieldValue.increment(1)});

      CustomToast.show(context, '$folderName 폴더에 쏙! 저장완료 🌿', theme.primary);
      _controller.clear();
      setState(
        () => _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)],
      );
    } catch (e) {
      CustomToast.show(context, '저장 중 오류가 발생했어요.', Colors.redAccent);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                            onPressed: _isSaving
                                ? null
                                : () =>
                                      _showFolderSelectionSheet(context, theme),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
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

                    // 💡 통계 (이번 주 메모 / 작성 일수)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('memos')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int weeklyMemos = 0;
                        Set<String> activeDays = {};

                        if (snapshot.hasData) {
                          final now = DateTime.now();
                          // 이번 주 월요일 계산
                          final startOfWeek = now.subtract(
                            Duration(days: now.weekday - 1),
                          );
                          final startOfWeekDate = DateTime(
                            startOfWeek.year,
                            startOfWeek.month,
                            startOfWeek.day,
                          );

                          for (var doc in snapshot.data!.docs) {
                            if (doc['folderId'] == 'trash') continue; // 휴지통 제외

                            final timestamp = doc['createdAt'] as Timestamp?;
                            if (timestamp != null) {
                              final date = timestamp.toDate();
                              activeDays.add(dateToYMD(date)); // 유니크 날짜 추가

                              // 월요일 0시 이후 작성된 것만 카운트
                              if (date.isAfter(
                                startOfWeekDate.subtract(
                                  const Duration(seconds: 1),
                                ),
                              )) {
                                weeklyMemos++;
                              }
                            }
                          }
                        }

                        return Row(
                          children: [
                            _buildStatCard(theme, '이번 주 메모', '${weeklyMemos}개'),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              theme,
                              '작성 일수',
                              '${activeDays.length}일',
                            ),
                          ],
                        );
                      },
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

  Widget _buildHoverIconButton(Color color, IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          hoverColor: color.withOpacity(0.1),
          splashColor: color.withOpacity(0.2),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
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

// --- 5. 폴더 화면 ---
class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _showFolderDialog(
    BuildContext context,
    AppThemeColor theme, {
    DocumentSnapshot? existingFolder,
  }) {
    final _nameController = TextEditingController(
      text: existingFolder != null ? existingFolder['name'] : '',
    );

    final List<Color> colorOptions = [
      theme.primary,
      theme.accent1,
      theme.accent2,
      Color(0xFFE76F51),
      Color(0xFF2A9D8F),
      Color(0xFF457B9D),
    ];
    Color selectedColor = existingFolder != null
        ? Color(existingFolder['colorValue'])
        : colorOptions[0];
    bool isEditing = existingFolder != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                isEditing ? '폴더 이름 변경 ✏️' : '새 폴더 만들기 📁',
                style: TextStyle(
                  color: theme.textHeader,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: theme.textHeader),
                    decoration: InputDecoration(
                      hintText: '폴더 이름 (예: 아이디어 ✨)',
                      hintStyle: TextStyle(
                        color: theme.textBody.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: theme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '폴더 색상',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textBody.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colorOptions.map((color) {
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () =>
                            setStateDialog(() => selectedColor = color),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: theme.textBody)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) return;

                    try {
                      if (isEditing) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('folders')
                            .doc(existingFolder.id)
                            .update({
                              'name': _nameController.text.trim(),
                              'colorValue': selectedColor.value,
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          CustomToast.show(
                            context,
                            '폴더 이름이 변경되었어요! ✨',
                            theme.primary,
                          );
                        }
                      } else {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('folders')
                            .add({
                              'name': _nameController.text.trim(),
                              'colorValue': selectedColor.value,
                              'count': 0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          CustomToast.show(
                            context,
                            '새 폴더가 만들어졌어요! 🎉',
                            theme.primary,
                          );
                        }
                      }
                    } catch (e) {
                      CustomToast.show(
                        context,
                        '요청 처리에 실패했습니다.',
                        Colors.redAccent,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? '저장' : '만들기',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 💡 빈 임시 폴더 삭제를 허용하도록 로직 업데이트
  Future<void> _deleteFolder(
    String folderId,
    int count,
    AppThemeColor theme,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      if (count > 0) {
        final tempFolderQuery = await userRef
            .collection('folders')
            .where('name', isEqualTo: '임시 폴더')
            .get();
        String tempFolderId;

        if (tempFolderQuery.docs.isEmpty) {
          final newFolder = await userRef.collection('folders').add({
            'name': '임시 폴더',
            'colorValue': theme.textBody.value,
            'count': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tempFolderId = newFolder.id;
        } else {
          tempFolderId = tempFolderQuery.docs.first.id;
        }

        final memosQuery = await userRef
            .collection('memos')
            .where('folderId', isEqualTo: folderId)
            .get();
        final batch = FirebaseFirestore.instance.batch();

        for (var doc in memosQuery.docs) {
          batch.update(doc.reference, {'folderId': tempFolderId});
        }

        batch.update(userRef.collection('folders').doc(tempFolderId), {
          'count': FieldValue.increment(count),
        });

        await batch.commit();
        CustomToast.show(
          context,
          '폴더 삭제 완료! 안의 메모들은 [임시 폴더]로 옮겼어요 📦',
          Colors.orange,
        );
      } else {
        CustomToast.show(context, '빈 폴더가 삭제되었습니다 🗑️', Colors.orange);
      }

      await userRef.collection('folders').doc(folderId).delete();
    } catch (e) {
      CustomToast.show(context, '폴더 삭제 중 오류가 발생했습니다.', Colors.redAccent);
    }
  }

  // 💡 임시 폴더 관리 조건 변경
  void _showFolderOptions(
    BuildContext context,
    AppThemeColor theme,
    DocumentSnapshot folderDoc,
  ) {
    bool isTempFolder = folderDoc['name'] == '임시 폴더';
    int memoCount = folderDoc['count'] ?? 0;

    if (isTempFolder && memoCount > 0) {
      CustomToast.show(context, '메모가 들어있는 임시 폴더는 지울 수 없어요.', theme.textBody);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isTempFolder)
                  ListTile(
                    leading: Icon(Icons.edit_rounded, color: theme.primary),
                    title: Text(
                      '폴더 이름/색상 변경',
                      style: TextStyle(
                        color: theme.textHeader,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showFolderDialog(
                        context,
                        theme,
                        existingFolder: folderDoc,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    isTempFolder ? '빈 임시 폴더 삭제' : '폴더 삭제 (메모는 임시폴더로)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.surface,
                        title: Text(
                          '정말 삭제할까요?',
                          style: TextStyle(color: theme.textHeader),
                        ),
                        content: Text(
                          isTempFolder
                              ? '빈 임시 폴더를 삭제합니다.'
                              : '메모가 있다면 임시 폴더로 안전하게 옮겨집니다.',
                          style: TextStyle(color: theme.textBody),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              '취소',
                              style: TextStyle(color: theme.textBody),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteFolder(folderDoc.id, memoCount, theme);
                            },
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
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
        final user = FirebaseAuth.instance.currentUser;
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          ],
                        ),
                        // 💡 휴지통 아이콘 추가
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.accent1,
                            size: 28,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrashPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '소중한 기억들을 카테고리별로 정리해요\n(폴더를 길게 누르면 편집/삭제 가능해요)',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('folders')
                            .orderBy('createdAt')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final folders = snapshot.data?.docs ?? [];

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: folders.length + 1,
                            itemBuilder: (context, index) {
                              if (index == folders.length) {
                                return Container(
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryLight.withOpacity(
                                          0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: theme.surface.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(24),
                                    child: InkWell(
                                      onTap: () =>
                                          _showFolderDialog(context, theme),
                                      borderRadius: BorderRadius.circular(24),
                                      hoverColor: theme.primaryLight
                                          .withOpacity(0.1),
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.primaryLight
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                                borderRadius:
                                                    BorderRadius.circular(16),
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

                              final doc = folders[index];
                              final String name = doc['name'];
                              final int count = doc['count'] ?? 0;
                              final Color c = Color(doc['colorValue']);

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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FolderDetailScreen(
                                                folderId: doc.id,
                                                folderName: name,
                                                folderColor: c,
                                              ),
                                        ),
                                      );
                                    },
                                    onLongPress: () =>
                                        _showFolderOptions(context, theme, doc),
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                                  name,
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
                                                      '$count개의 메모',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
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

// --- 🗑️ 휴지통 화면 ---
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedMemos = {};

  Future<void> _deleteSelectedMemos(AppThemeColor theme) async {
    if (_selectedMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in _selectedMemos) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memos')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();

      CustomToast.show(
        context,
        '${_selectedMemos.length}개의 메모가 영구 삭제되었습니다. 🗑️',
        Colors.orange,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '삭제 실패', Colors.redAccent);
    }
  }

  Future<void> _restoreMemos(
    AppThemeColor theme,
    List<DocumentSnapshot> allMemos, {
    bool isAll = false,
  }) async {
    final memosToRestore = isAll
        ? allMemos
        : allMemos.where((d) => _selectedMemos.contains(d.id)).toList();
    if (memosToRestore.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final foldersQuery = await userRef.collection('folders').get();
      final existingFolderIds = foldersQuery.docs.map((e) => e.id).toSet();

      String tempFolderId = '';
      try {
        tempFolderId = foldersQuery.docs
            .firstWhere((e) => e['name'] == '임시 폴더')
            .id;
      } catch (e) {
        final newFolder = await userRef.collection('folders').add({
          'name': '임시 폴더',
          'colorValue': Colors.grey.value,
          'count': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tempFolderId = newFolder.id;
        existingFolderIds.add(tempFolderId);
      }

      final batch = FirebaseFirestore.instance.batch();
      Map<String, int> folderIncrements = {};

      for (var doc in memosToRestore) {
        String targetFolder = tempFolderId;
        if (doc.data() is Map &&
            (doc.data() as Map).containsKey('originalFolderId')) {
          targetFolder = doc['originalFolderId'];
        }

        if (!existingFolderIds.contains(targetFolder)) {
          targetFolder = tempFolderId;
        }

        batch.update(doc.reference, {
          'folderId': targetFolder,
          'originalFolderId': FieldValue.delete(),
        });

        folderIncrements[targetFolder] =
            (folderIncrements[targetFolder] ?? 0) + 1;
      }

      for (var entry in folderIncrements.entries) {
        batch.update(userRef.collection('folders').doc(entry.key), {
          'count': FieldValue.increment(entry.value),
        });
      }

      await batch.commit();

      CustomToast.show(
        context,
        '${memosToRestore.length}개의 메모가 복구되었습니다! ✨',
        theme.primary,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '복구에 실패했습니다.', Colors.redAccent);
    }
  }

  Future<void> _emptyTrash(
    AppThemeColor theme,
    List<DocumentSnapshot> allMemos,
  ) async {
    if (allMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in allMemos) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      CustomToast.show(context, '휴지통을 싹 비웠습니다! ✨', theme.primary);
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '휴지통 비우기에 실패했어요.', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('memos')
              .where('folderId', isEqualTo: 'trash')
              .snapshots(),
          builder: (context, snapshot) {
            final allMemos = snapshot.data?.docs ?? [];

            return Scaffold(
              backgroundColor: theme.bg,
              appBar: AppBar(
                backgroundColor: theme.surface.withOpacity(0.8),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    _isSelectionMode
                        ? Icons.close_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    color: theme.textHeader,
                  ),
                  onPressed: () {
                    if (_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedMemos.clear();
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: _isSelectionMode
                    ? Text(
                        '${_selectedMemos.length}개 선택됨',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textHeader,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '휴지통',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textHeader,
                            ),
                          ),
                        ],
                      ),
                centerTitle: true,
                actions: _isSelectionMode
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.restore_rounded,
                            color: theme.primary,
                          ),
                          onPressed: _selectedMemos.isEmpty
                              ? null
                              : () => _restoreMemos(
                                  theme,
                                  allMemos,
                                  isAll: false,
                                ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: _selectedMemos.isEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.surface,
                                      title: Text(
                                        '선택 영구 삭제',
                                        style: TextStyle(
                                          color: theme.textHeader,
                                        ),
                                      ),
                                      content: Text(
                                        '선택한 메모를 영구 삭제하시겠습니까?',
                                        style: TextStyle(color: theme.textBody),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: theme.textBody,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteSelectedMemos(theme);
                                          },
                                          child: const Text(
                                            '삭제',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(width: 8),
                      ]
                    : [
                        TextButton(
                          onPressed: allMemos.isEmpty
                              ? null
                              : () =>
                                    _restoreMemos(theme, allMemos, isAll: true),
                          child: Text(
                            '전체 복구',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: allMemos.isEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.surface,
                                      title: Text(
                                        '휴지통 비우기',
                                        style: TextStyle(
                                          color: theme.textHeader,
                                        ),
                                      ),
                                      content: Text(
                                        '휴지통 안의 모든 메모를 영구 삭제할까요?',
                                        style: TextStyle(color: theme.textBody),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: theme.textBody,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _emptyTrash(theme, allMemos);
                                          },
                                          child: const Text(
                                            '비우기',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          child: const Text(
                            '전체 삭제',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : allMemos.isEmpty
                  ? Center(
                      child: Text(
                        '휴지통이 깨끗하게 비어있어요! 🌿',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textBody.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: allMemos.length,
                      itemBuilder: (context, index) {
                        final doc = allMemos[index];
                        final String content = doc['content'] ?? '';
                        final lines = content.split('\n');
                        final title = lines.first.length > 20
                            ? '${lines.first.substring(0, 20)}...'
                            : lines.first;
                        final isSelected = _selectedMemos.contains(doc.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? theme.primary.withOpacity(0.6)
                                  : theme.primaryLight.withOpacity(0.2),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Material(
                            color: isSelected
                                ? theme.primary.withOpacity(0.12)
                                : theme.surface,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onLongPress: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedMemos.add(doc.id);
                                });
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMemos.remove(doc.id);
                                    } else {
                                      _selectedMemos.add(doc.id);
                                    }
                                    if (_selectedMemos.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  });
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrashMemoViewScreen(
                                        memoDoc: doc,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isSelectionMode) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                          right: 12.0,
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? theme.primary
                                              : theme.textBody.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: theme.textHeader,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                dateToYMD(
                                                  (doc['createdAt']
                                                          as Timestamp)
                                                      .toDate(),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.textBody
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (content.split('\n').length > 1 &&
                                              content
                                                  .split('\n')
                                                  .sublist(1)
                                                  .join('\n')
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              content
                                                  .split('\n')
                                                  .sublist(1)
                                                  .join('\n')
                                                  .trim(),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.textBody
                                                    .withOpacity(0.8),
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
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
            );
          },
        );
      },
    );
  }
}

// --- 🗑️ 휴지통 개별 메모 확인 및 복구/삭제 화면 ---
class TrashMemoViewScreen extends StatefulWidget {
  final DocumentSnapshot memoDoc;
  final AppThemeColor theme;

  const TrashMemoViewScreen({
    super.key,
    required this.memoDoc,
    required this.theme,
  });

  @override
  State<TrashMemoViewScreen> createState() => _TrashMemoViewScreenState();
}

class _TrashMemoViewScreenState extends State<TrashMemoViewScreen> {
  bool _isProcessing = false;

  Future<void> _restoreMemo() async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final foldersQuery = await userRef.collection('folders').get();
      final existingFolderIds = foldersQuery.docs.map((e) => e.id).toSet();

      String targetFolder = '';
      final data = widget.memoDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('originalFolderId')) {
        targetFolder = data['originalFolderId'];
      }

      if (!existingFolderIds.contains(targetFolder)) {
        try {
          targetFolder = foldersQuery.docs
              .firstWhere((e) => e['name'] == '임시 폴더')
              .id;
        } catch (e) {
          final newFolder = await userRef.collection('folders').add({
            'name': '임시 폴더',
            'colorValue': Colors.grey.value,
            'count': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          targetFolder = newFolder.id;
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.update(widget.memoDoc.reference, {
        'folderId': targetFolder,
        'originalFolderId': FieldValue.delete(),
      });
      batch.update(userRef.collection('folders').doc(targetFolder), {
        'count': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 성공적으로 복구되었습니다! ✨', widget.theme.primary);
      }
    } catch (e) {
      CustomToast.show(context, '복구에 실패했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deletePermanent() async {
    setState(() => _isProcessing = true);
    try {
      await widget.memoDoc.reference.delete();
      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 완전히 삭제되었습니다. 🗑️', Colors.orange);
      }
    } catch (e) {
      CustomToast.show(context, '삭제 실패', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.memoDoc['content'] ?? '';
    final timestamp = widget.memoDoc['createdAt'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final dateString =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.theme.textHeader,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '휴지통 메모 확인',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.theme.textHeader,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateString,
                style: TextStyle(
                  color: widget.theme.textBody.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.theme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.theme.textHeader,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deletePermanent,
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '영구 삭제',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restoreMemo,
                        icon: const Icon(
                          Icons.restore_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '복구하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 📁 폴더 상세 ---
class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String folderName;
  final Color folderColor;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.folderColor,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedMemos = {};

  Future<void> _moveSelectedToTrash(AppThemeColor theme) async {
    if (_selectedMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in _selectedMemos) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memos')
            .doc(id);
        batch.update(ref, {
          'folderId': 'trash',
          'originalFolderId': widget.folderId,
        });
      }

      final folderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(widget.folderId);
      batch.update(folderRef, {
        'count': FieldValue.increment(-_selectedMemos.length),
      });

      await batch.commit();

      CustomToast.show(
        context,
        '${_selectedMemos.length}개의 메모를 휴지통으로 보냈습니다. 🗑️',
        Colors.orange,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '이동 중 오류가 발생했습니다.', Colors.redAccent);
    }
  }

  void _showMoveFolderSheet(AppThemeColor theme) {
    if (_selectedMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어느 폴더로 이동할까요? 📁',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textHeader,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('folders')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final folders = snapshot.data!.docs
                        .where((doc) => doc.id != widget.folderId)
                        .toList();

                    if (folders.isEmpty) {
                      return Center(
                        child: Text(
                          '이동할 수 있는 다른 폴더가 없어요.',
                          style: TextStyle(color: theme.textBody),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final doc = folders[index];
                        final Color folderColor = Color(doc['colorValue']);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: folderColor.withOpacity(0.2),
                            child: Icon(
                              Icons.folder_rounded,
                              color: folderColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            doc['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textHeader,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _moveToAnotherFolder(
                              theme,
                              doc.id,
                              doc['name'],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _moveToAnotherFolder(
    AppThemeColor theme,
    String targetFolderId,
    String targetFolderName,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in _selectedMemos) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memos')
            .doc(id);
        batch.update(ref, {'folderId': targetFolderId});
      }

      final currentFolderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(widget.folderId);
      batch.update(currentFolderRef, {
        'count': FieldValue.increment(-_selectedMemos.length),
      });

      final targetFolderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(targetFolderId);
      batch.update(targetFolderRef, {
        'count': FieldValue.increment(_selectedMemos.length),
      });

      await batch.commit();

      CustomToast.show(
        context,
        '메모가 [$targetFolderName] 폴더로 이동되었어요! 🚀',
        theme.primary,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '폴더 이동에 실패했습니다.', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        bool isTempFolder = widget.folderName == '임시 폴더';

        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: theme.surface.withOpacity(0.8),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                _isSelectionMode
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () {
                if (_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedMemos.clear();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: _isSelectionMode
                ? Text(
                    '${_selectedMemos.length}개 선택됨',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textHeader,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        color: widget.folderColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.folderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textHeader,
                        ),
                      ),
                    ],
                  ),
            centerTitle: true,
            actions: _isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        Icons.drive_file_move_rounded,
                        color: theme.primary,
                      ),
                      onPressed: _selectedMemos.isEmpty
                          ? null
                          : () => _showMoveFolderSheet(theme),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: _selectedMemos.isEmpty
                          ? null
                          : () => _moveSelectedToTrash(theme),
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.textHeader,
                      ),
                      color: theme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // 💡 상위의 FolderPage _showFolderDialog 로직을 여기로 구현하기 어려우므로
                          // _FolderPageState의 팝업 옵션을 사용하는 것이 자연스럽지만,
                          // 이미 상세 페이지에 들어와 있으므로 여기서 처리하게 할 수도 있음.
                          // (간결함을 위해 수정은 리스트 화면에서 하는 것을 권장)
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.surface,
                              title: Text(
                                '정말 삭제할까요?',
                                style: TextStyle(color: theme.textHeader),
                              ),
                              content: Text(
                                isTempFolder
                                    ? '빈 임시 폴더를 삭제합니다.'
                                    : '메모가 있다면 임시 폴더로 안전하게 옮겨집니다.',
                                style: TextStyle(color: theme.textBody),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(color: theme.textBody),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);

                                    final db = FirebaseFirestore.instance;
                                    final memosSnapshot = await db
                                        .collection('users')
                                        .doc(user!.uid)
                                        .collection('memos')
                                        .where(
                                          'folderId',
                                          isEqualTo: widget.folderId,
                                        )
                                        .get();

                                    if (isTempFolder &&
                                        memosSnapshot.docs.isNotEmpty) {
                                      CustomToast.show(
                                        context,
                                        '메모가 남아있는 임시 폴더는 지울 수 없어요.',
                                        Colors.redAccent,
                                      );
                                      return;
                                    }

                                    if (memosSnapshot.docs.isNotEmpty &&
                                        !isTempFolder) {
                                      final tempFolderQuery = await db
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('folders')
                                          .where('name', isEqualTo: '임시 폴더')
                                          .limit(1)
                                          .get();
                                      String tempFolderId;

                                      if (tempFolderQuery.docs.isEmpty) {
                                        final newTempFolder = await db
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('folders')
                                            .add({
                                              'name': '임시 폴더',
                                              'colorValue': Colors.grey.value,
                                              'count':
                                                  memosSnapshot.docs.length,
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                        tempFolderId = newTempFolder.id;
                                      } else {
                                        tempFolderId =
                                            tempFolderQuery.docs.first.id;
                                        await db
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('folders')
                                            .doc(tempFolderId)
                                            .update({
                                              'count': FieldValue.increment(
                                                memosSnapshot.docs.length,
                                              ),
                                            });
                                      }

                                      WriteBatch batch = db.batch();
                                      for (var doc in memosSnapshot.docs) {
                                        batch.update(doc.reference, {
                                          'folderId': tempFolderId,
                                        });
                                      }
                                      await batch.commit();
                                    }

                                    await db
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('folders')
                                        .doc(widget.folderId)
                                        .delete();

                                    if (mounted) {
                                      Navigator.pop(context);
                                      CustomToast.show(
                                        context,
                                        isTempFolder
                                            ? '임시 폴더가 삭제되었습니다.'
                                            : '폴더가 삭제되었습니다.',
                                        Colors.orange,
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isTempFolder)
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              '폴더 수정 (리스트에서 가능)',
                              style: TextStyle(
                                color: theme.textBody.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            enabled: false,
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            isTempFolder ? '빈 임시 폴더 삭제 🗑️' : '폴더 삭제 🗑️',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('memos')
                .where('folderId', isEqualTo: widget.folderId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    '이 폴더는 아직 비어있어요.\n새로운 기록을 남겨보세요! 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textBody.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final memos = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                itemCount: memos.length,
                itemBuilder: (context, index) {
                  final doc = memos[index];
                  final String content = doc['content'] ?? '';

                  final timestamp = doc['createdAt'] as Timestamp?;
                  final date = timestamp?.toDate() ?? DateTime.now();
                  final dateString =
                      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

                  final lines = content.split('\n');
                  final title = lines.first.length > 20
                      ? '${lines.first.substring(0, 20)}...'
                      : lines.first;
                  final body = lines.length > 1
                      ? lines.sublist(1).join('\n')
                      : '';

                  final isSelected = _selectedMemos.contains(doc.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? widget.folderColor.withOpacity(0.6)
                            : widget.folderColor.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: isSelected
                          ? widget.folderColor.withOpacity(0.12)
                          : theme.surface,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onLongPress: () {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedMemos.add(doc.id);
                          });
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedMemos.remove(doc.id);
                              } else {
                                _selectedMemos.add(doc.id);
                              }
                              if (_selectedMemos.isEmpty) {
                                _isSelectionMode = false;
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoEditScreen(
                                  memoId: doc.id,
                                  folderId: widget.folderId,
                                  initialContent: content,
                                  folderColor: widget.folderColor,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isSelectionMode) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 2.0,
                                    right: 12.0,
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? widget.folderColor
                                        : theme.textBody.withOpacity(0.3),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: theme.textHeader,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateString,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textBody.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (body.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.textBody.withOpacity(
                                            0.8,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// --- 📝 개별 메모 수정 및 삭제 화면 ---
class MemoEditScreen extends StatefulWidget {
  final String memoId;
  final String folderId;
  final String initialContent;
  final Color folderColor;

  const MemoEditScreen({
    super.key,
    required this.memoId,
    required this.folderId,
    required this.initialContent,
    required this.folderColor,
  });

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late TextEditingController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  Future<void> _updateMemo(AppThemeColor theme) async {
    if (_controller.text.trim().isEmpty) {
      CustomToast.show(context, '내용을 입력해주세요.', Colors.orange);
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('memos')
          .doc(widget.memoId)
          .update({
            'content': _controller.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 수정되었습니다. ✨', theme.primary);
      }
    } catch (e) {
      CustomToast.show(context, '수정 실패: 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteMemo() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('memos')
          .doc(widget.memoId)
          .update({'folderId': 'trash', 'originalFolderId': widget.folderId});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('folders')
          .doc(widget.folderId)
          .update({'count': FieldValue.increment(-1)});

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모를 휴지통으로 옮겼습니다. 🗑️', Colors.orange);
      }
    } catch (e) {
      CustomToast.show(context, '삭제 실패: 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: _isProcessing ? null : _deleteMemo,
              ),
              IconButton(
                icon: Icon(Icons.check_rounded, color: theme.primary, size: 28),
                onPressed: _isProcessing ? null : () => _updateMemo(theme),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: widget.folderColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.folderColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                          hintText: '메모를 수정해보세요...',
                          hintStyle: TextStyle(
                            color: theme.textBody.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- 💡 일정 추가/수정용 바텀 시트 ---
class _EventBottomSheet extends StatefulWidget {
  final AppThemeColor theme;
  final DateTime selectedDate;
  final DocumentSnapshot? eventDoc;

  const _EventBottomSheet({
    required this.theme,
    required this.selectedDate,
    this.eventDoc,
  });

  @override
  State<_EventBottomSheet> createState() => _EventBottomSheetState();
}

class _EventBottomSheetState extends State<_EventBottomSheet> {
  final TextEditingController _eventController = TextEditingController();
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  int? _alarmMinutes;

  @override
  void initState() {
    super.initState();
    if (widget.eventDoc != null) {
      final data = widget.eventDoc!.data() as Map<String, dynamic>;
      _eventController.text = data['title'] ?? '';
      _startDateTime = (data['startTime'] as Timestamp).toDate();
      _endDateTime = (data['endTime'] as Timestamp).toDate();
      _alarmMinutes = data['alarmMinutes'];
    } else {
      DateTime now = DateTime.now();
      _startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        now.hour,
        0,
      );
      _endDateTime = _startDateTime.add(const Duration(hours: 1));
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    DateTime initialDate = isStart ? _startDateTime : _endDateTime;
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: initialDate.hour,
          minute: initialDate.minute,
        ),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          DateTime finalDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isStart) {
            _startDateTime = finalDateTime;
            if (_startDateTime.isAfter(_endDateTime)) {
              _endDateTime = _startDateTime.add(const Duration(hours: 1));
            }
          } else {
            _endDateTime = finalDateTime;
            if (_endDateTime.isBefore(_startDateTime)) {
              _startDateTime = _endDateTime.subtract(const Duration(hours: 1));
            }
          }
        });
      }
    }
  }

  void _showAlarmPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                '알림 설정',
                style: TextStyle(
                  color: widget.theme.textHeader,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildAlarmOption('없음', null, ctx),
              _buildAlarmOption('5분 전', 5, ctx),
              _buildAlarmOption('10분 전', 10, ctx),
              _buildAlarmOption('30분 전', 30, ctx),
              _buildAlarmOption('1시간 전', 60, ctx),
              _buildAlarmOption('1일 전', 1440, ctx),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlarmOption(String label, int? minutes, BuildContext ctx) {
    return ListTile(
      title: Text(label, style: TextStyle(color: widget.theme.textHeader)),
      trailing: _alarmMinutes == minutes
          ? Icon(Icons.check_rounded, color: widget.theme.primary)
          : null,
      onTap: () {
        setState(() => _alarmMinutes = minutes);
        Navigator.pop(ctx);
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getAlarmText() {
    if (_alarmMinutes == null) return '없음';
    if (_alarmMinutes == 5) return '5분 전';
    if (_alarmMinutes == 10) return '10분 전';
    if (_alarmMinutes == 30) return '30분 전';
    if (_alarmMinutes == 60) return '1시간 전';
    if (_alarmMinutes == 1440) return '1일 전';
    return '설정됨';
  }

  Future<void> _saveEvent() async {
    if (_eventController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final data = {
      'title': _eventController.text.trim(),
      'startTime': Timestamp.fromDate(_startDateTime),
      'endTime': Timestamp.fromDate(_endDateTime),
      'alarmMinutes': _alarmMinutes,
    };

    if (widget.eventDoc == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('events')
          .add(data);
    } else {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await widget.eventDoc!.reference.update(data);
    }

    if (mounted) {
      Navigator.pop(context);
      CustomToast.show(
        context,
        widget.eventDoc == null ? '일정이 등록되었습니다! ✨' : '일정이 수정되었습니다! ✍️',
        widget.theme.primary,
      );
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.eventDoc == null) return;

    // 💡 1. 실수 방지용 삭제 확인 팝업 띄우기
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '일정 삭제',
          style: TextStyle(
            color: widget.theme.textHeader,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '이 일정을 삭제할까요?',
          style: TextStyle(color: widget.theme.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: widget.theme.textBody)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx); // 다이얼로그 닫기

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // 💡 2. reference.delete() 대신 정확한 경로를 지정하여 확실하게 타격(삭제)
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('events')
                      .doc(widget.eventDoc!.id)
                      .delete();
                }

                if (mounted) {
                  Navigator.pop(context); // 일정 바텀 시트 닫기
                  CustomToast.show(
                    context,
                    '일정이 깔끔하게 삭제되었습니다. 🗑️',
                    Colors.orange,
                  );
                }
              } catch (e) {
                CustomToast.show(
                  context,
                  '삭제 중 서버 오류가 발생했습니다.',
                  Colors.redAccent,
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.eventDoc == null ? '새로운 일정 추가 🗓️' : '일정 수정 ✏️',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textHeader,
                ),
              ),
              Row(
                children: [
                  if (widget.eventDoc != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: _deleteEvent,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: widget.theme.textBody,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _eventController,
            style: TextStyle(color: widget.theme.textHeader, fontSize: 18),
            decoration: InputDecoration(
              hintText: '일정 제목',
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildDateTimeRow('시작', _startDateTime, true),
          const SizedBox(height: 16),
          _buildDateTimeRow('종료', _endDateTime, false),
          const SizedBox(height: 16),

          InkWell(
            onTap: _showAlarmPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: widget.theme.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: widget.theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '알림',
                    style: TextStyle(
                      color: widget.theme.textBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getAlarmText(),
                    style: TextStyle(
                      color: widget.theme.textHeader,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.eventDoc == null ? '일정 저장하기' : '수정 완료',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow(String label, DateTime dt, bool isStart) {
    return InkWell(
      onTap: () => _pickDateTime(isStart: isStart),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: widget.theme.bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              color: widget.theme.accent1,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: widget.theme.textBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _formatDateTime(dt),
              style: TextStyle(
                color: widget.theme.textHeader,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. 캘린더 화면 ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _isPickerExpanded = false;
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isDayInRange(DateTime day, DateTime start, DateTime end) {
    DateTime dayOnly = DateTime(day.year, day.month, day.day);
    DateTime startOnly = DateTime(start.year, start.month, start.day);
    DateTime endOnly = DateTime(end.year, end.month, end.day);
    return !dayOnly.isBefore(startOnly) && !dayOnly.isAfter(endOnly);
  }

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

  void _showEventSheet(AppThemeColor theme, {DocumentSnapshot? eventDoc}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return _EventBottomSheet(
          theme: theme,
          selectedDate: _selectedDay ?? DateTime.now(),
          eventDoc: eventDoc,
        );
      },
    );
  }

  void _showDayEventsSheet(
    AppThemeColor theme,
    List<QueryDocumentSnapshot> events,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDay!.month}월 ${_selectedDay!.day}일의 일정 🗓️',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textHeader,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final doc = events[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String title = data['title'] ?? '';
                    DateTime start = (data['startTime'] as Timestamp).toDate();
                    DateTime end = (data['endTime'] as Timestamp).toDate();

                    String timeStr =
                        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} ~ ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.accent1.withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _showEventSheet(theme, eventDoc: doc);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: theme.textHeader,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: theme.textBody.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: theme.textBody.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
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
        );
      },
    );
  }

  void _showDayMemosSheet(
    AppThemeColor theme,
    List<QueryDocumentSnapshot> memos,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDay!.month}월 ${_selectedDay!.day}일의 메모 🌿',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textHeader,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final doc = memos[index];
                    final String content = doc['content'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primaryLight.withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            Color fColor = theme.primary;
                            try {
                              final fDoc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .collection('folders')
                                  .doc(doc['folderId'])
                                  .get();
                              if (fDoc.exists)
                                fColor = Color(fDoc['colorValue']);
                            } catch (_) {}

                            if (!mounted) return;
                            Navigator.pop(sheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MemoEditScreen(
                                  memoId: doc.id,
                                  folderId: doc['folderId'],
                                  initialContent: content,
                                  folderColor: fColor,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              content,
                              style: TextStyle(
                                color: theme.textHeader,
                                fontSize: 15,
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('events')
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  List<QueryDocumentSnapshot> allEvents = eventSnapshot.hasData
                      ? eventSnapshot.data!.docs
                      : [];

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => _isPickerExpanded =
                                          !_isPickerExpanded,
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
                                  eventLoader: (day) {
                                    return allEvents.where((doc) {
                                      if (doc.data() is Map<String, dynamic> &&
                                          (doc.data() as Map<String, dynamic>)
                                              .containsKey('startTime') &&
                                          (doc.data() as Map<String, dynamic>)
                                              .containsKey('endTime')) {
                                        DateTime start =
                                            (doc['startTime'] as Timestamp)
                                                .toDate();
                                        DateTime end =
                                            (doc['endTime'] as Timestamp)
                                                .toDate();
                                        return _isDayInRange(day, start, end);
                                      }
                                      return false;
                                    }).toList();
                                  },
                                  calendarStyle: CalendarStyle(
                                    markersMaxCount: 1,
                                    markerDecoration: BoxDecoration(
                                      color: theme.primary,
                                      shape: BoxShape.circle,
                                    ),
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
                                        colors: [
                                          theme.primary,
                                          theme.primaryLight,
                                        ],
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
                          Container(
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
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => _showEventSheet(theme),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: theme.primaryLight.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: theme.primary,
                                          size: 20,
                                        ),
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
                                const SizedBox(height: 16),

                                Builder(
                                  builder: (context) {
                                    final dayEvents = allEvents.where((doc) {
                                      if (doc.data() is Map<String, dynamic> &&
                                          (doc.data() as Map<String, dynamic>)
                                              .containsKey('startTime') &&
                                          (doc.data() as Map<String, dynamic>)
                                              .containsKey('endTime')) {
                                        DateTime start =
                                            (doc['startTime'] as Timestamp)
                                                .toDate();
                                        DateTime end =
                                            (doc['endTime'] as Timestamp)
                                                .toDate();
                                        return _isDayInRange(
                                          _selectedDay!,
                                          start,
                                          end,
                                        );
                                      }
                                      return false;
                                    }).toList();

                                    return InkWell(
                                      onTap: dayEvents.isNotEmpty
                                          ? () => _showDayEventsSheet(
                                              theme,
                                              dayEvents,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: theme.primaryLight
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: theme.accent1
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${dayEvents.length}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.accent1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '이날의 일정 확인하기',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: theme.textBody,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: theme.textBody.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user?.uid)
                                      .collection('memos')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int dayMemoCount = 0;
                                    List<QueryDocumentSnapshot> dayMemos = [];

                                    if (snapshot.hasData) {
                                      DateTime start = DateTime(
                                        _selectedDay!.year,
                                        _selectedDay!.month,
                                        _selectedDay!.day,
                                      );
                                      DateTime end = DateTime(
                                        _selectedDay!.year,
                                        _selectedDay!.month,
                                        _selectedDay!.day,
                                        23,
                                        59,
                                        59,
                                        999,
                                      );

                                      dayMemos = snapshot.data!.docs.where((
                                        doc,
                                      ) {
                                        if (doc['folderId'] == 'trash')
                                          return false;
                                        DateTime dt =
                                            (doc['createdAt'] as Timestamp)
                                                .toDate();
                                        return dt.isAfter(
                                              start.subtract(
                                                const Duration(seconds: 1),
                                              ),
                                            ) &&
                                            dt.isBefore(end);
                                      }).toList();

                                      dayMemoCount = dayMemos.length;
                                    }

                                    return InkWell(
                                      onTap: dayMemoCount > 0
                                          ? () => _showDayMemosSheet(
                                              theme,
                                              dayMemos,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              color: theme.primaryLight
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: theme.primary
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$dayMemoCount',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '이날의 메모 확인하기',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: theme.textBody,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: theme.textBody.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 7. 마이페이지 ---
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

  void _showAuthDialogBeforeSettings(
    BuildContext context,
    AppThemeColor theme,
  ) {
    final passwordController = TextEditingController();
    bool isProcessing = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                '본인 확인 🔐',
                style: TextStyle(
                  color: theme.textHeader,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '설정에 접근하려면 비밀번호를 다시 입력해주세요.',
                    style: TextStyle(color: theme.textBody, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: theme.textHeader),
                    decoration: InputDecoration(
                      hintText: '현재 비밀번호',
                      hintStyle: TextStyle(
                        color: theme.textBody.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: theme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                  child: Text('취소', style: TextStyle(color: theme.textBody)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty) return;
                          setStateDialog(() {
                            isProcessing = true;
                            errorMessage = null;
                          });
                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                  email: user!.email!,
                                  password: passwordController.text,
                                )
                                .timeout(const Duration(seconds: 10));

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AccountSettingsPage(),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (_) {
                            setStateDialog(
                              () => errorMessage = '비밀번호가 일치하지 않습니다.',
                            );
                          } catch (_) {
                            setStateDialog(() => errorMessage = '오류가 발생했습니다.');
                          } finally {
                            setStateDialog(() => isProcessing = false);
                          }
                        },
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '확인',
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
      },
    );
  }

  void _showAppVersionDialog(BuildContext context, AppThemeColor theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Aura',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '버전 v0.0.2',
              style: TextStyle(
                fontSize: 16,
                color: theme.textBody.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '최신 버전을 사용 중입니다 ✨',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                '확인',
                style: TextStyle(
                  color: theme.textBody,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        String nickname = "사용자";
                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          nickname = userSnapshot.data!['nickname'] ?? "사용자";
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('memos')
                              .snapshots(),
                          builder: (context, memoSnapshot) {
                            int totalMemosCount = 0;
                            int activeDaysCount = 0;

                            if (memoSnapshot.hasData) {
                              final memos = memoSnapshot.data!.docs
                                  .where((doc) => doc['folderId'] != 'trash')
                                  .toList();
                              totalMemosCount = memos.length;

                              Set<String> uniqueDays = {};
                              for (var doc in memos) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (data['createdAt'] != null) {
                                  DateTime dt = (data['createdAt'] as Timestamp)
                                      .toDate();
                                  uniqueDays.add(
                                    '${dt.year}-${dt.month}-${dt.day}',
                                  );
                                }
                              }
                              activeDaysCount = uniqueDays.length;
                            }

                            return Container(
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
                                        colors: [
                                          theme.primary,
                                          theme.primaryLight,
                                        ],
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '반가워요, $nickname님! 👋',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textHeader,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user?.email ?? '',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.textBody.withOpacity(
                                              0.8,
                                            ),
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
                                                    color: theme.textBody
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '$totalMemosCount개',
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
                                                    color: theme.textBody
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '$activeDaysCount일',
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
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildMenuRow(
                            theme,
                            Icons.manage_accounts_rounded,
                            '계정 관리',
                            theme.primary,
                            () => _showAuthDialogBeforeSettings(context, theme),
                          ),
                          _buildMenuRow(
                            theme,
                            Icons.notifications_rounded,
                            '알림 설정',
                            theme.accent1,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationSettingsPage(),
                              ),
                            ),
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
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BackupRestorePage(),
                              ),
                            ),
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
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportPage(),
                              ),
                            ),
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.info_outline_rounded,
                            '앱 버전 정보 (v0.0.2)',
                            onTap: () => _showAppVersionDialog(context, theme),
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

  Widget _buildInfoRow(
    AppThemeColor theme,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryLight.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
          ),
        ),
      ),
    );
  }
}

// --- ⚙️ 8. 계정 설정 페이지 ---
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _emailController.text = doc['email'] ?? user.email ?? '';
          _idController.text = doc['userId'] ?? '';
          _nicknameController.text = doc['nickname'] ?? '';
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveBasicInfo(AppThemeColor theme) async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'email': _emailController.text.trim(),
            'userId': _idController.text.trim(),
            'nickname': _nicknameController.text.trim(),
          });

      if (user.email != _emailController.text.trim()) {
        try {
          await user.verifyBeforeUpdateEmail(_emailController.text.trim());
          CustomToast.show(
            context,
            '이메일 변경 인증 메일이 발송되었습니다. 확인해주세요!',
            theme.accent1,
          );
        } catch (e) {
          CustomToast.show(context, '이메일 변경 요청 실패', Colors.redAccent);
        }
      }

      CustomToast.show(context, '기본 정보가 성공적으로 저장되었습니다! ✨', theme.primary);
    } catch (e) {
      CustomToast.show(context, '저장에 실패했습니다.', Colors.redAccent);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '계정 관리',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
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
                        child: GlowBackground(
                          color: Colors.redAccent,
                          size: 250,
                        ),
                      ),

                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '기본 정보',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textHeader,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.surface.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.name.contains('다크')
                                        ? Colors.black.withOpacity(0.3)
                                        : theme.primaryLight.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: theme.primaryLight.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel(theme, '이메일 주소'),
                                  _buildTextField(
                                    theme,
                                    '이메일',
                                    Icons.email_outlined,
                                    controller: _emailController,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputLabel(theme, '아이디'),
                                  _buildTextField(
                                    theme,
                                    '아이디',
                                    Icons.badge_outlined,
                                    controller: _idController,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputLabel(theme, '닉네임'),
                                  _buildTextField(
                                    theme,
                                    '닉네임',
                                    Icons.face_rounded,
                                    controller: _nicknameController,
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _saveBasicInfo(theme),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primary,
                                      minimumSize: const Size(
                                        double.infinity,
                                        56,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      shadowColor: theme.primary.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            '저장하기',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 48),

                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '위험 구역',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildDangerItem(
                                    theme,
                                    '비밀번호 변경',
                                    Icons.lock_reset_rounded,
                                    () => showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) =>
                                          _PasswordChangeDialog(theme: theme),
                                    ),
                                  ),
                                  _buildDangerItem(
                                    theme,
                                    '로그아웃',
                                    Icons.logout_rounded,
                                    () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.pop(context);
                                      CustomToast.show(
                                        context,
                                        '로그아웃 되었습니다. 👋',
                                        Colors.orange,
                                      );
                                    },
                                  ),
                                  _buildDangerItem(
                                    theme,
                                    '회원 탈퇴',
                                    Icons.person_off_rounded,
                                    () => showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) =>
                                          _DeleteAccountDialog(theme: theme),
                                    ),
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInputLabel(AppThemeColor theme, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: theme.textHeader.withOpacity(0.7),
      ),
    ),
  );
  Widget _buildTextField(
    AppThemeColor theme,
    String hint,
    IconData icon, {
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.textHeader, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.primaryLight),
        filled: true,
        fillColor: theme.bg.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildDangerItem(
    AppThemeColor theme,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.redAccent.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.redAccent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textHeader,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.textBody.withOpacity(0.3),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: Colors.redAccent.withOpacity(0.2), height: 1),
          ),
      ],
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  final AppThemeColor theme;
  const _PasswordChangeDialog({required this.theme});
  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        '비밀번호 변경',
        style: TextStyle(
          color: widget.theme.textHeader,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '안전한 변경을 위해 현재 비밀번호를 입력해주세요.',
            style: TextStyle(color: widget.theme.textBody, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '현재 비밀번호',
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: widget.theme.textHeader),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '새 비밀번호 (6자리 이상)',
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: widget.theme.textHeader),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '새 비밀번호 재확인',
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: widget.theme.textHeader),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text('취소', style: TextStyle(color: widget.theme.textBody)),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  if (_newController.text != _confirmController.text)
                    return setState(
                      () => _errorMessage = '새 비밀번호가 서로 일치하지 않습니다.',
                    );
                  if (_newController.text.length < 6)
                    return setState(
                      () => _errorMessage = '새 비밀번호는 6자리 이상이어야 합니다.',
                    );
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = true;
                  });

                  try {
                    User? user = FirebaseAuth.instance.currentUser;
                    await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                          email: user!.email!,
                          password: _currentController.text,
                        )
                        .timeout(const Duration(seconds: 10));
                    await user
                        .updatePassword(_newController.text)
                        .timeout(const Duration(seconds: 10));
                    if (mounted) {
                      Navigator.pop(context);
                      CustomToast.show(
                        context,
                        '비밀번호가 안전하게 변경되었습니다. 🔒',
                        widget.theme.primary,
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password' ||
                        e.code == 'invalid-credential')
                      setState(() => _errorMessage = '현재 비밀번호가 일치하지 않습니다.');
                    else
                      setState(() => _errorMessage = '오류 발생: ${e.code}');
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.theme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  '변경하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final AppThemeColor theme;
  const _DeleteAccountDialog({required this.theme});
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        '회원 탈퇴',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정말로 탈퇴하시겠습니까?\n모든 데이터가 영구 삭제됩니다.',
            style: TextStyle(color: widget.theme.textBody, height: 1.5),
          ),
          const SizedBox(height: 20),
          Text(
            '본인 확인을 위해 비밀번호를 입력해주세요.',
            style: TextStyle(
              color: widget.theme.textHeader,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '비밀번호 입력',
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(color: widget.theme.textHeader),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: Text('취소', style: TextStyle(color: widget.theme.textBody)),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = true;
                  });

                  try {
                    User? user = FirebaseAuth.instance.currentUser;

                    // 1. 비밀번호 재인증
                    await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                          email: user!.email!,
                          password: _passwordController.text,
                        )
                        .timeout(const Duration(seconds: 10));

                    // --- 💡 데이터 영구 삭제 로직 추가 ---
                    final db = FirebaseFirestore.instance;
                    final uid = user.uid;

                    // 유저의 모든 하위 컬렉션 데이터 가져오기
                    final memos = await db
                        .collection('users')
                        .doc(uid)
                        .collection('memos')
                        .get();
                    final folders = await db
                        .collection('users')
                        .doc(uid)
                        .collection('folders')
                        .get();
                    final events = await db
                        .collection('users')
                        .doc(uid)
                        .collection('events')
                        .get();

                    // Firestore는 한 번에 최대 500개까지만 일괄 처리(Batch)가 가능합니다.
                    WriteBatch batch = db.batch();
                    int batchCount = 0;

                    // 모든 문서를 하나의 리스트로 합치기
                    final allDocs = [
                      ...memos.docs,
                      ...folders.docs,
                      ...events.docs,
                    ];

                    for (var doc in allDocs) {
                      batch.delete(doc.reference);
                      batchCount++;

                      // 500개가 차면 먼저 전송하고 새로운 Batch 시작
                      if (batchCount == 500) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                      }
                    }

                    // 남은 데이터 마저 전송
                    if (batchCount > 0) {
                      await batch.commit();
                    }
                    // ---------------------------------

                    // 2. 유저 부모 문서 삭제
                    await db.collection('users').doc(uid).delete();

                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                      CustomToast.show(
                        context,
                        '안전하게 탈퇴 처리되었으며, 모든 데이터가 파기되었습니다. 😭',
                        Colors.redAccent,
                      );
                    }

                    // 3. Auth(인증) 계정 영구 삭제
                    await user.delete();
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password' ||
                        e.code == 'invalid-credential') {
                      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
                    } else {
                      setState(() => _errorMessage = '오류 발생: ${e.code}');
                    }
                  } catch (e) {
                    setState(() => _errorMessage = '서버 통신 중 오류가 발생했습니다.');
                  } finally {
                    if (mounted) setState(() => _isProcessing = false);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  '탈퇴하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

// --- 🔔 알림 설정 페이지 ---
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _eventAlertEnabled = true;
  bool _marketingEnabled = false;

  Widget _buildSwitchTile(
    AppThemeColor theme,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크')
                ? Colors.black.withOpacity(0.2)
                : theme.primaryLight.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textHeader,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textBody.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: theme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '알림 설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '어떤 소식을 받을지 선택해주세요 📮',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textHeader,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSwitchTile(
                  theme,
                  '앱 푸시 알림',
                  'Aura의 기본적인 알림을 받습니다.',
                  _pushEnabled,
                  (v) => setState(() => _pushEnabled = v),
                ),
                _buildSwitchTile(
                  theme,
                  '일정 리마인더',
                  '캘린더에 등록한 일정 알림을 받습니다.',
                  _eventAlertEnabled,
                  (v) => setState(() => _eventAlertEnabled = v),
                ),
                _buildSwitchTile(
                  theme,
                  '마케팅 정보 수신',
                  '새로운 기능과 이벤트 소식을 받습니다.',
                  _marketingEnabled,
                  (v) {
                    setState(() => _marketingEnabled = v);
                    if (v)
                      CustomToast.show(
                        context,
                        '마케팅 정보 수신에 동의하셨습니다. 🎉',
                        theme.primary,
                      );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- ☁️ 데이터 백업/복원 페이지 ---
class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  bool _isProcessing = false;
  String _lastBackupDate = '2026.03.24 10:42';

  Future<void> _handleBackup(AppThemeColor theme) async {
    setState(() => _isProcessing = true);
    // 실제 백업 로직 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isProcessing = false;
      _lastBackupDate =
          '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    });
    if (mounted)
      CustomToast.show(context, '데이터가 안전하게 클라우드에 백업되었습니다! ☁️', theme.primary);
  }

  Future<void> _handleRestore(AppThemeColor theme) async {
    setState(() => _isProcessing = true);
    // 실제 복원 로직 시뮬레이션
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isProcessing = false);
    if (mounted)
      CustomToast.show(context, '마지막 백업 데이터로 복원이 완료되었습니다. ✨', theme.accent1);
  }

  Widget _buildActionCard(
    AppThemeColor theme,
    String title,
    String desc,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _isProcessing ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textHeader,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textBody.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '데이터 백업 / 복원',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            centerTitle: true,
          ),
          body: _isProcessing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.primary),
                      const SizedBox(height: 16),
                      Text(
                        '클라우드 서버와 통신 중입니다...',
                        style: TextStyle(
                          color: theme.textHeader,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryLight.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: theme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '마지막 백업: $_lastBackupDate',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildActionCard(
                        theme,
                        '지금 데이터 백업하기',
                        '현재 기기의 모든 메모, 폴더, 일정을 안전하게 클라우드에 저장합니다.',
                        Icons.cloud_upload_rounded,
                        theme.primary,
                        () => _handleBackup(theme),
                      ),
                      _buildActionCard(
                        theme,
                        '백업 데이터 복원하기',
                        '클라우드에 저장된 마지막 데이터를 현재 기기로 불러옵니다.',
                        Icons.cloud_download_rounded,
                        theme.accent1,
                        () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                '데이터 복원',
                                style: TextStyle(
                                  color: theme.textHeader,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                '현재 기기의 데이터가 백업된 데이터로 덮어씌워집니다. 계속할까요?',
                                style: TextStyle(color: theme.textBody),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(color: theme.textBody),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primary,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleRestore(theme);
                                  },
                                  child: const Text(
                                    '복원하기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// --- 🎧 도움말 및 문의 페이지 ---
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Widget _buildFaqItem(AppThemeColor theme, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.primary,
          collapsedIconColor: theme.textBody.withOpacity(0.5),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textHeader,
              fontSize: 15,
            ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: theme.textBody,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          backgroundColor: theme.bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: theme.textHeader,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '도움말 및 문의',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '자주 묻는 질문 🤔',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textHeader,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFaqItem(
                  theme,
                  '메모 폴더는 어떻게 삭제하나요?',
                  '폴더 목록에서 지우고 싶은 폴더를 길게 꾹 누르시면 메뉴 창이 나타납니다. 거기서 삭제를 선택할 수 있어요.',
                ),
                _buildFaqItem(
                  theme,
                  '임시 폴더는 무엇인가요?',
                  '폴더를 삭제했을 때 그 안의 메모들이 안전하게 이동되는 기본 폴더입니다. 메모가 비어있을 때만 지울 수 있습니다.',
                ),
                _buildFaqItem(
                  theme,
                  '비밀번호를 잊어버렸어요.',
                  '로그인 화면 하단의 [비밀번호 찾기]를 통해 가입하신 이메일로 비밀번호 재설정 링크를 받으실 수 있습니다.',
                ),
                _buildFaqItem(
                  theme,
                  '데이터는 안전하게 보관되나요?',
                  '네, 작성하신 모든 데이터는 Google Firebase의 강력한 보안 시스템을 통해 암호화되어 안전하게 보관됩니다.',
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 48,
                        color: theme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '더 도움이 필요하신가요?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.textHeader,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '언제든 편하게 문의를 남겨주세요.',
                        style: TextStyle(
                          color: theme.textBody.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // 💡 이메일 주소 업데이트 완료
                          CustomToast.show(
                            context,
                            '아래 이메일로 문의를 남겨주세요!\nll.team.aura.ll@gmail.com',
                            theme.primary,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '1:1 문의하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
