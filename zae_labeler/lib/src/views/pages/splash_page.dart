// lib/src/views/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import 'dart:async';

import '../../view_models/auth_view_model.dart';

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

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    await authVM.signInWithGoogle();
    if (authVM.isSignedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/project_list');
    }
  }

  Future<void> _signInWithGitHub(BuildContext context) async {
    final authVM = context.read<AuthViewModel>();
    await authVM.signInWithGitHub();
    if (authVM.isSignedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/project_list');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return GestureDetector(
      onTap: _handleUserInteraction,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: AutoSeparatedColumn(
            separator: const SizedBox(height: 16),
            children: [
              Expanded(
                child: Center(
                  child: Lottie.asset('assets/zae-splash.json', width: 250, height: 250, fit: BoxFit.contain),
                ),
              ),
              const Text("ZAE Labeler", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 1),
              AnimatedOpacity(
                opacity: _showStartButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: _showLoginButtons ? const SizedBox.shrink() : ElevatedButton(onPressed: _handleUserInteraction, child: const Text("시작하기")),
              ),

              /// ✅ 로그인 버튼
              AnimatedOpacity(
                opacity: _showLoginButtons ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: _showLoginButtons
                    ? AutoSeparatedColumn(
                        separator: const SizedBox(height: 16),
                        children: [
                          if (authVM.conflictingEmail != null)
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                "⚠️ ${authVM.conflictingEmail} 계정은 이미 가입되어 있었니다. 다른 방법으로 다시 시도해주세요.",
                                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ElevatedButton.icon(icon: const Icon(Icons.login), label: const Text("Google로 로그인"), onPressed: () => _signInWithGoogle(context)),
                          ElevatedButton.icon(icon: const Icon(Icons.code), label: const Text("GitHub로 로그인"), onPressed: () => _signInWithGitHub(context)),
                          TextButton.icon(icon: const Icon(Icons.open_in_new), label: const Text("비회원으로 이용하기"), onPressed: _handleGuestAccess),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
