import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/task_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../domain/models/task.dart';
import '../../domain/models/attachment.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(),
);

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(),
);

// ─── Tasks with Realtime ─────────────────────────────────────────────────
final tasksProvider = StreamNotifierProvider.family<TasksNotifier, List<Task>, String>(
  TasksNotifier.new,
);

class TasksNotifier extends StreamNotifier<List<Task>> {
  TasksNotifier(this._projectId);

  final String _projectId;
  late TaskRepository _repo;

  @override
  Stream<List<Task>> build() {
    _repo = ref.read(taskRepositoryProvider);
    return _repo.watchTasks(_projectId).map(
          (rows) => rows.map((json) => Task.fromJson(json)).toList(),
        );
  }

  Future<void> createTask({
    required String organizationId,
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'medium',
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    await _repo.createTask(
      organizationId: organizationId,
      projectId: _projectId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      dueDate: dueDate,
    );
  }

  Future<void> moveTask(String taskId, String newStatus) async {
    await _repo.updateTask(taskId, status: newStatus);
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? dueDate,
  }) async {
    await _repo.updateTask(
      taskId,
      title: title,
      description: description,
      status: status,
      priority: priority,
      assigneeId: assigneeId,
      dueDate: dueDate,
    );
  }

  Future<void> deleteTask(String taskId) async {
    await _repo.deleteTask(taskId);
  }
}

// ─── Single Task Detail ──────────────────────────────────────────────────
final taskDetailProvider =
    FutureProvider.family<Task, String>((ref, taskId) {
  return ref.read(taskRepositoryProvider).getTaskById(taskId);
});

// ─── Attachments ─────────────────────────────────────────────────────────
final attachmentsProvider =
    FutureProvider.family<List<TaskAttachment>, String>((ref, taskId) {
  return ref.read(attachmentRepositoryProvider).getAttachments(taskId);
});
