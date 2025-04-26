import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'project_list_page.dart';
import '../../view_models/auth_view_model.dart';
import '../../../env.dart';
import '../widgets/buttons/social_login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        if (isDev || authVM.isSignedIn) {
          return Scaffold(
            appBar: AppBar(
              title: Text("Welcome, ${authVM.userName.isNotEmpty ? authVM.userName : 'Guest'}"),
              actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => authVM.signOut())],
            ),
            body: const ProjectListPage(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _hasShownConflictSnackbar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showConflictSnackbarIfNeeded();
  }

  void _showConflictSnackbarIfNeeded() {
    final authVM = context.read<AuthViewModel>();
    final provider = authVM.conflictingProvider;
    final email = authVM.conflictingEmail;

    if (!_hasShownConflictSnackbar && provider != null && email != null) {
      _hasShownConflictSnackbar = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final msg = "⚠️ $email 계정은 이미 가입되어 있습니다.\n다른 방법으로 로그인해주세요.";
        debugPrint("[Snackbar] $msg");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final provider = authVM.conflictingProvider;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (provider != null)
              Column(
                children: [
                  Text(
                    "⚠️ 이전에 $provider 로 로그인한 계정입니다.",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text("아래의 $provider 버튼을 눌러 다시 로그인해주세요."),
                  const SizedBox(height: 24),
                ],
              ),
            SocialLoginButton.google(onPressed: () => authVM.signInWithGoogle()),
            SocialLoginButton.github(onPressed: () => authVM.signInWithGitHub()),
          ],
        ),
      ),
    );
  }
}
