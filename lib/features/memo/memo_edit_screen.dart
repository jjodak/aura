// ignore_for_file: prefer_const_constructors
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_toast.dart';

// --- 📝 개별 메모 수정 및 삭제 화면 ---
class MemoEditScreen extends StatefulWidget {
  final String memoId;
  final String folderId;
  final String initialContent;
  final Color folderColor;

  const MemoEditScreen({
    super.key,
    required this.memoId,
    required this.folderId,
    required this.initialContent,
    required this.folderColor,
  });

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late TextEditingController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  Future<void> _updateMemo(AppThemeColor theme) async {
    if (_controller.text.trim().isEmpty) {
      CustomToast.show(context, '내용을 입력해주세요.', Colors.orange);
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('memos')
          .doc(widget.memoId)
          .update({
            'content': _controller.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모가 수정되었습니다. ✨', theme.primary);
      }
    } catch (e) {
      CustomToast.show(context, '수정 실패: 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteMemo() async {
    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('memos')
          .doc(widget.memoId)
          .update({'folderId': 'trash', 'originalFolderId': widget.folderId});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('folders')
          .doc(widget.folderId)
          .update({'count': FieldValue.increment(-1)});

      if (mounted) {
        Navigator.pop(context);
        CustomToast.show(context, '메모를 휴지통으로 옮겼습니다. 🗑️', Colors.orange);
      }
    } catch (e) {
      CustomToast.show(context, '삭제 실패: 오류가 발생했습니다.', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                onPressed: _isProcessing ? null : _deleteMemo,
              ),
              IconButton(
                icon: Icon(Icons.check_rounded, color: theme.primary, size: 28),
                onPressed: _isProcessing ? null : () => _updateMemo(theme),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.surface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: widget.folderColor.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.folderColor.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                          hintText: '메모를 수정해보세요...',
                          hintStyle: TextStyle(
                            color: theme.textBody.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
