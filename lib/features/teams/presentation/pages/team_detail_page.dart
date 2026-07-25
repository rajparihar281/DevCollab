import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/widgets/message_bubble.dart';
import '../providers/team_providers.dart';
import '../widgets/add_team_member_dialog.dart';
import '../../../projects/presentation/providers/project_providers.dart';
import '../../../projects/presentation/widgets/project_card.dart';

class TeamDetailPage extends ConsumerWidget {
  const TeamDetailPage({
    super.key,
    required this.orgId,
    required this.teamId,
  });

  final String orgId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamRepo = ref.read(teamRepositoryProvider);

    return FutureBuilder(
      future: teamRepo.getTeamById(teamId),
      builder: (context, snap) {
        final teamName = snap.hasData ? snap.data!.name : 'Team';
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(teamName),
              actions: [
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  tooltip: 'Full Screen Chat',
                  onPressed: () => context.push(
                    RouteNames.chatPath(orgId, teamId),
                  ),
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.folder_rounded), text: 'Projects'),
                  Tab(icon: Icon(Icons.people_rounded), text: 'Members'),
                  Tab(icon: Icon(Icons.chat_rounded), text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProjectsTab(orgId: orgId, teamId: teamId),
                _MembersTab(orgId: orgId, teamId: teamId),
                _ChatTab(teamId: teamId),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'create_project',
              onPressed: () =>
                  context.push(RouteNames.createProjectPath(orgId, teamId)),
              icon: Icon(Icons.add_rounded),
              label: Text('New Project'),
            ),
          ),
        );
      },
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab({required this.orgId, required this.teamId});
  final String orgId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider(teamId));
    return projectsAsync.when(
      loading: () => AppLoader(message: 'Loading projects...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(projectsProvider(teamId)),
      ),
      data: (projects) => projects.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha:0.4),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No projects yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(projectsProvider(teamId).notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: projects.length,
                separatorBuilder: (_, _) => SizedBox(height: 12),
                itemBuilder: (_, i) => ProjectCard(
                  project: projects[i],
                  onTap: () => context.push(
                    RouteNames.projectDetailPath(orgId, teamId, projects[i].id),
                  ),
                ),
              ),
            ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.orgId, required this.teamId});
  final String orgId;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUserMemberAsync = ref.watch(currentUserMemberProvider(orgId));

    return membersAsync.when(
      loading: () => AppLoader(message: 'Loading team members...'),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
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
                color: context.colorSurface,
                border: Border(
                  bottom: BorderSide(
                    color: context.colorBorder.withValues(alpha:0.5),
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
                      color: context.colorPrimary.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${members.length} ${members.length == 1 ? 'Member' : 'Members'}',
                      style: TextStyle(
                        color: context.colorPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Spacer(),
                  if (canManage)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddTeamMemberDialog(
                            organizationId: orgId,
                            teamId: teamId,
                            existingTeamMemberUserIds:
                                members.map((m) => m.userId).toSet(),
                          ),
                        );
                      },
                      icon: Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(
                        'Add Member',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPrimary,
                        foregroundColor: context.colorOnPrimary,
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

            // List of team members
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(teamMembersProvider(teamId).notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = members[i];
                    final name = m.fullName?.isNotEmpty == true
                        ? m.fullName!
                        : 'Unknown Colleague';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colorSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: context.colorBorder.withValues(alpha:0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.04),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            avatarUrl: m.avatarUrl,
                            name: name,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: context.colorTextPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colorSecondary
                                            .withValues(alpha:0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'TEAM MEMBER',
                                        style: TextStyle(
                                          color: context.colorSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Joined ${_formatDate(m.joinedAt)}',
                                      style: TextStyle(
                                        color: context.colorTextMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (canManage)
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline_rounded,
                                color: context.colorError,
                              ),
                              tooltip: 'Remove from team',
                              onPressed: () => _confirmRemove(context, ref, m.id, name),
                            ),
                        ],
                      ),
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

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String memberId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.colorSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove from Team?',
          style: TextStyle(
            color: context.colorTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $name from this team? They will no longer see tasks or chat in this team.',
          style: TextStyle(color: context.colorTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(teamMembersProvider(teamId).notifier).removeMember(memberId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorError,
              foregroundColor: context.colorOnPrimary,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ChatTab extends ConsumerStatefulWidget {
  const _ChatTab({required this.teamId});
  final String teamId;

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ref.read(chatProvider(widget.teamId).notifier).sendMessage(text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatProvider(widget.teamId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            loading: () => AppLoader(message: 'Loading messages...'),
            error: (e, _) => Center(
              child: Text(
                'Error loading chat: $e',
                style: TextStyle(color: context.colorError),
              ),
            ),
            data: (messages) => messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 54,
                          color: context.colorTextMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No team messages yet',
                          style: TextStyle(
                            color: context.colorTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start a discussion with your team members!',
                          style: TextStyle(
                            color: context.colorTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMe = msg.userId == currentUserId;
                      final showAvatar =
                          i == 0 || messages[i - 1].userId != msg.userId;
                      return MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showAvatar: showAvatar,
                      );
                    },
                  ),
          ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: context.colorSurface,
            border: Border(
              top: BorderSide(
                color: context.colorBorder.withValues(alpha:0.5),
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(color: context.colorTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message to team...',
                      hintStyle: TextStyle(color: context.colorTextMuted, fontSize: 14),
                      filled: true,
                      fillColor: context.colorBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: context.colorBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: context.colorBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: context.colorPrimary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: context.colorPrimary,
                    foregroundColor: context.colorOnPrimary,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
