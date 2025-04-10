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

        return Scaffold(
          body: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              onPressed: () => authVM.signInWithGoogle(),
            ),
          ),
        );
      },
    );
  }
}
