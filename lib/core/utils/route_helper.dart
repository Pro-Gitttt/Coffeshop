import '../../../core/models/user_model.dart';

/// Helper class for role-based routing
class RouteHelper {
  /// Get the default route for a user based on their role
  static String getRouteForRole(String? role) {
    switch (role) {
      case 'admin':
        return '/admin/dashboard';
      case 'employee':
        return '/employee/orders';
      case 'customer':
      default:
        return '/user/menu';
    }
  }

  /// Get the default route for a user model
  static String getRouteForUser(UserModel? user) {
    if (user == null) {
      return '/login';
    }
    return getRouteForRole(user.role);
  }
}

