// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

// --- 💡 일정 추가/수정용 바텀 시트 ---
// 원래 _EventBottomSheet (private)였으나 별도 파일로 분리하면서 public으로 변경
class EventBottomSheet extends StatefulWidget {
  final AppThemeColor theme;
  final DateTime selectedDate;
  final DocumentSnapshot? eventDoc;

  const EventBottomSheet({
    super.key,
    required this.theme,
    required this.selectedDate,
    this.eventDoc,
  });

  @override
  State<EventBottomSheet> createState() => _EventBottomSheetState();
}

class _EventBottomSheetState extends State<EventBottomSheet> {
  final TextEditingController _eventController = TextEditingController();
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  int? _alarmMinutes;
  bool _isStartPickerOpen = false;
  bool _isEndPickerOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventDoc != null) {
      final data = widget.eventDoc!.data() as Map<String, dynamic>;
      _eventController.text = data['title'] ?? '';
      _startDateTime = (data['startTime'] as Timestamp).toDate();
      _endDateTime = (data['endTime'] as Timestamp).toDate();
      _alarmMinutes = data['alarmMinutes'];
    } else {
      DateTime now = DateTime.now();
      _startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        now.hour,
        0,
      );
      _endDateTime = _startDateTime.add(const Duration(hours: 1));
    }
  }

  void _toggleStartPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isStartPickerOpen = !_isStartPickerOpen;
      if (_isStartPickerOpen) _isEndPickerOpen = false;
    });
  }

  void _toggleEndPicker() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isEndPickerOpen = !_isEndPickerOpen;
      if (_isEndPickerOpen) _isStartPickerOpen = false;
    });
  }

  void _showAlarmPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                '알림 설정',
                style: TextStyle(
                  color: widget.theme.textHeader,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildAlarmOption('없음', null, ctx),
              _buildAlarmOption('5분 전', 5, ctx),
              _buildAlarmOption('10분 전', 10, ctx),
              _buildAlarmOption('30분 전', 30, ctx),
              _buildAlarmOption('1시간 전', 60, ctx),
              _buildAlarmOption('1일 전', 1440, ctx),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlarmOption(String label, int? minutes, BuildContext ctx) {
    return ListTile(
      title: Text(label, style: TextStyle(color: widget.theme.textHeader)),
      trailing: _alarmMinutes == minutes
          ? Icon(Icons.check_rounded, color: widget.theme.primary)
          : null,
      onTap: () {
        setState(() => _alarmMinutes = minutes);
        Navigator.pop(ctx);
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _getAlarmText() {
    if (_alarmMinutes == null) return '없음';
    if (_alarmMinutes == 5) return '5분 전';
    if (_alarmMinutes == 10) return '10분 전';
    if (_alarmMinutes == 30) return '30분 전';
    if (_alarmMinutes == 60) return '1시간 전';
    if (_alarmMinutes == 1440) return '1일 전';
    return '설정됨';
  }

  Future<void> _saveEvent() async {
    if (_eventController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final data = {
      'title': _eventController.text.trim(),
      'startTime': Timestamp.fromDate(_startDateTime),
      'endTime': Timestamp.fromDate(_endDateTime),
      'alarmMinutes': _alarmMinutes,
    };

    if (widget.eventDoc == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('events')
          .add(data);
    } else {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await widget.eventDoc!.reference.update(data);
    }

    if (mounted) {
      Navigator.pop(context);
      CustomToast.show(
        context,
        widget.eventDoc == null ? '일정이 등록되었습니다! ✨' : '일정이 수정되었습니다! ✍️',
        widget.theme.primary,
      );
    }
  }

  Future<void> _deleteEvent() async {
    if (widget.eventDoc == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '일정 삭제',
          style: TextStyle(
            color: widget.theme.textHeader,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '이 일정을 삭제할까요?',
          style: TextStyle(color: widget.theme.textBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: widget.theme.textBody)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('events')
                      .doc(widget.eventDoc!.id)
                      .delete();
                }

                if (mounted) {
                  Navigator.pop(context);
                  CustomToast.show(
                    context,
                    '일정이 깔끔하게 삭제되었습니다. 🗑️',
                    Colors.orange,
                  );
                }
              } catch (e) {
                CustomToast.show(
                  context,
                  '삭제 중 서버 오류가 발생했습니다.',
                  Colors.redAccent,
                );
              }
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.eventDoc == null ? '새로운 일정 추가 🗓️' : '일정 수정 ✏️',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.theme.textHeader,
                ),
              ),
              Row(
                children: [
                  if (widget.eventDoc != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: _deleteEvent,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: widget.theme.textBody,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _eventController,
            style: TextStyle(color: widget.theme.textHeader, fontSize: 18),
            decoration: InputDecoration(
              hintText: '일정 제목',
              hintStyle: TextStyle(
                color: widget.theme.textBody.withOpacity(0.5),
              ),
              filled: true,
              fillColor: widget.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildDateTimeSection('시작', _startDateTime, true),
          const SizedBox(height: 16),
          _buildDateTimeSection('종료', _endDateTime, false),
          const SizedBox(height: 16),

          InkWell(
            onTap: _showAlarmPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: widget.theme.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: widget.theme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '알림',
                    style: TextStyle(
                      color: widget.theme.textBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getAlarmText(),
                    style: TextStyle(
                      color: widget.theme.textHeader,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saveEvent,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.eventDoc == null ? '일정 저장하기' : '수정 완료',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(String label, DateTime dt, bool isStart) {
    bool isOpen = isStart ? _isStartPickerOpen : _isEndPickerOpen;

    return Column(
      children: [
        InkWell(
          onTap: isStart ? _toggleStartPicker : _toggleEndPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: widget.theme.bg,
              borderRadius: BorderRadius.circular(16),
              border: isOpen
                  ? Border.all(color: widget.theme.primary.withOpacity(0.5))
                  : Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: isOpen ? widget.theme.primary : widget.theme.accent1,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isOpen ? widget.theme.primary : widget.theme.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(dt),
                  style: TextStyle(
                    color: widget.theme.textHeader,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isOpen ? 200 : 0,
          margin: const EdgeInsets.only(top: 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(),
          child: isOpen
              ? CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: widget.theme.textHeader,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: dt,
                    onDateTimeChanged: (newDate) {
                      setState(() {
                        if (isStart) {
                          _startDateTime = newDate;
                          if (_startDateTime.isAfter(_endDateTime)) {
                            _endDateTime = _startDateTime.add(const Duration(hours: 1));
                          }
                        } else {
                          _endDateTime = newDate;
                          if (_endDateTime.isBefore(_startDateTime)) {
                            _startDateTime = _endDateTime.subtract(const Duration(hours: 1));
                          }
                        }
                      });
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
