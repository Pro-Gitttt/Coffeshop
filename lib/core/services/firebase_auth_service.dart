import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/auth_config.dart';
import '../errors/app_exception.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[FirebaseAuthService] signInWithEmailAndPassword() called');
    debugPrint('  Email: $email');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      debugPrint(
          '[FirebaseAuthService] Step 1: Calling Firebase Auth signInWithEmailAndPassword...');
      UserCredential? credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('[FirebaseAuthService] ✅ Firebase Auth signIn successful');
      } catch (e) {
        // Handle Pigeon decode error specifically - this is a known issue on Android emulators
        // where Firebase Auth succeeds but the response decode fails
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('type cast') ||
            e.toString().contains('is not a subtype')) {
          debugPrint(
              '[FirebaseAuthService] ⚠️ Pigeon decode error detected, checking session...');
          // Check if auth actually succeeded despite the decode error
          await Future.delayed(const Duration(milliseconds: 100));
          final sessionUser = _auth.currentUser;
          if (sessionUser != null) {
            debugPrint(
                '[FirebaseAuthService] ✅ Session exists despite decode error, proceeding...');
            // Continue with session user instead of credential
            final user = sessionUser;
            try {
              final userModel = await _ensureUserDoc(
                user,
                displayName: user.displayName,
                phoneNumber: user.phoneNumber,
                photoUrl: user.photoURL,
              );
              return userModel;
            } catch (inner) {
              debugPrint(
                  '[FirebaseAuthService] ⚠️ ensureUserDoc failed: $inner');
              final email = user.email ?? '';
              final role = isAdminEmail(email) ? 'admin' : 'client';
              return UserModel(
                uid: user.uid,
                email: email,
                displayName: user.displayName,
                phoneNumber: user.phoneNumber,
                photoUrl: user.photoURL,
                role: role,
                createdAt: DateTime.now(),
              );
            }
          }
        }
        // Re-throw if it's not a Pigeon decode error or if no session exists
        rethrow;
      }

      final user = credential.user ?? _auth.currentUser;
      if (user != null) {
        debugPrint(
            '[FirebaseAuthService] Step 2: User obtained from Firebase Auth');
        debugPrint('  - UID: ${user.uid}');
        debugPrint('  - Email: ${user.email}');
        debugPrint('  - Email verified: ${user.emailVerified}');

        // Ensure user document exists and is up to date with role overrides
        try {
          debugPrint(
              '[FirebaseAuthService] Step 3: Ensuring user document exists in Firestore...');
          final userModel = await _ensureUserDoc(
            user,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
          );
          debugPrint('[FirebaseAuthService] ✅ User document ensured');
          debugPrint('  - Role: ${userModel.role}');
          debugPrint('  - DisplayName: ${userModel.displayName}');
          debugPrint('═══════════════════════════════════════════════════════');
          return userModel;
        } on AppException catch (e) {
          debugPrint('[FirebaseAuthService] ⚠️ AppException in _ensureUserDoc');
          debugPrint('  - Code: ${e.code}');
          debugPrint('  - Message: ${e.message}');
          debugPrint('[FirebaseAuthService] Creating fallback UserModel...');
          // Fallback: if Firestore/AppCheck is temporarily unavailable, still allow login
          final email = user.email ?? '';
          final role = isAdminEmail(email) ? 'admin' : 'client';
          final fallbackModel = UserModel(
            uid: user.uid,
            email: email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
            role: role,
            createdAt: DateTime.now(),
          );
          debugPrint('[FirebaseAuthService] ✅ Returning fallback UserModel');
          debugPrint('  - Role: ${fallbackModel.role}');
          debugPrint('═══════════════════════════════════════════════════════');
          return fallbackModel;
        } catch (e, stackTrace) {
          debugPrint(
              '[FirebaseAuthService] ❌ Unexpected error in _ensureUserDoc');
          debugPrint('  - Error: $e');
          debugPrint('  - Stack trace: $stackTrace');
          debugPrint('[FirebaseAuthService] Creating fallback UserModel...');
          final email = user.email ?? '';
          final role = isAdminEmail(email) ? 'admin' : 'client';
          final fallbackModel = UserModel(
            uid: user.uid,
            email: email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
            role: role,
            createdAt: DateTime.now(),
          );
          debugPrint('[FirebaseAuthService] ✅ Returning fallback UserModel');
          debugPrint('═══════════════════════════════════════════════════════');
          return fallbackModel;
        }
      }

      debugPrint('[FirebaseAuthService] ❌ No user returned from Firebase Auth');
      debugPrint('═══════════════════════════════════════════════════════');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] ❌ FirebaseAuthException');
      debugPrint('  - Code: ${e.code}');
      debugPrint('  - Message: ${e.message}');
      debugPrint('═══════════════════════════════════════════════════════');
      throw AppException.fromFirebaseAuth(e.code);
    } catch (e, stackTrace) {
      debugPrint('[FirebaseAuthService] ❌ Unexpected exception');
      debugPrint('  - Error: $e');
      debugPrint('  - Stack trace: $stackTrace');

      // Workaround: Some environments hit a Pigeon decode mismatch during signIn,
      // but Firebase Auth actually completes and establishes a session.
      // If a currentUser exists, treat this as success and continue.
      try {
        final sessionUser = _auth.currentUser;
        if (sessionUser != null) {
          debugPrint(
              '[FirebaseAuthService] ⚠️ Decode error suspected but session exists. Proceeding with ensure user doc.');
          try {
            final ensured = await _ensureUserDoc(
              sessionUser,
              displayName: sessionUser.displayName,
              phoneNumber: sessionUser.phoneNumber,
              photoUrl: sessionUser.photoURL,
            );
            debugPrint(
                '[FirebaseAuthService] ✅ Session-based recovery succeeded');
            debugPrint(
                '═══════════════════════════════════════════════════════');
            return ensured;
          } catch (inner) {
            debugPrint(
                '[FirebaseAuthService] ⚠️ ensureUserDoc failed during recovery: $inner');
            // Fallback to lightweight model from session
            final email = sessionUser.email ?? '';
            final role = isAdminEmail(email) ? 'admin' : 'client';
            final fallbackModel = UserModel(
              uid: sessionUser.uid,
              email: email,
              displayName: sessionUser.displayName,
              phoneNumber: sessionUser.phoneNumber,
              photoUrl: sessionUser.photoURL,
              role: role,
              createdAt: DateTime.now(),
            );
            debugPrint(
                '[FirebaseAuthService] ✅ Returning session fallback UserModel');
            debugPrint(
                '═══════════════════════════════════════════════════════');
            return fallbackModel;
          }
        }
      } catch (_) {
        // Ignore recovery errors and fall through to standard error
      }
      debugPrint('═══════════════════════════════════════════════════════');
      throw const AppException('unknown', 'Connection error');
    }
  }

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Create or update user doc and apply role override if listed
        try {
          return await _ensureUserDoc(
            user,
            preferredEmail: email,
            displayName: displayName ?? user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
          );
        } catch (e) {
          // If Firestore fails but user was created, still return success
          // The user can update their profile later
          debugPrint(
              'Warning: Firestore document creation failed but user created: $e');
          final role = isAdminEmail(email) ? 'admin' : 'client';
          // Return successful UserModel even if Firestore write failed
          final fallbackModel = UserModel(
            uid: user.uid,
            email: email,
            displayName: displayName ?? user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
            role: role,
            createdAt: DateTime.now(),
          );
          debugPrint(
              'Returning fallback UserModel: ${fallbackModel.uid}, displayName: ${fallbackModel.displayName}');
          return fallbackModel;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // If the email is already in use, fallback to sign-in automatically
      if (e.code == 'email-already-in-use') {
        try {
          return await signInWithEmailAndPassword(email, password);
        } on AppException {
          // Re-throw inner auth error (e.g., wrong password) with clear message
          rethrow;
        }
      }
      throw AppException.fromFirebaseAuth(e.code);
    } catch (e) {
      // Only throw error if user was NOT created
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // User was created, return success even if something else failed
        debugPrint('User exists in Firebase Auth despite error: $e');
        final role = isAdminEmail(email) ? 'admin' : 'client';
        return UserModel(
          uid: currentUser.uid,
          email: currentUser.email ?? email,
          displayName: currentUser.displayName,
          phoneNumber: currentUser.phoneNumber,
          photoUrl: currentUser.photoURL,
          role: role,
          createdAt: DateTime.now(),
        );
      }
      debugPrint('SignUp error: $e');
      throw const AppException('unknown', 'Sign up error');
    }
  }

  // Helper method to retry Firestore operations with exponential backoff
  Future<T> _retryFirestoreOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } on FirebaseException catch (e) {
        attempt++;
        // Retry on transient errors
        if ((e.code == 'unavailable' ||
                e.code == 'deadline-exceeded' ||
                e.code == 'internal' ||
                e.code == 'resource-exhausted') &&
            attempt < maxRetries) {
          debugPrint(
              '[FirebaseAuthService] Firestore error (attempt $attempt/$maxRetries): ${e.code}, retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
          delay = Duration(
              milliseconds: delay.inMilliseconds * 2); // Exponential backoff
          continue;
        }
        // Non-retryable error or max retries reached
        rethrow;
      } catch (e) {
        // Non-Firebase exceptions - don't retry
        rethrow;
      }
    }

    throw const AppException('firestore', 'Operation failed after retries');
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _retryFirestoreOperation(
        () => _firestore.collection('users').doc(uid).get(),
      );
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('Retrieved user data from Firestore: ${data.keys}');
        return UserModel.fromFirestore(data, doc.id);
      }
      debugPrint('User document does not exist for uid: $uid');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firestore error getting user data: ${e.code} - ${e.message}');
      throw AppException(
          'firestore', 'Error retrieving data: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('Unexpected error getting user data: $e');
      throw const AppException('firestore', 'Error retrieving data');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Note: updateDisplayName is already implemented below

  // Update email in Firebase Auth and Firestore
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('auth-required', 'You must be logged in.');
    }
    try {
      // Newer firebase_auth versions may change the User API surface
      // across platforms. Call via `dynamic` to avoid static API
      // mismatches at compile time while still attempting the update
      // at runtime. If the method is unavailable at runtime this will
      // throw and be transformed into an AppException below.
      await (user as dynamic).updateEmail(newEmail);
      // Attempt to reload the user to refresh local state
      try {
        await (user as dynamic).reload();
      } catch (_) {
        // Ignore reload failures; update itself is the priority
      }
      await _firestore.collection('users').doc(user.uid).set(
        {'email': newEmail},
        SetOptions(merge: true),
      );
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e.code);
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating email: ${e.message ?? e.code}');
    }
  }

  // Update password
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('auth-required', 'You must be logged in.');
    }
    try {
      // Re-authenticate user before password change
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      // Use dynamic calls to work with different firebase_auth versions
      await (user as dynamic).reauthenticateWithCredential(credential);

      // Update password (dynamic to avoid static API mismatches)
      await (user as dynamic).updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AppException.fromFirebaseAuth(e.code);
    }
  }

  // Update displayName in Firestore
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('auth-required', 'You must be logged in.');
    }
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'displayName': displayName},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating display name: ${e.message ?? e.code}');
    }
  }

  // Update phoneNumber in Firestore
  Future<void> updatePhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('auth-required', 'You must be logged in.');
    }
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'phoneNumber': phoneNumber},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw AppException(
          'firestore', 'Error updating phone number: ${e.message ?? e.code}');
    }
  }

  // Ensure the Firestore user document exists. If not, create it with
  // default role and apply role override for configured admin emails.
  Future<UserModel> _ensureUserDoc(
    User user, {
    String? preferredEmail,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('[FirebaseAuthService] _ensureUserDoc() called');
    debugPrint('  - UID: ${user.uid}');
    debugPrint('  - Preferred email: $preferredEmail');
    debugPrint('  - DisplayName: $displayName');
    debugPrint('═══════════════════════════════════════════════════════');

    final uid = user.uid;
    final email = preferredEmail ?? user.email ?? '';
    final resolvedDisplayName = (displayName?.trim().isNotEmpty == true)
        ? displayName!.trim()
        : (user.displayName ?? '').trim();
    final resolvedPhoneNumber = (phoneNumber?.trim().isNotEmpty == true)
        ? phoneNumber!.trim()
        : (user.phoneNumber ?? '').trim();
    final resolvedPhotoUrl = (photoUrl?.trim().isNotEmpty == true)
        ? photoUrl!.trim()
        : (user.photoURL ?? '').trim();

    final ref = _firestore.collection('users').doc(uid);
    debugPrint(
        '[FirebaseAuthService] Step 1: Checking if user document exists...');
    final snapshot = await _retryFirestoreOperation(
      () => ref.get(),
      maxRetries: 3,
    );
    debugPrint('[FirebaseAuthService] Document exists: ${snapshot.exists}');

    if (snapshot.exists) {
      debugPrint(
          '[FirebaseAuthService] Step 2: User document exists, parsing...');
      final existing = UserModel.fromFirestore(snapshot.data()!, uid);
      debugPrint('[FirebaseAuthService] Existing user data:');
      debugPrint('  - Email: ${existing.email}');
      debugPrint('  - DisplayName: ${existing.displayName}');
      debugPrint('  - Role: ${existing.role}');

      // Preserve existing role - don't change it on login
      final desiredRole = existing.role;
      final desiredDisplayName = resolvedDisplayName.isNotEmpty
          ? resolvedDisplayName
          : existing.displayName;
      final desiredPhoneNumber = resolvedPhoneNumber.isNotEmpty
          ? resolvedPhoneNumber
          : existing.phoneNumber;
      final desiredPhotoUrl =
          resolvedPhotoUrl.isNotEmpty ? resolvedPhotoUrl : existing.photoUrl;
      debugPrint(
          '[FirebaseAuthService] Preserving existing role: $desiredRole');

      final needsUpdate = (existing.email != email && email.isNotEmpty) ||
          (desiredDisplayName != null &&
              desiredDisplayName.isNotEmpty &&
              existing.displayName != desiredDisplayName) ||
          (desiredPhoneNumber != null &&
              desiredPhoneNumber.isNotEmpty &&
              existing.phoneNumber != desiredPhoneNumber) ||
          (desiredPhotoUrl != null &&
              desiredPhotoUrl.isNotEmpty &&
              existing.photoUrl != desiredPhotoUrl);

      debugPrint('[FirebaseAuthService] Needs update: $needsUpdate');

      if (needsUpdate) {
        debugPrint('[FirebaseAuthService] Step 3: Updating user document...');
        final updated = UserModel(
          uid: uid,
          email: email.isNotEmpty ? email : existing.email,
          displayName: desiredDisplayName ?? existing.displayName,
          phoneNumber: desiredPhoneNumber ?? existing.phoneNumber,
          photoUrl: desiredPhotoUrl ?? existing.photoUrl,
          role: desiredRole,
          createdAt: existing.createdAt,
        );
        try {
          final updateData = <String, dynamic>{};
          // Don't update role - preserve existing role
          if (email.isNotEmpty && existing.email != email) {
            updateData['email'] = email;
            debugPrint(
                '[FirebaseAuthService] Updating email: ${existing.email} -> $email');
          }
          if (desiredDisplayName != null &&
              desiredDisplayName.isNotEmpty &&
              existing.displayName != desiredDisplayName) {
            updateData['displayName'] = desiredDisplayName;
            debugPrint(
                '[FirebaseAuthService] Updating displayName: ${existing.displayName} -> $desiredDisplayName');
          }
          if (desiredPhoneNumber != null &&
              desiredPhoneNumber.isNotEmpty &&
              existing.phoneNumber != desiredPhoneNumber) {
            updateData['phoneNumber'] = desiredPhoneNumber;
            debugPrint('[FirebaseAuthService] Updating phoneNumber');
          }
          if (desiredPhotoUrl != null &&
              desiredPhotoUrl.isNotEmpty &&
              existing.photoUrl != desiredPhotoUrl) {
            updateData['photoUrl'] = desiredPhotoUrl;
            debugPrint('[FirebaseAuthService] Updating photoUrl');
          }
          debugPrint('[FirebaseAuthService] Update data: $updateData');
          await _retryFirestoreOperation(
            () => ref.set(updateData, SetOptions(merge: true)),
            maxRetries: 3,
          );
          debugPrint('[FirebaseAuthService] ✅ User document updated');
        } on FirebaseException catch (e) {
          debugPrint('[FirebaseAuthService] ❌ FirebaseException during update');
          debugPrint('  - Code: ${e.code}');
          debugPrint('  - Message: ${e.message}');
          throw AppException(
              'firestore', 'Update failed: ${e.message ?? e.code}');
        }
        debugPrint('═══════════════════════════════════════════════════════');
        return updated;
      }
      debugPrint(
          '[FirebaseAuthService] ✅ No update needed, returning existing user');
      debugPrint('═══════════════════════════════════════════════════════');
      return existing;
    }

    debugPrint(
        '[FirebaseAuthService] Step 2: User document does not exist, creating new one...');
    // For new users, assign role based on admin email list
    // For existing users logging in, this should not happen as document should exist
    final role = isAdminEmail(email) ? 'admin' : 'client';
    debugPrint('[FirebaseAuthService] New user role: $role');

    try {
      debugPrint(
          '[FirebaseAuthService] Creating user document for uid: $uid, email: $email, displayName: $displayName');

      // Double-check document doesn't exist (race condition protection)
      final doubleCheck = await _retryFirestoreOperation(
        () => ref.get(),
        maxRetries: 2,
      );
      if (doubleCheck.exists) {
        // Document exists! This shouldn't happen, but if it does, use existing data
        debugPrint(
            '[FirebaseAuthService] ⚠️ WARNING: Document exists after initial check, using existing data');
        final existing = UserModel.fromFirestore(doubleCheck.data()!, uid);
        debugPrint('[FirebaseAuthService] Existing role: ${existing.role}');
        return existing;
      }

      // Create with server timestamp to ensure canonical creation time
      final Map<String, dynamic> data = {
        'uid': uid,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (email.isNotEmpty) {
        data['email'] = email;
      }
      if (resolvedDisplayName.isNotEmpty) {
        data['displayName'] = resolvedDisplayName;
        debugPrint(
            '[FirebaseAuthService] Adding displayName to Firestore data: $resolvedDisplayName');
      }
      if (resolvedPhoneNumber.isNotEmpty) {
        data['phoneNumber'] = resolvedPhoneNumber;
        debugPrint(
            '[FirebaseAuthService] Adding phoneNumber to Firestore data');
      }
      if (resolvedPhotoUrl.isNotEmpty) {
        data['photoUrl'] = resolvedPhotoUrl;
        debugPrint('[FirebaseAuthService] Adding photoUrl to Firestore data');
      }

      debugPrint(
          '[FirebaseAuthService] Writing user document with data: $data');

      // For new documents, use set() without merge to ensure all fields are written
      // This is safe because we've confirmed the document doesn't exist
      await _retryFirestoreOperation(
        () => ref.set(data),
        maxRetries: 3,
      );
      debugPrint(
          '[FirebaseAuthService] ✅ User document written to Firestore successfully');

      // Wait a bit for eventual consistency, then verify
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify write succeeded by reading back (with retry for eventual consistency)
      int retries = 3;
      while (retries > 0) {
        try {
          debugPrint(
              '[FirebaseAuthService] Step 3: Verifying document write (retry ${4 - retries}/3)...');
          final verify = await _retryFirestoreOperation(
            () => ref.get(),
            maxRetries: 2,
          );
          if (verify.exists) {
            final verifiedData = verify.data()!;
            debugPrint('[FirebaseAuthService] ✅ Document verified');
            debugPrint(
                '[FirebaseAuthService] Verified document data: $verifiedData');

            // Verify role wasn't changed (shouldn't happen for new documents, but safety check)
            if (verifiedData.containsKey('role') &&
                verifiedData['role'] != role) {
              debugPrint(
                  '[FirebaseAuthService] ⚠️ WARNING: Role mismatch! Expected: $role, Found: ${verifiedData['role']}');
              // This shouldn't happen for new documents, but if it does, use what's in Firestore
              // Don't update it - just use the existing role
            }

            if (resolvedDisplayName.isNotEmpty &&
                verifiedData['displayName'] != resolvedDisplayName) {
              debugPrint(
                  '[FirebaseAuthService] ⚠️ displayName mismatch detected, updating...');
              await _retryFirestoreOperation(
                () => ref.update({'displayName': resolvedDisplayName}),
                maxRetries: 2,
              );
              verifiedData['displayName'] = resolvedDisplayName;
              debugPrint('[FirebaseAuthService] ✅ displayName updated');
            }
            if (resolvedPhoneNumber.isNotEmpty &&
                verifiedData['phoneNumber'] != resolvedPhoneNumber) {
              debugPrint(
                  '[FirebaseAuthService] ⚠️ phoneNumber mismatch detected, updating...');
              await _retryFirestoreOperation(
                () => ref.update({'phoneNumber': resolvedPhoneNumber}),
                maxRetries: 2,
              );
              verifiedData['phoneNumber'] = resolvedPhoneNumber;
              debugPrint('[FirebaseAuthService] ✅ phoneNumber updated');
            }
            if (resolvedPhotoUrl.isNotEmpty &&
                verifiedData['photoUrl'] != resolvedPhotoUrl) {
              debugPrint(
                  '[FirebaseAuthService] ⚠️ photoUrl mismatch detected, updating...');
              await _retryFirestoreOperation(
                () => ref.update({'photoUrl': resolvedPhotoUrl}),
                maxRetries: 2,
              );
              verifiedData['photoUrl'] = resolvedPhotoUrl;
              debugPrint('[FirebaseAuthService] ✅ photoUrl updated');
            }

            final userModel = UserModel.fromFirestore(verifiedData, uid);
            debugPrint('[FirebaseAuthService] Created UserModel:');
            debugPrint('  - UID: ${userModel.uid}');
            debugPrint('  - Email: ${userModel.email}');
            debugPrint('  - DisplayName: ${userModel.displayName}');
            debugPrint('  - Role: ${userModel.role}');
            debugPrint(
                '═══════════════════════════════════════════════════════');
            return userModel;
          }
          debugPrint(
              '[FirebaseAuthService] ⚠️ Document not found on retry ${4 - retries}');
          retries--;
          if (retries > 0) {
            await Future.delayed(Duration(milliseconds: 200 * (4 - retries)));
          }
        } on FirebaseException catch (e) {
          debugPrint(
              '[FirebaseAuthService] ❌ Firestore read error on retry ${4 - retries}');
          debugPrint('  - Code: ${e.code}');
          debugPrint('  - Message: ${e.message}');
          if (retries == 1) {
            // If read fails but write succeeded, return model anyway
            debugPrint(
                '[FirebaseAuthService] ⚠️ Warning: Firestore read-back failed but write succeeded');
            final fallbackModel = UserModel(
              uid: uid,
              email: email,
              displayName:
                  resolvedDisplayName.isNotEmpty ? resolvedDisplayName : null,
              phoneNumber:
                  resolvedPhoneNumber.isNotEmpty ? resolvedPhoneNumber : null,
              photoUrl: resolvedPhotoUrl.isNotEmpty ? resolvedPhotoUrl : null,
              role: role,
              createdAt: DateTime.now(),
            );
            debugPrint(
                '[FirebaseAuthService] Returning fallback UserModel with displayName: ${fallbackModel.displayName}');
            debugPrint(
                '═══════════════════════════════════════════════════════');
            return fallbackModel;
          }
          retries--;
          await Future.delayed(Duration(milliseconds: 200 * (4 - retries)));
        }
      }

      // If all retries failed but write succeeded, return model anyway
      debugPrint(
          '[FirebaseAuthService] ⚠️ All retries failed, returning fallback model');
      final fallbackModel = UserModel(
        uid: uid,
        email: email,
        displayName:
            resolvedDisplayName.isNotEmpty ? resolvedDisplayName : null,
        phoneNumber:
            resolvedPhoneNumber.isNotEmpty ? resolvedPhoneNumber : null,
        photoUrl: resolvedPhotoUrl.isNotEmpty ? resolvedPhotoUrl : null,
        role: role,
        createdAt: DateTime.now(),
      );
      debugPrint(
          '[FirebaseAuthService] Returning fallback UserModel with displayName: ${fallbackModel.displayName}');
      debugPrint('═══════════════════════════════════════════════════════');
      return fallbackModel;
    } on FirebaseException catch (e) {
      debugPrint('[FirebaseAuthService] ❌ Firestore write error');
      debugPrint('  - Code: ${e.code}');
      debugPrint('  - Message: ${e.message}');
      debugPrint('═══════════════════════════════════════════════════════');
      // Re-throw so the caller can handle it
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('[FirebaseAuthService] ❌ Unexpected error in _ensureUserDoc');
      debugPrint('  - Error: $e');
      debugPrint('  - Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      // Re-throw so the caller can handle it
      rethrow;
    }
  }

  // Public helper to ensure the current user's document exists and return it
  Future<UserModel?> ensureCurrentUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('No current user in ensureCurrentUserDocument');
      return null;
    }
    try {
      debugPrint('Ensuring user document exists for uid: ${user.uid}');
      return await _ensureUserDoc(
        user,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoURL,
      );
    } catch (e, stackTrace) {
      debugPrint('Error ensuring user document: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Migration helper: Migrate username field to displayName for existing users
  // This can be called manually or during app initialization for existing users
  Future<void> migrateUsernameToDisplayName(String uid) async {
    try {
      final ref = _firestore.collection('users').doc(uid);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        // If username field exists but displayName doesn't, migrate it
        if (data.containsKey('username') && !data.containsKey('displayName')) {
          await ref.update({
            'displayName': data['username'],
          });
          debugPrint('Migrated username to displayName for user $uid');
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('Migration error: ${e.message ?? e.code}');
      // Don't throw - migration is non-critical
    }
  }
}
