// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

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
