import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/models/activity_log.dart';
import '../../../../shared/widgets/avatar_widget.dart';

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key, required this.logs});
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text('No activity yet', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final log = logs[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarWidget(
                avatarUrl: log.actorAvatar,
                name: log.actorName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: log.actorName ?? 'Someone',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: ' ${_actionText(log)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(log.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _actionText(ActivityLog log) {
    final meta = log.metadata;
    switch (log.action) {
      case 'create':
        final name = meta?['name'] as String?;
        return 'created ${log.entityType}${name != null ? ' "$name"' : ''}';
      case 'update':
        return 'updated a ${log.entityType}';
      case 'delete':
        return 'deleted a ${log.entityType}';
      case 'move':
        final to = meta?['to'] as String?;
        return 'moved a task${to != null ? ' to $to' : ''}';
      default:
        return '${log.action} ${log.entityType}';
    }
  }
}
