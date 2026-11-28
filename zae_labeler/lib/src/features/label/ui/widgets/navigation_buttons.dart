// lib/src/features/label/ui/widgets/navigation_buttons.dart
import 'package:flutter/material.dart';

/// 이전/다음 버튼. 이동이 진행되는 동안 중복 입력을 막습니다.
class NavigationButtons extends StatefulWidget {
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;
  final bool hasPrevious;
  final bool hasNext;

  const NavigationButtons({super.key, required this.onPrevious, required this.onNext, this.hasPrevious = true, this.hasNext = true});

  @override
  State<NavigationButtons> createState() => _NavigationButtonsState();
}

class _NavigationButtonsState extends State<NavigationButtons> {
  bool _isLoading = false;

  static const _indicator = SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));

  Future<void> _handle(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _isLoading || !widget.hasPrevious ? null : () => _handle(widget.onPrevious),
            child: _isLoading ? _indicator : const Text('이전'),
          ),
          ElevatedButton(onPressed: _isLoading || !widget.hasNext ? null : () => _handle(widget.onNext), child: _isLoading ? _indicator : const Text('다음')),
        ],
      ),
    );
  }
}
