import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '/admin/users';
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userRole = currentUser.role.toLowerCase();
    final isAdmin = userRole == 'admin';
    final isclient = userRole == 'client';

    // Redirect clients
    if (isclient) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final navigator = Navigator.maybeOf(context, rootNavigator: true);
          navigator?.pushReplacementNamed('/user/menu');
        }
      });
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: isAdmin ? 'User Management' : 'View Users',
        currentRoute: route,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: FirestoreService().getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, theme, snapshot.error.toString());
          }

          final users = snapshot.data ?? [];
          final filteredUsers = _filterUsers(users);

          return Column(
            children: [
              _buildHeaderSection(context, theme, users),
              _buildSearchAndFilters(context, theme),
              Expanded(
                child: filteredUsers.isEmpty
                    ? _buildEmptyState(context, theme)
                    : _buildUserList(
                        context, theme, filteredUsers, currentUser),
              ),
            ],
          );
        },
      ),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    final query = _searchController.text.trim().toLowerCase();
    return users.where((user) {
      // Case-insensitive role comparison
      final userRole = user.role.toLowerCase().trim();
      final filterRole = _roleFilter.toLowerCase().trim();
      final matchesRole = filterRole == 'all' || userRole == filterRole;
      if (!matchesRole) return false;
      if (query.isEmpty) return true;
      final name = (user.displayName ?? '').toLowerCase();
      final email = user.email.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Widget _buildHeaderSection(
      BuildContext context, ThemeData theme, List<UserModel> users) {
    final stats = {
      'total': users.length,
      'admin':
          users.where((u) => u.role.toLowerCase().trim() == 'admin').length,
      'client':
          users.where((u) => u.role.toLowerCase().trim() == 'client').length,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            Responsive.responsiveSpacing(context, mobile: 24, tablet: 32),
        vertical: Responsive.responsiveSpacing(context, mobile: 20, tablet: 24),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.02),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Responsive.responsiveContainer(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
            Text(
              'Manage and view all system users',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 20)),
            _buildStatsGrid(context, theme, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, ThemeData theme, Map<String, int> stats) {
    return Responsive.isMobile(context)
        ? Column(
            children: [
              _StatCard(
                icon: Icons.people_alt_outlined,
                label: 'Total Users',
                value: stats['total']!.toString(),
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              SizedBox(
                  height: Responsive.responsiveSpacing(context, mobile: 12)),
              _StatCard(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Administrators',
                value: stats['admin']!.toString(),
                color: Colors.orange,
                theme: theme,
              ),
              SizedBox(
                  height: Responsive.responsiveSpacing(context, mobile: 12)),
              _StatCard(
                icon: Icons.person_outline,
                label: 'Clients',
                value: stats['client']!.toString(),
                color: Colors.blue,
                theme: theme,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_outlined,
                  label: 'Total Users',
                  value: stats['total']!.toString(),
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              SizedBox(
                  width: Responsive.responsiveSpacing(context,
                      mobile: 16, tablet: 20)),
              Expanded(
                child: _StatCard(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Administrators',
                  value: stats['admin']!.toString(),
                  color: Colors.orange,
                  theme: theme,
                ),
              ),
              SizedBox(
                  width: Responsive.responsiveSpacing(context,
                      mobile: 16, tablet: 20)),
              Expanded(
                child: _StatCard(
                  icon: Icons.person_outline,
                  label: 'Clients',
                  value: stats['client']!.toString(),
                  color: Colors.blue,
                  theme: theme,
                ),
              ),
            ],
          );
  }

  Widget _buildSearchAndFilters(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            Responsive.responsiveSpacing(context, mobile: 24, tablet: 32),
        vertical: Responsive.responsiveSpacing(context, mobile: 20, tablet: 24),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Responsive.responsiveContainer(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: Icon(Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: Responsive.responsiveSpacing(context,
                        mobile: 16, tablet: 18),
                  ),
                ),
              ),
            ),
            SizedBox(
                height: Responsive.responsiveSpacing(context,
                    mobile: 20, tablet: 24)),

            // Filter Chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Role:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                SizedBox(
                    height: Responsive.responsiveSpacing(context, mobile: 12)),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _FilterChip(
                      label: 'All Users',
                      value: 'all',
                      selected: _roleFilter == 'all',
                      onSelected: () => setState(() => _roleFilter = 'all'),
                      icon: Icons.people_outline,
                    ),
                    _FilterChip(
                      label: 'Admins',
                      value: 'admin',
                      selected: _roleFilter == 'admin',
                      onSelected: () => setState(() => _roleFilter = 'admin'),
                      icon: Icons.admin_panel_settings_outlined,
                      color: Colors.orange,
                    ),
                    _FilterChip(
                      label: 'Clients',
                      value: 'client',
                      selected: _roleFilter == 'client',
                      onSelected: () => setState(() => _roleFilter = 'client'),
                      icon: Icons.person_outline,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                  Responsive.responsiveSpacing(context, mobile: 24)),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),
            Text(
              'Unable to Load Users',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 12)),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 32)),
            FilledButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.responsiveSpacing(context, mobile: 24),
                  vertical: Responsive.responsiveSpacing(context, mobile: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                  Responsive.responsiveSpacing(context, mobile: 24)),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),
            Text(
              'No Users Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 12)),
            Text(
              'Try adjusting your search or filter criteria to find users',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    ThemeData theme,
    List<UserModel> users,
    UserModel currentUser,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
            Responsive.responsiveSpacing(context, mobile: 24, tablet: 32),
        vertical: Responsive.responsiveSpacing(context, mobile: 16, tablet: 20),
      ),
      child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (context, index) => SizedBox(
          height: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16),
        ),
        itemBuilder: (context, index) {
          return _UserCard(
            key: ValueKey('user_${users[index].uid}'),
            user: users[index],
            currentUserId: currentUser.uid,
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final String currentUserId;

  const _UserCard({
    super.key,
    required this.user,
    required this.currentUserId,
  });

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'client':
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'client':
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'client':
      default:
        return 'Client';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = user.uid == currentUserId;
    final roleColor = _getRoleColor(user.role);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
            Responsive.responsiveSpacing(context, mobile: 20, tablet: 24)),
        child: Row(
          children: [
            // Avatar with Role Badge
            Stack(
              children: [
                Container(
                  width: Responsive.responsiveIconSize(context,
                      mobile: 64, tablet: 72),
                  height: Responsive.responsiveIconSize(context,
                      mobile: 64, tablet: 72),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor.withOpacity(0.8),
                        roleColor,
                      ],
                    ),
                  ),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: Colors.white,
                    size: Responsive.responsiveIconSize(context,
                        mobile: 28, tablet: 32),
                  ),
                ),
                if (isCurrentUser)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.star,
                        color: theme.colorScheme.onPrimary,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
                width: Responsive.responsiveSpacing(context,
                    mobile: 20, tablet: 24)),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'No Name',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(
                                height: Responsive.responsiveSpacing(context,
                                    mobile: 4)),
                            Text(
                              user.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'You',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                      height:
                          Responsive.responsiveSpacing(context, mobile: 12)),

                  // Role Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: roleColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(user.role),
                          size: 16,
                          color: roleColor,
                        ),
                        SizedBox(
                            width: Responsive.responsiveSpacing(context,
                                mobile: 8)),
                        Text(
                          _getRoleLabel(user.role),
                          style: theme.textTheme.labelLarge?.copyWith(
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
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: selected
                  ? chipColor
                  : theme.colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: chipColor.withOpacity(0.15),
      checkmarkColor: chipColor,
      side: BorderSide(
        color:
            selected ? chipColor : theme.colorScheme.outline.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        color:
            selected ? chipColor : theme.colorScheme.onSurface.withOpacity(0.8),
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
          Responsive.responsiveSpacing(context, mobile: 20, tablet: 24)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
                Responsive.responsiveSpacing(context, mobile: 12, tablet: 14)),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: Responsive.responsiveIconSize(context,
                  mobile: 24, tablet: 28),
            ),
          ),
          SizedBox(
              width: Responsive.responsiveSpacing(context,
                  mobile: 16, tablet: 20)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: Responsive.responsiveFontSize(context,
                        mobile: 24, tablet: 28),
                  ),
                ),
                SizedBox(
                    height: Responsive.responsiveSpacing(context, mobile: 4)),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
