// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';
import '../../core/services/email_service.dart';

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
    _generatedOtp = EmailService.generateOtp();

    try {
      final success = await EmailService.sendOtp(
        _emailController.text.trim(),
        _generatedOtp,
      );

      if (success) {
        setState(() => _isOtpSent = true);
        CustomToast.show(
          context,
          '인증번호가 발송되었습니다.\n메일함에서 6자리 숫자를 확인해주세요! 💌',
          Colors.blueAccent,
        );
      } else {
        CustomToast.show(context, '발송 실패: 이메일 서버를 확인해주세요.', Colors.redAccent);
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
