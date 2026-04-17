// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/utils/date_helpers.dart';
import 'trash_memo_view_screen.dart';

// --- 🗑️ 휴지통 화면 ---
class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedMemos = {};

  Future<void> _deleteSelectedMemos(AppThemeColor theme) async {
    if (_selectedMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (String id in _selectedMemos) {
        final ref = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memos')
            .doc(id);
        batch.delete(ref);
      }
      await batch.commit();

      CustomToast.show(
        context,
        '${_selectedMemos.length}개의 메모가 영구 삭제되었습니다. 🗑️',
        Colors.orange,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '삭제 실패', Colors.redAccent);
    }
  }

  Future<void> _restoreMemos(
    AppThemeColor theme,
    List<DocumentSnapshot> allMemos, {
    bool isAll = false,
  }) async {
    final memosToRestore = isAll
        ? allMemos
        : allMemos.where((d) => _selectedMemos.contains(d.id)).toList();
    if (memosToRestore.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final foldersQuery = await userRef.collection('folders').get();
      final existingFolderIds = foldersQuery.docs.map((e) => e.id).toSet();

      String tempFolderId = '';
      try {
        tempFolderId = foldersQuery.docs
            .firstWhere((e) => e['name'] == '임시 폴더')
            .id;
      } catch (e) {
        final newFolder = await userRef.collection('folders').add({
          'name': '임시 폴더',
          'colorValue': Colors.grey.value,
          'count': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tempFolderId = newFolder.id;
        existingFolderIds.add(tempFolderId);
      }

      final batch = FirebaseFirestore.instance.batch();
      Map<String, int> folderIncrements = {};

      for (var doc in memosToRestore) {
        String targetFolder = tempFolderId;
        if (doc.data() is Map &&
            (doc.data() as Map).containsKey('originalFolderId')) {
          targetFolder = doc['originalFolderId'];
        }

        if (!existingFolderIds.contains(targetFolder)) {
          targetFolder = tempFolderId;
        }

        batch.update(doc.reference, {
          'folderId': targetFolder,
          'originalFolderId': FieldValue.delete(),
        });

        folderIncrements[targetFolder] =
            (folderIncrements[targetFolder] ?? 0) + 1;
      }

      for (var entry in folderIncrements.entries) {
        batch.update(userRef.collection('folders').doc(entry.key), {
          'count': FieldValue.increment(entry.value),
        });
      }

      await batch.commit();

      CustomToast.show(
        context,
        '${memosToRestore.length}개의 메모가 복구되었습니다! ✨',
        theme.primary,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '복구에 실패했습니다.', Colors.redAccent);
    }
  }

  Future<void> _emptyTrash(
    AppThemeColor theme,
    List<DocumentSnapshot> allMemos,
  ) async {
    if (allMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in allMemos) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      CustomToast.show(context, '휴지통을 싹 비웠습니다! ✨', theme.primary);
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '휴지통 비우기에 실패했어요.', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .collection('memos')
              .where('folderId', isEqualTo: 'trash')
              .snapshots(),
          builder: (context, snapshot) {
            final allMemos = snapshot.data?.docs ?? [];

            return Scaffold(
              backgroundColor: theme.bg,
              appBar: AppBar(
                backgroundColor: theme.surface.withOpacity(0.8),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    _isSelectionMode
                        ? Icons.close_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    color: theme.textHeader,
                  ),
                  onPressed: () {
                    if (_isSelectionMode) {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedMemos.clear();
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: _isSelectionMode
                    ? Text(
                        '${_selectedMemos.length}개 선택됨',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.textHeader,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '휴지통',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textHeader,
                            ),
                          ),
                        ],
                      ),
                centerTitle: true,
                actions: _isSelectionMode
                    ? [
                        IconButton(
                          icon: Icon(
                            Icons.restore_rounded,
                            color: theme.primary,
                          ),
                          onPressed: _selectedMemos.isEmpty
                              ? null
                              : () => _restoreMemos(
                                  theme,
                                  allMemos,
                                  isAll: false,
                                ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_forever_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: _selectedMemos.isEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.surface,
                                      title: Text(
                                        '선택 영구 삭제',
                                        style: TextStyle(
                                          color: theme.textHeader,
                                        ),
                                      ),
                                      content: Text(
                                        '선택한 메모를 영구 삭제하시겠습니까?',
                                        style: TextStyle(color: theme.textBody),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: theme.textBody,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteSelectedMemos(theme);
                                          },
                                          child: const Text(
                                            '삭제',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(width: 8),
                      ]
                    : [
                        TextButton(
                          onPressed: allMemos.isEmpty
                              ? null
                              : () =>
                                    _restoreMemos(theme, allMemos, isAll: true),
                          child: Text(
                            '전체 복구',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: allMemos.isEmpty
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: theme.surface,
                                      title: Text(
                                        '휴지통 비우기',
                                        style: TextStyle(
                                          color: theme.textHeader,
                                        ),
                                      ),
                                      content: Text(
                                        '휴지통 안의 모든 메모를 영구 삭제할까요?',
                                        style: TextStyle(color: theme.textBody),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: theme.textBody,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _emptyTrash(theme, allMemos);
                                          },
                                          child: const Text(
                                            '비우기',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          child: const Text(
                            '전체 삭제',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : allMemos.isEmpty
                  ? Center(
                      child: Text(
                        '휴지통이 깨끗하게 비어있어요! 🌿',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textBody.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: allMemos.length,
                      itemBuilder: (context, index) {
                        final doc = allMemos[index];
                        final String content = doc['content'] ?? '';
                        final lines = content.split('\n');
                        final title = lines.first.length > 20
                            ? '${lines.first.substring(0, 20)}...'
                            : lines.first;
                        final isSelected = _selectedMemos.contains(doc.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? theme.primary.withOpacity(0.6)
                                  : theme.primaryLight.withOpacity(0.2),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Material(
                            color: isSelected
                                ? theme.primary.withOpacity(0.12)
                                : theme.surface,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onLongPress: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedMemos.add(doc.id);
                                });
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedMemos.remove(doc.id);
                                    } else {
                                      _selectedMemos.add(doc.id);
                                    }
                                    if (_selectedMemos.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  });
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TrashMemoViewScreen(
                                        memoDoc: doc,
                                        theme: theme,
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isSelectionMode) ...[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 2.0,
                                          right: 12.0,
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: isSelected
                                              ? theme.primary
                                              : theme.textBody.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: theme.textHeader,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                dateToYMD(
                                                  (doc['createdAt']
                                                          as Timestamp)
                                                      .toDate(),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.textBody
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (content.split('\n').length > 1 &&
                                              content
                                                  .split('\n')
                                                  .sublist(1)
                                                  .join('\n')
                                                  .trim()
                                                  .isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              content
                                                  .split('\n')
                                                  .sublist(1)
                                                  .join('\n')
                                                  .trim(),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: theme.textBody
                                                    .withOpacity(0.8),
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
