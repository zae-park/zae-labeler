import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/common/i18n.dart';

import '../../view_models/auth_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../core/services/user_preference_service.dart';

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
    _applySavedLocale();

    // 시작하기 버튼은 3초 후 표시
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showStartButton = true);
      }
    });
  }

  void _applySavedLocale() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = context.read<UserPreferenceService>();
      final locale = prefs.locale;
      context.read<LocaleViewModel>().changeLocale(locale.languageCode);
    });
  }

  void _handleUserInteraction() {
    if (!_showLoginButtons) {
      setState(() => _showLoginButtons = true);
    }
  }

  void _handleGuestAccess() async {
    final url = Uri.parse('https://zae-park.github.io/zae-labeler/');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.splashPage_guest_guide),
        content: Text(context.l10n.splashPage_guest_message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.splashPage_guest_cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(context.l10n.splashPage_guest_confirm),
          ),
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
              Expanded(child: Center(child: Image.asset('assets/zae-splash2.gif', width: 250, height: 250, fit: BoxFit.contain))),
              const Text("ZAE Labeler", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 시작하기 버튼
                    AnimatedOpacity(
                      opacity: _showLoginButtons ? 0.0 : (_showStartButton ? 1.0 : 0.0),
                      duration: const Duration(milliseconds: 600),
                      child: Visibility(
                        visible: !_showLoginButtons,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.grey[300],
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          onPressed: () {
                            setState(() => _showStartButton = false);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted) setState(() => _showLoginButtons = true);
                            });
                          },
                          child: Text(context.l10n.splashPage_start, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                    // 로그인 버튼들
                    AnimatedOpacity(
                      opacity: _showLoginButtons ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 600),
                      child: Visibility(
                        visible: _showLoginButtons,
                        child: AutoSeparatedColumn(
                          separator: const SizedBox(height: 16),
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
                            ElevatedButton.icon(
                                icon: const Icon(Icons.login), label: Text(context.l10n.splashPage_google), onPressed: () => _signInWithGoogle(context)),
                            ElevatedButton.icon(
                                icon: const Icon(Icons.code), label: Text(context.l10n.splashPage_github), onPressed: () => _signInWithGitHub(context)),
                            TextButton.icon(icon: const Icon(Icons.open_in_new), label: Text(context.l10n.splashPage_guest), onPressed: _handleGuestAccess),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
