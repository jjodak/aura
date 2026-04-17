// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

// --- 🎧 도움말 및 문의 페이지 ---
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  Widget _buildFaqItem(AppThemeColor theme, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.primaryLight.withOpacity(0.2)),
        ),
        child: Theme(
          data: ThemeData(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
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
                        onPressed: () async {
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'll.team.aura.ll@gmail.com',
                            query: 'subject=Aura 앱 문의',
                          );
                          if (!await launchUrl(emailLaunchUri)) {
                            if (context.mounted) {
                              CustomToast.show(
                                context,
                                '메일 앱을 열 수 없습니다. 아래 주소로 문의를 남겨주세요!\nll.team.aura.ll@gmail.com',
                                theme.primary,
                              );
                            }
                          }
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
