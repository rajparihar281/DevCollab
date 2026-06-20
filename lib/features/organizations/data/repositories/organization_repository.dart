import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/organization.dart';

class OrganizationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Organization>> getOrganizations() async {
    final response = await _client
        .from('organizations')
        .select()
        .order('created_at');

    return response
        .map<Organization>((json) => Organization.fromJson(json))
        .toList();
  }

  Future<Organization> createOrganization(String name) async {
    final user = _client.auth.currentUser!;

    final response = await _client
        .from('organizations')
        .insert({'name': name, 'owner_id': user.id})
        .select()
        .single();

    return Organization.fromJson(response);
  }

  Future<void> deleteOrganization(String organizationId) async {
    await _client.from('organizations').delete().eq('id', organizationId);
  }
}
