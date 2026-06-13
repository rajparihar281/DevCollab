import 'dart:developer';

import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    log('[SignupPage] signUp() called');
    log('[SignupPage] email: $email');
    log('[SignupPage] password length: ${password.length}');

    if (email.isEmpty || password.isEmpty) {
      log('[SignupPage] Validation failed — empty fields');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
      }
      return;
    }

    try {
      setState(() => isLoading = true);
      log('[SignupPage] Setting isLoading = true');

      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUp(
        email: email,
        password: password,
      );

      log('[SignupPage] signUp completed successfully');
      log('[SignupPage] session: ${response.session != null ? "EXISTS" : "NULL"}');
      log('[SignupPage] user: ${response.user?.email ?? "NULL"}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        log('[SignupPage] Navigated back to LoginPage');
      }
    } catch (e, st) {
      log('[SignupPage] signUp ERROR: $e');
      log('[SignupPage] signUp STACK: $st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        log('[SignupPage] Setting isLoading = false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => signUp(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : signUp,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
