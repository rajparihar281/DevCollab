import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/project_repository.dart';
import '../../domain/models/project.dart';

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepository(),
);

// ─── Projects List ───────────────────────────────────────────────────────
final projectsProvider = AsyncNotifierProvider.family<ProjectsNotifier, List<Project>, String>(
  ProjectsNotifier.new,
);

class ProjectsNotifier extends AsyncNotifier<List<Project>> {
  ProjectsNotifier(this._teamId);

  final String _teamId;
  late ProjectRepository _repo;

  @override
  Future<List<Project>> build() async {
    _repo = ref.read(projectRepositoryProvider);
    return _repo.getProjects(_teamId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Project?> createProject({
    required String organizationId,
    required String name,
    String? description,
  }) async {
    final project = await _repo.createProject(
      organizationId: organizationId,
      teamId: _teamId,
      name: name,
      description: description,
    );
    ref.invalidateSelf();
    await future;
    return project;
  }

  Future<void> archiveProject(String projectId) async {
    await _repo.updateProject(projectId, status: 'archived');
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteProject(String projectId) async {
    await _repo.deleteProject(projectId);
    ref.invalidateSelf();
    await future;
  }
}
