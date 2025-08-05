import 'package:aiassistant1/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // 4. Create Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Sign in to Firebase
    final authResult = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = authResult.user;

    // 6. Navigate to home screen
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    // 8. Show welcome message
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authResult.additionalUserInfo?.isNewUser ?? false
              ? 'Welcome to BudgetApp!'
              : 'Welcome back, ${user?.displayName ?? ''}!',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.fixed,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
    );
  } on FirebaseAuthException catch (e) {
    Navigator.pop(context); // Dismiss loading
    if (!context.mounted) return;
    _handleFirebaseAuthError(context, e.code);
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
    debugPrint('Google sign-in error: $e');
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

void _handleFirebaseAuthError(BuildContext context, String code) {
  final message = switch (code) {
    'account-exists-with-different-credential' =>
      'This email is already linked with another sign-in method.',
    'invalid-credential' => 'Invalid authentication credentials.',
    'operation-not-allowed' => 'Google sign-in is not enabled.',
    'user-disabled' => 'This account has been disabled.',
    'network-request-failed' => 'Network error. Please check your connection.',
    _ => 'Authentication failed. Please try again.',
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.fixed,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    ),
  );
}
