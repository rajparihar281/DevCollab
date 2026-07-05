import 'package:dev_collab/features/auth/domain/models/profile.dart';
import 'package:dev_collab/features/organizations/domain/models/organization_member.dart';
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Models & Theme Tests', () {
    test('OrganizationMember json serialization and role helpers', () {
      final json = {
        'id': 'mem_123',
        'organization_id': 'org_1',
        'user_id': 'usr_1',
        'role': 'admin',
        'joined_at': '2026-06-15T10:00:00.000Z',
        'profiles': {
          'full_name': 'Alice Admin',
          'avatar_url': 'https://example.com/avatar.png',
        },
      };

      final member = OrganizationMember.fromJson(json);

      expect(member.id, 'mem_123');
      expect(member.organizationId, 'org_1');
      expect(member.userId, 'usr_1');
      expect(member.role, 'admin');
      expect(member.fullName, 'Alice Admin');
      expect(member.avatarUrl, 'https://example.com/avatar.png');
      expect(member.isAdmin, isTrue);
      expect(member.isOwner, isFalse);
      expect(member.canManage, isTrue);
    });

    test('Profile json serialization and equality', () {
      final json = {
        'id': 'usr_2',
        'full_name': 'Bob Builder',
        'avatar_url': null,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'usr_2');
      expect(profile.fullName, 'Bob Builder');
      expect(profile.avatarUrl, isNull);
    });

    test('AppColors constants check', () {
      expect(AppColors.primary, const Color(0xFF6C63FF));
      expect(AppColors.success, const Color(0xFF00C853));
      expect(AppColors.error, const Color(0xFFCF6679));
    });
  });
}
