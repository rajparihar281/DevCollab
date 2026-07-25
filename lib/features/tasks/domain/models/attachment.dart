class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.uploadedBy,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    required this.uploadedAt,
    this.uploaderName,
  });

  final String id;
  final String taskId;
  final String uploadedBy;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final DateTime uploadedAt;
  final String? uploaderName;

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TaskAttachment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      uploaderName: profile?['full_name'] as String?,
    );
  }

  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
