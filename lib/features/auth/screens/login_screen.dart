import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:provider/provider.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/route_helper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email to reset password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await fb_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
          backgroundColor: Colors.green,
        ),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (!mounted) return;
      final code = e.code;
      String message = 'Unable to send email.';
      if (code == 'invalid-email') {
        message = 'Invalid email.';
      }
      if (code == 'user-not-found') {
        message = 'No user found with this email.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Unexpected error.'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final passwordLength = _passwordController.text.length;

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔐 LOGIN PROCESS STARTED');
      debugPrint('Email: $email');
      debugPrint('Password length: $passwordLength');
      debugPrint('═══════════════════════════════════════════════════════');

      setState(() => _isLoading = true);

      try {
        debugPrint('[LoginScreen] Step 1: Reading AuthRepository...');
        final repo = context.read<AuthRepository>();

        debugPrint('[LoginScreen] Step 2: Calling repo.signIn()...');
        final Result result =
            await repo.signIn(email, _passwordController.text);

        debugPrint('[LoginScreen] Step 3: SignIn result received');
        debugPrint('  - isSuccess: ${result.isSuccess}');
        debugPrint('  - code: ${result.code}');
        debugPrint('  - message: ${result.message}');

        if (!mounted) {
          debugPrint('[LoginScreen] Widget not mounted, aborting');
          return;
        }

        if (result.isSuccess) {
          debugPrint(
              '[LoginScreen] Step 4: Login successful, loading user data...');
          try {
            final authProvider = context.read<AuthProvider>();
            debugPrint(
                '[LoginScreen] Step 5: Calling authProvider.loadUserData()...');
            await authProvider.loadUserData();

            if (!mounted) {
              debugPrint('[LoginScreen] Widget not mounted after loadUserData');
              return;
            }

            final role = authProvider.currentUser?.role;
            final uid = authProvider.currentUser?.uid;
            debugPrint('[LoginScreen] Step 6: User data loaded');
            debugPrint('  - UID: $uid');
            debugPrint('  - Email: ${authProvider.currentUser?.email}');
            debugPrint('  - DisplayName: ${authProvider.currentUser?.displayName}');
            debugPrint('  - Role: $role');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful.'),
                backgroundColor: Colors.green,
              ),
            );

            final target = RouteHelper.getRouteForRole(role);
            debugPrint('[LoginScreen] Step 7: Navigating to: $target');
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
                context, target, (route) => false);
            debugPrint(
                '[LoginScreen] ✅ LOGIN PROCESS COMPLETED SUCCESSFULLY');
          } catch (e, stackTrace) {
            debugPrint('[LoginScreen] ❌ ERROR in loadUserData: $e');
            debugPrint('[LoginScreen] Stack trace: $stackTrace');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Error loading user data: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
            // Still navigate even if loadUserData fails
            debugPrint('[LoginScreen] Attempting fallback navigation...');
            final authProvider = context.read<AuthProvider>();
            final target = RouteHelper.getRouteForUser(authProvider.currentUser);
            debugPrint('[LoginScreen] Fallback navigation to: $target');
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
                context, target, (route) => false);
          }
        } else {
          debugPrint('[LoginScreen] ❌ LOGIN FAILED');
          debugPrint('  - Error code: ${result.code}');
          debugPrint('  - Error message: ${result.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Login error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e, stackTrace) {
        debugPrint('[LoginScreen] ❌ UNEXPECTED ERROR: $e');
        debugPrint('[LoginScreen] Stack trace: $stackTrace');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
          debugPrint('[LoginScreen] Loading state set to false');
        }
        debugPrint('═══════════════════════════════════════════════════════');
      }
    } else {
      debugPrint('[LoginScreen] Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Responsive.responsiveContainer(
          context,
          child: SingleChildScrollView(
            padding: Responsive.responsivePadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Icon
                  Icon(Icons.local_cafe,
                      size: Responsive.responsiveIconSize(context, mobile: 80, tablet: 100, desktop: 120),
                      color: theme.colorScheme.primary),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24, tablet: 32, desktop: 40)),

                  // Title
                  Text('CoffeeStock',
                      style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontSize: Responsive.responsiveFontSize(context, mobile: 32, tablet: 36, desktop: 40)),
                      textAlign: TextAlign.center),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
                  Text('Stock Management',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: Responsive.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18)),
                      textAlign: TextAlign.center),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 48, tablet: 56, desktop: 64)),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16)),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 32, tablet: 40)),

                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.responsiveSpacing(context, mobile: 16, tablet: 18, desktop: 20),
                        )),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Sign In',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimary,
                                fontSize: Responsive.responsiveFontSize(context, mobile: 16, tablet: 18))),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 16)),

                  // Sign up link
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: Text('Create Account',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.responsiveFontSize(context, mobile: 14, tablet: 16))),
                  ),
                  SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
                  // Forgot password
                  TextButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    child: Text('Forgot Password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: Responsive.responsiveFontSize(context, mobile: 14, tablet: 16))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
