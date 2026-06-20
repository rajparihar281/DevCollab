import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/organization_repository.dart';
import '../../domain/models/organization.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>(
  (ref) => OrganizationRepository(),
);

final organizationsProvider =
    AsyncNotifierProvider<OrganizationsNotifier, List<Organization>>(
      OrganizationsNotifier.new,
    );

class OrganizationsNotifier extends AsyncNotifier<List<Organization>> {
  late final OrganizationRepository _repository;

  @override
  Future<List<Organization>> build() async {
    _repository = ref.read(organizationRepositoryProvider);

    return _repository.getOrganizations();
  }

  Future<void> refreshOrganizations() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _repository.getOrganizations());
  }

  Future<void> createOrganization(String name) async {
    await _repository.createOrganization(name);

    await refreshOrganizations();
  }

  Future<void> deleteOrganization(String organizationId) async {
    await _repository.deleteOrganization(organizationId);

    await refreshOrganizations();
  }
}
