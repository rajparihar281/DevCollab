import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/avatar_widget.dart';
import '../../../../shared/widgets/priority_badge.dart';
import '../../domain/models/task.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = TaskPriorityExt.fromString(task.priority);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: priority),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (task.assigneeId != null)
                    AvatarWidget(
                      avatarUrl: task.assigneeAvatar,
                      name: task.assigneeName,
                      radius: 12,
                    ),
                  const Spacer(),
                  if (task.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: _dueDateColor(task.dueDate!),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(task.dueDate!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _dueDateColor(task.dueDate!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _dueDateColor(DateTime due) {
    final now = DateTime.now();
    if (due.isBefore(now)) return Colors.red;
    if (due.difference(now).inDays <= 2) return Colors.orange;
    return const Color(0xFF888899);
  }
}
