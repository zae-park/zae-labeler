import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions; // ✅ 자유롭게 버튼을 배치할 수 있도록 List<Widget>으로 받음
  final Widget? leading;

  const AppHeader({super.key, required this.title, this.actions = const [], this.leading});

  @override
  Widget build(BuildContext context) => AppBar(leading: leading, title: Text(title), centerTitle: false, actions: actions);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
