import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization.dart';

class OrganizationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Returns all organizations the current user is a member of.
  Future<List<Organization>> getOrganizations() async {
    final user = _client.auth.currentUser!;

    // Get org IDs where user is member
    final memberships = await _client
        .from('organization_members')
        .select('organization_id')
        .eq('user_id', user.id);

    if (memberships.isEmpty) return [];

    final orgIds = memberships
        .map<String>((m) => m['organization_id'] as String)
        .toList();

    final response = await _client
        .from('organizations')
        .select()
        .inFilter('id', orgIds)
        .order('created_at');

    return response
        .map<Organization>((json) => Organization.fromJson(json))
        .toList();
  }

  Future<Organization> getOrganizationById(String id) async {
    final response = await _client
        .from('organizations')
        .select()
        .eq('id', id)
        .single();
    return Organization.fromJson(response);
  }

  Future<Organization> createOrganization(String name, {String? description}) async {
    final user = _client.auth.currentUser!;
    final now = DateTime.now().toIso8601String();

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

    // Auto-add creator as owner member
    await _client.from('organization_members').insert({
      'organization_id': org.id,
      'user_id': user.id,
      'role': 'owner',
      'joined_at': now,
    });

    return org;
  }

  Future<void> updateOrganization(
    String id, {
    String? name,
    String? description,
  }) async {
    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await _client.from('organizations').update(updates).eq('id', id);
  }

  Future<void> deleteOrganization(String organizationId) async {
    await _client.from('organizations').delete().eq('id', organizationId);
  }
}
