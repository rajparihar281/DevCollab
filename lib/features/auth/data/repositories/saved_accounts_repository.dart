import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/saved_account.dart';

class SavedAccountsRepository {
  static const _kSavedAccountsKey = 'saved_accounts_metadata_v1';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _secureKeyForEmail(String email) =>
      'saved_acc_pwd_${email.toLowerCase()}';

  /// Returns all saved accounts sorted by most recent login.
  Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_kSavedAccountsKey);
    if (rawJson == null) return [];

    try {
      final List<dynamic> list = jsonDecode(rawJson) as List<dynamic>;
      final result = <SavedAccount>[];

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final email = map['email'] as String;
        final pwd = await _secureStorage.read(key: _secureKeyForEmail(email));
        if (pwd != null && pwd.isNotEmpty) {
          result.add(SavedAccount.fromJson(map, pwd));
        }
      }

      result.sort((a, b) => b.lastLoginAt.compareTo(a.lastLoginAt));
      return result;
    } catch (e, st) {
      dev.log('[SavedAccountsRepository] Error reading saved accounts: $e',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Saves or updates an account without overlapping other accounts.
  Future<void> saveAccount({
    required String email,
    required String password,
    required String fullName,
    String? avatarUrl,
  }) async {
    final lowerEmail = email.toLowerCase();
    dev.log('[SavedAccountsRepository] Saving account for $lowerEmail securely');

    // Save secure password inside encrypted keychain / secure storage
    await _secureStorage.write(
      key: _secureKeyForEmail(lowerEmail),
      value: password,
    );

    // Read current accounts and replace or append
    final current = await getSavedAccounts();
    final updated = current.where((a) => a.email.toLowerCase() != lowerEmail).toList();

    updated.insert(
      0,
      SavedAccount(
        email: lowerEmail,
        fullName: fullName,
        avatarUrl: avatarUrl,
        securePassword: password,
        lastLoginAt: DateTime.now(),
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    final jsonList = updated.map((a) => a.toJson()).toList();
    await prefs.setString(_kSavedAccountsKey, jsonEncode(jsonList));
  }

  /// Removes a saved account by email.
  Future<void> removeAccount(String email) async {
    final lowerEmail = email.toLowerCase();
    dev.log('[SavedAccountsRepository] Removing saved account: $lowerEmail');

    await _secureStorage.delete(key: _secureKeyForEmail(lowerEmail));

    final current = await getSavedAccounts();
    final updated =
        current.where((a) => a.email.toLowerCase() != lowerEmail).toList();

    final prefs = await SharedPreferences.getInstance();
    final jsonList = updated.map((a) => a.toJson()).toList();
    await prefs.setString(_kSavedAccountsKey, jsonEncode(jsonList));
  }
}
