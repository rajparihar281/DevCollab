import 'dart:math';

import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:dev_collab/features/organizations/domain/models/kanban_task.dart';
import 'package:dev_collab/features/organizations/domain/models/org_message.dart';
import 'package:dev_collab/features/organizations/domain/models/organization.dart';
import 'package:dev_collab/features/organizations/domain/models/organization_member.dart';
import 'package:dev_collab/features/organizations/presentation/providers/organization_providers.dart';
import 'package:dev_collab/features/organizations/presentation/widgets/add_organization_member_dialog.dart';
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:dev_collab/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OrgWorkspacePage extends ConsumerStatefulWidget {
  const OrgWorkspacePage({required this.organization, super.key});

  final Organization organization;

  @override
  ConsumerState<OrgWorkspacePage> createState() => _OrgWorkspacePageState();
}

class _OrgWorkspacePageState extends ConsumerState<OrgWorkspacePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(org.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text(
              'Team Workspace',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _KanbanBoardTab(orgId: org.id),
          _TeamChatTab(orgId: org.id),
          _TeamMembersAndInvitesTab(organization: org),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_kanban_outlined),
            selectedIcon: Icon(Icons.view_kanban_rounded),
            label: 'Kanban Board',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Team Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Members & Invites',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// TAB 1: KANBAN BOARD & SPRINT TRACKER
// =========================================================================
class _KanbanBoardTab extends ConsumerStatefulWidget {
  const _KanbanBoardTab({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_KanbanBoardTab> createState() => _KanbanBoardTabState();
}

class _KanbanBoardTabState extends ConsumerState<_KanbanBoardTab> {
  String _selectedFilter = 'All'; // 'All', 'todo', 'in_progress', 'code_review', 'done'

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(orgTasksProvider(widget.orgId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_kanban_new_task',
        onPressed: _showCreateTaskModal,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Task'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'All'),
                _buildFilterChip('To Do', 'todo'),
                _buildFilterChip('In Progress', 'in_progress'),
                _buildFilterChip('Code Review', 'code_review'),
                _buildFilterChip('Done', 'done'),
              ],
            ),
          ),

          // Tasks List
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading tasks: $e')),
              data: (tasks) {
                final filtered = _selectedFilter == 'All'
                    ? tasks
                    : tasks.where((t) => t.status == _selectedFilter).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No tasks yet in this sprint',
                    subtitle:
                        'Create your first sprint task to start tracking work across To Do, In Progress, Code Review, and Done.',
                    action: _showCreateTaskModal,
                    actionLabel: '+ Create First Task',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(orgTasksProvider(widget.orgId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _buildTaskCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final selected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedFilter = status),
      ),
    );
  }

  Widget _buildTaskCard(KanbanTask task) {
    final theme = Theme.of(context);
    Color priorityColor = Colors.grey;
    if (task.priority == 'urgent') priorityColor = AppColors.error;
    if (task.priority == 'high') priorityColor = Colors.orange;
    if (task.priority == 'medium') priorityColor = AppColors.primary;

    String statusLabel = 'To Do';
    if (task.status == 'in_progress') statusLabel = 'In Progress';
    if (task.status == 'code_review') statusLabel = 'Code Review';
    if (task.status == 'done') statusLabel = 'Done';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style:
                      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error,
                onPressed: () => _deleteTask(task.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description!,
              style: TextStyle(
                  fontSize: 13, color: theme.textTheme.bodySmall?.color),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (task.dueDate != null) ...[
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat.yMMMd().format(task.dueDate!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
              ],
              PopupMenuButton<String>(
                onSelected: (newStatus) => _changeStatus(task.id, newStatus),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Move Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz_rounded,
                          size: 16, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'todo', child: Text('To Do')),
                  PopupMenuItem(
                      value: 'in_progress', child: Text('In Progress')),
                  PopupMenuItem(
                      value: 'code_review', child: Text('Code Review')),
                  PopupMenuItem(value: 'done', child: Text('Done')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String taskId, String newStatus) async {
    await ref
        .read(organizationRepositoryProvider)
        .updateTaskStatus(taskId, newStatus);
    ref.invalidate(orgTasksProvider(widget.orgId));
  }

  Future<void> _deleteTask(String taskId) async {
    await ref.read(organizationRepositoryProvider).deleteTask(taskId);
    ref.invalidate(orgTasksProvider(widget.orgId));
  }

  void _showCreateTaskModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String status = 'todo';
    String priority = 'medium';
    DateTime? dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Sprint Task',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                            value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) => setModalState(() => priority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'todo', child: Text('To Do')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'code_review', child: Text('Code Review')),
                        DropdownMenuItem(value: 'done', child: Text('Done')),
                      ],
                      onChanged: (v) => setModalState(() => status = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_rounded),
                title: Text(dueDate == null
                    ? 'Set Due Date'
                    : 'Due: ${DateFormat.yMMMd().format(dueDate!)}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setModalState(() => dueDate = picked);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    await ref.read(organizationRepositoryProvider).createTask(
                          orgId: widget.orgId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          status: status,
                          priority: priority,
                          dueDate: dueDate,
                        );
                    ref.invalidate(orgTasksProvider(widget.orgId));
                  },
                  child: const Text('Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// TAB 2: REAL-TIME TEAM CHAT & ANNOUNCEMENTS
// =========================================================================
class _TeamChatTab extends ConsumerStatefulWidget {
  const _TeamChatTab({required this.orgId});
  final String orgId;

  @override
  ConsumerState<_TeamChatTab> createState() => _TeamChatTabState();
}

class _TeamChatTabState extends ConsumerState<_TeamChatTab> {
  final _msgController = TextEditingController();
  bool _isAnnouncement = false;

  @override
  Widget build(BuildContext context) {
    final streamAsync = ref.watch(orgMessagesStreamProvider(widget.orgId));
    final theme = Theme.of(context);

    return Column(
      children: [
        // Messages Area
        Expanded(
          child: streamAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading chat: $e')),
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 56, color: theme.disabledColor),
                        const SizedBox(height: 12),
                        const Text(
                          'No team messages yet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Start your team discussion or broadcast a high-priority announcement below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _buildMessageBubble(messages[i]),
              );
            },
          ),
        ),

        // Composer Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Announcement'),
                      selected: _isAnnouncement,
                      onSelected: (val) =>
                          setState(() => _isAnnouncement = val),
                      selectedColor: Colors.orange.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _isAnnouncement ? Colors.orange : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: 'Message team...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(OrgMessage msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: msg.isAnnouncement
            ? Colors.orange.withValues(alpha: 0.15)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: msg.isAnnouncement
            ? Border.all(color: Colors.orange, width: 1.5)
            : Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                msg.userName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 8),
              if (msg.isAnnouncement)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ANNOUNCEMENT',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const Spacer(),
              if (msg.createdAt != null)
                Text(
                  DateFormat.Hm().format(msg.createdAt!),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(msg.content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    await ref.read(organizationRepositoryProvider).sendMessage(
          orgId: widget.orgId,
          content: text,
          isAnnouncement: _isAnnouncement,
        );
    setState(() => _isAnnouncement = false);
  }
}

// =========================================================================
// TAB 3: MEMBERS (MD / MG / EMP / ADMIN) & INVITE CODES
// =========================================================================
class _TeamMembersAndInvitesTab extends ConsumerWidget {
  const _TeamMembersAndInvitesTab({required this.organization});
  final Organization organization;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(organizationMembersProvider(organization.id));
    final invitesAsync = ref.watch(orgInvitesProvider(organization.id));
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_rounded), text: 'Members (MD/MG/EMP)'),
              Tab(icon: Icon(Icons.qr_code_rounded), text: 'Invite Codes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Sub-Tab 1: Organization Members List + Add Member button
            membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading members: $e')),
              data: (members) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Active Team Members (${members.length})',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_rounded, size: 18),
                            label: const Text('Add Member'),
                            onPressed: () => _showAddMemberDialog(
                                context,
                                ref,
                                members.map((m) => m.userId).toSet()),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: members.isEmpty
                          ? EmptyState(
                              icon: Icons.people_outline_rounded,
                              title: 'No extra members yet',
                              subtitle:
                                  'Invite developers, MD, MG, or EMP to collaborate on sprint boards.',
                              action: () => _showAddMemberDialog(
                                  context, ref, <String>{}),
                              actionLabel: '+ Invite Member',
                            )
                          : RefreshIndicator(
                              onRefresh: () async => ref.refresh(
                                  organizationMembersProvider(organization.id)),
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: members.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (ctx, i) =>
                                    _buildMemberCard(ctx, ref, members[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),

            // Sub-Tab 2: Invite Codes + Delete feature
            Scaffold(
              floatingActionButton: FloatingActionButton.extended(
                heroTag: 'fab_team_invite_code',
                onPressed: () => _generateNewInviteCode(context, ref),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('Create Invite Code'),
              ),
              body: invitesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading invites: $e'),
                data: (invites) {
                  if (invites.isEmpty) {
                    return EmptyState(
                      icon: Icons.vpn_key_outlined,
                      title: 'No active invite codes',
                      subtitle:
                          'Create shareable join codes so teammates can instantly join your organization.',
                      action: () => _generateNewInviteCode(context, ref),
                      actionLabel: '+ Create Invite Code',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: invites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final inv = invites[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.vpn_key_rounded,
                              color: AppColors.primary),
                          title: Text(
                            inv.inviteCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 16),
                          ),
                          subtitle: Text('Role: ${inv.role.toUpperCase()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded),
                                tooltip: 'Copy Code',
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: inv.inviteCode));
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Copied code "${inv.inviteCode}" to clipboard!'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.error),
                                tooltip: 'Delete Invite Code',
                                onPressed: () async {
                                  await ref
                                      .read(organizationRepositoryProvider)
                                      .deleteInviteCode(inv.id);
                                  ref.invalidate(
                                      orgInvitesProvider(organization.id));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(
      BuildContext context, WidgetRef ref, OrganizationMember member) {
    final theme = Theme.of(context);
    final currentUser = ref.read(authRepositoryProvider).currentUser;
    final isMe = currentUser?.id == member.userId;

    Color badgeColor = Colors.grey;
    final roleUp = member.role.toUpperCase();
    if (roleUp == 'OWNER' || roleUp == 'MD') badgeColor = Colors.purple;
    if (roleUp == 'ADMIN' || roleUp == 'MG') badgeColor = Colors.orange;
    if (roleUp == 'EMP' || roleUp == 'MEMBER') badgeColor = AppColors.primary;

    final dispName = member.fullName ?? member.email ?? 'Team Member';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: badgeColor.withValues(alpha: 0.2),
            child: Text(
              dispName.isNotEmpty ? dispName[0].toUpperCase() : 'U',
              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dispName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      const Text('(You)',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleUp,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor),
                  ),
                ),
              ],
            ),
          ),
          if (!isMe)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (newRole) async {
                if (newRole == 'REMOVE') {
                  await ref
                      .read(organizationMembersProvider(organization.id).notifier)
                      .removeMember(member.id);
                } else {
                  await ref
                      .read(organizationMembersProvider(organization.id).notifier)
                      .updateMemberRole(memberId: member.id, role: newRole);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'md', child: Text('Set Role: MD')),
                PopupMenuItem(value: 'mg', child: Text('Set Role: MG')),
                PopupMenuItem(value: 'emp', child: Text('Set Role: EMP')),
                PopupMenuItem(value: 'admin', child: Text('Set Role: Admin')),
                PopupMenuItem(value: 'member', child: Text('Set Role: Member')),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'REMOVE',
                  child: Text('Remove Member',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(
      BuildContext context, WidgetRef ref, Set<String> existingIds) {
    showDialog(
      context: context,
      builder: (_) => AddOrganizationMemberDialog(
        organizationId: organization.id,
        existingMemberIds: existingIds,
      ),
    );
  }

  Future<void> _generateNewInviteCode(
      BuildContext context, WidgetRef ref) async {
    final randomDigits = Random().nextInt(89999) + 10000;
    final code = 'DEV-$randomDigits';

    await ref.read(organizationRepositoryProvider).createInviteCode(
          orgId: organization.id,
          inviteCode: code,
          role: 'member',
        );

    ref.invalidate(orgInvitesProvider(organization.id));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created join code $code!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
