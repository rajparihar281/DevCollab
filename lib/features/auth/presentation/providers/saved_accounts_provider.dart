import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/saved_accounts_repository.dart';
import '../../domain/models/saved_account.dart';

final savedAccountsRepositoryProvider = Provider<SavedAccountsRepository>((ref) {
  return SavedAccountsRepository();
});

final savedAccountsProvider =
    AsyncNotifierProvider<SavedAccountsNotifier, List<SavedAccount>>(
        SavedAccountsNotifier.new);

class SavedAccountsNotifier extends AsyncNotifier<List<SavedAccount>> {
  @override
  Future<List<SavedAccount>> build() async {
    final repo = ref.read(savedAccountsRepositoryProvider);
    return repo.getSavedAccounts();
  }

  Future<void> saveAccount({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
  }) async {
    final repo = ref.read(savedAccountsRepositoryProvider);
    await repo.saveAccount(
      email: email,
      password: password,
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeAccount(String email) async {
    final repo = ref.read(savedAccountsRepositoryProvider);
    await repo.removeAccount(email);
    ref.invalidateSelf();
    await future;
  }
}
