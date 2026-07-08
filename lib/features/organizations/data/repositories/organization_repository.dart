import 'dart:developer' as dev;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization.dart';

class OrganizationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns all organizations the current user is a member of.
  Future<List<Organization>> getOrganizations() async {
    final user = _client.auth.currentUser!;
    dev.log('[OrganizationRepository] Fetching organizations for user: ${user.id}');

    try {
      // Get org IDs where user is member
      final memberships = await _client
          .from('organization_members')
          .select('organization_id')
          .eq('user_id', user.id);

      if (memberships.isEmpty) {
        dev.log('[OrganizationRepository] User has 0 memberships.');
        return [];
      }

      final orgIds = memberships
          .map<String>((m) => m['organization_id'] as String)
          .toList();

      dev.log('[OrganizationRepository] Found ${orgIds.length} organization memberships: $orgIds');

      final response = await _client
          .from('organizations')
          .select()
          .inFilter('id', orgIds)
          .order('created_at');

      final orgs = response
          .map<Organization>((json) => Organization.fromJson(json))
          .toList();

      dev.log('[OrganizationRepository] Loaded ${orgs.length} organizations successfully.');
      return orgs;
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
}
