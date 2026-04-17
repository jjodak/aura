import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';
import '../settings/account_settings_page.dart';
import '../settings/notification_settings_page.dart';
import '../settings/backup_restore_page.dart';
import '../settings/help_support_page.dart';

// --- 7. 마이페이지 ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showThemePicker(BuildContext context, AppThemeColor currentTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: currentTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '테마 선택하기 🎨',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: currentTheme.textHeader,
                ),
              ),
              SizedBox(height: 24.h),
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
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.primary.withOpacity(0.15)
                            : (currentTheme.name.contains('다크')
                                  ? Color(0xFF2A2A2A)
                                  : Color(0xFFF5F5F5)),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isSelected ? t.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(t.emoji, style: TextStyle(fontSize: 24.sp)),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: currentTheme.textHeader,
                                fontSize: 14.sp,
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
                borderRadius: BorderRadius.circular(24.r),
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
                    style: TextStyle(color: theme.textBody, fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
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
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: 12.h),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12.sp,
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
                                .timeout(Duration(seconds: 10));

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AccountSettingsPage(),
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
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        contentPadding: EdgeInsets.all(32.w),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.primary, size: 48),
            SizedBox(height: 16.h),
            Text(
              'Aura',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: theme.textHeader,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '버전 v0.0.3',
              style: TextStyle(
                fontSize: 16.sp,
                color: theme.textBody.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: theme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                '최신 버전을 사용 중입니다 ✨',
                style: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
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
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: theme.accent1,
                          size: 24,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'My Space',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.textBody.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '마이페이지',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.textHeader,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      '나만의 설정과 정보를 관리하세요',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 32.h),

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
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primary.withOpacity(0.15),
                                    theme.accent1.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(32.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.name.contains('다크')
                                        ? Colors.black.withOpacity(0.4)
                                        : theme.primaryLight.withOpacity(0.25),
                                    blurRadius: 40,
                                    offset: Offset(0, 10),
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
                                      borderRadius: BorderRadius.circular(20.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primary.withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 20.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '반가워요, $nickname님! 👋',
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: theme.textHeader,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          user?.email ?? '',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: theme.textBody.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16.h),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '총 메모',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: theme.textBody
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '$totalMemosCount개',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(width: 24.w),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '활동일',
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color: theme.textBody
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                                Text(
                                                  '$activeDaysCount일',
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
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
                    SizedBox(height: 32.h),

                    Column(
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
                                    NotificationSettingsPage(),
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
                                builder: (context) => BackupRestorePage(),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Divider(
                            color: theme.name.contains('다크')
                                ? Colors.white24
                                : Color(0xFFE8E8E8),
                            thickness: 1,
                          ),
                          SizedBox(height: 16.h),
                          _buildInfoRow(
                            theme,
                            Icons.help_outline_rounded,
                            '도움말 및 문의',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HelpSupportPage(),
                              ),
                            ),
                          ),
                          _buildInfoRow(
                            theme,
                            Icons.info_outline_rounded,
                            '앱 버전 정보 (v0.0.3)',
                            onTap: () => _showAppVersionDialog(context, theme),
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
  }

  Widget _buildMenuRow(
    AppThemeColor theme,
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크')
                ? Colors.black.withOpacity(0.3)
                : theme.primaryLight.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24.r),
          hoverColor: theme.primaryLight.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textHeader,
                  ),
                ),
                Spacer(),
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
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: theme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.primaryLight.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: theme.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: theme.textBody, size: 20),
                ),
                SizedBox(width: 16.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.textBody,
                  ),
                ),
                Spacer(),
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
