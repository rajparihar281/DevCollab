import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository.dart';
import '../../domain/models/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

final chatProvider = StreamNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
  ChatNotifier.new,
);

class ChatNotifier extends StreamNotifier<List<ChatMessage>> {
  ChatNotifier(this._teamId);

  final String _teamId;
  late ChatRepository _repo;

  @override
  Stream<List<ChatMessage>> build() {
    _repo = ref.read(chatRepositoryProvider);
    return _repo.watchMessages(_teamId).map(
          (rows) => rows.map((json) => ChatMessage.fromJson(json)).toList(),
        );
  }

  Future<void> sendMessage(String content) async {
    await _repo.sendMessage(teamId: _teamId, content: content);
  }
}
