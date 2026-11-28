import 'dart:async';
import 'package:flutter/material.dart';

enum AlertType { info, success, error }

/// 화면 상단 알림을 순서대로 하나씩 보여줍니다.
///
/// 요청 시점에 **루트 Overlay**를 잡아 두므로, 알림을 요청한 화면이 닫혀도(예: 저장 후 pop)
/// 대기 중인 알림이 안전하게 표시됩니다.
class GlobalAlertManager {
  static final _queue = <_AlertRequest>[];
  static bool _isShowing = false;

  static void show(BuildContext context, String message, {AlertType type = AlertType.info, Duration duration = const Duration(seconds: 2)}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _queue.add(_AlertRequest(message, type, duration, overlay));
    if (!_isShowing) _showNext();
  }

  static void _showNext() {
    // 그 사이 사라진 Overlay(앱 재시작 등)에 대한 요청은 건너뜁니다.
    while (_queue.isNotEmpty && !_queue.first.overlay.mounted) {
      _queue.removeAt(0);
    }
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final current = _queue.removeAt(0);
    final entry = OverlayEntry(
      builder: (_) => _GlobalAlertWidget(message: current.message, type: current.type),
    );
    current.overlay.insert(entry);

    Future.delayed(current.duration, () {
      if (entry.mounted) entry.remove();
      _showNext(); // 다음 알림
    });
  }
}

class _AlertRequest {
  final String message;
  final AlertType type;
  final Duration duration;
  final OverlayState overlay;

  _AlertRequest(this.message, this.type, this.duration, this.overlay);
}

class _GlobalAlertWidget extends StatelessWidget {
  final String message;
  final AlertType type;

  const _GlobalAlertWidget({required this.message, required this.type});

  Color get backgroundColor {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade600;
      case AlertType.error:
        return Colors.red.shade600;
      case AlertType.info:
        return Colors.black87;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle;
      case AlertType.error:
        return Icons.error;
      case AlertType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).viewPadding.top + 16,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
