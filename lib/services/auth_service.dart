import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Only mobile GoogleSignIn needs clientId; web uses FirebaseAuth popup
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? null
        : 'YOUR_ANDROID_IOS_CLIENT_ID.apps.googleusercontent.com',
  );

  /// REGISTER USER
  Future<bool> registerUser(
    BuildContext context, {
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'client',
        'createdAt': DateTime.now(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = 'Registration error';
        if (e.code == 'email-already-in-use') message = 'Email already in use';
        if (e.code == 'weak-password') message = 'Password too weak';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return false;
    }
  }

  /// LOGIN USER
  Future<bool> loginUser(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      final role = doc['role'];

      if (context.mounted) {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }

      return true;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = 'Login failed';
        if (e.code == 'user-not-found') message = 'No user found';
        if (e.code == 'wrong-password') message = 'Incorrect password';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
      return false;
    }
  }

Future<void> logout(BuildContext context) async {
  await _auth.signOut();

  if (!kIsWeb) {
    await _googleSignIn.signOut();
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // ignore if user didn't login with FB
    }
  }

  if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
}

  /// GOOGLE SIGN-IN (Web & Mobile)
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // Web: Firebase popup login
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Mobile login flow
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return; // User cancelled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      await _saveUserToFirestore(userCredential.user!);
      if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Google Sign-In error: $e')));
      }
    }
  }

  Future<void> signInWithFacebook(BuildContext context) async {
  try {
    // Web: already initialized in main.dart
    final result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final accessToken = result.accessToken!;
      final credential = FacebookAuthProvider.credential(accessToken.tokenString);
      final userCredential = await _auth.signInWithCredential(credential);

      await _saveUserToFirestore(userCredential.user!);

      if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
    } else if (result.status == LoginStatus.cancelled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Facebook login cancelled')));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Facebook login failed: ${result.message}')));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Facebook login error: $e')));
    }
  }
}

  /// SAVE USER TO FIRESTORE
  Future<void> _saveUserToFirestore(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'role': 'client',
        'createdAt': DateTime.now(),
      });
    }
  }
}
