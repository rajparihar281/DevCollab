import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/themes/app_colors.dart';
import '../../../organizations/domain/models/organization_member.dart';
import '../../../organizations/presentation/providers/organization_providers.dart';
import '../providers/team_providers.dart';

class AddTeamMemberDialog extends ConsumerStatefulWidget {
  const AddTeamMemberDialog({
    super.key,
    required this.organizationId,
    required this.teamId,
    required this.existingTeamMemberUserIds,
  });

  final String organizationId;
  final String teamId;
  final Set<String> existingTeamMemberUserIds;

  @override
  ConsumerState<AddTeamMemberDialog> createState() =>
      _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends ConsumerState<AddTeamMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrganizationMember? _selectedMember;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedMember == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(teamMembersProvider(widget.teamId).notifier)
          .addMember(_selectedMember!.userId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${_selectedMember!.fullName ?? 'Member'} to the team!',
            ),
            backgroundColor: context.colorSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add team member: $e'),
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
    final orgMembersAsync =
        ref.watch(organizationMembersProvider(widget.organizationId));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 480,
        constraints: BoxConstraints(maxHeight: 550),
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
                      Icons.group_add_rounded,
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
                          'Add Team Member',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colorTextPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select an organization colleague to add to this team',
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
                      'Search Organization Members',
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
                        hintText: 'Search by name or role...',
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
                                    _selectedMember = null;
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
                          if (_selectedMember != null &&
                              !(_selectedMember!.fullName ?? '')
                                  .toLowerCase()
                                  .contains(val.toLowerCase())) {
                            _selectedMember = null;
                          }
                        });
                      },
                    ),

                    SizedBox(height: 16),

                    // Members list
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: context.colorBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colorBorder),
                      ),
                      child: orgMembersAsync.when(
                        data: (members) {
                          final availableMembers = members
                              .where((m) => !widget.existingTeamMemberUserIds
                                  .contains(m.userId))
                              .where((m) =>
                                  _searchQuery.isEmpty ||
                                  (m.fullName ?? '')
                                      .toLowerCase()
                                      .contains(_searchQuery.toLowerCase()))
                              .toList();

                          if (availableMembers.isEmpty) {
                            return Center(
                              child: Text(
                                'No available organization members found.',
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
                            itemCount: availableMembers.length,
                            separatorBuilder: (_, _) =>
                                SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final member = availableMembers[index];
                              final isSelected =
                                  _selectedMember?.userId == member.userId;
                              final name = member.fullName?.isNotEmpty == true
                                  ? member.fullName!
                                  : 'Unknown Member';

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedMember = member;
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
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
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
                                              name,
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
                                            Text(
                                              'Org Role: ${member.role.toUpperCase()}',
                                              style: TextStyle(
                                                color: context.colorTextMuted,
                                                fontSize: 11,
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
                            'Error loading members: $err',
                            style: TextStyle(
                              color: context.colorError,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
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
                    onPressed: (_selectedMember == null || _isSubmitting)
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
                            'Add to Team',
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
