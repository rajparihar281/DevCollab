import 'package:dev_collab/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:dev_collab/routing/route_names.dart';
import 'package:dev_collab/shared/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User Section
          if (user != null) ...[
            InkWell(
              onTap: () => context.push(RouteNames.profile),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: profile?.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: (profile?.avatarUrl == null ||
                              profile!.avatarUrl!.isEmpty)
                          ? Text(
                              (user.email ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.email ?? 'DevCollab User',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Edit Profile, Bio & Private Teams',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications Section
            Text(
              'NOTIFICATIONS & EMAILS',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Notification & Email Preferences'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(RouteNames.notificationPreferences),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Appearance Section
          Text(
            'APPEARANCE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListTile(
              leading: Icon(
                themeMode == ThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('OLED Dark Theme'),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (val) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Legal & Privacy Section
          Text(
            'LEGAL & COMPLIANCE',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms & Conditions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.terms),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(RouteNames.privacy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          OutlinedButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout, color: Color(0xFFFF4B6E)),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFFF4B6E)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF4B6E)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
