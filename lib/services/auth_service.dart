import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? null : 'YOUR_ANDROID_IOS_CLIENT_ID.apps.googleusercontent.com',
  );

  /// REGISTER USER WITH PHONE VERIFICATION
  Future<void> registerUserWithPhone(
    BuildContext context, {
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification (rare on Android)
          final userCredential = await _auth.signInWithCredential(credential);
          await _saveUserToFirestore(userCredential.user!, name: name, email: email, phone: phone);
          if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
        },
        verificationFailed: (FirebaseAuthException e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Phone verification failed: ${e.message}')),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _showOtpDialog(context, verificationId, name: name, email: email, password: password, phone: phone);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SMS: $e')),
        );
      }
    }
  }

  void _showOtpDialog(BuildContext context, String verificationId,
      {required String name, required String email, required String password, required String phone}) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "OTP",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.isEmpty) return;
              try {
                final credential = PhoneAuthProvider.credential(
                    verificationId: verificationId, smsCode: otp);

                // Crée un compte email/password et lie le téléphone
                final userCredential =
                    await _auth.createUserWithEmailAndPassword(email: email, password: password);

                await userCredential.user!.linkWithCredential(credential);

                await _saveUserToFirestore(userCredential.user!, name: name, email: email, phone: phone);

                if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('OTP verification failed: $e')),
                );
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return false;
    }
  }

  /// RESET PASSWORD
  Future<void> resetPassword(String email, BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = 'Error sending password reset email.';
        if (e.code == 'user-not-found') message = 'No user found with that email.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  /// LOGOUT USER
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
    }
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  /// GOOGLE SIGN-IN
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In error: $e')),
        );
      }
    }
  }

  /// FACEBOOK SIGN-IN
  Future<void> signInWithFacebook(BuildContext context) async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!;
        final credential = FacebookAuthProvider.credential(accessToken.tokenString);
        final userCredential = await _auth.signInWithCredential(credential);
        await _saveUserToFirestore(userCredential.user!);
        if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
      } else if (result.status == LoginStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Facebook login cancelled')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook login failed: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook login error: $e')),
        );
      }
    }
  }

  /// SAVE USER TO FIRESTORE
  Future<void> _saveUserToFirestore(User user, {String? name, String? email, String? phone}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'name': name ?? user.displayName ?? '',
        'email': email ?? user.email ?? '',
        'phone': phone ?? '',
        'photoURL': user.photoURL ?? '',
        'role': 'client',
        'createdAt': DateTime.now(),
      });
    }
  }
}
