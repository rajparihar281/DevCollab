import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/models/organization_member.dart';
import '../providers/organization_providers.dart';
import '../providers/activity_providers.dart';
import '../../../teams/presentation/providers/team_providers.dart';
import '../widgets/activity_feed.dart';
import '../widgets/add_organization_member_dialog.dart';
import '../../../teams/presentation/widgets/team_card.dart';

class OrganizationDetailPage extends ConsumerWidget {
  const OrganizationDetailPage({super.key, required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationDetailProvider(orgId));

    return orgAsync.when(
      loading: () => const Scaffold(body: AppLoader()),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
      data: (org) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(org.name),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.groups_rounded), text: 'Teams'),
                Tab(icon: Icon(Icons.people_alt_rounded), text: 'Members'),
                Tab(icon: Icon(Icons.history_rounded), text: 'Activity'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _TeamsTab(orgId: orgId),
              _MembersTab(orgId: orgId),
              _ActivityTab(orgId: orgId),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'create_team',
            onPressed: () =>
                context.push(RouteNames.createTeamPath(orgId)),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Team'),
          ),
        ),
      ),
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  const _TeamsTab({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider(orgId));

    return teamsAsync.when(
      loading: () => const AppLoader(message: 'Loading teams...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(teamsProvider(orgId)),
      ),
      data: (teams) => teams.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No teams yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a team to start working on projects.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(teamsProvider(orgId).notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: teams.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => TeamCard(
                  team: teams[i],
                  onTap: () => context.push(
                    RouteNames.teamDetailPath(orgId, teams[i].id),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider(orgId));
    return logsAsync.when(
      loading: () => const AppLoader(message: 'Loading activity...'),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (logs) => ActivityFeed(logs: logs),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.orgId});
  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(organizationMembersProvider(orgId));
    final currentUserMemberAsync = ref.watch(currentUserMemberProvider(orgId));

    return membersAsync.when(
      loading: () => const AppLoader(message: 'Loading members...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(organizationMembersProvider(orgId)),
      ),
      data: (members) {
        final currentMember = currentUserMemberAsync.value;
        final canManage = currentMember?.canManage ?? false;

        return Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border.withValues(alpha:0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${members.length} ${members.length == 1 ? 'Member' : 'Members'}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (canManage)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddOrganizationMemberDialog(
                            organizationId: orgId,
                            existingMemberIds:
                                members.map((m) => m.userId).toSet(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text(
                        'Add Member',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ),

            // Members List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(organizationMembersProvider(orgId).notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _MemberCard(
                      member: member,
                      canManage: canManage && !member.isOwner,
                      onUpdateRole: (newRole) {
                        ref
                            .read(organizationMembersProvider(orgId).notifier)
                            .updateMemberRole(
                              memberId: member.id,
                              role: newRole,
                            );
                      },
                      onRemove: () {
                        ref
                            .read(organizationMembersProvider(orgId).notifier)
                            .removeMember(member.id);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.canManage,
    required this.onUpdateRole,
    required this.onRemove,
  });

  final OrganizationMember member;
  final bool canManage;
  final ValueChanged<String> onUpdateRole;
  final VoidCallback onRemove;

  Color _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const Color(0xFF9333EA); // Purple
      case 'admin':
        return AppColors.primary; // Teal/Blue
      case 'member':
        return AppColors.success; // Green
      default:
        return AppColors.textSecondary; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getRoleBadgeColor(member.role);
    final displayName = member.fullName?.isNotEmpty == true
        ? member.fullName!
        : 'Unknown Member';
    final initials =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: badgeColor.withValues(alpha:0.15),
            child: Text(
              initials,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.role.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Joined ${_formatDate(member.joinedAt)}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.surfaceLight,
              onSelected: (val) {
                if (val == 'remove') {
                  _showRemoveConfirmation(context);
                } else {
                  onUpdateRole(val);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'CHANGE ROLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (member.role != 'admin')
                  const PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Make Admin'),
                      ],
                    ),
                  ),
                if (member.role != 'member')
                  const PopupMenuItem(
                    value: 'member',
                    child: Row(
                      children: [
                        Icon(Icons.person_rounded, size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Text('Make Member'),
                      ],
                    ),
                  ),
                if (member.role != 'viewer')
                  const PopupMenuItem(
                    value: 'viewer',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Make Viewer'),
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text(
                        'Remove from Org',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showRemoveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Member?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove ${member.fullName ?? 'this user'} from the organization? They will lose access to all teams and projects.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
