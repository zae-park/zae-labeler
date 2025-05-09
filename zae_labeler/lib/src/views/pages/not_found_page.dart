import 'dart:async';
import 'package:flutter/material.dart';

class NotFoundPage extends StatefulWidget {
  const NotFoundPage({super.key});

  @override
  State<NotFoundPage> createState() => _NotFoundPageState();
}

class _NotFoundPageState extends State<NotFoundPage> {
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    // ⏳ 5초 후 자동 리디렉션
    _redirectTimer = Timer(const Duration(seconds: 5), _redirectToHome);
  }

  void _redirectToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel(); // ✅ 사용자가 수동 이동 시 타이머 제거
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("404 - 페이지를 찾을 수 없습니다")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("존재하지 않는 페이지입니다.\n5초 후 홈으로 이동합니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(icon: const Icon(Icons.home), label: const Text("지금 이동하기"), onPressed: _redirectToHome),
          ],
        ),
      ),
    );
  }
}
