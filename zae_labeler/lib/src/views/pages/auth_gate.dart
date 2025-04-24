import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'project_list_page.dart';
import '../../../env.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, _) {
        if (isDev || authVM.isSignedIn) {
          return Scaffold(
            appBar: AppBar(
              title: Text(authVM.isSignedIn ? "Welcome, ${authVM.userName}" : "Welcome Guest"),
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
    _maybeShowConflictSnackbar();
  }

  void _maybeShowConflictSnackbar() {
    final authVM = context.read<AuthViewModel>();
    final provider = authVM.conflictingProvider;
    final email = authVM.conflictingEmail;

    if (!_hasShownConflictSnackbar && provider != null && email != null) {
      _hasShownConflictSnackbar = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ $email 계정은 $provider 계정으로 가입되어 있습니다."),
            backgroundColor: Colors.red.shade700,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowConflictSnackbar(); // 👈 build 중에도 체크

    final authVM = context.watch<AuthViewModel>();
    final hasConflict = authVM.conflictingProvider != null;
    final provider = authVM.conflictingProvider;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasConflict) ...[
              Text(
                "⚠️ 이전에 $provider 로 로그인한 계정입니다.",
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => authVM.signInWithGoogle(),
              child: const Text("Sign in with Google"),
            ),
            ElevatedButton(
              onPressed: () => authVM.signInWithGitHub(),
              child: const Text("Sign in with GitHub"),
            ),
          ],
        ),
      ),
    );
  }
}
