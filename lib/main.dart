import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/repositories/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/user/screens/stock_screen.dart';
import 'features/user/screens/user_history_screen.dart';
import 'features/user/screens/user_order_forecasts_screen.dart';
import 'features/user/screens/complaints_screen.dart';
import 'features/user/screens/complaint_detail_screen.dart';
import 'features/user/screens/orders_dashboard_screen.dart';
import 'features/admin/screens/dashboard_screen.dart';
import 'features/admin/screens/add_stock_screen.dart';
import 'features/admin/screens/edit_stock_screen.dart';
import 'features/admin/screens/history_screen.dart';
import 'features/admin/screens/shortage_reports_screen.dart';
import 'features/admin/screens/user_management_screen.dart';
import 'features/admin/screens/order_forecasts_screen.dart';
import 'features/admin/screens/add_employee_screen.dart';
import 'features/admin/screens/admin_complaints_screen.dart';
import 'features/admin/screens/reports_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'features/admin/screens/menu_list_screen.dart';
import 'features/admin/screens/edit_menu_item_screen.dart';
import 'features/user/providers/cart_provider.dart';
import 'features/user/screens/menu_screen.dart';
import 'features/user/screens/product_detail_screen.dart';
import 'features/user/screens/cart_screen.dart';
import 'features/user/screens/order_status_screen.dart';
import 'core/utils/route_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress font loading errors silently
  FlutterError.onError = (details) {
    if (details.exception.toString().contains('google_fonts') ||
        details.exception.toString().contains('Failed to load font')) {
      debugPrint('Font loading error suppressed: ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint('Firebase already initialized, skipping...');
    } else {
      rethrow;
    }
  }

  // Set Firebase Auth language
  await fb_auth.FirebaseAuth.instance.setLanguageCode('en');

  // Configure Firestore for offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuthService>(create: (_) => FirebaseAuthService()),
        ProxyProvider<FirebaseAuthService, AuthRepository>(
          update: (_, authService, __) => AuthRepository(authService),
        ),
        ChangeNotifierProxyProvider<FirebaseAuthService, AuthProvider>(
          create: (context) =>
              AuthProvider(context.read<FirebaseAuthService>()),
          update: (context, authService, previous) =>
              previous ?? AuthProvider(authService),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'CoffeeStock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/user/menu': (context) => const MenuScreen(),
          '/user/product': (context) => const ProductDetailScreen(),
          '/user/cart': (context) => const CartScreen(),
          '/user/order-status': (context) => const OrderStatusScreen(),
          '/employee/orders': (context) => const OrdersDashboardScreen(),
          '/user/stock': (context) => const StockScreen(),
          '/user/history': (context) => const UserHistoryScreen(),
          '/user/order-forecasts': (context) =>
              const UserOrderForecastsScreen(),
          '/user/complaints': (context) => const ComplaintsScreen(),
          '/user/complaint-detail': (context) => const ComplaintDetailScreen(),
          '/admin/dashboard': (context) => const DashboardScreen(),
          '/admin/menu': (context) => const AdminMenuListScreen(),
          '/admin/menu/edit': (context) => const EditMenuItemScreen(),
          '/admin/add-stock': (context) => const AddStockScreen(),
          '/admin/edit-stock': (context) => const EditStockScreen(),
          '/admin/history': (context) => const HistoryScreen(),
          '/admin/shortage-reports': (context) => const ShortageReportsScreen(),
          '/admin/users': (context) => const UserManagementScreen(),
          '/admin/add-employee': (context) => const AddEmployeeScreen(),
          '/admin/order-forecasts': (context) => const OrderForecastsScreen(),
          '/admin/complaints': (context) => const AdminComplaintsScreen(),
          '/admin/reports': (context) => const ReportsScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

/// Splash screen that handles auth initialization
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _navigated = false;
  AuthProvider? _authProvider;

  void _handleAuthChange() {
    if (!mounted || _navigated) return;
    final authProvider = _authProvider ?? context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) return;

    final user = authProvider.currentUser;
    if (user == null) return;

    _navigated = true;
    final target = RouteHelper.getRouteForUser(user);
    Navigator.pushReplacementNamed(context, target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider ??= context.read<AuthProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = _authProvider ?? context.read<AuthProvider>();
      _authProvider ??= authProvider;

      authProvider.addListener(_handleAuthChange);

      if (authProvider.isAuthenticated && !_navigated) {
        _handleAuthChange();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading…', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      _navigated = false;
      return const LoginScreen();
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_handleAuthChange);
    super.dispose();
  }
}
