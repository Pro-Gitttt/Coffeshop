import 'dart:js' as js;
import 'package:coffee_shop_app/services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

Future<void> signInWithFacebookWebSafe(BuildContext context) async {
  if (kIsWeb) {
    // Wait until the FB SDK is ready
    while (js.context['fbLoaded'] != true) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Call the normal signInWithFacebook method
  await AuthService().signInWithFacebook(context);
}
