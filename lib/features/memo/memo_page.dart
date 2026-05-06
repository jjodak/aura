import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/image_text_recognition_service.dart';
import '../../core/services/memo_ai_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';

// --- 4. 메인 메모 화면 ---
class MemoPage extends StatefulWidget {
  const MemoPage({super.key});
  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final List<String> _hintTexts = [
    '번뜩이는 아이디어, 잊기 전에 메모하세요 💡',
    '할 일, 일정, 스쳐가는 생각... 무엇이든 적어두세요 📌',
    '지금 떠오르는 것들을 가볍게 남겨보세요 🌿',
  ];
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ImageTextRecognitionService _textRecognitionService =
      ImageTextRecognitionService();
  final MemoAiService _memoAiService = MemoAiService();

  late String _currentHint;
  bool _isSaving = false;
  bool _isRecognizingImage = false;

  @override
  void initState() {
    super.initState();
    _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showImageSourceSheet(AppThemeColor theme) {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.photo_camera_rounded,
                    color: theme.primary,
                  ),
                  title: Text(
                    '카메라로 촬영',
                    style: TextStyle(
                      color: theme.textHeader,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _pickAndRecognizeImage(
                    ImageSource.camera,
                    theme,
                    sheetContext,
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_rounded,
                    color: theme.accent1,
                  ),
                  title: Text(
                    '이미지 선택',
                    style: TextStyle(
                      color: theme.textHeader,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _pickAndRecognizeImage(
                    ImageSource.gallery,
                    theme,
                    sheetContext,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndRecognizeImage(
    ImageSource source,
    AppThemeColor theme,
    BuildContext sheetContext,
  ) async {
    Navigator.pop(sheetContext);

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (image == null) return;

      setState(() => _isRecognizingImage = true);
      final text = await _textRecognitionService.recognizeText(image.path);

      if (text.isEmpty) {
        CustomToast.show(context, '이미지에서 텍스트를 찾지 못했어요.', Colors.orange);
        return;
      }

      _appendRecognizedText(text);
      CustomToast.show(context, '이미지 텍스트를 메모에 입력했어요.', theme.primary);
    } catch (_) {
      CustomToast.show(context, '이미지 인식 중 오류가 발생했어요.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isRecognizingImage = false);
    }
  }

  void _appendRecognizedText(String text) {
    final current = _controller.text.trim();
    final next = current.isEmpty ? text : '$current\n\n$text';
    _controller
      ..text = next
      ..selection = TextSelection.collapsed(offset: next.length);
  }

  Future<void> _showAiSaveDialog(
    BuildContext context,
    AppThemeColor theme,
  ) async {
    final memoContent = _controller.text.trim();
    if (memoContent.isEmpty) {
      CustomToast.show(context, '메모 내용을 먼저 입력해 주세요! ✍️', theme.accent2);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomToast.show(context, '로그인이 필요합니다.', Colors.redAccent);
        return;
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final folderSnapshot = await userRef
          .collection('folders')
          .orderBy('createdAt')
          .get();
      final folders = folderSnapshot.docs
          .where((doc) => (doc.data()['name'] ?? '') != '임시 폴더')
          .map((doc) {
            final data = doc.data();
            return MemoFolderCandidate(
              id: doc.id,
              name: data['name'] ?? '이름 없는 폴더',
              colorValue: data['colorValue'] ?? theme.primary.toARGB32(),
            );
          })
          .toList();

      final analysis = await _memoAiService.analyze(
        content: memoContent,
        now: DateTime.now(),
        folders: folders,
      );
      final existingEvents = analysis.schedule == null
          ? <QueryDocumentSnapshot>[]
          : await _loadExistingEventsFor(userRef, analysis.schedule!);

      if (!mounted) return;
      setState(() => _isSaving = false);

      final selection = await _showAiSaveConfirmDialog(
        theme: theme,
        analysis: analysis,
        folders: folders,
        existingEvents: existingEvents,
      );

      if (selection == null) return;
      await _saveMemoWithSelection(theme, analysis, selection);
    } catch (_) {
      CustomToast.show(context, 'AI 저장 분석 중 오류가 발생했어요.', Colors.redAccent);
    } finally {
      if (mounted && _isSaving) setState(() => _isSaving = false);
    }
  }

  Future<List<QueryDocumentSnapshot>> _loadExistingEventsFor(
    DocumentReference<Map<String, dynamic>> userRef,
    MemoScheduleIntent schedule,
  ) async {
    final dayStart = DateTime(
      schedule.startTime.year,
      schedule.startTime.month,
      schedule.startTime.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));
    final snapshot = await userRef
        .collection('events')
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aStart = (a['startTime'] as Timestamp).toDate();
      final bStart = (b['startTime'] as Timestamp).toDate();
      return aStart.compareTo(bStart);
    });
    return docs;
  }

  Future<_AiSaveSelection?> _showAiSaveConfirmDialog({
    required AppThemeColor theme,
    required MemoAiAnalysis analysis,
    required List<MemoFolderCandidate> folders,
    required List<QueryDocumentSnapshot> existingEvents,
  }) {
    final recommendedOptions = _buildRecommendedFolderOptions(
      analysis: analysis,
      folders: folders,
    );
    final manualFolderOptions = folders
        .map(
          (folder) => _FolderSaveOption(
            folderId: folder.id,
            name: folder.name,
            colorValue: folder.colorValue,
            isNew: false,
          ),
        )
        .toList();

    var selectedFolder = recommendedOptions.first;
    var manualMode = false;
    var createManualFolder = false;
    var selectedManualFolder = manualFolderOptions.isNotEmpty
        ? manualFolderOptions.first
        : null;
    final customFolderController = TextEditingController(
      text: analysis.folder.name,
    );
    final scheduleTitleController = TextEditingController(
      text:
          analysis.schedule?.title ??
          _makeManualScheduleTitle(_controller.text),
    );
    var step = 0;
    var saveSchedule = analysis.schedule != null;
    var scheduleStart =
        analysis.schedule?.startTime ??
        DateTime.now().add(const Duration(hours: 1));
    var scheduleEnd =
        analysis.schedule?.endTime ??
        scheduleStart.add(const Duration(hours: 1));
    var isStartPickerOpen = false;
    var isEndPickerOpen = false;
    int? alarmMinutes;

    final dialog = showDialog<_AiSaveSelection>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final schedule = analysis.schedule;
            final hasScheduleStep = saveSchedule;

            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'AI 저장 확인',
                style: TextStyle(
                  color: theme.textHeader,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (step == 0) ...[
                          Text(
                            'AI가 보기에 이런 폴더가 좋아요',
                            style: TextStyle(
                              color: theme.textBody.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '어떤 폴더로 저장할까요?',
                            style: TextStyle(
                              color: theme.textHeader,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...recommendedOptions.map((option) {
                            final selected =
                                !manualMode && selectedFolder == option;
                            return _buildFolderOptionTile(
                              theme: theme,
                              option: option,
                              selected: selected,
                              onTap: () => setDialogState(() {
                                manualMode = false;
                                selectedFolder = option;
                              }),
                            );
                          }),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => setDialogState(() {
                              manualMode = !manualMode;
                            }),
                            icon: Icon(
                              Icons.tune_rounded,
                              color: manualMode ? Colors.white : theme.primary,
                              size: 18,
                            ),
                            label: Text(
                              manualMode ? '추천 목록으로 돌아가기' : '목록에 없어요, 직접 선택',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: manualMode
                                  ? Colors.white
                                  : theme.primary,
                              backgroundColor: manualMode
                                  ? theme.primary
                                  : Colors.transparent,
                              side: BorderSide(color: theme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (manualMode) ...[
                            const SizedBox(height: 12),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: createManualFolder,
                              activeThumbColor: theme.primary,
                              title: Text(
                                '새 폴더 만들기',
                                style: TextStyle(
                                  color: theme.textHeader,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                createManualFolder
                                    ? '입력한 이름으로 새 폴더를 만듭니다.'
                                    : '기존 폴더 중에서 직접 고릅니다.',
                                style: TextStyle(color: theme.textBody),
                              ),
                              onChanged: (value) => setDialogState(
                                () => createManualFolder = value,
                              ),
                            ),
                            if (createManualFolder)
                              TextField(
                                controller: customFolderController,
                                style: TextStyle(color: theme.textHeader),
                                decoration: InputDecoration(
                                  labelText: '새 폴더 이름',
                                  labelStyle: TextStyle(color: theme.textBody),
                                  filled: true,
                                  fillColor: theme.bg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.primaryLight.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else if (manualFolderOptions.isEmpty)
                              Text(
                                '아직 직접 선택할 기존 폴더가 없습니다.',
                                style: TextStyle(
                                  color: theme.textBody.withValues(alpha: 0.65),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: theme.primaryLight.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<_FolderSaveOption>(
                                    value: selectedManualFolder,
                                    isExpanded: true,
                                    dropdownColor: theme.surface,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: theme.textBody,
                                    ),
                                    items: manualFolderOptions.map((option) {
                                      return DropdownMenuItem<
                                        _FolderSaveOption
                                      >(
                                        value: option,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.folder_rounded,
                                              color: Color(option.colorValue),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                option.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: theme.textHeader,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (option) {
                                      if (option == null) return;
                                      setDialogState(
                                        () => selectedManualFolder = option,
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                          Text(
                            manualMode
                                ? '직접 선택한 위치에 저장합니다.'
                                : selectedFolder.isNew
                                ? '저장하면 이 폴더를 새로 만듭니다.'
                                : '기존 폴더에 저장합니다.',
                            style: TextStyle(
                              color: theme.textBody.withValues(alpha: 0.65),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: saveSchedule,
                            activeColor: theme.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              '일정 추가하겠습니까?',
                              style: TextStyle(
                                color: theme.textHeader,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              schedule != null
                                  ? '일정으로 감지되어 날짜와 시간이 자동으로 채워졌어요.'
                                  : '필요하면 직접 날짜와 시간을 선택할 수 있어요.',
                              style: TextStyle(color: theme.textBody),
                            ),
                            onChanged: (value) => setDialogState(() {
                              saveSchedule = value ?? false;
                              if (saveSchedule &&
                                  scheduleTitleController.text.trim().isEmpty) {
                                scheduleTitleController.text =
                                    _makeManualScheduleTitle(_controller.text);
                              }
                            }),
                          ),
                        ],
                        if (step == 1) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.folder_rounded,
                                color: Color(selectedFolder.colorValue),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${selectedFolder.name} 폴더에 저장',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textBody.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: saveSchedule,
                            activeThumbColor: theme.primary,
                            title: Text(
                              '캘린더에도 저장',
                              style: TextStyle(
                                color: theme.textHeader,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              saveSchedule
                                  ? _formatDateTime(scheduleStart)
                                  : '메모만 저장합니다.',
                              style: TextStyle(color: theme.textBody),
                            ),
                            onChanged: (value) => setDialogState(() {
                              saveSchedule = value;
                              if (saveSchedule &&
                                  scheduleTitleController.text.trim().isEmpty) {
                                scheduleTitleController.text =
                                    _makeManualScheduleTitle(_controller.text);
                              }
                            }),
                          ),
                          if (saveSchedule) ...[
                            TextField(
                              controller: scheduleTitleController,
                              style: TextStyle(
                                color: theme.textHeader,
                                fontSize: 18,
                              ),
                              onTap: () => setDialogState(() {
                                isStartPickerOpen = false;
                                isEndPickerOpen = false;
                              }),
                              decoration: InputDecoration(
                                hintText: '일정 제목',
                                hintStyle: TextStyle(
                                  color: theme.textBody.withValues(alpha: 0.5),
                                ),
                                filled: true,
                                fillColor: theme.bg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAiDateTimeSection(
                              theme: theme,
                              label: '시작',
                              dateTime: scheduleStart,
                              isOpen: isStartPickerOpen,
                              onTap: () => setDialogState(() {
                                isStartPickerOpen = !isStartPickerOpen;
                                if (isStartPickerOpen) isEndPickerOpen = false;
                              }),
                              onChanged: (newDate) => setDialogState(() {
                                final duration = scheduleEnd.difference(
                                  scheduleStart,
                                );
                                scheduleStart = newDate;
                                scheduleEnd = scheduleStart.add(
                                  duration.isNegative || duration.inMinutes == 0
                                      ? const Duration(hours: 1)
                                      : duration,
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            _buildAiDateTimeSection(
                              theme: theme,
                              label: '종료',
                              dateTime: scheduleEnd,
                              isOpen: isEndPickerOpen,
                              onTap: () => setDialogState(() {
                                isEndPickerOpen = !isEndPickerOpen;
                                if (isEndPickerOpen) isStartPickerOpen = false;
                              }),
                              onChanged: (newDate) => setDialogState(() {
                                scheduleEnd = newDate;
                                if (scheduleEnd.isBefore(scheduleStart) ||
                                    scheduleEnd.isAtSameMomentAs(
                                      scheduleStart,
                                    )) {
                                  scheduleStart = scheduleEnd.subtract(
                                    const Duration(hours: 1),
                                  );
                                }
                              }),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasOverlappingEventRange(
                                    scheduleStart,
                                    scheduleEnd,
                                    existingEvents,
                                  )
                                  ? '겹치는 일정이 있어요'
                                  : '같은 날 기존 일정',
                              style: TextStyle(
                                color:
                                    _hasOverlappingEventRange(
                                      scheduleStart,
                                      scheduleEnd,
                                      existingEvents,
                                    )
                                    ? Colors.orange
                                    : theme.textBody.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (existingEvents.isEmpty)
                              Text(
                                '등록된 일정이 없습니다.',
                                style: TextStyle(
                                  color: theme.textBody.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              )
                            else
                              ...existingEvents.take(4).map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final start = (data['startTime'] as Timestamp)
                                    .toDate();
                                final end = (data['endTime'] as Timestamp)
                                    .toDate();
                                final overlaps = _isOverlapping(
                                  scheduleStart,
                                  scheduleEnd,
                                  start,
                                  end,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: overlaps
                                        ? Colors.orange.withValues(alpha: 0.12)
                                        : theme.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: overlaps
                                          ? Colors.orange.withValues(alpha: 0.5)
                                          : theme.primaryLight.withValues(
                                              alpha: 0.15,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        overlaps
                                            ? Icons.warning_amber_rounded
                                            : Icons.event_available_rounded,
                                        color: overlaps
                                            ? Colors.orange
                                            : theme.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${data['title'] ?? '일정'} · ${_formatTime(start)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: theme.textHeader,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 12),
                            Text(
                              '알림',
                              style: TextStyle(
                                color: theme.textBody.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: theme.bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: theme.primaryLight.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [null, 5, 10, 30, 60, 1440].map((
                                  minutes,
                                ) {
                                  return _buildAlarmChoiceTile(
                                    theme: theme,
                                    minutes: minutes,
                                    selected: alarmMinutes == minutes,
                                    onTap: () => setDialogState(
                                      () => alarmMinutes = minutes,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (step == 1) {
                      setDialogState(() => step = 0);
                      return;
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    step == 1 ? '이전' : '취소',
                    style: TextStyle(color: theme.textBody),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final resolvedFolder = _resolveSelectedFolder(
                      theme: theme,
                      selectedFolder: selectedFolder,
                      manualMode: manualMode,
                      createManualFolder: createManualFolder,
                      selectedManualFolder: selectedManualFolder,
                      customFolderName: customFolderController.text,
                    );
                    if (resolvedFolder == null) {
                      CustomToast.show(
                        context,
                        '저장할 폴더를 선택해 주세요.',
                        Colors.orange,
                      );
                      return;
                    }
                    if (hasScheduleStep && step == 0) {
                      setDialogState(() {
                        selectedFolder = resolvedFolder;
                        manualMode = false;
                        createManualFolder = resolvedFolder.isNew;
                        step = 1;
                      });
                      return;
                    }
                    final scheduleTitle = scheduleTitleController.text.trim();
                    if (saveSchedule && scheduleTitle.isEmpty) {
                      CustomToast.show(
                        context,
                        '일정 제목을 입력해 주세요.',
                        Colors.orange,
                      );
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _AiSaveSelection(
                        folderId: resolvedFolder.folderId,
                        folderName: resolvedFolder.name,
                        folderColorValue: resolvedFolder.colorValue,
                        createFolder: resolvedFolder.isNew,
                        saveSchedule: saveSchedule,
                        scheduleTitle: saveSchedule ? scheduleTitle : null,
                        scheduleStartTime: saveSchedule ? scheduleStart : null,
                        scheduleEndTime: saveSchedule ? scheduleEnd : null,
                        alarmMinutes: alarmMinutes,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    hasScheduleStep && step == 0 ? '다음' : '저장하기',
                    style: const TextStyle(
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
    return dialog;
  }

  List<_FolderSaveOption> _buildRecommendedFolderOptions({
    required MemoAiAnalysis analysis,
    required List<MemoFolderCandidate> folders,
  }) {
    final options = <_FolderSaveOption>[];
    final seen = <String>{};
    final sortedScores = analysis.categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    void addOption(_FolderSaveOption option) {
      final key = option.folderId ?? 'new:${option.name}';
      if (seen.add(key)) options.add(option);
    }

    addOption(
      _FolderSaveOption(
        folderId: analysis.folder.folderId,
        name: analysis.folder.name,
        colorValue: analysis.folder.colorValue,
        isNew: analysis.folder.isNew,
        confidence: analysis.categoryConfidence,
      ),
    );

    for (final entry in sortedScores.take(5)) {
      addOption(
        _optionForCategory(
          category: entry.key,
          confidence: entry.value,
          folders: folders,
        ),
      );
      if (options.length >= 4) break;
    }

    options.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    return options;
  }

  _FolderSaveOption _optionForCategory({
    required String category,
    required double confidence,
    required List<MemoFolderCandidate> folders,
  }) {
    final normalizedCategory = _normalizeFolderName(category);
    MemoFolderCandidate? matched;

    for (final folder in folders) {
      final normalizedFolder = _normalizeFolderName(folder.name);
      if (normalizedFolder == normalizedCategory ||
          normalizedFolder.contains(normalizedCategory) ||
          normalizedCategory.contains(normalizedFolder)) {
        matched = folder;
        break;
      }
    }

    if (matched != null) {
      return _FolderSaveOption(
        folderId: matched.id,
        name: matched.name,
        colorValue: matched.colorValue,
        isNew: false,
        confidence: confidence,
      );
    }

    return _FolderSaveOption(
      folderId: null,
      name: category,
      colorValue: _categoryColor(category),
      isNew: true,
      confidence: confidence,
    );
  }

  int _categoryColor(String category) {
    return switch (category) {
      '일정' => 0xFF219EBC,
      '할 일' => 0xFFE9C46A,
      '아이디어' => 0xFFE56B6F,
      '공부' => 0xFF6D597A,
      '업무' => 0xFF457B9D,
      '건강' => 0xFF588157,
      '여행' => 0xFF2A9D8F,
      '재정' => 0xFFD4A373,
      '일기' => 0xFFB5838D,
      _ => 0xFF8D99AE,
    };
  }

  String _normalizeFolderName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z0-9]'), '');
  }

  _FolderSaveOption? _resolveSelectedFolder({
    required AppThemeColor theme,
    required _FolderSaveOption selectedFolder,
    required bool manualMode,
    required bool createManualFolder,
    required _FolderSaveOption? selectedManualFolder,
    required String customFolderName,
  }) {
    if (!manualMode) return selectedFolder;

    if (!createManualFolder) return selectedManualFolder;

    final name = customFolderName.trim();
    if (name.isEmpty) return null;

    return _FolderSaveOption(
      folderId: null,
      name: name,
      colorValue: theme.primary.toARGB32(),
      isNew: true,
    );
  }

  Widget _buildFolderOptionTile({
    required AppThemeColor theme,
    required _FolderSaveOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = Color(option.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? color.withValues(alpha: 0.14) : theme.bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.65)
                    : theme.primaryLight.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(
                    option.isNew
                        ? Icons.create_new_folder_rounded
                        : Icons.folder_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.isNew ? '새 폴더: ${option.name}' : option.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textHeader,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (option.confidence != null)
                        Text(
                          'AI 확신도 ${_formatConfidence(option.confidence!)}',
                          style: TextStyle(
                            color: theme.textBody.withValues(alpha: 0.62),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? color
                      : theme.textBody.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmChoiceTile({
    required AppThemeColor theme,
    required int? minutes,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        _alarmLabel(minutes),
        style: TextStyle(
          color: theme.textHeader,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: theme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildAiDateTimeSection({
    required AppThemeColor theme,
    required String label,
    required DateTime dateTime,
    required bool isOpen,
    required VoidCallback onTap,
    required ValueChanged<DateTime> onChanged,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOpen
                    ? theme.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: isOpen ? theme.primary : theme.accent1,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isOpen ? theme.primary : theme.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(dateTime),
                  style: TextStyle(
                    color: theme.textHeader,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          height: isOpen ? 180 : 0,
          margin: const EdgeInsets.only(top: 8),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: isOpen
              ? CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: theme.textHeader,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: dateTime,
                    onDateTimeChanged: onChanged,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _formatConfidence(double value) {
    return '${(value * 100).clamp(0, 100).round()}%';
  }

  Future<void> _saveMemoWithSelection(
    AppThemeColor theme,
    MemoAiAnalysis analysis,
    _AiSaveSelection selection,
  ) async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomToast.show(context, '로그인이 필요합니다.', Colors.redAccent);
        return;
      }

      final memoContent = _controller.text.trim();
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final batch = FirebaseFirestore.instance.batch();
      final memoRef = userRef.collection('memos').doc();
      final folderRef = selection.createFolder
          ? userRef.collection('folders').doc()
          : userRef.collection('folders').doc(selection.folderId);

      if (selection.createFolder) {
        batch.set(folderRef, {
          'name': selection.folderName,
          'colorValue': selection.folderColorValue,
          'count': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'ai',
        });
      } else {
        batch.update(folderRef, {'count': FieldValue.increment(1)});
      }

      batch.set(memoRef, {
        'content': memoContent,
        'folderId': folderRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'aiCategory': analysis.category,
        'aiFolderConfidence': analysis.folder.confidence,
      });

      DocumentReference<Map<String, dynamic>>? eventRef;
      if (selection.saveSchedule &&
          selection.scheduleTitle != null &&
          selection.scheduleStartTime != null &&
          selection.scheduleEndTime != null) {
        eventRef = userRef.collection('events').doc();
        batch.set(eventRef, {
          'title': selection.scheduleTitle,
          'startTime': Timestamp.fromDate(selection.scheduleStartTime!),
          'endTime': Timestamp.fromDate(selection.scheduleEndTime!),
          'alarmMinutes': selection.alarmMinutes,
          'colorValue': selection.folderColorValue,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'ai_memo',
          'sourceMemoId': memoRef.id,
        });
      }

      await batch.commit();

      if (eventRef != null && selection.alarmMinutes != null) {
        await NotificationService().requestPermissions();
        await NotificationService().scheduleEventNotification(
          id: eventRef.id.hashCode.abs(),
          title: selection.scheduleTitle!,
          scheduledTime: selection.scheduleStartTime!,
          alarmMinutes: selection.alarmMinutes!,
        );
      }

      final scheduleText = eventRef == null ? '' : ' 일정도 저장했어요.';
      CustomToast.show(
        context,
        '${selection.folderName} 폴더에 저장했어요.$scheduleText',
        theme.primary,
      );
      _controller.clear();
      setState(
        () => _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)],
      );
    } catch (_) {
      CustomToast.show(context, '저장 중 오류가 발생했어요.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}.${dt.month}.${dt.day} ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _alarmLabel(int? minutes) {
    if (minutes == null) return '없음';
    if (minutes == 0) return '시작할 때';
    if (minutes == 5) return '5분 전';
    if (minutes == 60) return '1시간 전';
    if (minutes == 1440) return '1일 전';
    return '$minutes분 전';
  }

  String _makeManualScheduleTitle(String content) {
    var title = content.split('\n').first.trim();
    title = title
        .replaceAll(RegExp(r'\d{4}\s*년\s*\d{1,2}\s*월\s*\d{1,2}\s*일?'), '')
        .replaceAll(RegExp(r'\d{4}[./-]\d{1,2}[./-]\d{1,2}'), '')
        .replaceAll(RegExp(r'\d{1,2}\s*월\s*\d{1,2}\s*일?'), '')
        .replaceAll(
          RegExp(r'(이번\s*주|다음\s*주|이번|다음)?\s*(월요일|화요일|수요일|목요일|금요일|토요일|일요일)'),
          '',
        )
        .replaceAll(RegExp(r'(오늘|내일|모레|이번\s*달|다음\s*달|이번\s*주말|다음\s*주말|주말)'), '')
        .replaceAll(
          RegExp(r'(오전|오후|아침|점심|저녁|밤)?\s*\d{1,2}\s*(?:시|:)\s*\d{0,2}\s*분?'),
          '',
        )
        .replaceAll(RegExp(r'(오전|오후|아침|점심|저녁|밤)'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty) return '메모 일정';
    if (title.length > 36) return '${title.substring(0, 36)}...';
    return title;
  }

  bool _hasOverlappingEventRange(
    DateTime startTime,
    DateTime endTime,
    List<QueryDocumentSnapshot> existingEvents,
  ) {
    return existingEvents.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final start = (data['startTime'] as Timestamp).toDate();
      final end = (data['endTime'] as Timestamp).toDate();
      return _isOverlapping(startTime, endTime, start, end);
    });
  }

  bool _isOverlapping(
    DateTime startA,
    DateTime endA,
    DateTime startB,
    DateTime endB,
  ) {
    return startA.isBefore(endB) && endA.isAfter(startB);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: GlowBackground(color: theme.accent1, size: 260),
            ),
            Positioned(
              top: 130,
              right: -130,
              child: GlowBackground(color: theme.primaryLight, size: 340),
            ),
            Positioned(
              bottom: -150,
              left: 20,
              child: GlowBackground(color: theme.accent2, size: 300),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMemoHeader(theme),
                    SizedBox(height: 14.h),
                    StreamBuilder<QuerySnapshot>(
                      stream: user == null
                          ? const Stream<QuerySnapshot>.empty()
                          : FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('memos')
                                .snapshots(),
                      builder: (context, snapshot) {
                        final stats = _resolveMemoStats(snapshot);
                        return _buildInsightStrip(theme, stats);
                      },
                    ),
                    SizedBox(height: 14.h),
                    Expanded(child: _buildMemoComposer(theme)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemoHeader(AppThemeColor theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 메모',
                style: TextStyle(
                  fontSize: 33.sp,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: theme.textHeader,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                '떠오른 생각을 정리하면 Aura가 폴더와 일정을 제안해요.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  height: 1.35,
                  color: theme.textBody.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primary.withValues(alpha: 0.16)),
          ),
          child: Icon(CupertinoIcons.sparkles, color: theme.primary, size: 22),
        ),
      ],
    );
  }

  _MemoStats _resolveMemoStats(AsyncSnapshot<QuerySnapshot> snapshot) {
    var weeklyMemos = 0;
    final activeDays = <String>{};

    if (snapshot.hasData) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      for (final doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null || data['folderId'] == 'trash') continue;

        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp == null) continue;

        final date = timestamp.toDate();
        activeDays.add(dateToYMD(date));

        if (date.isAfter(
          startOfWeekDate.subtract(const Duration(seconds: 1)),
        )) {
          weeklyMemos++;
        }
      }
    }

    return _MemoStats(weeklyMemos: weeklyMemos, activeDays: activeDays.length);
  }

  Widget _buildInsightStrip(AppThemeColor theme, _MemoStats stats) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.primaryLight.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          _buildStatPill(
            theme: theme,
            icon: CupertinoIcons.square_pencil,
            label: '이번 주',
            value: '${stats.weeklyMemos}개',
            color: theme.primary,
          ),
          const SizedBox(width: 6),
          _buildStatPill(
            theme: theme,
            icon: CupertinoIcons.calendar_today,
            label: '작성 일수',
            value: '${stats.activeDays}일',
            color: theme.accent2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required AppThemeColor theme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textBody.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      color: theme.textHeader,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoComposer(AppThemeColor theme) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.surface.withValues(
          alpha: theme.name.contains('다크') ? 0.9 : 0.96,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.primaryLight.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크')
                ? Colors.black.withValues(alpha: 0.36)
                : theme.primaryLight.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                cursorColor: theme.primary,
                style: TextStyle(
                  color: theme.textHeader,
                  fontSize: 18,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _currentHint,
                  hintStyle: TextStyle(
                    color: theme.textBody.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, child) {
              final trimmed = value.text.trim();
              final canSave =
                  trimmed.isNotEmpty && !_isSaving && !_isRecognizingImage;
              return Container(
                padding: EdgeInsets.fromLTRB(12, 10, 12, 12.h),
                decoration: BoxDecoration(
                  color: theme.bg.withValues(alpha: 0.72),
                  border: Border(
                    top: BorderSide(
                      color: theme.primaryLight.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildComposerIconButton(
                      theme: theme,
                      color: theme.accent2,
                      icon: CupertinoIcons.camera,
                      tooltip: '이미지에서 텍스트 가져오기',
                      onTap: _isRecognizingImage
                          ? null
                          : () => _showImageSourceSheet(theme),
                      isLoading: _isRecognizingImage,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          trimmed.isEmpty
                              ? '가볍게 적고, 준비되면 저장하세요.'
                              : '${trimmed.length}자 작성 중',
                          key: ValueKey(trimmed.isEmpty),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.textBody.withValues(alpha: 0.62),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildSaveButton(theme: theme, canSave: canSave),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComposerIconButton({
    required AppThemeColor theme,
    required Color color,
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(icon, color: color, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton({
    required AppThemeColor theme,
    required bool canSave,
  }) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: canSave ? () => _showAiSaveDialog(context, theme) : null,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(CupertinoIcons.checkmark_alt, size: 18),
        label: const Text('저장'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          disabledBackgroundColor: theme.primaryLight.withValues(alpha: 0.22),
          foregroundColor: Colors.white,
          disabledForegroundColor: theme.textBody.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MemoStats {
  final int weeklyMemos;
  final int activeDays;

  const _MemoStats({required this.weeklyMemos, required this.activeDays});
}

class _FolderSaveOption {
  final String? folderId;
  final String name;
  final int colorValue;
  final bool isNew;
  final double? confidence;

  const _FolderSaveOption({
    required this.folderId,
    required this.name,
    required this.colorValue,
    required this.isNew,
    this.confidence,
  });
}

class _AiSaveSelection {
  final String? folderId;
  final String folderName;
  final int folderColorValue;
  final bool createFolder;
  final bool saveSchedule;
  final String? scheduleTitle;
  final DateTime? scheduleStartTime;
  final DateTime? scheduleEndTime;
  final int? alarmMinutes;

  const _AiSaveSelection({
    required this.folderId,
    required this.folderName,
    required this.folderColorValue,
    required this.createFolder,
    required this.saveSchedule,
    required this.scheduleTitle,
    required this.scheduleStartTime,
    required this.scheduleEndTime,
    required this.alarmMinutes,
  });
}
