import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// EmailJS를 통한 인증번호 발송 서비스
/// SignUpPage, ForgotPasswordPage에서 공통 사용
class EmailService {
  static const _serviceId = 'service_0kg1egk';
  static const _templateId = 'template_a3aimju';
  static const _publicKey = 'qB5sTKurzqvVg4WCZ';

  /// 6자리 OTP 코드 생성
  static String generateOtp() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  /// EmailJS를 통해 인증번호 이메일 발송
  /// 성공 시 true, 실패 시 false 반환
  static Future<bool> sendOtp(String email, String otp) async {
    final response = await http
        .post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': _serviceId,
            'template_id': _templateId,
            'user_id': _publicKey,
            'template_params': {
              'to_email': email,
              'auth_code': otp,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    return response.statusCode == 200;
  }
}
