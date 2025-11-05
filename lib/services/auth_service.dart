import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📝 Register user
  Future<void> registerUser(
    BuildContext context, {
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1️⃣ Create account in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2️⃣ Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now(),
        'role': 'client',
      });

      // 3️⃣ Send welcome email (using EmailJS API)
      await sendWelcomeEmail(name, email);

      // 4️⃣ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Registration successful! Check your email.')),
      );

      // 5️⃣ Redirect to Login
      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Registration error: $e')),
      );
    }
  }

  /// 💌 Send welcome email via EmailJS (client-side)
  Future<void> sendWelcomeEmail(String name, String email) async {
    const String serviceId = 'service_ab75res'; // replace with your EmailJS service ID
    const String templateId = 'template_lsx8fp4'; // replace with your EmailJS template ID
    const String publicKey = '3ICQUlxq0LapNCqZh'; // replace with your EmailJS public key

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_name': name,
          'to_email': email,
        },
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('⚠️ Failed to send email: ${response.body}');
    }
  }

  /// 🔓 Login user
  Future<void> loginUser(BuildContext context,
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Navigate based on role
      final userDoc =
          await _firestore.collection('users').where('email', isEqualTo: email).get();

      final role = userDoc.docs.first['role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') message = 'No user found with that email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 🚪 Logout
  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
