import 'package:flutter/material.dart';

import '../../domain/models/task.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.onMoveTask,
    required this.onTapTask,
  });

  final List<Task> tasks;
  final Future<void> Function(String taskId, String newStatus) onMoveTask;
  final void Function(Task task) onTapTask;

  static const _columns = [
    ('todo', 'To Do', Color(0xFF888899)),
    ('in_progress', 'In Progress', Color(0xFF6C63FF)),
    ('review', 'Review', Color(0xFFFFA726)),
    ('done', 'Done', Color(0xFF4CAF50)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      itemCount: _columns.length,
      itemBuilder: (_, i) {
        final (status, label, color) = _columns[i];
        final columnTasks =
            tasks.where((t) => t.status == status).toList();
        return KanbanColumn(
          status: status,
          label: label,
          color: color,
          tasks: columnTasks,
          onMoveTask: onMoveTask,
          onTapTask: onTapTask,
        );
      },
    );
  }
}
