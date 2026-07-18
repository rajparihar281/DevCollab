import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/kanban_project.dart';
import '../../domain/models/kanban_task.dart';
import '../../domain/models/org_invite.dart';
import '../../domain/models/org_message.dart';
import '../../domain/models/organization.dart';

class OrganizationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns all organizations the current user owns or is a member of.
  Future<List<Organization>> getOrganizations() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      dev.log('[OrganizationRepository] No current auth user logged in. Returning empty organizations list.');
      return [];
    }
    dev.log('[OrganizationRepository] Fetching organizations for user: ${user.id}');

    try {
      // Get org IDs where user is member
      final memberships = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', user.id);

      final memberOrgIds = memberships
          .map<String>((m) => m['organization_id'] as String)
          .toSet();

      // Fetch organizations owned by user OR where user is a member
      final response = await _client
          .from('organizations')
          .select()
          .order('created_at');

      final allOrgs = response
          .map<Organization>((json) => Organization.fromJson(json))
          .toList();

      // Strictly filter to ensure user is either the owner or an explicit member
      final myOrgs = allOrgs.where((org) {
        return org.ownerId == user.id || memberOrgIds.contains(org.id);
      }).toList();

      dev.log('[OrganizationRepository] Loaded ${myOrgs.length} organizations strictly belonging to user ${user.id}.');
      return myOrgs;
    } catch (e, st) {
      dev.log('[OrganizationRepository] Error fetching organizations: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Organization> getOrganizationById(String id) async {
    dev.log('[OrganizationRepository] Fetching organization by ID: $id');
    try {
      final response = await _client
          .from('organizations')
          .select()
          .eq('id', id)
          .single();
      return Organization.fromJson(response);
    } catch (e, st) {
      dev.log('[OrganizationRepository] Error fetching organization $id: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<Organization> createOrganization(String name, {String? description}) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

    dev.log('[OrganizationRepository] Creating organization "$name" by user ${user.id}');

    try {
      final response = await _client
          .from('organizations')
          .insert({
            'name': name,
            'description': description,
            'owner_id': user.id,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final org = Organization.fromJson(response);
      dev.log('[OrganizationRepository] Organization inserted: ID=${org.id}. Ensuring owner membership via upsert...');

      // Auto-add creator as owner member (upsert avoids conflict with DB trigger)
      await _client.from('organization_members').upsert({
        'organization_id': org.id,
        'user_id': user.id,
        'role': 'owner',
        'joined_at': now,
      }, onConflict: 'organization_id, user_id');

      dev.log('[OrganizationRepository] Organization created and membership ensured successfully: ${org.name}');
      return org;
    } catch (e, st) {
      dev.log('[OrganizationRepository] ERROR creating organization "$name": $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateOrganization(
    String id, {
    String? name,
    String? description,
  }) async {
    dev.log('[OrganizationRepository] Updating organization $id');
    try {
      final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;

      await _client.from('organizations').update(updates).eq('id', id);
      dev.log('[OrganizationRepository] Updated organization $id successfully.');
    } catch (e, st) {
      dev.log('[OrganizationRepository] Error updating organization $id: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteOrganization(String organizationId) async {
    dev.log('[OrganizationRepository] Deleting organization $organizationId');
    try {
      await _client.from('organizations').delete().eq('id', organizationId);
      dev.log('[OrganizationRepository] Deleted organization $organizationId successfully.');
    } catch (e, st) {
      dev.log('[OrganizationRepository] Error deleting organization $organizationId: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ==========================================
  // KANBAN BOARD: PROJECTS & TASKS
  // ==========================================
  Future<List<KanbanProject>> getProjects(String orgId) async {
    final res = await _client
        .from('projects')
        .select()
        .eq('org_id', orgId)
        .order('created_at');
    return res.map<KanbanProject>((j) => KanbanProject.fromJson(j)).toList();
  }

  Future<KanbanProject> createProject(
      String orgId, String title, [String? description]) async {
    final user = _client.auth.currentUser;
    final res = await _client
        .from('projects')
        .insert({
          'org_id': orgId,
          'title': title,
          'description': ?description,
          'created_by': user?.id,
        })
        .select()
        .single();
    return KanbanProject.fromJson(res);
  }

  Future<List<KanbanTask>> getTasks(String orgId) async {
    final res = await _client
        .from('tasks')
        .select()
        .eq('org_id', orgId)
        .order('created_at');
    return res.map<KanbanTask>((j) => KanbanTask.fromJson(j)).toList();
  }

  Future<KanbanTask> createTask({
    required String orgId,
    String? projectId,
    required String title,
    String? description,
    required String status,
    required String priority,
    String? assigneeId,
    String? assigneeName,
    String? assigneeAvatar,
    List<String>? assigneeUserIds,
    List<String>? assigneeTeamIds,
    DateTime? dueDate,
  }) async {
    final user = _client.auth.currentUser;
    final res = await _client
        .from('tasks')
        .insert({
          'org_id': orgId,
          'project_id': ?projectId,
          'title': title,
          'description': ?description,
          'status': status,
          'priority': priority,
          'assignee_id': ?assigneeId,
          'assignee_name': ?assigneeName,
          'assignee_avatar': ?assigneeAvatar,
          'due_date': ?(dueDate?.toIso8601String().substring(0, 10)),
          'created_by': user?.id,
        })
        .select()
        .single();
    
    final task = KanbanTask.fromJson(res);

    // Insert multiple assignees if provided
    if (assigneeUserIds != null || assigneeTeamIds != null) {
      final List<Map<String, dynamic>> assigneesToInsert = [];
      if (assigneeUserIds != null) {
        for (var uid in assigneeUserIds) {
          assigneesToInsert.add({'task_id': task.id, 'user_id': uid});
        }
      }
      if (assigneeTeamIds != null) {
        for (var tid in assigneeTeamIds) {
          assigneesToInsert.add({'task_id': task.id, 'team_id': tid});
        }
      }
      if (assigneesToInsert.isNotEmpty) {
        try {
          await _client.from('task_assignees').insert(assigneesToInsert);
        } catch (_) {} // Ignore if table doesn't exist yet
      }
    }

    return task;
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _client.from('tasks').update({'status': newStatus}).eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  // ==========================================
  // REAL-TIME TEAM CHAT & ANNOUNCEMENTS
  // ==========================================
  Stream<List<OrgMessage>> getMessagesStream(String orgId) {
    return _client
        .from('org_messages')
        .stream(primaryKey: ['id'])
        .eq('org_id', orgId)
        .order('created_at')
        .map((rows) => rows.map<OrgMessage>((r) => OrgMessage.fromJson(r)).toList());
  }

  Future<OrgMessage> sendMessage({
    required String orgId,
    required String content,
    bool isAnnouncement = false,
  }) async {
    final user = _client.auth.currentUser;
    final res = await _client
        .from('org_messages')
        .insert({
          'org_id': orgId,
          'user_id': user?.id,
          'user_name': user?.userMetadata?['full_name'] ??
              user?.email?.split('@').first ??
              'Developer',
          'content': content,
          'is_announcement': isAnnouncement,
        })
        .select()
        .single();
    return OrgMessage.fromJson(res);
  }

  // ==========================================
  // INVITES & JOIN CODES
  // ==========================================
  Future<OrgInvite> createInviteCode({
    required String orgId,
    required String inviteCode,
    String role = 'member',
  }) async {
    final user = _client.auth.currentUser;
    final res = await _client
        .from('org_invites')
        .insert({
          'org_id': orgId,
          'invite_code': inviteCode,
          'role': role,
          'created_by': user?.id,
        })
        .select()
        .single();
    return OrgInvite.fromJson(res);
  }

  Future<List<OrgInvite>> getInvites(String orgId) async {
    final res = await _client
        .from('org_invites')
        .select()
        .eq('org_id', orgId)
        .order('created_at', ascending: false);
    return res.map<OrgInvite>((j) => OrgInvite.fromJson(j)).toList();
  }

  Future<String> joinOrgWithCode(String code) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to join');

    final inviteRow = await _client
        .from('org_invites')
        .select()
        .eq('invite_code', code.trim().toUpperCase())
        .maybeSingle();

    if (inviteRow == null) {
      throw Exception('Invalid invite code "$code". Please verify with your team leader.');
    }

    final orgId = inviteRow['org_id'] as String;
    final role = inviteRow['role'] as String? ?? 'member';

    // Insert into organization_members
    await _client.from('organization_members').upsert({
      'organization_id': orgId,
      'user_id': user.id,
      'role': role,
    });

    return orgId;
  }

  Future<void> deleteInviteCode(String inviteId) async {
    await _client.from('org_invites').delete().eq('id', inviteId);
  }
}
