import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/utils/responsive.dart';

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    debugPrint(
        '[AddEmployeeScreen] ===========================================');
    debugPrint('[AddEmployeeScreen] _createEmployee() called');
    debugPrint(
        '[AddEmployeeScreen] ===========================================');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[AddEmployeeScreen] Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // Store admin credentials before creating employee
    final adminUser = auth.currentUser;
    if (adminUser == null) {
      debugPrint('[AddEmployeeScreen] ❌ No admin user found');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be signed in as admin'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final adminEmail = adminUser.email!;
    debugPrint('[AddEmployeeScreen] Admin email: $adminEmail');

    final adminPassword = await _getCurrentPassword(context);
    if (adminPassword == null) {
      debugPrint('[AddEmployeeScreen] ❌ Admin password not provided');
      setState(() => _isLoading = false);
      return;
    }
    debugPrint('[AddEmployeeScreen] ✅ Admin password verified');

    String? employeeUid;

    try {
      // Create the employee account
      // Note: createUserWithEmailAndPassword automatically signs in the new user
      debugPrint(
          '[AddEmployeeScreen] Creating employee account in Firebase Auth...');
      debugPrint(
          '[AddEmployeeScreen] Employee email: ${_emailController.text.trim()}');
      final employeeCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint(
          '[AddEmployeeScreen] ✅ Employee account created in Firebase Auth');

      final employeeUser = employeeCredential.user;
      if (employeeUser == null) {
        throw Exception('Failed to create employee account');
      }

      employeeUid = employeeUser.uid;
      debugPrint('[AddEmployeeScreen] Employee UID: $employeeUid');

      // Create Firestore document IMMEDIATELY while signed in as employee
      // Users can typically write their own documents, so this should work
      // We do this BEFORE signing out to avoid permission issues
      final employeeData = {
        'uid': employeeUid,
        'email': _emailController.text.trim(),
        'displayName': _nameController.text.trim(),
        'role': 'employee', // Explicitly set role to 'employee'
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint(
          '[AddEmployeeScreen] ===========================================');
      debugPrint(
          '[AddEmployeeScreen] Creating employee document in Firestore (as employee)');
      debugPrint('[AddEmployeeScreen] Employee UID: $employeeUid');
      debugPrint('[AddEmployeeScreen] Email: ${_emailController.text.trim()}');
      debugPrint(
          '[AddEmployeeScreen] DisplayName: ${_nameController.text.trim()}');
      debugPrint('[AddEmployeeScreen] Role: employee');
      debugPrint('[AddEmployeeScreen] Data to write: $employeeData');
      debugPrint(
          '[AddEmployeeScreen] ===========================================');

      try {
        // Write the document to Firestore while signed in as employee
        // This works because users can write their own documents
        debugPrint(
            '[AddEmployeeScreen] Attempting Firestore write as employee...');
        await firestore.collection('users').doc(employeeUid).set(
              employeeData,
              SetOptions(merge: false), // Overwrite any existing document
            );
        debugPrint(
            '[AddEmployeeScreen] ✅ Firestore write completed without exception');
      } on FirebaseException catch (firestoreError) {
        debugPrint(
            '[AddEmployeeScreen] ❌ FirebaseException during Firestore write');
        debugPrint('[AddEmployeeScreen] Error code: ${firestoreError.code}');
        debugPrint(
            '[AddEmployeeScreen] Error message: ${firestoreError.message}');
        // Don't throw yet - try to sign out and restore admin, then throw
        await auth.signOut();
        // Try to restore admin session
        try {
          await auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        } catch (_) {
          // Ignore restore errors
        }
        // Re-throw with detailed error
        throw Exception(
            'Failed to create employee document in Firestore. Error code: ${firestoreError.code}, Message: ${firestoreError.message}. Please check Firestore security rules.');
      } catch (firestoreError) {
        debugPrint(
            '[AddEmployeeScreen] ❌ Unexpected error during Firestore write: $firestoreError');
        debugPrint(
            '[AddEmployeeScreen] Error type: ${firestoreError.runtimeType}');
        // Don't throw yet - try to sign out and restore admin, then throw
        await auth.signOut();
        // Try to restore admin session
        try {
          await auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
        } catch (_) {
          // Ignore restore errors
        }
        // Re-throw to be caught by outer catch block
        throw Exception(
            'Failed to create employee document in Firestore: $firestoreError. Please check Firestore security rules.');
      }

      // Wait a moment for Firestore write to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Now sign out the employee account
      debugPrint('[AddEmployeeScreen] Signing out employee account...');
      await auth.signOut();

      // Restore admin session with Pigeon error handling
      debugPrint('[AddEmployeeScreen] Restoring admin session...');
      bool adminSessionRestored = false;
      try {
        await auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        debugPrint('[AddEmployeeScreen] ✅ Admin session restored successfully');
        adminSessionRestored = true;
      } catch (signInError) {
        // Handle Pigeon decode error - known issue on Android where sign-in
        // succeeds but the response decode fails
        final errorString = signInError.toString();
        if (errorString.contains('PigeonUserDetails') ||
            errorString.contains('type cast') ||
            errorString.contains('is not a subtype') ||
            errorString.contains('List<Object?>')) {
          debugPrint(
              '[AddEmployeeScreen] ⚠️ Pigeon decode error detected, checking if sign-in succeeded...');
          // Check if sign-in actually succeeded despite the decode error
          await Future.delayed(const Duration(milliseconds: 300));
          final currentUser = auth.currentUser;
          if (currentUser != null && currentUser.email == adminEmail) {
            debugPrint(
                '[AddEmployeeScreen] ✅ Admin session restored despite decode error');
            // Sign-in succeeded, suppress the error and continue
            adminSessionRestored = true;
          } else {
            debugPrint('[AddEmployeeScreen] ❌ Admin session not restored');
            // Only throw if session wasn't actually created
            throw Exception(
                'Failed to restore admin session. Please sign in again.');
          }
        } else {
          // Re-throw if it's not a Pigeon error
          debugPrint('[AddEmployeeScreen] ❌ Sign-in error: $signInError');
          rethrow;
        }
      }

      // Verify admin session is active
      if (!adminSessionRestored) {
        final verifyUser = auth.currentUser;
        if (verifyUser == null || verifyUser.email != adminEmail) {
          throw Exception(
              'Admin session could not be restored. Please sign in again.');
        }
      }

      // Wait a moment for eventual consistency
      await Future.delayed(const Duration(milliseconds: 300));

      // Verify the document was created successfully
      debugPrint('[AddEmployeeScreen] Verifying document creation...');
      bool documentExists = false;
      int verificationRetries = 3;

      while (verificationRetries > 0 && !documentExists) {
        try {
          final verifyDoc =
              await firestore.collection('users').doc(employeeUid).get();
          documentExists = verifyDoc.exists;

          if (documentExists) {
            final savedData = verifyDoc.data();
            final savedRole = savedData?['role'] as String?;
            debugPrint(
                '[AddEmployeeScreen] ✅ Document verified - exists: true');
            debugPrint('[AddEmployeeScreen] Saved role: $savedRole');

            if (savedRole != 'employee') {
              // If role wasn't set correctly, update it
              debugPrint(
                  '[AddEmployeeScreen] ⚠️ Role mismatch! Expected: employee, Got: $savedRole. Updating...');
              try {
                await firestore
                    .collection('users')
                    .doc(employeeUid)
                    .update({'role': 'employee'});
                debugPrint('[AddEmployeeScreen] ✅ Role updated to employee');
              } catch (updateError) {
                debugPrint(
                    '[AddEmployeeScreen] ❌ Failed to update role: $updateError');
                throw Exception('Failed to set employee role: $updateError');
              }
            } else {
              debugPrint('[AddEmployeeScreen] ✅ Role is correct: employee');
            }
          } else {
            verificationRetries--;
            if (verificationRetries > 0) {
              debugPrint(
                  '[AddEmployeeScreen] ⚠️ Document not found, retrying... ($verificationRetries attempts left)');
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } catch (verifyError) {
          debugPrint(
              '[AddEmployeeScreen] ❌ Error verifying document: $verifyError');
          verificationRetries--;
          if (verificationRetries > 0) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (!documentExists) {
        debugPrint(
            '[AddEmployeeScreen] ❌ CRITICAL: Document was not created in Firestore after all retries!');
        // Don't suppress this error - it's critical
        throw Exception(
            'Employee document was not created in Firestore. The employee account was created in Firebase Auth but the Firestore document is missing. Please check Firestore security rules. The employee UID is: $employeeUid');
      }

      debugPrint(
          '[AddEmployeeScreen] ✅ Employee document successfully created and verified');
      debugPrint(
          '[AddEmployeeScreen] ===========================================');
      debugPrint('[AddEmployeeScreen] ✅ SUCCESS: Employee creation completed');
      debugPrint('[AddEmployeeScreen] Employee UID: $employeeUid');
      debugPrint(
          '[AddEmployeeScreen] Employee Email: ${_emailController.text.trim()}');
      debugPrint('[AddEmployeeScreen] Employee Role: employee');
      debugPrint(
          '[AddEmployeeScreen] ===========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Ensure we're signed out as employee if account was created
      try {
        if (auth.currentUser?.email == _emailController.text.trim()) {
          await auth.signOut();
        }
      } catch (_) {
        // Ignore sign out errors
      }

      // Try to restore admin session if we're not already signed in
      try {
        if (auth.currentUser?.email != adminEmail) {
          debugPrint(
              '[AddEmployeeScreen] Attempting to restore admin session in error handler...');
          try {
            await auth.signInWithEmailAndPassword(
              email: adminEmail,
              password: adminPassword,
            );
            debugPrint(
                '[AddEmployeeScreen] ✅ Admin session restored in error handler');
          } catch (signInError) {
            // Handle Pigeon decode error
            if (signInError.toString().contains('PigeonUserDetails') ||
                signInError.toString().contains('type cast') ||
                signInError.toString().contains('is not a subtype')) {
              debugPrint(
                  '[AddEmployeeScreen] ⚠️ Pigeon decode error in error handler, checking session...');
              await Future.delayed(const Duration(milliseconds: 200));
              final currentUser = auth.currentUser;
              if (currentUser != null && currentUser.email == adminEmail) {
                debugPrint(
                    '[AddEmployeeScreen] ✅ Admin session restored despite decode error');
              } else {
                debugPrint(
                    '[AddEmployeeScreen] Failed to restore admin session');
              }
            } else {
              debugPrint(
                  '[AddEmployeeScreen] Failed to restore admin session: $signInError');
            }
          }
        }
      } catch (restoreError) {
        // If we can't restore admin session, user will need to sign in again
        debugPrint(
            '[AddEmployeeScreen] Failed to restore admin session: $restoreError');
      }

      if (mounted) {
        // Check if this is a Pigeon error that we've already handled
        final errorString = e.toString();
        final isPigeonError = errorString.contains('PigeonUserDetails') ||
            errorString.contains('type cast') ||
            errorString.contains('is not a subtype') ||
            errorString.contains('List<Object?>');

        // Check if the error is about Firestore - never suppress Firestore errors
        final isFirestoreError = errorString.contains('Firestore') ||
            errorString.contains('permission-denied') ||
            errorString.contains('permission denied') ||
            errorString.contains('not created in Firestore') ||
            errorString.contains('Document was not created');

        // If it's a Pigeon error (not Firestore), check if admin session was restored
        // AND verify Firestore document was created before suppressing
        if (isPigeonError && !isFirestoreError && employeeUid != null) {
          await Future.delayed(const Duration(milliseconds: 200));
          final currentUser = auth.currentUser;
          if (currentUser != null && currentUser.email == adminEmail) {
            // Pigeon error but session is restored - check if Firestore document exists
            debugPrint(
                '[AddEmployeeScreen] Pigeon error detected, verifying Firestore document...');
            try {
              final checkDoc =
                  await firestore.collection('users').doc(employeeUid).get();
              if (checkDoc.exists) {
                final savedRole = checkDoc.data()?['role'] as String?;
                debugPrint(
                    '[AddEmployeeScreen] ✅ Firestore document exists with role: $savedRole');
                // Firestore document exists, suppress the Pigeon error
                debugPrint(
                    '[AddEmployeeScreen] Suppressing Pigeon error - both session and Firestore document exist');
                // Show success message instead
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Employee account created successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
                return; // Don't show error to user
              } else {
                debugPrint(
                    '[AddEmployeeScreen] ⚠️ Firestore document missing - will show error');
                // Firestore document doesn't exist - don't suppress, show error
              }
            } catch (checkError) {
              debugPrint(
                  '[AddEmployeeScreen] Error checking Firestore: $checkError');
              // Error checking - don't suppress, show error to be safe
            }
          }
        }

        String errorMessage = 'Failed to create employee account';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'This email is already registered';
              break;
            case 'weak-password':
              errorMessage = 'Password is too weak';
              break;
            case 'invalid-email':
              errorMessage = 'Invalid email address';
              break;
            default:
              errorMessage = e.message ?? 'Authentication error';
          }
        } else if (isPigeonError && !isFirestoreError) {
          // For Pigeon errors (not Firestore), show a more user-friendly message
          errorMessage =
              'Account creation may have succeeded. Please check the user list.';
        } else {
          // Show the actual error message, especially for Firestore errors
          errorMessage = e.toString();
          // Extract a more readable message if it's too long
          if (errorMessage.length > 150) {
            errorMessage = errorMessage.substring(0, 150) + '...';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getCurrentPassword(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route =
        ModalRoute.of(context)?.settings.name ?? '/admin/add-employee';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: AppDrawer(currentRoute: route),
      appBar: CustomAppBar(
        title: 'Add Employee (Barista)',
        currentRoute: route,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Info card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Create a new employee account. The employee will be able to manage orders.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter employee name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter employee name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'employee@example.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimum 6 characters',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Create button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createEmployee,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Employee Account',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndSubmit() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user?.email == null) {
        throw Exception('No current user');
      }

      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }

      final email = user!.email!;

      debugPrint('[PasswordDialog] Verifying password for user: $email');
      debugPrint('[PasswordDialog] Password length: ${password.length}');

      // Use reauthenticateWithCredential to verify password without signing out
      // This is the proper way to verify a password for an already authenticated user
      try {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        debugPrint('[PasswordDialog] Password verification successful');

        // Password is correct - return it to be used in _createEmployee
        if (mounted) {
          Navigator.pop(context, password);
        }
      } catch (reAuthError) {
        // Handle Pigeon decode error - known issue on Android where reauthentication
        // succeeds but the response decode fails
        if (reAuthError.toString().contains('PigeonUserDetails') ||
            reAuthError.toString().contains('type cast') ||
            reAuthError.toString().contains('is not a subtype')) {
          debugPrint(
              '[PasswordDialog] ⚠️ Pigeon decode error detected, checking if reauth succeeded...');
          // Check if reauthentication actually succeeded despite the decode error
          await Future.delayed(const Duration(milliseconds: 100));
          final currentUser = auth.currentUser;
          // If user is still authenticated and it's the same user, reauth succeeded
          if (currentUser != null &&
              currentUser.uid == user.uid &&
              currentUser.email == email) {
            debugPrint(
                '[PasswordDialog] ✅ Reauthentication succeeded despite decode error');
            // Password is correct - return it to be used in _createEmployee
            if (mounted) {
              Navigator.pop(context, password);
              return;
            }
          }
          // If we get here, the reauth actually failed
          debugPrint(
              '[PasswordDialog] Reauthentication failed - user session invalid');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Password verification failed',
          );
        }

        debugPrint(
            '[PasswordDialog] Password verification failed: $reAuthError');
        if (reAuthError is FirebaseAuthException) {
          debugPrint(
              '[PasswordDialog] Error code: ${reAuthError.code}, message: ${reAuthError.message}');
          rethrow;
        }
        throw FirebaseAuthException(
          code: 'verification-failed',
          message: reAuthError.toString(),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Verification failed';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
            case 'invalid-credential':
            case 'invalid-password':
              errorMessage = 'Incorrect password. Please try again.';
              break;
            case 'user-mismatch':
              errorMessage = 'User mismatch. Please sign in again.';
              break;
            case 'user-not-found':
            case 'user-disabled':
              errorMessage =
                  'User not found or disabled. Please sign in again.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'network-request-failed':
              errorMessage = 'Network error. Please check your connection.';
              break;
            case 'verification-failed':
            case 'reauthentication-failed':
              errorMessage = 'Password verification failed. Please try again.';
              break;
            default:
              // Safely get message, handling potential type issues
              final message = e.message;
              if (message is String && message.isNotEmpty) {
                errorMessage = 'Authentication error: $message';
              } else {
                errorMessage = 'Authentication error: ${e.code}';
              }
          }
        } else {
          // Safely convert any exception to string
          try {
            errorMessage = 'Error: ${e.toString()}';
          } catch (_) {
            errorMessage = 'An unexpected error occurred. Please try again.';
          }
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Verify Admin Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter your admin password to create an employee account.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Admin Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              errorText: _errorMessage,
            ),
            obscureText: _obscurePassword,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _verifyAndSubmit(),
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyAndSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
