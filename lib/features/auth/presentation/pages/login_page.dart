import 'dart:developer';

import 'package:dev_collab/features/auth/presentation/pages/signup_page.dart';
import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    log('[LoginPage] login() called');
    log('[LoginPage] email: $email');
    log('[LoginPage] password length: ${password.length}');

    if (email.isEmpty || password.isEmpty) {
      log('[LoginPage] Validation failed — empty fields');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
      }
      return;
    }

    try {
      setState(() => isLoading = true);
      log('[LoginPage] Setting isLoading = true');

      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signIn(
        email: email,
        password: password,
      );

      log('[LoginPage] signIn completed successfully');
      log('[LoginPage] session: ${response.session != null ? "EXISTS" : "NULL"}');
      log('[LoginPage] user: ${response.user?.email ?? "NULL"}');

      // No explicit navigation needed — AuthGate will reactively rebuild
      // when the authStateProvider stream emits the signedIn event.
      log('[LoginPage] Waiting for AuthGate to handle navigation via stream...');
    } catch (e, st) {
      log('[LoginPage] login ERROR: $e');
      log('[LoginPage] login STACK: $st');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        log('[LoginPage] Setting isLoading = false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
              onSubmitted: (_) => login(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
            TextButton(
              onPressed: () {
                log('[LoginPage] Navigating to SignupPage');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
