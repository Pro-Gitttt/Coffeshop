import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../config/auth_config.dart';
import '../errors/app_exception.dart';
import '../utils/result.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  AuthRepository(this._authService);

  Future<Result<UserModel>> signIn(String email, String password) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[AuthRepository] signIn() called');
    debugPrint('  Email: $email');
    debugPrint('  Password length: ${password.length}');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      debugPrint(
          '[AuthRepository] Step 1: Calling _authService.signInWithEmailAndPassword()...');
      final user =
          await _authService.signInWithEmailAndPassword(email, password);

      if (user != null) {
        debugPrint('[AuthRepository] ✅ SignIn successful');
        debugPrint('  - UID: ${user.uid}');
        debugPrint('  - Email: ${user.email}');
        debugPrint('  - DisplayName: ${user.displayName}');
        debugPrint('  - Role: ${user.role}');
        debugPrint('═══════════════════════════════════════════════════════');
        return Result.ok(user);
      }

      debugPrint(
          '[AuthRepository] ⚠️ User is null, checking Firebase Auth session...');
      // Fallback: if service returned null but Firebase holds a session, treat as success
      final current = _authService.currentUser;
      if (current != null) {
        debugPrint('[AuthRepository] ✅ Firebase Auth session found');
        debugPrint('  - UID: ${current.uid}');
        debugPrint('  - Email: ${current.email}');

        try {
          debugPrint('[AuthRepository] Attempting to ensure user document...');
          final ensured = await _authService.ensureCurrentUserDocument();
          if (ensured != null) {
            debugPrint('[AuthRepository] ✅ User document ensured');
            debugPrint('  - Role: ${ensured.role}');
            debugPrint(
                '═══════════════════════════════════════════════════════');
            return Result.ok(ensured);
          }
        } catch (e) {
          debugPrint(
              '[AuthRepository] ⚠️ ensureCurrentUserDocument failed: $e');
          // ignore and continue to basic fallback
        }

        debugPrint('[AuthRepository] Creating fallback UserModel...');
        final fallbackModel = UserModel(
          uid: current.uid,
          email: current.email ?? '',
          displayName: current.displayName,
          phoneNumber: current.phoneNumber,
          photoUrl: current.photoURL,
          role: isAdminEmail(current.email) ? 'admin' : 'client',
          createdAt: DateTime.now(),
        );
        debugPrint('[AuthRepository] ✅ Returning fallback UserModel');
        debugPrint('  - Role: ${fallbackModel.role}');
        debugPrint('═══════════════════════════════════════════════════════');
        return Result.ok(fallbackModel);
      }

      debugPrint('[AuthRepository] ❌ No user found in Firebase Auth');
      debugPrint('═══════════════════════════════════════════════════════');
      return Result.fail(code: 'unknown', message: 'Unable to connect');
    } on AppException catch (e) {
      debugPrint('[AuthRepository] ❌ AppException caught');
      debugPrint('  - Code: ${e.code}');
      debugPrint('  - Message: ${e.message}');
      debugPrint('═══════════════════════════════════════════════════════');
      return Result.fail(code: e.code, message: e.message);
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] ❌ Unexpected exception');
      debugPrint('  - Error: $e');
      debugPrint('  - Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      return Result.fail(code: 'unknown', message: 'Login error');
    }
  }

  Future<Result<UserModel>> signUp(String email, String password,
      {String? displayName}) async {
    try {
      debugPrint('SignUp called with email: $email, displayName: $displayName');
      final user = await _authService.signUpWithEmailAndPassword(
          email, password,
          displayName: displayName);
      if (user != null) {
        debugPrint(
            'SignUp successful: ${user.uid}, email: ${user.email}, displayName: ${user.displayName}');
        return Result.ok(user);
      }
      debugPrint('SignUp failed: user is null');
      return Result.fail(
          code: 'unknown', message: 'Sign up failed: user not created');
    } on AppException catch (e) {
      debugPrint('SignUp AppException: ${e.code} - ${e.message}');

      // Check if user was actually created despite the exception
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        debugPrint(
            'User exists in Firebase Auth despite AppException, returning success');
        final role = isAdminEmail(currentUser.email) ? 'admin' : 'client';
        return Result.ok(UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? email,
          displayName: displayName ?? currentUser.displayName,
          phoneNumber: currentUser.phoneNumber,
          photoUrl: currentUser.photoURL,
          role: role,
          createdAt: DateTime.now(),
        ));
      }

      if (e.code == 'email-already-in-use') {
        // Email exists → try to sign in instead
        try {
          final existing =
              await _authService.signInWithEmailAndPassword(email, password);
          if (existing != null) return Result.ok(existing);
          return Result.fail(
            code: 'unknown',
            message: 'Unable to connect with this email.',
          );
        } on AppException catch (signInErr) {
          if (signInErr.code == 'wrong-password') {
            return Result.fail(
              code: 'wrong-password',
              message:
                  'Email already in use, but password is incorrect. Reset it from the login screen.',
            );
          }
          return Result.fail(code: signInErr.code, message: signInErr.message);
        } catch (_) {
          return Result.fail(code: 'unknown', message: 'Login error.');
        }
      }
      return Result.fail(code: e.code, message: e.message);
    } catch (e, stackTrace) {
      // This should rarely happen now since _ensureUserDoc failures are handled
      debugPrint('SignUp unexpected error: $e');
      debugPrint('StackTrace: $stackTrace');
      // Check if user was actually created in Firebase Auth
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // User was created but something else failed - still return success
        debugPrint(
            'User exists in Firebase Auth, returning success despite error');
        final role = isAdminEmail(currentUser.email) ? 'admin' : 'client';
        return Result.ok(UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? email,
          displayName: displayName ?? currentUser.displayName,
          phoneNumber: currentUser.phoneNumber,
          photoUrl: currentUser.photoURL,
          role: role,
          createdAt: DateTime.now(),
        ));
      }
      return Result.fail(code: 'unknown', message: 'Sign up error');
    }
  }
}
