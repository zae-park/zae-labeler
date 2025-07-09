import 'dart:async';
import 'package:flutter/material.dart';

enum AlertType { info, success, error }

class GlobalAlertManager {
  static final _queue = <_AlertRequest>[];
  static bool _isShowing = false;

  static void show(BuildContext context, String message, {AlertType type = AlertType.info, Duration duration = const Duration(seconds: 2)}) {
    _queue.add(_AlertRequest(message, type, duration));
    if (!_isShowing) _showNext(context);
  }

  static void _showNext(BuildContext context) {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }

    _isShowing = true;
    final current = _queue.removeAt(0);

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _GlobalAlertWidget(message: current.message, type: current.type),
    );

    overlay.insert(entry);

    Future.delayed(current.duration, () {
      entry.remove();
      _showNext(context); // 다음 알림
    });
  }
}

class _AlertRequest {
  final String message;
  final AlertType type;
  final Duration duration;

  _AlertRequest(this.message, this.type, this.duration);
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
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
