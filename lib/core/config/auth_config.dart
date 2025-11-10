// Central place to configure role-based behavior in the app.
// In production, prefer to drive roles from Firestore only.

// Emails listed here will be treated as admins at sign-in, even if the
// Firestore document has no role yet. Useful for initial bootstrap.
const List<String> kAdminEmails = <String>[
  // Add your admin emails here
  'karimtorjmen67@gmail.com',
];

bool isAdminEmail(String? email) {
  if (email == null) return false;
  return kAdminEmails.contains(email.trim().toLowerCase());
}
