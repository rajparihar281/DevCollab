import 'dart:io';

import 'package:dev_collab/features/auth/domain/models/profile.dart';
import 'package:dev_collab/features/auth/presentation/providers/user_profile_provider.dart';
import 'package:dev_collab/features/profile/presentation/pages/avatar_editor_screen.dart';
import 'package:dev_collab/routing/route_names.dart';
import 'package:dev_collab/shared/themes/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _teamInputController;

  DateTime? _selectedDob;
  List<String> _teams = [];
  bool _initialized = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  void _showAvatarActionSheet(Profile? profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasPhoto = profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: context.colorPrimary ),
                title: Text('Choose Photo & Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickEditAndUploadAvatar();
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: context.colorError ),
                  title: Text(
                    'Remove Current Photo',
                    style: TextStyle(color: context.colorError),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeAvatar();
                  },
                ),
              SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploadingAvatar = true);
    try {
      await ref.read(userProfileProvider.notifier).deleteAvatar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture removed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) { /* ignored */ } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickEditAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.single.path == null) return;

      final originalFile = File(result.files.single.path!);

      if (!mounted) return;
      final editedFile = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => AvatarEditorScreen(imageFile: originalFile),
        ),
      );

      if (editedFile == null) return;

      setState(() => _uploadingAvatar = true);
      final newUrl =
          await ref.read(userProfileProvider.notifier).uploadAvatar(editedFile);

      if (mounted && newUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: context.colorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {

      final errStr = e.toString();
      if ((errStr.contains('403') ||
              errStr.contains('row-level security') ||
              errStr.contains('Unauthorized')) &&
          mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Storage Policy Required'),
              ],
            ),
            content: Text(
              'Your "profile pics" bucket is protected by Supabase Row-Level Security (RLS).\n\nPlease execute the SQL script in your Supabase SQL Editor to allow image uploads:\n\nsupabase/migrations/20260710000002_add_storage_bucket_policies.sql',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('OK, Got It'),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: context.colorError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _jobTitleController = TextEditingController();
    _companyController = TextEditingController();
    _teamInputController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _teamInputController.dispose();
    super.dispose();
  }

  void _populateFromProfile(Profile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.fullName;
    _usernameController.text = profile.username ?? '';
    _bioController.text = profile.bio ?? '';
    _jobTitleController.text = profile.jobTitle ?? '';
    _companyController.text = profile.currentCompany ?? '';
    _selectedDob = profile.dob;
    _teams = List.from(profile.teams);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (date != null) {
      setState(() => _selectedDob = date);
    }
  }

  void _addTeam() {
    final text = _teamInputController.text.trim();
    if (text.isNotEmpty && !_teams.contains(text)) {
      setState(() {
        _teams.add(text);
        _teamInputController.clear();
      });
    }
  }

  void _removeTeam(String team) {
    setState(() => _teams.remove(team));
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final updates = {
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'job_title': _jobTitleController.text.trim(),
        'current_company': _companyController.text.trim(),
        'dob': _selectedDob?.toIso8601String().split('T').first,
        'teams': _teams,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await ref.read(userProfileProvider.notifier).updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: context.colorSuccess,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {

      final errorStr = e.toString();
      if (errorStr.contains('PGRST204') || errorStr.contains('Could not find the')) {
        try {
          // Fallback update for basic fields if extended columns aren't migrated yet
          await ref.read(userProfileProvider.notifier).updateProfile({
            'full_name': _nameController.text.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) { /* ignored */ }

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Database Migration Required'),
                ],
              ),
              content: Text(
                'Basic profile name saved!\n\nTo save bio, username, teams, and notification settings, please execute the SQL migration file in your Supabase SQL Editor:\n\nsupabase/migrations/20260710000001_add_profile_extended_and_notification_fields.sql',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('OK, Got It'),
                ),
              ],
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: context.colorError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active_outlined),
            tooltip: 'Notification & Email Preferences',
            onPressed: () => context.push(RouteNames.notificationPreferences),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (profile) {
          if (profile != null) _populateFromProfile(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  Center(
                    child: GestureDetector(
                      onTap: _uploadingAvatar
                          ? null
                          : () => _showAvatarActionSheet(profile),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: profile?.avatarUrl != null &&
                                    profile!.avatarUrl!.isNotEmpty
                                ? NetworkImage(profile.avatarUrl!)
                                : null,
                            child: _uploadingAvatar
                                ? CircularProgressIndicator(
                                    color: Colors.white)
                                : (profile?.avatarUrl == null ||
                                        profile!.avatarUrl!.isEmpty)
                                    ? Text(
                                        (_nameController.text.isNotEmpty
                                                ? _nameController.text
                                                : 'U')[0]
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 28),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Name is required'
                        : null,
                  ),
                  SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell your team about yourself...',
                      prefixIcon: Icon(Icons.info_outline_rounded),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Date of Birth
                  InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        _selectedDob != null
                            ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
                            : 'Select date of birth',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Job Title / Description
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: InputDecoration(
                      labelText: 'Job Description / Title',
                      prefixIcon: Icon(Icons.work_outline_rounded),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Current Company
                  TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      labelText: 'Current Company',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  SizedBox(height: 28),

                  // Private Teams Section (Visible only to owner)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'My Current Teams (Private)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Only you can see this list of internal teams.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _teams.map((t) {
                            return Chip(
                              label: Text(t),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () => _removeTeam(t),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _teamInputController,
                                decoration: InputDecoration(
                                  hintText: 'Add team (e.g. Core Infra)',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                                onSubmitted: (_) => _addTeam(),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _addTeam,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                              ),
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Save Changes'),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
