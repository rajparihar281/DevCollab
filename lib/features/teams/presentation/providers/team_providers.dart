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

final teamMembersProvider = AsyncNotifierProvider.family<
    TeamMembersNotifier, List<TeamMember>, String>(
  TeamMembersNotifier.new,
);

class TeamMembersNotifier extends AsyncNotifier<List<TeamMember>> {
  TeamMembersNotifier(this._teamId);

  final String _teamId;
  late TeamRepository _repo;

  @override
  Future<List<TeamMember>> build() async {
    _repo = ref.read(teamRepositoryProvider);
    return _repo.getTeamMembers(_teamId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addMember(String userId) async {
    await _repo.addTeamMember(teamId: _teamId, userId: userId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeMember(String memberId) async {
    await _repo.removeTeamMember(memberId);
    ref.invalidateSelf();
    await future;
  }
}
