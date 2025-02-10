import 'package:flutter/material.dart';

/// ✅ 이전/다음 버튼을 포함한 네비게이션 컨트롤러
class NavigationButtons extends StatefulWidget {
  final Future<void> Function() onPrevious; // ✅ 이전 버튼 콜백 (비동기 지원)
  final Future<void> Function() onNext; // ✅ 다음 버튼 콜백 (비동기 지원)

  const NavigationButtons({Key? key, required this.onPrevious, required this.onNext}) : super(key: key);

  @override
  NavigationButtonsState createState() => NavigationButtonsState();
}

class NavigationButtonsState extends State<NavigationButtons> {
  bool _isLoading = false; // ✅ 로딩 상태 추가

  Widget indicator = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));

  /// ✅ 버튼을 클릭하면 비동기 처리 후 UI 업데이트
  Future<void> _handleNavigation(Future<void> Function() action) async {
    setState(() => _isLoading = true); // ✅ 로딩 시작
    await action(); // ✅ 비동기 동작 실행
    setState(() => _isLoading = false); // ✅ 로딩 종료
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(onPressed: _isLoading ? null : () => _handleNavigation(widget.onPrevious), child: _isLoading ? indicator : const Text('이전')),
          ElevatedButton(onPressed: _isLoading ? null : () => _handleNavigation(widget.onNext), child: _isLoading ? indicator : const Text('다음')),
        ],
      ),
    );
  }
}
