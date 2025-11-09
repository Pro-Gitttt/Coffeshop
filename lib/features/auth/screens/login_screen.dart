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
            debugPrint(
                '  - DisplayName: ${authProvider.currentUser?.displayName}');
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
            debugPrint('[LoginScreen] ✅ LOGIN PROCESS COMPLETED SUCCESSFULLY');
          } catch (e, stackTrace) {
            debugPrint('[LoginScreen] ❌ ERROR in loadUserData: $e');
            debugPrint('[LoginScreen] Stack trace: $stackTrace');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading user data: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
            // Still navigate even if loadUserData fails
            debugPrint('[LoginScreen] Attempting fallback navigation...');
            final authProvider = context.read<AuthProvider>();
            final target =
                RouteHelper.getRouteForUser(authProvider.currentUser);
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Responsive.responsiveContainer(
          context,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.responsiveSpacing(context,
                  mobile: 24, tablet: 32, desktop: 48),
              vertical: Responsive.responsiveSpacing(context,
                  mobile: 32, tablet: 48, desktop: 64),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Section
                  _buildWelcomeSection(context, theme, isDark),

                  SizedBox(
                      height: Responsive.responsiveSpacing(context,
                          mobile: 48, tablet: 56, desktop: 64)),

                  // Login Form
                  _buildLoginForm(context, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Animated Coffee Icon Container
        Container(
          width: Responsive.responsiveIconSize(context,
              mobile: 100, tablet: 120, desktop: 140),
          height: Responsive.responsiveIconSize(context,
              mobile: 100, tablet: 120, desktop: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(Icons.local_cafe,
              size: Responsive.responsiveIconSize(context,
                  mobile: 50, tablet: 60, desktop: 70),
              color: theme.colorScheme.onPrimary),
        ),

        SizedBox(
            height: Responsive.responsiveSpacing(context,
                mobile: 32, tablet: 40, desktop: 48)),

        // Title Section
        Column(
          children: [
            Text('Coffee Shop',
                style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.responsiveFontSize(context,
                        mobile: 28, tablet: 32, desktop: 36)),
                textAlign: TextAlign.center),
            SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),
            Text('Sign in to your account',
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: Responsive.responsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20)),
                textAlign: TextAlign.center),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(
        Responsive.responsiveSpacing(context,
            mobile: 24, tablet: 32, desktop: 40),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          _buildTextField(
            context: context,
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Invalid email address';
              }
              return null;
            },
          ),

          SizedBox(
              height: Responsive.responsiveSpacing(context,
                  mobile: 20, tablet: 24)),

          // Password field
          _buildTextField(
            context: context,
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
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

          SizedBox(height: Responsive.responsiveSpacing(context, mobile: 8)),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Forgot Password?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.responsiveFontSize(context,
                          mobile: 14, tablet: 15))),
            ),
          ),

          SizedBox(
              height: Responsive.responsiveSpacing(context,
                  mobile: 32, tablet: 40)),

          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                vertical: Responsive.responsiveSpacing(context,
                    mobile: 18, tablet: 20, desktop: 22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sign In',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onPrimary,
                              fontSize: Responsive.responsiveFontSize(context,
                                  mobile: 16, tablet: 18))),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
          ),

          SizedBox(height: Responsive.responsiveSpacing(context, mobile: 24)),

          // Sign up section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Don\'t have an account?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: Responsive.responsiveFontSize(context,
                          mobile: 14, tablet: 15))),
              SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Create Account',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: Responsive.responsiveFontSize(context,
                            mobile: 14, tablet: 15))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical:
              Responsive.responsiveSpacing(context, mobile: 16, tablet: 18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }
}
