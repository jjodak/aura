// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';

// ✨ CustomToast 시스템
class CustomToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String message, Color color) {
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        color: color,
        onDismissed: () {
          _entry?.remove();
          _entry = null;
        },
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color color;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.color,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDismissing = false; // 💡 중복 닫힘 방지 플래그

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 💡 원래대로 상단에서 내려오도록 설정 (-100에서 20으로)
    _animation = Tween<double>(
      begin: -100.0,
      end: 20.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // 2.5초 뒤 자동 닫힘
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && !_isDismissing) {
        _dismiss();
      }
    });
  }

  // 💡 즉시 닫기 함수 (위로 부드럽게 올라가며 사라짐)
  void _dismiss() {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          // 💡 상단 배치 유지 (안전 영역 고려)
          top: _animation.value + MediaQuery.of(context).padding.top,
          left: 24,
          right: 24,
          child: GestureDetector(
            // 💡 탭하거나 위로 스와이프하면 즉시 닫힘
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // 속도가 0보다 작으면 위로 스와이프한 것
                _dismiss();
              }
            },
            child: Material(
              elevation: 15,
              borderRadius: BorderRadius.circular(100),
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
  }
}
