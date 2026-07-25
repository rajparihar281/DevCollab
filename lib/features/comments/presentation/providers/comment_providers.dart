import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/comment_repository.dart';
import '../../domain/models/comment.dart';

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(),
);

final commentsProvider = StreamNotifierProvider.family<CommentsNotifier, List<Comment>, String>(
  CommentsNotifier.new,
);

class CommentsNotifier extends StreamNotifier<List<Comment>> {
  CommentsNotifier(this._taskId);

  final String _taskId;
  late CommentRepository _repo;

  @override
  Stream<List<Comment>> build() {
    _repo = ref.read(commentRepositoryProvider);
    return _repo.watchComments(_taskId).map(
          (rows) => rows.map((json) => Comment.fromJson(json)).toList(),
        );
  }

  Future<void> addComment(String content) async {
    await _repo.createComment(taskId: _taskId, content: content);
  }

  Future<void> deleteComment(String commentId) async {
    await _repo.deleteComment(commentId);
  }
}
