// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

// --- 🗑️ 휴지통 개별 메모 확인 및 복구/삭제 화면 ---
class TrashMemoViewScreen extends StatefulWidget {
  final DocumentSnapshot memoDoc;
  final AppThemeColor theme;

  const TrashMemoViewScreen({
    super.key,
    required this.memoDoc,
    required this.theme,
  });

  @override
  State<TrashMemoViewScreen> createState() => _TrashMemoViewScreenState();
}

class _TrashMemoViewScreenState extends State<TrashMemoViewScreen> {
  bool _isProcessing = false;

  Future<void> _restoreMemo() async {
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final foldersQuery = await userRef.collection('folders').get();
      final existingFolderIds = foldersQuery.docs.map((e) => e.id).toSet();

      String targetFolder = '';
      final data = widget.memoDoc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('originalFolderId')) {
        targetFolder = data['originalFolderId'];
      }

      if (!existingFolderIds.contains(targetFolder)) {
        try {
          targetFolder = foldersQuery.docs
              .firstWhere((e) => e['name'] == '임시 폴더')
              .id;
        } catch (e) {
          final newFolder = await userRef.collection('folders').add({
            'name': '임시 폴더',
            'colorValue': Colors.grey.value,
            'count': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          targetFolder = newFolder.id;
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.update(widget.memoDoc.reference, {
        'folderId': targetFolder,
        'originalFolderId': FieldValue.delete(),
      });
      batch.update(userRef.collection('folders').doc(targetFolder), {
        'count': FieldValue.increment(1),
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 성공적으로 복구되었습니다! ✨', widget.theme.primary);
      }
    } catch (e) {
      CustomToast.show(context, '복구에 실패했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deletePermanent() async {
    setState(() => _isProcessing = true);
    try {
      await widget.memoDoc.reference.delete();
      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 완전히 삭제되었습니다. 🗑️', Colors.orange);
      }
    } catch (e) {
      CustomToast.show(context, '삭제 실패', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.memoDoc['content'] ?? '';
    final timestamp = widget.memoDoc['createdAt'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final dateString =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: widget.theme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.theme.textHeader,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '휴지통 메모 확인',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.theme.textHeader,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateString,
                style: TextStyle(
                  color: widget.theme.textBody.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.theme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.theme.textHeader,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deletePermanent,
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '영구 삭제',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restoreMemo,
                        icon: const Icon(
                          Icons.restore_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          '복구하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.theme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
