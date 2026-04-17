// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';

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
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _emailController.text = data.containsKey('email') ? data['email'] : user.email ?? '';
            _idController.text = data.containsKey('userId') ? data['userId'] : '';
            _nicknameController.text = data.containsKey('nickname') ? data['nickname'] : '';
          });
        } else {
          setState(() {
            _emailController.text = user.email ?? '';
          });
        }
      } catch (e) {
        setState(() {
          _emailController.text = user.email ?? '';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveBasicInfo(AppThemeColor theme) async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // update 대신 set과 merge 옵션을 사용하여 유저 문서가 없어도 생성되도록 수정
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'email': _emailController.text.trim(),
            'userId': _idController.text.trim(),
            'nickname': _nicknameController.text.trim(),
          }, SetOptions(merge: true));

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
                                          PasswordChangeDialog(theme: theme),
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
                                          DeleteAccountDialog(theme: theme),
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

// --- 비밀번호 변경 다이얼로그 ---
class PasswordChangeDialog extends StatefulWidget {
  final AppThemeColor theme;
  const PasswordChangeDialog({super.key, required this.theme});
  @override
  State<PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<PasswordChangeDialog> {
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

// --- 회원탈퇴 다이얼로그 ---
class DeleteAccountDialog extends StatefulWidget {
  final AppThemeColor theme;
  const DeleteAccountDialog({super.key, required this.theme});
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
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

                    // --- 💡 데이터 영구 삭제 로직 ---
                    final db = FirebaseFirestore.instance;
                    final uid = user.uid;

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

                    WriteBatch batch = db.batch();
                    int batchCount = 0;

                    final allDocs = [
                      ...memos.docs,
                      ...folders.docs,
                      ...events.docs,
                    ];

                    for (var doc in allDocs) {
                      batch.delete(doc.reference);
                      batchCount++;

                      if (batchCount == 500) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                      }
                    }

                    if (batchCount > 0) {
                      await batch.commit();
                    }

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
