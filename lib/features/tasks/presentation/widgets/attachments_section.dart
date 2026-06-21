import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attachment.dart';
import '../providers/task_providers.dart';

class AttachmentsSection extends ConsumerWidget {
  const AttachmentsSection({
    super.key,
    required this.taskId,
    required this.organizationId,
    required this.projectId,
  });

  final String taskId;
  final String organizationId;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(attachmentsProvider(taskId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
          child: Row(
            children: [
              Text(
                'Attachments',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _uploadFile(context, ref),
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Upload'),
              ),
            ],
          ),
        ),
        attachmentsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e',
              style: TextStyle(color: theme.colorScheme.error)),
          data: (attachments) => attachments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No attachments yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : Column(
                  children:
                      attachments.map((a) => _AttachmentTile(a)).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _uploadFile(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    try {
      await ref.read(attachmentRepositoryProvider).uploadAttachment(
            taskId: taskId,
            organizationId: organizationId,
            projectId: projectId,
            file: file,
            fileName: fileName,
          );
      ref.invalidate(attachmentsProvider(taskId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile(this.attachment);
  final TaskAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _fileIcon(attachment.fileName),
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        attachment.fileName,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        attachment.fileSizeLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        onPressed: () => _openFile(context, attachment),
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(ext)) return Icons.description_rounded;
    if (['mp4', 'mov', 'avi'].contains(ext)) return Icons.video_file_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _openFile(BuildContext context, TaskAttachment a) async {
    try {
      // Download to temp and open
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${a.fileName}');
      // Use Supabase to download bytes
      final bytes = await Supabase.instance.client.storage
          .from('attachments')
          .download(a.filePath);
      await tempFile.writeAsBytes(bytes);
      await OpenFilex.open(tempFile.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e')),
        );
      }
    }
  }
}
