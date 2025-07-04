// ✅ STEP 4: SplashPage + AuthGate → 명확한 라우팅 흐름 통합

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zae_labeler/common/i18n.dart';
import '../../view_models/auth_view_model.dart';
import '../../features/project/ui/pages/project_list_page.dart';

class AuthNavigator extends StatelessWidget {
  const AuthNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        if (authVM.user == null) {
          return const SplashPage();
        } else {
          return const ProjectListPage();
        }
      },
    );
  }
}

// ✅ SplashPage 내에서 로그인 시도 후 자동 라우팅
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _showStartButton = false;
  bool _showLoginButtons = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showStartButton = true);
    });
  }

  void _handleStart() {
    setState(() => _showStartButton = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showLoginButtons = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset('assets/zae-splash2.gif', width: 250, height: 250),
            const Text("ZAE Labeler", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _showLoginButtons
                  ? const LoginScreen()
                  : _showStartButton
                      ? ElevatedButton(onPressed: _handleStart, child: const Text("시작하기", style: TextStyle(fontSize: 20)))
                      : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ✅ 로그인 화면 분리
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (authVM.conflictingEmail != null)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "⚠️ ${authVM.conflictingEmail} ${context.l10n.splashPage_error}",
              style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ElevatedButton.icon(icon: const Icon(Icons.login), label: Text(context.l10n.splashPage_google), onPressed: () => authVM.signInWithGoogle()),
        ElevatedButton.icon(icon: const Icon(Icons.code), label: Text(context.l10n.splashPage_github), onPressed: () => authVM.signInWithGitHub()),
        TextButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: Text(context.l10n.splashPage_guest),
          onPressed: () async {
            final url = Uri.parse('https://zae-park.github.io/zae-labeler/');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}
