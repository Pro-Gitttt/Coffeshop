import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/complaint_model.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'employee':
        return Colors.green;
      case 'client':
      default:
        return Colors.blue;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Employee';
      case 'client':
      default:
        return 'client';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'employee':
        return Icons.coffee;
      case 'client':
      default:
        return Icons.person;
    }
  }

  List<Color> _getGradientColors(Color baseColor) {
    if (baseColor == Colors.orange) {
      return [Colors.orange.shade400, Colors.orange.shade700];
    } else if (baseColor == Colors.green) {
      return [Colors.green.shade400, Colors.green.shade700];
    } else {
      return [Colors.blue.shade400, Colors.blue.shade700];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final role = user.role.toLowerCase();
    final isAdmin = role == 'admin';
    final isEmployee = role == 'employee';
    final roleColor = _getRoleColor(user.role);
    final roleLabel = _getRoleLabel(user.role);
    final roleIcon = _getRoleIcon(user.role);
    final displayName = user.displayName ?? user.email.split('@')[0];

    final List<Widget> navItems = [];

    if (isAdmin) {
      navItems.addAll([
        _DrawerTile(
          icon: Icons.dashboard,
          title: 'Dashboard',
          route: '/admin/dashboard',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/dashboard'),
        ),
        _DrawerTile(
          icon: Icons.restaurant_menu,
          title: 'Menu Management',
          route: '/admin/menu',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/menu'),
        ),
        _DrawerTile(
          icon: Icons.inventory_2,
          title: 'Add Stock',
          route: '/admin/add-stock',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/add-stock'),
        ),
        _DrawerTile(
          icon: Icons.history,
          title: 'History',
          route: '/admin/history',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/history'),
        ),
        _DrawerTile(
          icon: Icons.warning_amber_rounded,
          title: 'Shortage Reports',
          route: '/admin/shortage-reports',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/shortage-reports'),
          badgeBuilder: () => StreamBuilder<List<dynamic>>(
            stream: FirestoreService().getShortageReports(unresolvedOnly: true),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              if (count > 0) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        _DrawerTile(
          icon: Icons.people,
          title: 'User Management',
          route: '/admin/users',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/users'),
        ),
        _DrawerTile(
          icon: Icons.calendar_today,
          title: 'Order Forecasts',
          route: '/admin/order-forecasts',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/order-forecasts'),
        ),
        _DrawerTile(
          icon: Icons.feedback,
          title: 'Complaints',
          route: '/admin/complaints',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/admin/complaints'),
          badgeBuilder: () => StreamBuilder<List<ComplaintModel>>(
            stream: FirestoreService().getAllComplaints(),
            builder: (context, snapshot) {
              final complaints = snapshot.data ?? [];
              final pendingCount = complaints
                  .where((c) => c.status == ComplaintStatus.pending)
                  .length;
              if (pendingCount > 0) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pendingCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ]);
    } else if (isEmployee) {
      navItems.addAll([
        _DrawerTile(
          icon: Icons.receipt_long,
          title: 'Orders',
          route: '/employee/orders',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/employee/orders'),
        ),
        _DrawerTile(
          icon: Icons.inventory_2,
          title: 'Stock',
          route: '/user/stock',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/stock'),
        ),
        _DrawerTile(
          icon: Icons.history,
          title: 'History',
          route: '/user/history',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/history'),
        ),
        _DrawerTile(
          icon: Icons.calendar_month,
          title: 'Forecasts',
          route: '/user/order-forecasts',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/order-forecasts'),
        ),
      ]);
    } else {
      navItems.addAll([
        _DrawerTile(
          icon: Icons.local_cafe,
          title: 'Menu',
          route: '/user/menu',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/menu'),
        ),
        _DrawerTile(
          icon: Icons.shopping_cart,
          title: 'Cart',
          route: '/user/cart',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/cart'),
        ),
        _DrawerTile(
          icon: Icons.history,
          title: 'Order History',
          route: '/user/history',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/history'),
        ),
        _DrawerTile(
          icon: Icons.feedback,
          title: 'Complaints',
          route: '/user/complaints',
          currentRoute: currentRoute,
          onTap: () => _navigate(context, '/user/complaints'),
        ),
      ]);
    }

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Enhanced Header with user info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    roleColor.withValues(alpha: 0.15),
                    roleColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with photo support
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getGradientColors(roleColor),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: roleColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: user.photoUrl != null &&
                                user.photoUrl!.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      roleIcon,
                                      size: 35,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                roleIcon,
                                size: 35,
                                color: Colors.white,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            roleIcon,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Display Name
                  Text(
                    displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Email
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Role badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          roleIcon,
                          size: 16,
                          color: roleColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          roleLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ...navItems,
                  const Divider(height: 32, indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    route: '/profile',
                    currentRoute: currentRoute,
                    onTap: () => _navigate(context, '/profile'),
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Sign Out',
                    route: '/logout',
                    currentRoute: currentRoute,
                    onTap: () => _handleLogout(context),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    Navigator.pop(context); // Close drawer
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget Function()? badgeBuilder;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    required this.onTap,
    this.isDestructive = false,
    this.badgeBuilder,
  });

  bool get isSelected => currentRoute == route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color.withValues(alpha: isSelected ? 1.0 : 0.8),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: badgeBuilder != null
            ? badgeBuilder!()
            : isSelected
                ? Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }
}
