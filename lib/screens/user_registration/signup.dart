import 'package:aiassistant1/screens/user_registration/signin.dart';
import 'package:aiassistant1/services/google_sign.dart';
import 'package:aiassistant1/widgets/build_text_field.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Disabled in demo build: no account creation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign up disabled in demo build.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Unused in demo build
  String _getErrorMessage(dynamic e) => 'Registration disabled in demo build';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Changed from false to true
      body: SafeArea(
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              // Added IntrinsicHeight
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header and Form content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "Create Account",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Join us to get started",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withAlpha(
                                  (0.8 * 255).toInt(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),

                        // Form remains the same
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              AuthTextField(
                                label: "Full Name",
                                icon: Icons.person,
                                controller: _nameController,
                                validator:
                                    (value) =>
                                        value!.isEmpty
                                            ? 'Please enter your name'
                                            : null,
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                label: "Email",
                                icon: Icons.email,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuthTextField(
                                label: "Password",
                                icon: Icons.lock,
                                isPassword: true,
                                controller: _passwordController,
                                validator: (value) {
                                  if (value == null || value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _createAccount,
                                  child:
                                      _isLoading
                                          ? CircularProgressIndicator(
                                            color: colorScheme.onPrimary,
                                          )
                                          : Text(
                                            "Sign up",
                                            style: TextStyle(
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.surface,
                                    foregroundColor: colorScheme.onSurface,
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 16,
                                    ),
                                  ),
                                  icon: Image.asset(
                                    'assets/images/google_logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  label: const Text(
                                    "Continue with Google",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () async {
                                            try {
                                              setState(() => _isLoading = true);
                                              await Google_login_signup(
                                                context,
                                              );
                                            } catch (e) {
                                              // ignore: use_build_context_synchronously
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Error: ${e.toString()}",
                                                  ),
                                                  backgroundColor:
                                                      colorScheme.error,
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _isLoading = false,
                                                );
                                              }
                                            }
                                          },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer (fixed at bottom)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24, top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Remember your password?",
                          style: TextStyle(
                            color: colorScheme.onSurface.withAlpha(
                              (0.6 * 255).toInt(),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignInPage(),
                                    ),
                                  ),
                          child: Text(
                            "Sign in",
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
