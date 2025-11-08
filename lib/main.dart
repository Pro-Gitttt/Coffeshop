import 'package:coffee_shop_app/screens/splash-screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Facebook SDK for web
  if (kIsWeb) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "1423685606028436", // replace with your Facebook App ID
      cookie: true,
      xfbml: true,
      version: "v17.0",
    );
  }

  runApp(const CoffeeShopApp());
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '☕ Coffee Shop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF8F5F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6F4E37),
          elevation: 4,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Poppins', color: Colors.black87),
        ),
      ),
      home: const SplashScreenWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/admin/menu': (context) => const AdminMenuScreen(),
      },
    );
  }
}

/// SplashScreenWrapper shows SplashScreen first, then navigates to AuthWrapper
class SplashScreenWrapper extends StatelessWidget {
  const SplashScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(
      nextScreen: AuthWrapper(), // pass the next screen after splash
    );
  }
}

/// AuthWrapper handles login / home / admin routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /// Replace this with your real role fetching logic
  Future<String?> _getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // TODO: Fetch role from Firestore, for now hardcode
    final uid = user.uid;
    // Example: fetch role from Firestore: 'users' collection
    // final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // return doc.data()?['role'];

    return 'client'; // hardcode for testing
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // No user logged in
        if (!snapshot.hasData) return const LoginScreen();

        // User logged in, fetch role
        return FutureBuilder<String?>(
          future: _getUserRole(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.brown),
                ),
              );
            }

            final role = roleSnapshot.data;

            if (role == 'admin') return const AdminScreen();
            if (role == 'client') return const HomeScreen();

            // If role unknown, log out to prevent stale session
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          },
        );
      },
    );
  }
}
