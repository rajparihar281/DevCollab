import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ChatMessage>> getMessages(String teamId, {int limit = 100}) async {
    final response = await _client
        .from('team_chat_messages')
        .select('*, profiles(full_name, avatar_url)')
        .eq('team_id', teamId)
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = response
        .map<ChatMessage>((json) => ChatMessage.fromJson(json))
        .toList();
    return messages.reversed.toList();
  }

  Future<ChatMessage> sendMessage({
    required String teamId,
    required String content,
  }) async {
    final user = _client.auth.currentUser!;

    final response = await _client
        .from('team_chat_messages')
        .insert({
          'team_id': teamId,
          'user_id': user.id,
          'content': content,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('*, profiles(full_name, avatar_url)')
        .single();

    return ChatMessage.fromJson(response);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String teamId) {
    return _client
        .from('team_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('team_id', teamId)
        .order('created_at');
  }
}
