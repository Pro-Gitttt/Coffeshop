class AppException implements Exception {
  final String code;
  final String message;

  const AppException(this.code, this.message);

  @override
  String toString() => message;

  static AppException fromFirebaseAuth(String code) {
    switch (code) {
      case 'invalid-email':
        return const AppException('invalid-email', 'Invalid email.');
      case 'user-disabled':
        return const AppException('user-disabled', 'This account is disabled.');
      case 'user-not-found':
        return const AppException('user-not-found', 'No user found with this email.');
      case 'wrong-password':
        return const AppException('wrong-password', 'Incorrect password.');
      case 'email-already-in-use':
        return const AppException('email-already-in-use', 'This email is already in use.');
      case 'weak-password':
        return const AppException('weak-password', 'Password is too weak.');
      case 'too-many-requests':
        return const AppException('too-many-requests', 'Too many attempts. Please try again later.');
      case 'operation-not-allowed':
        return const AppException('operation-not-allowed', 'Operation not allowed.');
      default:
        return AppException(code, 'Authentication error ($code).');
    }
  }
}


