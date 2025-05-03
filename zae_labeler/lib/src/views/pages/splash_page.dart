// lib/src/views/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

// import 'package:zae_labeler/common/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  bool _showStartButton = false;
  bool _showLoginButtons = false;

  @override
  void initState() {
    super.initState();

    // 시작하기 버튼은 3초 후 표시
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showStartButton = true;
        });
      }
    });
  }

  void _handleUserInteraction() {
    if (!_showLoginButtons) {
      setState(() {
        _showLoginButtons = true;
      });
    }
  }

  void _handleGuestAccess() async {
    final url = Uri.parse('https://zae-park.github.io/zae-labeler/');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("비회원 안내"),
        content: const Text("비회원 모드 이용 시 진행 사항이 저장되지 않습니다.\n외부 링크로 이동할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text("이동")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleUserInteraction,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Lottie.asset('assets/zae-splash.json', width: 250, height: 250, fit: BoxFit.contain),
                ),
              ),
              const Text("ZAE Labeler", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: _showStartButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: _showStartButton ? ElevatedButton(onPressed: _handleUserInteraction, child: const Text("시작하기")) : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // 로그인 버튼 세트
              AnimatedOpacity(
                opacity: _showLoginButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: _showLoginButtons
                    ? Column(
                        children: [
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text("Google로 로그인"),
                            // TODO: Google 로그인 로직 삽입
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/project_list');
                            },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.code),
                            label: const Text("GitHub로 로그인"),
                            // TODO: GitHub 로그인 로직 삽입
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/project_list');
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(icon: const Icon(Icons.open_in_new), label: const Text("비회원으로 이용하기"), onPressed: _handleGuestAccess),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
