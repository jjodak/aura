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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: -100.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
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
          top: _animation.value + MediaQuery.of(context).padding.top,
          left: 24,
          right: 24,
          child: Material(
            elevation: 15,
            borderRadius: BorderRadius.circular(100),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

// --- ✨ 2. 회원가입 페이지 (EmailJS 6자리 인증 완벽 적용) ---
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

                    // --- [STEP 1] 이메일 및 인증번호 영역 ---
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

                    // --- [STEP 2] 상세 계정 정보 영역 ---
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

  @override
  void initState() {
    super.initState();
    _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)];
  }

  void _saveMemo() {
    final theme = appThemeNotifier.value;
    if (_controller.text.trim().isEmpty) {
      CustomToast.show(context, '메모 내용을 먼저 입력해 주세요! ✍️', theme.accent2);
      return;
    }
    FocusScope.of(context).unfocus();
    CustomToast.show(context, '메모가 저장되었습니다. 🌿', theme.primary);
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

// --- 5. 메모 저장 폴더 화면 ---
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

// --- 7. 마이페이지 (디자인 시스템 완벽 복구 및 파이어베이스 연동) ---
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
                      builder: (context, snapshot) {
                        String nickname = "사용자";
                        if (snapshot.hasData && snapshot.data!.exists) {
                          nickname = snapshot.data!['nickname'] ?? "사용자";
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
                                                color: theme.textBody
                                                    .withOpacity(0.6),
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
                                                color: theme.textBody
                                                    .withOpacity(0.6),
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
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AccountSettingsPage(),
                              ),
                            ),
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
                            '앱 버전 정보 (v0.0.1)',
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

// --- 8. 계정 설정 페이지 ---
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

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
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  right: -50,
                  child: GlowBackground(color: theme.primary, size: 320),
                ),
                ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSettingsItem(
                      theme,
                      '비밀번호 변경',
                      Icons.lock_reset_rounded,
                      theme.primary,
                      () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => _PasswordChangeDialog(theme: theme),
                      ),
                    ),
                    _buildSettingsItem(
                      theme,
                      '로그아웃',
                      Icons.logout_rounded,
                      Colors.orange,
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
                    _buildSettingsItem(
                      theme,
                      '회원 탈퇴',
                      Icons.person_off_rounded,
                      Colors.redAccent,
                      () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => _DeleteAccountDialog(theme: theme),
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

  Widget _buildSettingsItem(
    AppThemeColor theme,
    String title,
    IconData icon,
    Color baseColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: baseColor.withOpacity(0.2),
          highlightColor: baseColor.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: baseColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: baseColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textHeader,
                    ),
                  ),
                ),
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

// 💡 팝업창 1: 비밀번호 변경 다이얼로그 (윈도우 무한로딩 우회 완벽 적용)
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
          TextField(
            controller: _currentController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: '현재 비밀번호',
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
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
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
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
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
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
                  if (_newController.text != _confirmController.text) {
                    setState(() => _errorMessage = '새 비밀번호가 서로 일치하지 않습니다.');
                    return;
                  }
                  if (_newController.text.length < 6) {
                    setState(() => _errorMessage = '새 비밀번호는 6자리 이상이어야 합니다.');
                    return;
                  }
                  setState(() {
                    _errorMessage = null;
                    _isProcessing = true;
                  });

                  try {
                    User? user = FirebaseAuth.instance.currentUser;

                    // 🔥 [핵심 수정] 윈도우 에러 피하기 위한 백그라운드 재로그인
                    await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                          email: user!.email!,
                          password: _currentController.text,
                        )
                        .timeout(const Duration(seconds: 10));

                    // 인증 통과 시 비밀번호 업데이트
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
                        e.code == 'invalid-credential') {
                      setState(() => _errorMessage = '현재 비밀번호가 일치하지 않습니다.');
                    } else if (e.code == 'weak-password') {
                      setState(() => _errorMessage = '비밀번호가 너무 약합니다.');
                    } else {
                      setState(() => _errorMessage = '오류 발생: ${e.code}');
                    }
                  } on TimeoutException catch (_) {
                    setState(() => _errorMessage = '서버 응답 시간이 초과되었습니다.');
                  } catch (e) {
                    setState(() => _errorMessage = '알 수 없는 오류 발생');
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

// 💡 팝업창 2: 회원 탈퇴 다이얼로그 (윈도우 무한로딩 우회 완벽 적용)
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
            '정말로 탈퇴하시겠습니까?\n모든 메모와 설정이 삭제되며 복구할 수 없습니다.',
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
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
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

                    // 🔥 [핵심 수정] 윈도우 에러 피하기 위한 백그라운드 재로그인
                    await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                          email: user!.email!,
                          password: _passwordController.text,
                        )
                        .timeout(const Duration(seconds: 10));

                    // 1. DB 정보 삭제
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete()
                        .timeout(const Duration(seconds: 10));

                    if (mounted) {
                      // 2. 화면 안전하게 닫기
                      Navigator.pop(context); // 팝업 닫기
                      Navigator.pop(context); // 설정화면 닫기
                      CustomToast.show(
                        context,
                        '안전하게 탈퇴 처리되었습니다. 😭',
                        Colors.redAccent,
                      );
                    }

                    // 3. 마지막으로 계정 삭제
                    await user.delete();
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password' ||
                        e.code == 'invalid-credential') {
                      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다.');
                    } else {
                      setState(() => _errorMessage = '오류 발생: ${e.code}');
                    }
                  } on TimeoutException catch (_) {
                    setState(() => _errorMessage = '서버 응답 시간이 초과되었습니다.');
                  } catch (e) {
                    setState(
                      () => _errorMessage =
                          'Firestore 보안 규칙 에러입니다!\n데이터를 지울 권한이 없습니다.',
                    );
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
