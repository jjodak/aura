// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';
import 'sign_up_page.dart';
import 'forgot_password_page.dart';

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
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordPage(),
                                ),
                              ),
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
