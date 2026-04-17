// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../memo/memo_edit_screen.dart';

// --- 📁 폴더 상세 ---
class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String folderName;
  final Color folderColor;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.folderColor,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedMemos = {};

  Future<void> _moveSelectedToTrash(AppThemeColor theme) async {
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
        batch.update(ref, {
          'folderId': 'trash',
          'originalFolderId': widget.folderId,
        });
      }

      final folderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(widget.folderId);
      batch.update(folderRef, {
        'count': FieldValue.increment(-_selectedMemos.length),
      });

      await batch.commit();

      CustomToast.show(
        context,
        '${_selectedMemos.length}개의 메모를 휴지통으로 보냈습니다. 🗑️',
        Colors.orange,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '이동 중 오류가 발생했습니다.', Colors.redAccent);
    }
  }

  void _showMoveFolderSheet(AppThemeColor theme) {
    if (_selectedMemos.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '어느 폴더로 이동할까요? 📁',
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
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final folders = snapshot.data!.docs
                        .where((doc) => doc.id != widget.folderId)
                        .toList();

                    if (folders.isEmpty) {
                      return Center(
                        child: Text(
                          '이동할 수 있는 다른 폴더가 없어요.',
                          style: TextStyle(color: theme.textBody),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final doc = folders[index];
                        final Color folderColor = Color(doc['colorValue']);

                        return ListTile(
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
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await _moveToAnotherFolder(
                              theme,
                              doc.id,
                              doc['name'],
                            );
                          },
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

  Future<void> _moveToAnotherFolder(
    AppThemeColor theme,
    String targetFolderId,
    String targetFolderName,
  ) async {
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
        batch.update(ref, {'folderId': targetFolderId});
      }

      final currentFolderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(widget.folderId);
      batch.update(currentFolderRef, {
        'count': FieldValue.increment(-_selectedMemos.length),
      });

      final targetFolderRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .doc(targetFolderId);
      batch.update(targetFolderRef, {
        'count': FieldValue.increment(_selectedMemos.length),
      });

      await batch.commit();

      CustomToast.show(
        context,
        '메모가 [$targetFolderName] 폴더로 이동되었어요! 🚀',
        theme.primary,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedMemos.clear();
      });
    } catch (e) {
      CustomToast.show(context, '폴더 이동에 실패했습니다.', Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        bool isTempFolder = widget.folderName == '임시 폴더';

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
                      Icon(
                        Icons.folder_rounded,
                        color: widget.folderColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.folderName,
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
                        Icons.drive_file_move_rounded,
                        color: theme.primary,
                      ),
                      onPressed: _selectedMemos.isEmpty
                          ? null
                          : () => _showMoveFolderSheet(theme),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: _selectedMemos.isEmpty
                          ? null
                          : () => _moveSelectedToTrash(theme),
                    ),
                    const SizedBox(width: 8),
                  ]
                : [
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.textHeader,
                      ),
                      color: theme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // 폴더 수정은 리스트 화면에서 가능
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.surface,
                              title: Text(
                                '정말 삭제할까요?',
                                style: TextStyle(color: theme.textHeader),
                              ),
                              content: Text(
                                isTempFolder
                                    ? '빈 임시 폴더를 삭제합니다.'
                                    : '메모가 있다면 임시 폴더로 안전하게 옮겨집니다.',
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
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);

                                    final db = FirebaseFirestore.instance;
                                    final memosSnapshot = await db
                                        .collection('users')
                                        .doc(user!.uid)
                                        .collection('memos')
                                        .where(
                                          'folderId',
                                          isEqualTo: widget.folderId,
                                        )
                                        .get();

                                    if (isTempFolder &&
                                        memosSnapshot.docs.isNotEmpty) {
                                      CustomToast.show(
                                        context,
                                        '메모가 남아있는 임시 폴더는 지울 수 없어요.',
                                        Colors.redAccent,
                                      );
                                      return;
                                    }

                                    if (memosSnapshot.docs.isNotEmpty &&
                                        !isTempFolder) {
                                      final tempFolderQuery = await db
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('folders')
                                          .where('name', isEqualTo: '임시 폴더')
                                          .limit(1)
                                          .get();
                                      String tempFolderId;

                                      if (tempFolderQuery.docs.isEmpty) {
                                        final newTempFolder = await db
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('folders')
                                            .add({
                                              'name': '임시 폴더',
                                              'colorValue': Colors.grey.value,
                                              'count':
                                                  memosSnapshot.docs.length,
                                              'createdAt':
                                                  FieldValue.serverTimestamp(),
                                            });
                                        tempFolderId = newTempFolder.id;
                                      } else {
                                        tempFolderId =
                                            tempFolderQuery.docs.first.id;
                                        await db
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('folders')
                                            .doc(tempFolderId)
                                            .update({
                                              'count': FieldValue.increment(
                                                memosSnapshot.docs.length,
                                              ),
                                            });
                                      }

                                      WriteBatch batch = db.batch();
                                      for (var doc in memosSnapshot.docs) {
                                        batch.update(doc.reference, {
                                          'folderId': tempFolderId,
                                        });
                                      }
                                      await batch.commit();
                                    }

                                    await db
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('folders')
                                        .doc(widget.folderId)
                                        .delete();

                                    if (mounted) {
                                      Navigator.pop(context);
                                      CustomToast.show(
                                        context,
                                        isTempFolder
                                            ? '임시 폴더가 삭제되었습니다.'
                                            : '폴더가 삭제되었습니다.',
                                        Colors.orange,
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isTempFolder)
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              '폴더 수정 (리스트에서 가능)',
                              style: TextStyle(
                                color: theme.textBody.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            enabled: false,
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            isTempFolder ? '빈 임시 폴더 삭제 🗑️' : '폴더 삭제 🗑️',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('memos')
                .where('folderId', isEqualTo: widget.folderId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    '이 폴더는 아직 비어있어요.\n새로운 기록을 남겨보세요! 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textBody.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final memos = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                itemCount: memos.length,
                itemBuilder: (context, index) {
                  final doc = memos[index];
                  final String content = doc['content'] ?? '';

                  final timestamp = doc['createdAt'] as Timestamp?;
                  final date = timestamp?.toDate() ?? DateTime.now();
                  final dateString =
                      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

                  final lines = content.split('\n');
                  final title = lines.first.length > 20
                      ? '${lines.first.substring(0, 20)}...'
                      : lines.first;
                  final body = lines.length > 1
                      ? lines.sublist(1).join('\n')
                      : '';

                  final isSelected = _selectedMemos.contains(doc.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? widget.folderColor.withOpacity(0.6)
                            : widget.folderColor.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: isSelected
                          ? widget.folderColor.withOpacity(0.12)
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
                                builder: (context) => MemoEditScreen(
                                  memoId: doc.id,
                                  folderId: widget.folderId,
                                  initialContent: content,
                                  folderColor: widget.folderColor,
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
                                        ? widget.folderColor
                                        : theme.textBody.withOpacity(0.3),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dateString,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.textBody.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (body.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: theme.textBody.withOpacity(
                                            0.8,
                                          ),
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
              );
            },
          ),
        );
      },
    );
  }
}
