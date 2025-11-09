import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  UserModel? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isEmployee => _currentUser?.role == 'employee';
  bool get isCustomer => _currentUser?.role == 'customer';

  void _init() {
    // Start in loading state until we process the initial auth status
    _isLoading = true;
    notifyListeners();

    // If a user is already signed in (app relaunch), load immediately
    final existing = _authService.currentUser;
    if (existing != null) {
      // loadUserData manages _isLoading on its own
      // and will notify listeners when done
      // ignore: discarded_futures
      loadUserData();
    } else {
      _isLoading = false;
      notifyListeners();
    }

    // Continue to react to subsequent auth state changes
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await loadUserData();
      } else {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('[AuthProvider] loadUserData() called');
      debugPrint('  - UID: ${user.uid}');
      debugPrint('  - Email: ${user.email}');
      debugPrint('═══════════════════════════════════════════════════════');
      
      _isLoading = true;
      notifyListeners();

      try {
        debugPrint('[AuthProvider] Step 1: Getting user data from Firestore...');
        _currentUser = await _authService.getUserData(user.uid);
        
        // If user doc doesn't exist yet (e.g., first login), ensure it's created
        if (_currentUser == null) {
          debugPrint('[AuthProvider] ⚠️ User document not found, creating it...');
          _currentUser = await _authService.ensureCurrentUserDocument();
          // Fallback: attempt one more read in case of eventual consistency
          if (_currentUser == null) {
            debugPrint('[AuthProvider] Still no user document after ensure, retrying...');
            await Future.delayed(const Duration(milliseconds: 500));
            _currentUser = await _authService.getUserData(user.uid);
          }
        }
        
        if (_currentUser != null) {
          debugPrint('[AuthProvider] ✅ User data loaded successfully');
          debugPrint('  - UID: ${_currentUser!.uid}');
          debugPrint('  - Email: ${_currentUser!.email}');
          debugPrint('  - DisplayName: ${_currentUser!.displayName}');
          debugPrint('  - Role: ${_currentUser!.role}');
        } else {
          debugPrint('[AuthProvider] ⚠️ User data is still null after all attempts');
        }
      } catch (e, stackTrace) {
        // Log error to aid debugging without breaking UI
        debugPrint('[AuthProvider] ❌ ERROR in loadUserData');
        debugPrint('  - Error: $e');
        debugPrint('  - Stack trace: $stackTrace');
        // Try to create user document if it doesn't exist
        try {
          debugPrint('[AuthProvider] Attempting to create user document...');
          _currentUser = await _authService.ensureCurrentUserDocument();
          debugPrint('[AuthProvider] User document created: ${_currentUser?.email}');
        } catch (createError) {
          debugPrint('[AuthProvider] Failed to create user document: $createError');
          // Fallback: create basic user model from Firebase Auth user
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            photoUrl: user.photoURL,
            role: 'customer', // Default role
            createdAt: DateTime.now(),
          );
          debugPrint('[AuthProvider] Created fallback UserModel');
        }
      } finally {
        _isLoading = false;
        notifyListeners();
        debugPrint('[AuthProvider] loadUserData() completed');
        debugPrint('  - isLoading: $_isLoading');
        debugPrint('  - isAuthenticated: $isAuthenticated');
        debugPrint('  - currentUser: ${_currentUser?.email}');
        debugPrint('═══════════════════════════════════════════════════════');
      }
    } else {
      debugPrint('[AuthProvider] loadUserData() called but no current user');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}

