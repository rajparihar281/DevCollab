import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DevCollab Privacy Policy',
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
              '1. Information We Collect',
              'We collect email addresses, display names, profile avatars, and organization activity logs to facilitate collaborative project management.',
            ),
            _buildSection(
              theme,
              '2. How We Use Your Data',
              'Your data is exclusively used to provide real-time updates, task assignments, chat messaging, and secure workspace access control.',
            ),
            _buildSection(
              theme,
              '3. Row-Level Security & Data Isolation',
              'DevCollab enforces strict Postgrest Row-Level Security (RLS) policies. Only authenticated members of your organization can view or interact with your workspace resources.',
            ),
            _buildSection(
              theme,
              '4. Consent Storage for Legal Verification',
              'Your acceptance of this Privacy Policy is stored with a secure cryptographic timestamp in our database to demonstrate legal compliance.',
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
