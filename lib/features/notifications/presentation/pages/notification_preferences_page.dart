import 'dart:developer';

import 'package:dev_collab/features/auth/domain/models/profile.dart';
import 'package:dev_collab/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool _taskAssigned = true;
  bool _mentions = true;
  bool _teamMessages = true;
  bool _emailDigest = false;
  bool _securityAlerts = true;
  bool _loaded = false;
  bool _saving = false;

  void _initFromProfile(Profile profile) {
    if (_loaded) return;
    _loaded = true;
    _taskAssigned = profile.notifyTaskAssigned;
    _mentions = profile.notifyMention;
    _teamMessages = profile.notifyTeamMessage;
    _emailDigest = profile.notifyEmailDigest;
    _securityAlerts = profile.notifySecurityAlerts;
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      final updates = {
        'notify_task_assigned': _taskAssigned,
        'notify_mention': _mentions,
        'notify_team_message': _teamMessages,
        'notify_email_digest': _emailDigest,
        'notify_security_alerts': _securityAlerts,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await ref.read(userProfileProvider.notifier).updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      log('[NotificationPreferencesPage] Error saving: $e');
      final errorStr = e.toString();
      if ((errorStr.contains('PGRST204') || errorStr.contains('Could not find the')) && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Database Migration Required'),
              ],
            ),
            content: const Text(
              'To save notification preferences, please execute the SQL migration file in your Supabase SQL Editor:\n\nsupabase/migrations/20260710000001_add_profile_extended_and_notification_fields.sql',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK, Got It'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Emails'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile != null) _initFromProfile(profile);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'QUICK NOTIFICATIONS',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Task Assignments'),
                subtitle: const Text(
                    'Get notified immediately when a task is assigned to you.'),
                value: _taskAssigned,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _taskAssigned = v),
              ),
              SwitchListTile(
                title: const Text('Mentions & Replies'),
                subtitle: const Text(
                    'Instant alerts when someone @mentions you in team chat or comments.'),
                value: _mentions,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _mentions = v),
              ),
              SwitchListTile(
                title: const Text('Team Messages'),
                subtitle: const Text(
                    'Receive push alerts for new activity in your active channels.'),
                value: _teamMessages,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _teamMessages = v),
              ),
              const SizedBox(height: 24),
              Text(
                'EMAIL DIGEST & SECURITY',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Weekly Email Digest'),
                subtitle: const Text(
                    'Summary email report of organization productivity & completed tasks.'),
                value: _emailDigest,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _emailDigest = v),
              ),
              SwitchListTile(
                title: const Text('Critical Security Alerts'),
                subtitle: const Text(
                    'Important alerts about password changes or new device logins.'),
                value: _securityAlerts,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (v) => setState(() => _securityAlerts = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Preferences'),
              ),
            ],
          );
        },
      ),
    );
  }
}
