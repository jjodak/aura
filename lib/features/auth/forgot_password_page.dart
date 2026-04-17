// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/services/email_service.dart';

// --- ✨ 2-1. 비밀번호 찾기 (OTP 방식) 페이지 ---
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _generatedOtp = "";
  bool _isOtpSent = false;
  bool _isEmailVerified = false;
  bool _isLoading = false;

  // 1. 가입된 이메일인지 확인 후 인증번호 발송
  Future<void> _checkEmailAndSendOtp() async {
    FocusScope.of(context).unfocus();
    String email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      CustomToast.show(context, '올바른 이메일 주소를 입력해주세요.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firestore에서 해당 이메일을 가진 사용자가 있는지 확인
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        CustomToast.show(context, '가입되지 않은 이메일입니다.', Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // 💡 EmailService를 사용하여 인증번호 발송 (중복 코드 제거)
      _generatedOtp = EmailService.generateOtp();
      final success = await EmailService.sendOtp(email, _generatedOtp);

      if (success) {
        setState(() => _isOtpSent = true);
        CustomToast.show(context, '인증번호가 발송되었습니다! 💌', Colors.blueAccent);
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

  // 2. 인증번호 확인
  void _verifyOtp() {
    if (_otpController.text.trim() == _generatedOtp && _generatedOtp.isNotEmpty) {
      setState(() => _isEmailVerified = true);
      CustomToast.show(context, '인증 성공! 새 비밀번호를 입력해주세요. ✨', Colors.green);
    } else {
      CustomToast.show(context, '인증번호가 일치하지 않습니다.', Colors.redAccent);
    }
  }

  // 3. 비밀번호 재설정 실행
  Future<void> _resetPassword(AppThemeColor theme) async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      CustomToast.show(context, '비밀번호가 일치하지 않습니다.', Colors.orange);
      return;
    }
    if (_newPasswordController.text.length < 6) {
      CustomToast.show(context, '비밀번호는 6자리 이상이어야 합니다.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      
      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(
          context,
          '비밀번호 재설정 링크가 이메일로 발송되었습니다.\n(인증 완료 확인됨) ✨',
          theme.primary,
        );
      }
    } catch (e) {
      CustomToast.show(context, '재설정 중 오류가 발생했습니다.', Colors.redAccent);
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
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textHeader),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('비밀번호 찾기', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textHeader)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildInfoCard(theme),
                const SizedBox(height: 32),
                
                _buildSection(
                  theme,
                  title: '이메일 인증',
                  child: Column(
                    children: [
                      _buildTextField(theme, '가입한 이메일 주소', Icons.email_outlined, 
                          controller: _emailController, enabled: !_isEmailVerified),
                      if (_isOtpSent && !_isEmailVerified) ...[
                        const SizedBox(height: 16),
                        _buildTextField(theme, '인증번호 6자리', Icons.lock_clock_outlined, 
                            controller: _otpController),
                      ],
                      const SizedBox(height: 24),
                      _buildAuthButtons(theme),
                    ],
                  ),
                ),

                if (_isEmailVerified) ...[
                  const SizedBox(height: 32),
                  _buildSection(
                    theme,
                    title: '새 비밀번호 설정',
                    child: Column(
                      children: [
                        _buildTextField(theme, '새 비밀번호', Icons.lock_outline_rounded, 
                            isPassword: true, controller: _newPasswordController),
                        const SizedBox(height: 16),
                        _buildTextField(theme, '비밀번호 재확인', Icons.lock_reset_rounded, 
                            isPassword: true, controller: _confirmPasswordController),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _resetPassword(theme),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('비밀번호 변경하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(AppThemeColor theme, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: theme.primaryLight.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textHeader)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAuthButtons(AppThemeColor theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: (_isOtpSent || _isEmailVerified) ? null : _checkEmailAndSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryLight,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('인증 발송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: (_isOtpSent && !_isEmailVerified) ? _verifyOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEmailVerified ? Colors.grey : theme.primary,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(_isEmailVerified ? '인증 완료' : '인증 확인', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(AppThemeColor theme) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: theme.accent1.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Row(
      children: [
        Icon(Icons.info_outline_rounded, color: theme.accent1),
        const SizedBox(width: 12),
        Expanded(
          child: Text('비밀번호를 잊으셨나요?\n이메일 인증을 통해 안전하게 재설정할 수 있습니다.',
              style: TextStyle(color: theme.textBody, fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );

  Widget _buildTextField(AppThemeColor theme, String hint, IconData icon, 
      {bool isPassword = false, required TextEditingController controller, bool enabled = true}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      style: TextStyle(color: theme.textHeader),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.textBody.withOpacity(0.4), fontSize: 14),
        prefixIcon: Icon(icon, color: theme.primaryLight, size: 20),
        filled: true,
        fillColor: theme.bg.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
