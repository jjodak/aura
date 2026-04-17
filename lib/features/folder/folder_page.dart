import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/glow_background.dart';
import 'folder_detail_screen.dart';
import '../trash/trash_page.dart';

// --- 5. 폴더 화면 ---
class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isGridView = false;

  void _showFolderDialog(
    BuildContext context,
    AppThemeColor theme, {
    DocumentSnapshot? existingFolder,
  }) {
    final nameController = TextEditingController(
      text: existingFolder != null ? existingFolder['name'] : '',
    );

    final List<Color> colorOptions = [
      theme.primary,
      theme.accent1,
      theme.accent2,
      Color(0xFFE76F51),
      Color(0xFF2A9D8F),
      Color(0xFF457B9D),
    ];
    Color selectedColor = existingFolder != null
        ? Color(existingFolder['colorValue'])
        : colorOptions[0];
    bool isEditing = existingFolder != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                isEditing ? '폴더 이름 변경 ✏️' : '새 폴더 만들기 📁',
                style: TextStyle(
                  color: theme.textHeader,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.textHeader),
                    decoration: InputDecoration(
                      hintText: '폴더 이름 (예: 아이디어 ✨)',
                      hintStyle: TextStyle(
                        color: theme.textBody.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: theme.bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '폴더 색상',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textBody.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colorOptions.map((color) {
                      final isSelected = selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () =>
                            setStateDialog(() => selectedColor = color),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: theme.textBody)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    try {
                      if (isEditing) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('folders')
                            .doc(existingFolder!.id)
                            .update({
                              'name': nameController.text.trim(),
                              'colorValue': selectedColor.value,
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          CustomToast.show(
                            context,
                            '폴더 이름이 변경되었어요! ✨',
                            theme.primary,
                          );
                        }
                      } else {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('folders')
                            .add({
                              'name': nameController.text.trim(),
                              'colorValue': selectedColor.value,
                              'count': 0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (mounted) {
                          Navigator.pop(context);
                          CustomToast.show(
                            context,
                            '새 폴더가 만들어졌어요! 🎉',
                            theme.primary,
                          );
                        }
                      }
                    } catch (e) {
                      CustomToast.show(
                        context,
                        '요청 처리에 실패했습니다.',
                        Colors.redAccent,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? '저장' : '만들기',
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
  }

  Future<void> _deleteFolder(
    String folderId,
    int count,
    AppThemeColor theme,
  ) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);

      if (count > 0) {
        final tempFolderQuery = await userRef
            .collection('folders')
            .where('name', isEqualTo: '임시 폴더')
            .get();
        String tempFolderId;

        if (tempFolderQuery.docs.isEmpty) {
          final newFolder = await userRef.collection('folders').add({
            'name': '임시 폴더',
            'colorValue': theme.textBody.value,
            'count': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tempFolderId = newFolder.id;
        } else {
          tempFolderId = tempFolderQuery.docs.first.id;
        }

        final memosQuery = await userRef
            .collection('memos')
            .where('folderId', isEqualTo: folderId)
            .get();
        final batch = FirebaseFirestore.instance.batch();

        for (var doc in memosQuery.docs) {
          batch.update(doc.reference, {'folderId': tempFolderId});
        }

        batch.update(userRef.collection('folders').doc(tempFolderId), {
          'count': FieldValue.increment(count),
        });

        await batch.commit();
        CustomToast.show(
          context,
          '폴더 삭제 완료! 안의 메모들은 [임시 폴더]로 옮겼어요 📦',
          Colors.orange,
        );
      } else {
        CustomToast.show(context, '빈 폴더가 삭제되었습니다 🗑️', Colors.orange);
      }

      await userRef.collection('folders').doc(folderId).delete();
    } catch (e) {
      CustomToast.show(context, '폴더 삭제 중 오류가 발생했습니다.', Colors.redAccent);
    }
  }

  void _showFolderOptions(
    BuildContext context,
    AppThemeColor theme,
    DocumentSnapshot folderDoc,
  ) {
    bool isTempFolder = folderDoc['name'] == '임시 폴더';
    int memoCount = folderDoc['count'] ?? 0;

    if (isTempFolder && memoCount > 0) {
      CustomToast.show(context, '메모가 들어있는 임시 폴더는 지울 수 없어요.', theme.textBody);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isTempFolder)
                  ListTile(
                    leading: Icon(Icons.edit_rounded, color: theme.primary),
                    title: Text(
                      '폴더 이름/색상 변경',
                      style: TextStyle(
                        color: theme.textHeader,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showFolderDialog(
                        context,
                        theme,
                        existingFolder: folderDoc,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    isTempFolder ? '빈 임시 폴더 삭제' : '폴더 삭제 (메모는 임시폴더로)',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
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
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteFolder(folderDoc.id, memoCount, theme);
                            },
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeColor>(
      valueListenable: appThemeNotifier,
      builder: (context, theme, child) {
        final user = FirebaseAuth.instance.currentUser;
        return Stack(
          children: [
            Positioned(
              top: 80,
              right: -50,
              child: GlowBackground(color: theme.primary, size: 320),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: theme.accent1,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'My Collection',
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
                              '나만의 공간',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.textHeader,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isGridView ? Icons.list_alt_rounded : Icons.grid_view_rounded,
                                color: theme.accent1,
                                size: 24,
                              ),
                              onPressed: () => setState(() => _isGridView = !_isGridView),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.accent1,
                                size: 24,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TrashPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '소중한 기억들을 카테고리별로 정리해요\n(폴더를 길게 누르면 편집/삭제 가능해요)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.textBody.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('folders')
                          .orderBy('createdAt')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final folders = snapshot.data?.docs ?? [];

                        if (_isGridView) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: folders.length + 1,
                            itemBuilder: (context, index) {
                              if (index == folders.length) {
                                return _buildGridAddButton(theme);
                              }
                              return _buildGridFolderItem(theme, folders[index]);
                            },
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: folders.length + 1,
                          itemBuilder: (context, index) {
                            if (index == folders.length) {
                              return _buildListAddButton(theme);
                            }
                            return _buildListFolderItem(theme, folders[index]);
                          },
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

  // --- 추가된 보조 위젯 빌더들 ---

  Widget _buildListAddButton(AppThemeColor theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryLight.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showFolderDialog(context, theme),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryLight.withOpacity(0.4), width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: theme.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  '새 폴더 만들기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textHeader),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridAddButton(AppThemeColor theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primaryLight.withOpacity(0.4), width: 1.5, style: BorderStyle.solid),
      ),
      child: Material(
        color: theme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showFolderDialog(context, theme),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, color: theme.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                '새 폴더',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textHeader),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListFolderItem(AppThemeColor theme, DocumentSnapshot doc) {
    final String name = doc['name'];
    final int count = doc['count'] ?? 0;
    final Color c = Color(doc['colorValue']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크') ? Colors.black.withOpacity(0.2) : c.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FolderDetailScreen(folderId: doc.id, folderName: name, folderColor: c))),
          onLongPress: () => _showFolderOptions(context, theme, doc),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: c.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.folder_rounded, color: c, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textHeader)),
                      Text('$count개의 메모', style: TextStyle(fontSize: 12, color: theme.textBody.withOpacity(0.7))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: c.withOpacity(0.5), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridFolderItem(AppThemeColor theme, DocumentSnapshot doc) {
    final String name = doc['name'];
    final int count = doc['count'] ?? 0;
    final Color c = Color(doc['colorValue']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.name.contains('다크') ? Colors.black.withOpacity(0.2) : c.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FolderDetailScreen(folderId: doc.id, folderName: name, folderColor: c))),
          onLongPress: () => _showFolderOptions(context, theme, doc),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: c.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.folder_rounded, color: c, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textHeader),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textBody.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
