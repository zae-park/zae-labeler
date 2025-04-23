import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';
import 'project_list_page.dart';
import '../../../env.dart';
import 'package:zae_labeler/common/common_widgets.dart';

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

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    final hasConflict = authVM.conflictingProvider != null;
    final provider = authVM.conflictingProvider;
    final email = authVM.conflictingEmail;

    return Scaffold(
      body: Center(
        child: AutoSeparatedColumn(
          separator: const SizedBox(height: 16),
          children: [
            if (hasConflict)
              Column(
                children: [
                  Text(
                    "⚠️ ${email ?? '해당 이메일'}은 이미 $provider 계정으로 가입되어 있습니다.",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text("아래의 $provider 버튼을 눌러 로그인해주세요."),
                ],
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              onPressed: () => authVM.signInWithGoogle(),
              style: hasConflict && provider == "Google" ? ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700) : null,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text("Sign in with GitHub"),
              onPressed: () => authVM.signInWithGitHub(),
              style: hasConflict && provider == "GitHub" ? ElevatedButton.styleFrom(backgroundColor: Colors.black87) : null,
            ),
          ],
        ),
      ),
    );
  }
}
