import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final String role; // "admin" | "customer" | "employee"
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawRole = (data['role'] as String?)?.toLowerCase().trim();
    String normalizedRole;
    if (rawRole == null || rawRole.isEmpty) {
      normalizedRole = 'customer';
    } else if (rawRole == 'client' || rawRole == 'user') {
      // Map legacy "user" and "client" to "customer"
      normalizedRole = 'customer';
    } else {
      normalizedRole = rawRole;
    }

    // Support migration from username to displayName
    final displayName = (data['displayName'] as String?)?.trim() ?? 
                       (data['username'] as String?)?.trim();

    return UserModel(
      uid: id,
      email: (data['email'] as String?) ?? '',
      displayName: displayName?.isNotEmpty == true ? displayName : null,
      phoneNumber: (data['phoneNumber'] as String?)?.trim(),
      photoUrl: (data['photoUrl'] as String?)?.trim(),
      role: normalizedRole,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (displayName != null && displayName!.isNotEmpty) {
      data['displayName'] = displayName;
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      data['photoUrl'] = photoUrl;
    }
    return data;
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

