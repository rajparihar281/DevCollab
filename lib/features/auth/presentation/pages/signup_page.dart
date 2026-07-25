
import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:dev_collab/routing/route_names.dart';
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted || !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must agree to both the Terms & Conditions and Privacy Policy to register.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: context.colorError,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();


    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      // Store explicit consent & timestamp in profiles DB as defending proof
      if (response.user != null) {
        final now = DateTime.now().toIso8601String();
        try {
          await Supabase.instance.client.from('profiles').update({
            'terms_accepted_at': now,
            'privacy_accepted_at': now,
            'consent_given': true,
          }).eq('id', response.user!.id);
        } catch (err) { /* ignored */ }
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Account created successfully! Welcome to DevCollab.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: context.colorSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Signup failed: ${_cleanErrorMessage(e.toString())}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: context.colorError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanErrorMessage(String raw) {
    if (raw.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  Future<void> _signUpWithGoogle() async {

    setState(() => _isLoading = true);
    
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle('732760635408-d2qmcnliljqp348v1mj240bn40sdsnjm.apps.googleusercontent.com');

      if (mounted) context.go(RouteNames.organizations);
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-Up failed: $e'),
            backgroundColor: context.colorError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorBackground,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colorSecondary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.colorPrimary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Back navigation & Logo
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: context.colorTextSecondary,
                              ),
                              tooltip: 'Back to Login',
                            ),
                            Spacer(),
                            Image.asset(
                              Theme.of(context).brightness == Brightness.dark
                                  ? 'assets/images/dark_mode_icon.png'
                                  : 'assets/images/light_mode_icon.png',
                              width: 60,
                              height: 60,
                            ),
                            Spacer(),
                            SizedBox(width: 48), // Balance spacing
                          ],
                        ),
                        SizedBox(height: 24),

                        // Title & Subtitle
                        Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.colorTextPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Join DevCollab and start managing teams, projects, and tasks in real-time.',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.colorTextSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 32),

                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: context.colorSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.colorBorder.withValues(alpha: 0.6),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Full Name Field
                                Text(
                                  'Full Name',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    color: context.colorTextPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Jane Doe',
                                    hintStyle: TextStyle(
                                      color: context.colorTextMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                      color: context.colorTextSecondary,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: context.colorBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorPrimary,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorError),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),

                                // Email Field
                                Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    color: context.colorTextPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'name@company.com',
                                    hintStyle: TextStyle(
                                      color: context.colorTextMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                      color: context.colorTextSecondary,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: context.colorBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorPrimary,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorError),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@') ||
                                        !value.contains('.')) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),

                                // Password Field
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _signUp(),
                                  style: TextStyle(
                                    color: context.colorTextPrimary,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'At least 6 characters',
                                    hintStyle: TextStyle(
                                      color: context.colorTextMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      color: context.colorTextSecondary,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: context.colorTextSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                    filled: true,
                                    fillColor: context.colorBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: context.colorPrimary,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: context.colorError),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),

                                // Legal Consent Checkboxes
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: context.colorPrimary,
                                  value: _termsAccepted,
                                  onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                                  title: GestureDetector(
                                    onTap: () => context.push(RouteNames.terms),
                                    child: Text(
                                      'I agree to the Terms & Conditions',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.colorPrimary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  activeColor: context.colorPrimary,
                                  value: _privacyAccepted,
                                  onChanged: (val) => setState(() => _privacyAccepted = val ?? false),
                                  title: GestureDetector(
                                    onTap: () => context.push(RouteNames.privacy),
                                    child: Text(
                                      'I agree to the Privacy Policy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.colorPrimary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Signup Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colorPrimary,
                                    foregroundColor: context.colorOnPrimary,
                                    disabledBackgroundColor: context.colorPrimary
                                        .withValues(alpha: 0.4),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: context.colorOnPrimary,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                                SizedBox(height: 16),
                                // Google Sign Up Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _signUpWithGoogle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black87,
                                    disabledBackgroundColor: Colors.grey.shade200,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.g_mobiledata_rounded,
                                        size: 26,
                                        color: Colors.black87,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sign Up with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Switch to Login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: context.colorTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: context.colorPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
