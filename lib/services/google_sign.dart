import 'package:aiassistant1/screens/home_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ignore: non_constant_identifier_names
Future<void> Google_login_signup(BuildContext context) async {
  try {
    // 1. Initialize Google Sign-In
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: '', // Add if needed for web/Android
    );

    // 2. Trigger Google Sign-In flow
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in
      Navigator.pop(context);
      return;
    }

    // 3. Get authentication tokens
    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw PlatformException(
        code: 'MISSING_TOKENS',
        message: 'Failed to obtain authentication tokens from Google',
      );
    }

    // Auth disabled in demo – skip Firebase sign-in

    // 6. Navigate to home screen
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    // 8. Show welcome message (demo)
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome! (Demo build)'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  } on PlatformException catch (e) {
    Navigator.pop(context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message ?? 'Authentication failed'),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  } catch (e) {
    Navigator.pop(context);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign-in failed. Please try again.'),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  }
}

// Auth error handler unused in demo build
