import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';
import '../../core/utils/date_helpers.dart';

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
  late String _currentHint;
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)];
  }

  void _showFolderSelectionSheet(BuildContext context, AppThemeColor theme) {
    if (_controller.text.trim().isEmpty) {
      CustomToast.show(context, '메모 내용을 먼저 입력해 주세요! ✍️', theme.accent2);
      return;
    }
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext sheetContext) {
        final user = FirebaseAuth.instance.currentUser;

        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어디에 보관할까요? 📁',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textHeader,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('folders')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allFolders = snapshot.data?.docs ?? [];
                    final visibleFolders = allFolders
                        .where((doc) => doc['name'] != '임시 폴더')
                        .toList();

                    if (visibleFolders.isEmpty) {
                      return Center(
                        child: Text(
                          '아직 폴더가 없어요!\n폴더 탭에서 먼저 만들어주세요. 📁',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textBody.withOpacity(0.6),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: visibleFolders.length,
                      itemBuilder: (context, index) {
                        final doc = visibleFolders[index];
                        final Color folderColor = Color(doc['colorValue']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.primaryLight.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: folderColor.withOpacity(0.2),
                              child: Icon(
                                Icons.folder_rounded,
                                color: folderColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              doc['name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.textHeader,
                              ),
                            ),
                            onTap: () => _saveMemoToDatabase(
                              sheetContext,
                              theme,
                              doc.id,
                              doc['name'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMemoToDatabase(
    BuildContext sheetContext,
    AppThemeColor theme,
    String folderId,
    String folderName,
  ) async {
    setState(() => _isSaving = true);
    Navigator.pop(sheetContext);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final memoContent = _controller.text.trim();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('memos')
          .add({
            'content': memoContent,
            'folderId': folderId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(folderId)
          .update({'count': FieldValue.increment(1)});

      CustomToast.show(context, '$folderName 폴더에 쏙! 저장완료 🌿', theme.primary);
      _controller.clear();
      setState(
        () => _currentHint = _hintTexts[Random().nextInt(_hintTexts.length)],
      );
    } catch (e) {
      CustomToast.show(context, '저장 중 오류가 발생했어요.', Colors.redAccent);
    } finally {
      setState(() => _isSaving = false);
    }
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
              top: -50,
              left: -50,
              child: GlowBackground(color: theme.accent1, size: 250),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: GlowBackground(color: theme.primaryLight, size: 350),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                bottom: 8.h,
                top: MediaQuery.of(context).padding.top + 4.h,
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: theme.accent1,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 이야기',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textHeader,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '당신만의 특별한 순간을 기록해보세요',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.textBody.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.surface.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: theme.name.contains('다크')
                                  ? Colors.black.withOpacity(0.4)
                                  : theme.primaryLight.withOpacity(0.2),
                              blurRadius: 60,
                              offset: const Offset(0, 20),
                            ),
                          ],
                          border: Border.all(
                            color: theme.primaryLight.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          style: TextStyle(
                            color: theme.textHeader,
                            fontSize: 17,
                            height: 1.8,
                          ),
                          decoration: InputDecoration(
                            hintText: _currentHint,
                            hintStyle: TextStyle(
                              color: theme.textBody.withOpacity(0.4),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          _buildHoverIconButton(
                            theme.accent1,
                            Icons.camera_alt_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildHoverIconButton(
                            theme.accent2,
                            Icons.mic_rounded,
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () =>
                                      _showFolderSelectionSheet(context, theme),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.save_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                            label: const Text(
                              '저장하기',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              elevation: 2,
                              shadowColor: theme.primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 💡 통계 (이번 주 메모 / 작성 일수)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('memos')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int weeklyMemos = 0;
                        Set<String> activeDays = {};

                        if (snapshot.hasData) {
                          final now = DateTime.now();
                          final startOfWeek = now.subtract(
                            Duration(days: now.weekday - 1),
                          );
                          final startOfWeekDate = DateTime(
                            startOfWeek.year,
                            startOfWeek.month,
                            startOfWeek.day,
                          );

                          for (var doc in snapshot.data!.docs) {
                            if (doc['folderId'] == 'trash') continue;

                            final timestamp = doc['createdAt'] as Timestamp?;
                            if (timestamp != null) {
                              final date = timestamp.toDate();
                              activeDays.add(dateToYMD(date));

                              if (date.isAfter(
                                startOfWeekDate.subtract(
                                  const Duration(seconds: 1),
                                ),
                              )) {
                                weeklyMemos++;
                              }
                            }
                          }
                        }

                        return Row(
                          children: [
                            _buildStatCard(theme, '이번 주 메모', '${weeklyMemos}개'),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              theme,
                              '작성 일수',
                              '${activeDays.length}일',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

  Widget _buildHoverIconButton(Color color, IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          hoverColor: color.withOpacity(0.1),
          splashColor: color.withOpacity(0.2),
          child: Center(child: Icon(icon, color: color, size: 24)),
        ),
      ),
    );
  }

  Widget _buildStatCard(AppThemeColor theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryLight.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textBody.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
