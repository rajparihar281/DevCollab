import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/organization_repository.dart';
import '../../data/repositories/organization_member_repository.dart';
import '../../domain/models/kanban_project.dart';
import '../../domain/models/kanban_task.dart';
import '../../domain/models/org_invite.dart';
import '../../domain/models/org_message.dart';
import '../../domain/models/organization.dart';
import '../../domain/models/organization_member.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepository(),
);

final organizationMemberRepositoryProvider =
    Provider<OrganizationMemberRepository>(
  (ref) => OrganizationMemberRepository(),
);

// ─── Organizations List ─────────────────────────────────────────────────
final organizationsProvider =
    AsyncNotifierProvider<OrganizationsNotifier, List<Organization>>(
  OrganizationsNotifier.new,
);

class OrganizationsNotifier extends AsyncNotifier<List<Organization>> {
  late OrganizationRepository _repo;

  @override
  Future<List<Organization>> build() async {
    // Watch auth state changes so switching user accounts automatically rebuilds this provider
    ref.watch(authStateProvider);

    _repo = ref.read(organizationRepositoryProvider);
    return _repo.getOrganizations();
  }

  Future<void> refresh() async {

    ref.invalidateSelf();
    await future;
  }

  Future<Organization?> create(String name, {String? description}) async {

    try {
      final org = await _repo.createOrganization(name, description: description);

      ref.invalidateSelf();
      await future;

      return org;
    } catch (e) {

      rethrow;
    }
  }

  Future<void> deleteOrganization(String id) async {

    try {
      await _repo.deleteOrganization(id);

      ref.invalidateSelf();
      await future;
    } catch (e) {

      rethrow;
    }
  }
}

// ─── Organization Detail ────────────────────────────────────────────────
final organizationDetailProvider =
    FutureProvider.family<Organization, String>((ref, orgId) {

  return ref.read(organizationRepositoryProvider).getOrganizationById(orgId);
});

final organizationMembersProvider = AsyncNotifierProvider.family<
    OrganizationMembersNotifier, List<OrganizationMember>, String>(
  OrganizationMembersNotifier.new,
);

class OrganizationMembersNotifier
    extends AsyncNotifier<List<OrganizationMember>> {
  OrganizationMembersNotifier(this._orgId);

  final String _orgId;
  late OrganizationMemberRepository _repo;

  @override
  Future<List<OrganizationMember>> build() async {

    _repo = ref.read(organizationMemberRepositoryProvider);
    return _repo.getMembers(_orgId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> addMember({
    required String userId,
    String role = 'member',
  }) async {

    await _repo.addMember(
      organizationId: _orgId,
      userId: userId,
      role: role,
    );
    ref.invalidateSelf();
    ref.invalidate(currentUserMemberProvider(_orgId));
    await future;
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {

    await _repo.updateMemberRole(memberId: memberId, role: role);
    ref.invalidateSelf();
    ref.invalidate(currentUserMemberProvider(_orgId));
    await future;
  }

  Future<void> removeMember(String memberId) async {

    await _repo.removeMember(memberId);
    ref.invalidateSelf();
    ref.invalidate(currentUserMemberProvider(_orgId));
    await future;
  }
}

final currentUserMemberProvider =
    FutureProvider.family<OrganizationMember?, String>((ref, orgId) {
  return ref
      .read(organizationMemberRepositoryProvider)
      .getCurrentUserMember(orgId);
});

// ─── Collaboration Providers ──────────────────────────────────────────────

final orgProjectsProvider =
    FutureProvider.family<List<KanbanProject>, String>((ref, orgId) {
  return ref.read(organizationRepositoryProvider).getProjects(orgId);
});

final orgTasksProvider =
    FutureProvider.family<List<KanbanTask>, String>((ref, orgId) {
  return ref.read(organizationRepositoryProvider).getTasks(orgId);
});

final orgMessagesStreamProvider =
    StreamProvider.family<List<OrgMessage>, String>((ref, orgId) {
  return ref.read(organizationRepositoryProvider).getMessagesStream(orgId);
});

final orgInvitesProvider =
    FutureProvider.family<List<OrgInvite>, String>((ref, orgId) {
  return ref.read(organizationRepositoryProvider).getInvites(orgId);
});
