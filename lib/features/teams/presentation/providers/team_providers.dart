import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/team_repository.dart';
import '../../domain/models/team.dart';
import '../../domain/models/team_member.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(),
);

// ─── Teams List ─────────────────────────────────────────────────────────
final teamsProvider = AsyncNotifierProvider.family<TeamsNotifier, List<Team>, String>(
  TeamsNotifier.new,
);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  TeamsNotifier(this._orgId);

  final String _orgId;
  late TeamRepository _repo;

  @override
  Future<List<Team>> build() async {
    _repo = ref.read(teamRepositoryProvider);
    return _repo.getTeams(_orgId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Team?> createTeam({
    required String name,
    String? description,
  }) async {
    final team = await _repo.createTeam(
      organizationId: _orgId,
      name: name,
      description: description,
    );
    ref.invalidateSelf();
    await future;
    return team;
  }

  Future<void> deleteTeam(String teamId) async {
    await _repo.deleteTeam(teamId);
    ref.invalidateSelf();
    await future;
  }
}

// ─── Team Members ───────────────────────────────────────────────────────
final teamMembersProvider =
    FutureProvider.family<List<TeamMember>, String>((ref, teamId) {
  return ref.read(teamRepositoryProvider).getTeamMembers(teamId);
});
