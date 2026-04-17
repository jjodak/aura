import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glow_background.dart';
import '../memo/memo_edit_screen.dart';
import 'event_bottom_sheet.dart';

// --- 6. 캘린더 화면 ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  bool _isPickerExpanded = false;
  final User? user = FirebaseAuth.instance.currentUser;

  bool _isDayInRange(DateTime day, DateTime start, DateTime end) {
    DateTime dayOnly = DateTime(day.year, day.month, day.day);
    DateTime startOnly = DateTime(start.year, start.month, start.day);
    DateTime endOnly = DateTime(end.year, end.month, end.day);
    return !dayOnly.isBefore(startOnly) && !dayOnly.isAfter(endOnly);
  }

  Map<String, int> _assignTracks(List<QueryDocumentSnapshot> allEvents) {
    List<QueryDocumentSnapshot> sortedDocs = List.from(allEvents)
      ..sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        if (!dataA.containsKey('startTime') || !dataB.containsKey('startTime')) return 0;

        final startA = (dataA['startTime'] as Timestamp).toDate();
        final endA = (dataA['endTime'] as Timestamp).toDate();
        final startB = (dataB['startTime'] as Timestamp).toDate();
        final endB = (dataB['endTime'] as Timestamp).toDate();

        DateTime sA = DateTime(startA.year, startA.month, startA.day);
        DateTime eA = DateTime(endA.year, endA.month, endA.day);
        DateTime sB = DateTime(startB.year, startB.month, startB.day);
        DateTime eB = DateTime(endB.year, endB.month, endB.day);

        int lenA = eA.difference(sA).inDays;
        int lenB = eB.difference(sB).inDays;

        if (lenA != lenB) return lenB.compareTo(lenA);
        return sA.compareTo(sB);
      });

    List<List<Map<String, DateTime>>> tracks = [];
    Map<String, int> assigned = {};

    for (var doc in sortedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (!data.containsKey('startTime')) continue;

      final start = (data['startTime'] as Timestamp).toDate();
      final end = (data['endTime'] as Timestamp).toDate();
      DateTime s = DateTime(start.year, start.month, start.day);
      DateTime e = DateTime(end.year, end.month, end.day);

      int targetTrack = -1;
      for (int i = 0; i < tracks.length; i++) {
        bool overlaps = false;
        for (var existing in tracks[i]) {
          if (!s.isAfter(existing['e']!) && !e.isBefore(existing['s']!)) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          targetTrack = i;
          break;
        }
      }

      if (targetTrack == -1) {
        targetTrack = tracks.length;
        tracks.add([]);
      }
      tracks[targetTrack].add({'s': s, 'e': e});
      assigned[doc.id] = targetTrack;
    }
    return assigned;
  }

  void _previousMonth() {
    setState(() {
      int y = _focusedDay.year;
      int m = _focusedDay.month - 1;
      if (m == 0) {
        y--;
        m = 12;
      }
      if (y >= 1900) _focusedDay = DateTime(y, m, 1);
      _isPickerExpanded = false;
    });
  }

  void _nextMonth() {
    setState(() {
      int y = _focusedDay.year;
      int m = _focusedDay.month + 1;
      if (m == 13) {
        y++;
        m = 1;
      }
      if (y <= 2080) _focusedDay = DateTime(y, m, 1);
      _isPickerExpanded = false;
    });
  }

  void _showEventSheet(AppThemeColor theme, {DocumentSnapshot? eventDoc}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return EventBottomSheet(
          theme: theme,
          selectedDate: _selectedDay ?? DateTime.now(),
          eventDoc: eventDoc,
        );
      },
    );
  }

  void _showUnifiedDaySheet(AppThemeColor theme, DateTime day, List<QueryDocumentSnapshot> allEvents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        final dayEvents = allEvents.where((doc) {
          if (doc.data() is Map<String, dynamic> &&
              (doc.data() as Map<String, dynamic>).containsKey('startTime') &&
              (doc.data() as Map<String, dynamic>).containsKey('endTime')) {
            DateTime start = (doc['startTime'] as Timestamp).toDate();
            DateTime end = (doc['endTime'] as Timestamp).toDate();
            return _isDayInRange(day, start, end);
          }
          return false;
        }).toList();

        return Container(
          padding: EdgeInsets.all(24.w),
          height: MediaQuery.of(context).size.height * 0.7,
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${day.month}월 ${day.day}일의 하루 🗓️',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: theme.textHeader),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_rounded, color: theme.primary),
                      onPressed: () {
                         Navigator.pop(sheetContext);
                         _showEventSheet(theme);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                TabBar(
                  labelColor: theme.primary,
                  unselectedLabelColor: theme.textBody.withOpacity(0.5),
                  indicatorColor: theme.primary,
                  tabs: [Tab(text: '일정'), Tab(text: '메모')],
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: TabBarView(
                    children: [
                      dayEvents.isEmpty
                          ? Center(child: Text('등록된 일정이 없습니다.', style: TextStyle(color: theme.textBody)))
                          : ListView.builder(
                              physics: BouncingScrollPhysics(),
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: dayEvents.length,
                              itemBuilder: (context, index) {
                                final doc = dayEvents[index];
                                final data = doc.data() as Map<String, dynamic>;
                                String title = data['title'] ?? '';
                                DateTime start = (data['startTime'] as Timestamp).toDate();
                                DateTime end = (data['endTime'] as Timestamp).toDate();
                                String timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} ~ ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: theme.accent1.withOpacity(0.3))),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16.r),
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        _showEventSheet(theme, eventDoc: doc);
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(16.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(title, style: TextStyle(color: theme.textHeader, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                            SizedBox(height: 4.h),
                                            Row(children: [Icon(Icons.access_time_rounded, size: 14, color: theme.textBody.withOpacity(0.6)), SizedBox(width: 6.w), Text(timeStr, style: TextStyle(color: theme.textBody.withOpacity(0.6), fontSize: 13.sp))]),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('memos').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                          DateTime startOfDay = DateTime(day.year, day.month, day.day);
                          DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

                          final dayMemos = snapshot.data!.docs.where((doc) {
                            if (doc['folderId'] == 'trash') return false;
                            DateTime dt = (doc['createdAt'] as Timestamp).toDate();
                            return dt.isAfter(startOfDay.subtract(Duration(seconds: 1))) && dt.isBefore(endOfDay);
                          }).toList();

                          if (dayMemos.isEmpty) return Center(child: Text('이날 작성한 메모가 없습니다.', style: TextStyle(color: theme.textBody)));

                          return ListView.builder(
                            physics: BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: dayMemos.length,
                            itemBuilder: (context, index) {
                              final doc = dayMemos[index];
                              final String content = doc['content'] ?? '';
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(16.r), border: Border.all(color: theme.primaryLight.withOpacity(0.3))),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.r),
                                    onTap: () async {
                                      Color fColor = theme.primary;
                                      try {
                                        final fDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('folders').doc(doc['folderId']).get();
                                        if (fDoc.exists) fColor = Color(fDoc['colorValue']);
                                      } catch (_) {}
                                      if (!mounted) return;
                                      Navigator.pop(sheetContext);
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => MemoEditScreen(memoId: doc.id, folderId: doc['folderId'], initialContent: content, folderColor: fColor)));
                                    },
                                    child: Padding(padding: EdgeInsets.all(16.w), child: Text(content, style: TextStyle(color: theme.textHeader, fontSize: 15.sp, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis)),
                                  ),
                                ),
                              );
                            },
                          );
                        },
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Stack(
          children: [
            RepaintBoundary(
              child: Positioned(
                top: -50,
                left: -50,
                child: GlowBackground(color: theme.accent1, size: 300),
              ),
            ),
            RepaintBoundary(
              child: Positioned(
                bottom: -50,
                right: -50,
                child: GlowBackground(color: theme.primaryLight, size: 400),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                bottom: 8.h,
                top: MediaQuery.of(context).padding.top + 4.h,
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('events')
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  List<QueryDocumentSnapshot> allEvents = eventSnapshot.hasData
                      ? eventSnapshot.data!.docs
                      : [];
                  Map<String, int> eventTracks = _assignTracks(allEvents);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: theme.accent1,
                            size: 20,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Time Flow',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.textBody.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '이달의 기록',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.textHeader,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '날짜를 선택해 그날의 이야기를 확인하세요',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.textBody.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 8.h),

                      Expanded(
                        child: RepaintBoundary(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.surface.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(32.r),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.name.contains('다크')
                                      ? Colors.black.withOpacity(0.4)
                                      : theme.primaryLight.withOpacity(0.2),
                                  blurRadius: 25,
                                  offset: Offset(0, 12),
                                ),
                              ],
                              border: Border.all(
                                color: theme.primaryLight.withOpacity(0.3),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _isPickerExpanded = !_isPickerExpanded,
                                      ),
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Row(
                                          children: [
                                            Text(
                                              '${_focusedDay.year}년 ${_focusedDay.month}월',
                                              style: TextStyle(
                                                fontSize: 22.sp,
                                                fontWeight: FontWeight.bold,
                                                color: theme.textHeader,
                                              ),
                                            ),
                                            Icon(
                                              _isPickerExpanded
                                                  ? Icons.arrow_drop_up_rounded
                                                  : Icons.arrow_drop_down_rounded,
                                              color: theme.textHeader,
                                              size: 32,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: _previousMonth,
                                          icon: Icon(
                                            Icons.chevron_left_rounded,
                                            size: 28,
                                          ),
                                          color: theme.primaryLight,
                                        ),
                                        IconButton(
                                          onPressed: _nextMonth,
                                          icon: Icon(
                                            Icons.chevron_right_rounded,
                                            size: 28,
                                          ),
                                          color: theme.primaryLight,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                if (_isPickerExpanded)
                                  SizedBox(
                                    height: 150,
                                    child: CupertinoTheme(
                                      data: CupertinoThemeData(
                                        textTheme: CupertinoTextThemeData(
                                          dateTimePickerTextStyle: TextStyle(
                                            color: theme.textHeader,
                                            fontSize: 18.sp,
                                          ),
                                        ),
                                      ),
                                      child: CupertinoDatePicker(
                                        mode: CupertinoDatePickerMode.monthYear,
                                        initialDateTime: _focusedDay,
                                        minimumYear: 1900,
                                        maximumYear: 2080,
                                        onDateTimeChanged: (newDate) => setState(
                                          () => _focusedDay = DateTime(
                                            newDate.year,
                                            newDate.month,
                                            1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: RepaintBoundary(
                                      child: TableCalendar(
                                        shouldFillViewport: true,
                                        firstDay: DateTime.utc(1900, 1, 1),
                                        lastDay: DateTime.utc(2080, 12, 31),
                                        focusedDay: _focusedDay,
                                        rowHeight: 92.h,
                                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                        onDaySelected: (selectedDay, focusedDay) {
                                          setState(() {
                                            _selectedDay = selectedDay;
                                            _focusedDay = focusedDay;
                                          });
                                          _showUnifiedDaySheet(theme, selectedDay, allEvents);
                                        },
                                        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                                        headerVisible: false,
                                        eventLoader: (day) {
                                          return allEvents.where((doc) {
                                            if (doc.data() is Map<String, dynamic> &&
                                                (doc.data() as Map<String, dynamic>).containsKey('startTime') &&
                                                (doc.data() as Map<String, dynamic>).containsKey('endTime')) {
                                              DateTime start = (doc['startTime'] as Timestamp).toDate();
                                              DateTime end = (doc['endTime'] as Timestamp).toDate();
                                              return _isDayInRange(day, start, end);
                                            }
                                            return false;
                                          }).toList();
                                        },
                                        calendarBuilders: CalendarBuilders(
                                          defaultBuilder: (context, day, focusedDay) {
                                            Color textColor = (day.weekday == DateTime.sunday || day.weekday == DateTime.saturday) ? theme.accent2 : theme.textHeader;
                                            return Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 6.h), child: Text('${day.day}', style: TextStyle(color: textColor, fontSize: 13.sp))));
                                          },
                                          outsideBuilder: (context, day, focusedDay) => Align(alignment: Alignment.topCenter, child: Padding(padding: EdgeInsets.only(top: 6.h), child: Text('${day.day}', style: TextStyle(color: theme.textBody.withOpacity(0.5), fontSize: 13.sp)))),
                                          todayBuilder: (context, day, focusedDay) => Align(alignment: Alignment.topCenter, child: Container(margin: EdgeInsets.only(top: 6.h), width: 22.h, height: 22.h, decoration: BoxDecoration(color: theme.accent1.withOpacity(0.5), shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: TextStyle(color: theme.textHeader, fontWeight: FontWeight.bold, fontSize: 12.sp))))),
                                          selectedBuilder: (context, day, focusedDay) => Align(alignment: Alignment.topCenter, child: Container(margin: EdgeInsets.only(top: 6.h), width: 22.h, height: 22.h, decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.primary, theme.primaryLight]), shape: BoxShape.circle), child: Center(child: Text('${day.day}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp))))),
                                          markerBuilder: (context, day, events) {
                                            if (events.isEmpty) return SizedBox();
                                            final filteredEvents = events.cast<QueryDocumentSnapshot>().where((doc) {
                                              return (eventTracks[doc.id] ?? 99) < 4;
                                            }).toList();
                                            return Positioned.fill(
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: filteredEvents.map((doc) {
                                                  final data = doc.data() as Map<String, dynamic>;
                                                  final title = data['title'] ?? '';
                                                  final start = (data['startTime'] as Timestamp).toDate();
                                                  final end = (data['endTime'] as Timestamp).toDate();
                                                  DateTime startOnly = DateTime(start.year, start.month, start.day);
                                                  DateTime endOnly = DateTime(end.year, end.month, end.day);
                                                  bool isStartDay = isSameDay(day, startOnly);
                                                  bool isEndDay = isSameDay(day, endOnly);
                                                  int span = endOnly.difference(startOnly).inDays + 1;
                                                  DateTime midDay = startOnly.add(Duration(days: span ~/ 2));
                                                  bool isMidDay = isSameDay(day, midDay);
                                                  bool showText = isMidDay || (span == 1);
                                                  Color baseColor;
                                                  if (data.containsKey('colorValue')) {
                                                    baseColor = Color(data['colorValue']);
                                                  } else {
                                                    final colors = [theme.primary, theme.accent1, theme.accent2];
                                                    baseColor = colors[doc.id.hashCode.abs() % colors.length];
                                                  }
                                                  int track = eventTracks[doc.id] ?? 0;
                                                  return Positioned(
                                                    top: 32.h + (track * 15.h),
                                                    left: isStartDay ? 2 : 0,
                                                    right: isEndDay ? 2 : 0,
                                                    height: 13.h,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: baseColor.withOpacity(theme.name.contains('다크') ? 0.3 : 0.15),
                                                        borderRadius: BorderRadius.horizontal(
                                                          left: isStartDay ? Radius.circular(4) : Radius.zero,
                                                          right: isEndDay ? Radius.circular(4) : Radius.zero,
                                                        ),
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: showText
                                                          ? Text(
                                                              title,
                                                              style: TextStyle(
                                                                fontSize: 8.sp,
                                                                fontWeight: FontWeight.w600,
                                                                color: theme.name.contains('다크') ? baseColor.withOpacity(0.9) : baseColor,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.clip,
                                                            )
                                                          : SizedBox.shrink(),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                        calendarStyle: CalendarStyle(
                                          todayDecoration: BoxDecoration(
                                            color: theme.accent1.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: theme.accent1, width: 2),
                                          ),
                                          todayTextStyle: TextStyle(color: theme.textHeader, fontWeight: FontWeight.bold),
                                          selectedDecoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [theme.primary, theme.primaryLight]),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.primary.withOpacity(0.4),
                                                blurRadius: 10,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          defaultTextStyle: TextStyle(color: theme.textHeader, fontWeight: FontWeight.w500),
                                          weekendTextStyle: TextStyle(color: theme.accent2, fontWeight: FontWeight.w500),
                                          outsideDaysVisible: false,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
