// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/services/notification_service.dart';

// --- 🔔 알림 설정 페이지 ---
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _pushEnabled = false;
  bool _eventAlertEnabled = false;
  bool _reminderEnabled = false;
  int _reminderHour = 20;
  int _reminderMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_enabled') ?? false;
      _eventAlertEnabled = prefs.getBool('event_alert_enabled') ?? false;
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
      _reminderHour = prefs.getInt('reminder_hour') ?? 20;
      _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _togglePush(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermissions();
      if (!granted) {
        if (mounted) {
          CustomToast.show(context, '기기의 설정에서 알림 권한을 허용해주세요.', appThemeNotifier.value.primary);
        }
        return;
      }
    } else {
      await NotificationService().cancelAllNotifications();
      setState(() {
        _eventAlertEnabled = false;
        _reminderEnabled = false;
      });
      await _saveSetting('event_alert_enabled', false);
      await _saveSetting('reminder_enabled', false);
    }
    setState(() {
      _pushEnabled = value;
    });
    await _saveSetting('push_enabled', value);
  }

  Future<void> _toggleEventAlert(bool value) async {
    if (!_pushEnabled && value) return; // 알림 전체가 꺼져있으면 켤 수 없음
    setState(() {
      _eventAlertEnabled = value;
    });
    await _saveSetting('event_alert_enabled', value);
  }

  Future<void> _toggleReminder(bool value) async {
    if (!_pushEnabled && value) return; // 알림 전체가 꺼져있으면 켤 수 없음
    setState(() {
      _reminderEnabled = value;
    });
    await _saveSetting('reminder_enabled', value);
    await NotificationService().scheduleDailyReminder(
      value,
      hour: _reminderHour,
      minute: _reminderMinute,
    );
    
    if (value && mounted) {
      final String timeStr = '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';
      CustomToast.show(
        context,
        '매일 $timeStr분에 작성 알림 설정이 완료되었습니다! 📝',
        appThemeNotifier.value.primary,
      );
    }
  }

  Future<void> _selectTime() async {
    DateTime tempDate = DateTime(2026, 1, 1, _reminderHour, _reminderMinute);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: appThemeNotifier.value.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '알림 시간 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appThemeNotifier.value.textHeader,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('완료', style: TextStyle(color: appThemeNotifier.value.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: appThemeNotifier.value.textHeader,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: tempDate,
                    onDateTimeChanged: (newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    setState(() {
      _reminderHour = tempDate.hour;
      _reminderMinute = tempDate.minute;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', _reminderHour);
    await prefs.setInt('reminder_minute', _reminderMinute);

    if (_reminderEnabled) {
      await NotificationService().scheduleDailyReminder(
        true,
        hour: _reminderHour,
        minute: _reminderMinute,
      );
      if (mounted) {
        final String timeStr = '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';
        CustomToast.show(
          context,
          '알림 시간이 $timeStr분으로 변경되었습니다! ✨',
          appThemeNotifier.value.primary,
        );
      }
    }
  }

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
                  _togglePush,
                ),
                _buildSwitchTile(
                  theme,
                  '일정 알림',
                  '캘린더에 등록한 일정 리마인더를 받습니다.',
                  _eventAlertEnabled,
                  _toggleEventAlert,
                ),
                _buildSwitchTile(
                  theme,
                  '기록 리마인더',
                  '하루를 돌아보며 메모를 남기도록 기억나게 해줍니다.',
                  _reminderEnabled,
                  _toggleReminder,
                ),
                if (_reminderEnabled)
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.surface.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        border: Border.all(color: theme.primaryLight.withOpacity(0.1)),
                      ),
                      child: InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 20, color: theme.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    '알림 시간 설정',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textHeader,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
