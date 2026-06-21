import 'package:flutter/material.dart';

import '../../domain/models/task.dart';
import 'task_card.dart';

class KanbanColumn extends StatefulWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.label,
    required this.color,
    required this.tasks,
    required this.onMoveTask,
    required this.onTapTask,
  });

  final String status;
  final String label;
  final Color color;
  final List<Task> tasks;
  final Future<void> Function(String taskId, String newStatus) onMoveTask;
  final void Function(Task task) onTapTask;

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final willAccept = details.data.status != widget.status;
        setState(() => _isDraggingOver = willAccept);
        return willAccept;
      },
      onLeave: (_) => setState(() => _isDraggingOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isDraggingOver = false);
        widget.onMoveTask(details.data.id, widget.status);
      },
      builder: (ctx, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: _isDraggingOver
                ? widget.color.withValues(alpha: 0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDraggingOver
                  ? widget.color
                  : theme.colorScheme.surfaceContainerHighest,
              width: _isDraggingOver ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.tasks.length}',
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tasks
              Expanded(
                child: widget.tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 32,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Drop here',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.tasks.length,
                        itemBuilder: (_, i) {
                          final task = widget.tasks[i];
                          return Draggable<Task>(
                            data: task,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 260,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: TaskCard(task: task, onTap: () {}),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(
                                task: task,
                                onTap: () => widget.onTapTask(task),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TaskCard(
                                task: task,
                                onTap: () => widget.onTapTask(task),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
