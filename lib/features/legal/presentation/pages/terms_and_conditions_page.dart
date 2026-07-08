import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DevCollab Terms of Service',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: July 2026',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              theme,
              '1. Acceptance of Terms',
              'By registering and using DevCollab, you agree to abide by these Terms and Conditions. If you do not agree with any part of these terms, you must not create an account or use our platform.',
            ),
            _buildSection(
              theme,
              '2. User Accounts & Organization Responsibilities',
              'You are responsible for safeguarding your authentication credentials and maintaining the confidentiality of your organization projects. You acknowledge that role-based permissions granted by organization owners dictate project visibility and edit rights.',
            ),
            _buildSection(
              theme,
              '3. Acceptable Use Policy',
              'You agree not to upload harmful code, abuse real-time chat endpoints, or violate the intellectual property rights of other team members.',
            ),
            _buildSection(
              theme,
              '4. Consent Recording & Legal Compliance',
              'By accepting these terms during registration, your consent timestamp and user identifier are securely recorded in our audit database as proof of agreement.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
