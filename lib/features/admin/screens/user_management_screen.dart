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
    final isCustomer = userRole == 'customer';

    // Redirect customers
    if (isCustomer) {
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
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/add-employee');
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add Employee'),
            )
          : null,
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
              _buildSearchAndFilters(context, theme),
              _buildStatistics(context, theme, users),
              Expanded(
                child: filteredUsers.isEmpty
                    ? _buildEmptyState(context, theme)
                    : _buildUserList(
                        context, theme, filteredUsers, currentUser, isAdmin),
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

  Widget _buildSearchAndFilters(BuildContext context, ThemeData theme) {
    return Container(
      padding: Responsive.responsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Responsive.responsiveContainer(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            SizedBox(
              height:
                  Responsive.responsiveSpacing(context, mobile: 12, tablet: 16),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'all',
                  selected: _roleFilter == 'all',
                  onSelected: () => setState(() => _roleFilter = 'all'),
                ),
                _FilterChip(
                  label: 'Admin',
                  value: 'admin',
                  selected: _roleFilter == 'admin',
                  onSelected: () => setState(() => _roleFilter = 'admin'),
                  color: Colors.orange,
                ),
                _FilterChip(
                  label: 'Employee',
                  value: 'employee',
                  selected: _roleFilter == 'employee',
                  onSelected: () => setState(() => _roleFilter = 'employee'),
                  color: Colors.green,
                ),
                _FilterChip(
                  label: 'Customer',
                  value: 'customer',
                  selected: _roleFilter == 'customer',
                  onSelected: () => setState(() => _roleFilter = 'customer'),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(
    BuildContext context,
    ThemeData theme,
    List<UserModel> users,
  ) {
    final stats = {
      'total': users.length,
      'admin': users.where((u) => u.role.toLowerCase().trim() == 'admin').length,
      'employee': users.where((u) => u.role.toLowerCase().trim() == 'employee').length,
      'customer': users.where((u) => u.role.toLowerCase().trim() == 'customer').length,
    };

    return Container(
      padding: Responsive.responsivePadding(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Responsive.responsiveContainer(
        context,
        child: Responsive.isMobile(context)
            ? Column(
                children: [
                  _StatCard(
                    icon: Icons.people,
                    label: 'Total Users',
                    value: stats['total']!.toString(),
                    color: theme.colorScheme.primary,
                    theme: theme,
                  ),
                  SizedBox(
                    height: Responsive.responsiveSpacing(context, mobile: 12),
                  ),
                  _StatCard(
                    icon: Icons.admin_panel_settings,
                    label: 'Admin',
                    value: stats['admin']!.toString(),
                    color: Colors.orange,
                    theme: theme,
                  ),
                  SizedBox(
                    height: Responsive.responsiveSpacing(context, mobile: 12),
                  ),
                  _StatCard(
                    icon: Icons.coffee,
                    label: 'Employee',
                    value: stats['employee']!.toString(),
                    color: Colors.green,
                    theme: theme,
                  ),
                  SizedBox(
                    height: Responsive.responsiveSpacing(context, mobile: 12),
                  ),
                  _StatCard(
                    icon: Icons.person,
                    label: 'Customer',
                    value: stats['customer']!.toString(),
                    color: Colors.blue,
                    theme: theme,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      label: 'Total Users',
                      value: stats['total']!.toString(),
                      color: theme.colorScheme.primary,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: Responsive.responsiveSpacing(context,
                        mobile: 12, tablet: 16),
                  ),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Admin',
                      value: stats['admin']!.toString(),
                      color: Colors.orange,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: Responsive.responsiveSpacing(context,
                        mobile: 12, tablet: 16),
                  ),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.coffee,
                      label: 'Employee',
                      value: stats['employee']!.toString(),
                      color: Colors.green,
                      theme: theme,
                    ),
                  ),
                  SizedBox(
                    width: Responsive.responsiveSpacing(context,
                        mobile: 12, tablet: 16),
                  ),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.person,
                      label: 'Customer',
                      value: stats['customer']!.toString(),
                      color: Colors.blue,
                      theme: theme,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: Responsive.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),
            Text(
              'Error Loading Users',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
            Icon(
              Icons.people_outline,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),
            Text(
              'No Users Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
            Text(
              'Try adjusting your search or filter criteria',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    bool isAdmin,
  ) {
    return Responsive.responsiveContainer(
      context,
      child: ListView.builder(
        padding: Responsive.responsivePadding(context),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _UserCard(
            key: ValueKey('user_${users[index].uid}'),
            user: users[index],
            currentUserId: currentUser.uid,
            canEdit: isAdmin,
            canDelete: isAdmin,
          );
        },
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final UserModel user;
  final String currentUserId;
  final bool canEdit;
  final bool canDelete;

  const _UserCard({
    super.key,
    required this.user,
    required this.currentUserId,
    this.canEdit = false,
    this.canDelete = false,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  UserModel get user => widget.user;
  String get currentUserId => widget.currentUserId;
  bool get canEdit => widget.canEdit;
  bool get canDelete => widget.canDelete;

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'employee':
        return Colors.green;
      case 'customer':
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'employee':
        return Icons.coffee;
      case 'customer':
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'employee':
        return 'Employee';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  Future<void> _showRoleSelectionDialog() async {
    if (!mounted || !canEdit) return;

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RoleSelectionDialog(
        user: user,
        currentRole: user.role,
      ),
    );

    if (selectedRole == null || !mounted) return;
    if (selectedRole == user.role.toLowerCase()) return;

    await _updateUserRole(selectedRole);
  }

  Future<void> _updateUserRole(String newRole) async {
    if (!mounted) return;

    _showLoadingDialog();

    try {
      await FirestoreService().updateUserRole(user.uid, newRole);
      
      if (!mounted) return;
      _hideLoadingDialog();

      // If changing current user's role, reload their data
      if (user.uid == currentUserId && mounted) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadUserData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Role updated successfully to ${_getRoleLabel(newRole)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _hideLoadingDialog();
      
      String errorMessage = 'Failed to update role';
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
        errorMessage = 'Permission denied. Only administrators can change roles.';
      } else if (errorString.contains('not-found') || errorString.contains('not found')) {
        errorMessage = 'User not found in database.';
      } else if (errorString.contains('firestore') || errorString.contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    if (!mounted || !canDelete) return;

    if (user.uid == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.displayName ?? user.email}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirestoreService().deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showCustomMenu(BuildContext context, ThemeData theme) {
    final isCurrentUserLocal = user.uid == currentUserId;
    final canEditLocal = canEdit;
    final canDeleteLocal = canDelete;
    
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null || !mounted) return;

    final RenderBox? button = context.findRenderObject() as RenderBox?;
    if (button == null || !mounted) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        if (canEditLocal && !isCurrentUserLocal)
          PopupMenuItem<String>(
            value: 'change_role',
            child: const Row(
              children: [
                Icon(Icons.swap_horiz, size: 20),
                SizedBox(width: 12),
                Text('Change Role'),
              ],
            ),
          ),
        if (canDeleteLocal && !isCurrentUserLocal)
          PopupMenuItem<String>(
            value: 'delete',
            child: const Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Delete User'),
              ],
            ),
          ),
        if (!canEditLocal && !canDeleteLocal)
          const PopupMenuItem<String>(
            enabled: false,
            value: 'view_only',
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20),
                SizedBox(width: 12),
                Text('View Only'),
              ],
            ),
          ),
      ],
    ).then((value) {
      // Execute immediately when menu closes, don't delay
      if (value == null) return;
      
      // Use WidgetsBinding to ensure we're in a safe frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        if (value == 'change_role' && canEditLocal && !isCurrentUserLocal) {
          _showRoleSelectionDialog();
        } else if (value == 'delete' && canDeleteLocal && !isCurrentUserLocal) {
          _deleteUser();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentUser = user.uid == currentUserId;
    final roleColor = _getRoleColor(user.role);
    final isMobile = Responsive.isMobile(context);

    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.responsiveSpacing(context, mobile: 12, tablet: 16),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: roleColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          Responsive.responsiveSpacing(context, mobile: 16, tablet: 20),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: Responsive.responsiveIconSize(context,
                  mobile: 56, tablet: 64),
              height: Responsive.responsiveIconSize(context,
                  mobile: 56, tablet: 64),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    roleColor.withValues(alpha: 0.8),
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
            SizedBox(
              width:
                  Responsive.responsiveSpacing(context, mobile: 16, tablet: 20),
            ),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? user.email,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'YOU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: Responsive.responsiveSpacing(context,
                        mobile: 4, tablet: 6),
                  ),
                  Text(
                    user.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: Responsive.responsiveSpacing(context,
                        mobile: 8, tablet: 12),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.responsiveSpacing(context,
                          mobile: 12, tablet: 16),
                      vertical: Responsive.responsiveSpacing(context,
                          mobile: 6, tablet: 8),
                    ),
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
                          _getRoleIcon(user.role),
                          size: Responsive.responsiveIconSize(context,
                              mobile: 16, tablet: 18),
                          color: roleColor,
                        ),
                        SizedBox(
                          width: Responsive.responsiveSpacing(context,
                              mobile: 6, tablet: 8),
                        ),
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
            // Actions
            if (!isMobile) ...[
              SizedBox(
                width: Responsive.responsiveSpacing(context,
                    mobile: 8, tablet: 16),
              ),
              if (canEdit && !isCurrentUser)
                IconButton(
                  icon: Icon(Icons.swap_horiz, color: roleColor),
                  tooltip: 'Change role',
                  onPressed: () => _showRoleSelectionDialog(),
                ),
              if (canDelete && !isCurrentUser)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete user',
                  onPressed: () => _deleteUser(),
                ),
            ] else ...[
              SizedBox(
                width: Responsive.responsiveSpacing(context, mobile: 8),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                onPressed: () => _showCustomMenu(context, theme),
              ),
            ],
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

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      checkmarkColor: chipColor,
      side: BorderSide(
        color: selected
            ? chipColor
            : theme.colorScheme.outline.withValues(alpha: 0.3),
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
        Responsive.responsiveSpacing(context, mobile: 16, tablet: 20),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.responsiveSpacing(context, mobile: 10, tablet: 12),
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: Responsive.responsiveIconSize(context,
                  mobile: 24, tablet: 28),
            ),
          ),
          SizedBox(
            width:
                Responsive.responsiveSpacing(context, mobile: 12, tablet: 16),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(
                  height: Responsive.responsiveSpacing(context, mobile: 4),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

/// Beautiful Material 3 role selection dialog
class _RoleSelectionDialog extends StatefulWidget {
  final UserModel user;
  final String currentRole;

  const _RoleSelectionDialog({
    required this.user,
    required this.currentRole,
  });

  @override
  State<_RoleSelectionDialog> createState() => _RoleSelectionDialogState();
}

class _RoleSelectionDialogState extends State<_RoleSelectionDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole.toLowerCase();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'employee':
        return Colors.green;
      case 'customer':
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'employee':
        return Icons.coffee;
      case 'customer':
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Employee';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'admin':
        return 'Full access to all features and user management';
      case 'employee':
        return 'Can process orders and view inventory';
      case 'customer':
      default:
        return 'Can browse menu and place orders';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = ['admin', 'employee', 'customer'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.swap_horiz,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change User Role',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a new role for this user',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                              theme.colorScheme.primary,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.displayName ?? widget.user.email,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRoleColor(widget.currentRole).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getRoleColor(widget.currentRole),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getRoleIcon(widget.currentRole),
                          size: 16,
                          color: _getRoleColor(widget.currentRole),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Current: ${_getRoleLabel(widget.currentRole)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getRoleColor(widget.currentRole),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Role Selection
            Text(
              'Select New Role',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Role Options
            ...roles.map((role) {
              final isSelected = _selectedRole == role;
              final roleColor = _getRoleColor(role);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => _selectedRole = role),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? roleColor.withValues(alpha: 0.1)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? roleColor
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? roleColor.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getRoleIcon(role),
                            color: isSelected ? roleColor : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getRoleLabel(role),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? roleColor : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getRoleDescription(role),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: roleColor,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _selectedRole == widget.currentRole.toLowerCase()
                      ? null
                      : () => Navigator.pop(context, _selectedRole),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
