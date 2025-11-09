import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? currentRoute;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.currentRoute,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(title, style: theme.appBarTheme.titleTextStyle),
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: theme.appBarTheme.elevation ?? 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        tooltip: 'Menu',
      ),
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
