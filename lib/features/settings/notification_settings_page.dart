// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

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
