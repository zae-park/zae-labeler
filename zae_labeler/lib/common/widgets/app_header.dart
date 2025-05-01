import 'package:flutter/material.dart';

/// [AppHeader] is a reusable, flexible AppBar widget used across the app.
///
/// It supports:
/// - Custom [title] as a string
/// - Optional [leading] widget (e.g., back button, logo)
/// - Flexible [actions] (e.g., icon buttons, menus)
/// - Configurable [centerTitle], [backgroundColor], and [elevation]
///
/// Usage:
/// ```dart
/// AppHeader(
///   title: 'My Page',
///   leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () {}),
///   actions: [Icon(Icons.more_vert)],
/// )
/// ```
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;

  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
