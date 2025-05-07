// lib/src/views/dialogs/onboarding_dialog.dart
import 'package:flutter/material.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final PageController _pageController = PageController();
  final List<String> _pages = [
    "👋 ZAE Labeler에 오신 걸 환영합니다!",
    "📁 프로젝트를 생성하거나 불러오세요.",
    "🧠 데이터를 업로드하고 라벨링을 시작하세요.",
  ];
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Navigator.of(context).pop(); // 종료
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64), // 🔧 좌우 여백 확보
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360), // ✅ 너비 제한
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        _pages[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 또는 spaceEvenly
                  children: [
                    Text(
                      "${_currentPage + 1} / ${_pages.length}",
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage == _pages.length - 1 ? "시작하기" : "다음"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
