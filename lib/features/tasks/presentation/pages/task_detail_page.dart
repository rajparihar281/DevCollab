import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/priority_badge.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../domain/models/task.dart';
import '../providers/task_providers.dart';
import '../../../comments/presentation/widgets/comment_section.dart';
import '../widgets/attachments_section.dart';

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({
    super.key,
    required this.orgId,
    required this.projectId,
    required this.taskId,
  });

  final String orgId;
  final String projectId;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return taskAsync.when(
      loading: () => const Scaffold(body: AppLoader(message: 'Loading task...')),
      error: (e, _) => Scaffold(body: ErrorView(message: e.toString())),
      data: (task) => _TaskDetailBody(
        task: task,
        orgId: orgId,
        projectId: projectId,
        ref: ref,
      ),
    );
  }
}

class _TaskDetailBody extends StatelessWidget {
  const _TaskDetailBody({
    required this.task,
    required this.orgId,
    required this.projectId,
    required this.ref,
  });

  final Task task;
  final String orgId;
  final String projectId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = TaskPriorityExt.fromString(task.priority);
    final status = TaskStatusExt.fromString(task.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                final confirmed = await _confirmDelete(context);
                if (confirmed && context.mounted) {
                  await ref
                      .read(tasksProvider(task.projectId).notifier)
                      .deleteTask(task.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Delete Task', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              task.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Status + Priority row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(status: status),
                PriorityBadge(priority: priority),
              ],
            ),
            // Description
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Description',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(task.description!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            const Divider(),
            // Meta info
            _MetaRow(
              icon: Icons.person_rounded,
              label: 'Assignee',
              child: task.assigneeId != null
                  ? Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: task.assigneeAvatar,
                          name: task.assigneeName,
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(task.assigneeName ?? 'Unknown',
                            style: theme.textTheme.bodyMedium),
                      ],
                    )
                  : Text('Unassigned',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
            ),
            if (task.dueDate != null)
              _MetaRow(
                icon: Icons.calendar_today_rounded,
                label: 'Due Date',
                child: Text(
                  DateFormat('MMMM d, yyyy').format(task.dueDate!),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            _MetaRow(
              icon: Icons.person_outline_rounded,
              label: 'Created by',
              child: Text(task.creatorName ?? 'Unknown',
                  style: theme.textTheme.bodyMedium),
            ),
            const Divider(),
            // Attachments
            AttachmentsSection(
              taskId: task.id,
              organizationId: task.organizationId,
              projectId: task.projectId,
            ),
            const Divider(),
            // Comments
            CommentSection(taskId: task.id),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.child});
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
