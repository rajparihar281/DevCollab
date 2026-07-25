import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../auth/domain/models/profile.dart';
import '../../../auth/presentation/providers/profile_providers.dart';
import '../providers/organization_providers.dart';

class AddOrganizationMemberDialog extends ConsumerStatefulWidget {
  const AddOrganizationMemberDialog({
    super.key,
    required this.organizationId,
    required this.existingMemberIds,
  });

  final String organizationId;
  final Set<String> existingMemberIds;

  @override
  ConsumerState<AddOrganizationMemberDialog> createState() =>
      _AddOrganizationMemberDialogState();
}

class _AddOrganizationMemberDialogState
    extends ConsumerState<AddOrganizationMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Profile? _selectedProfile;
  String _selectedRole = 'member';
  bool _isSubmitting = false;

  final List<Map<String, String>> _roles = [
    {
      'value': 'admin',
      'label': 'Admin',
      'desc': 'Can manage teams, projects, and members',
    },
    {
      'value': 'member',
      'label': 'Member',
      'desc': 'Can create tasks, comment, and collaborate',
    },
    {
      'value': 'viewer',
      'label': 'Viewer',
      'desc': 'Read-only access to organization content',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedProfile == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(organizationMembersProvider(widget.organizationId).notifier)
          .addMember(
            userId: _selectedProfile!.id,
            role: _selectedRole,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedProfile!.fullName} as $_selectedRole',
            ),
            backgroundColor: context.colorSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: $e'),
            backgroundColor: context.colorError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(searchProfilesProvider(_searchQuery));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 480,
        constraints: BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colorBorder.withValues(alpha:0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colorPrimary.withValues(alpha:0.15),
                    context.colorSecondary.withValues(alpha:0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: context.colorBorder.withValues(alpha:0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colorPrimary.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: context.colorPrimary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Organization Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colorTextPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search for users and assign a collaborative role',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.colorTextSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search box
                    Text(
                      'Select User',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colorTextPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: context.colorTextPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: TextStyle(
                          color: context.colorTextMuted,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.colorTextSecondary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: context.colorTextSecondary,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedProfile = null;
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.colorBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.colorBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.colorBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colorPrimary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          if (_selectedProfile != null &&
                              !_selectedProfile!.fullName
                                  .toLowerCase()
                                  .contains(val.toLowerCase())) {
                            _selectedProfile = null;
                          }
                        });
                      },
                    ),

                    SizedBox(height: 12),

                    // User Results List
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: context.colorBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorBorder),
                      ),
                      child: profilesAsync.when(
                        data: (profiles) {
                          final availableProfiles = profiles
                              .where((p) => !widget.existingMemberIds
                                  .contains(p.id))
                              .toList();

                          if (availableProfiles.isEmpty) {
                            return Center(
                              child: Text(
                                'No users found or all users are already members.',
                                style: TextStyle(
                                  color: context.colorTextMuted,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: availableProfiles.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final profile = availableProfiles[index];
                              final isSelected =
                                  _selectedProfile?.id == profile.id;

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedProfile = profile;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? context.colorPrimary.withValues(alpha:0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: context.colorPrimary
                                                .withValues(alpha:0.5),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isSelected
                                            ? context.colorPrimary
                                            : context.colorSurfaceLight,
                                        child: Text(
                                          profile.fullName.isNotEmpty
                                              ? profile.fullName[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : context.colorTextPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile.fullName,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? context.colorPrimary
                                                    : context.colorTextPrimary,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: context.colorPrimary,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colorPrimary,
                          ),
                        ),
                        error: (err, _) => Center(
                          child: Text(
                            'Error loading users: $err',
                            style: TextStyle(
                              color: context.colorError,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Role Selection
                    Text(
                      'Assign Role',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colorTextPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._roles.map((role) {
                      final isSelected = _selectedRole == role['value'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRole = role['value']!;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? context.colorPrimary.withValues(alpha:0.1)
                                  : context.colorBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? context.colorPrimary
                                    : context.colorBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected
                                      ? context.colorPrimary
                                      : context.colorTextSecondary,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role['label']!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? context.colorPrimary
                                              : context.colorTextPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        role['desc']!,
                                        style: TextStyle(
                                          color: context.colorTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Footer / Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorBackground.withValues(alpha:0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.colorBorder.withValues(alpha:0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: context.colorTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: (_selectedProfile == null || _isSubmitting)
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colorPrimary,
                      foregroundColor: context.colorOnPrimary,
                      disabledBackgroundColor:
                          context.colorPrimary.withValues(alpha:0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Add Member',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
