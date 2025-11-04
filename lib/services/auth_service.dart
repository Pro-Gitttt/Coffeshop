import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Register new user (always client)
  Future<void> registerUser(
    BuildContext context, {
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email.trim(),
        'name': name.trim(),
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Account created successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Register error: $e")),
      );
    }
  }

  // 🔹 Login logic (admin or client)
  Future<void> loginUser(BuildContext context, String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception("User not found");

      // ✅ Special case: hard-coded admin
      if (email.trim().toLowerCase() == "kaledgadh0@gmail.com") {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/admin');
        }
        return;
      }

      // ✅ Otherwise, use role from Firestore (optional)
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final role = snapshot.data()?['role'] ?? 'client';

      if (context.mounted) {
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login error: $e")),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
