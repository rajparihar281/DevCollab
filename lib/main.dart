import 'dart:developer';

import 'package:dev_collab/app/app.dart';
import 'package:dev_collab/core/supabase/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log('[main] Initializing Supabase...');
  log('[main] URL: ${SupabaseConfig.url}');
  log('[main] AnonKey length: ${SupabaseConfig.anonKey.length}');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  log('[main] Supabase initialized successfully');

  final session = Supabase.instance.client.auth.currentSession;
  log('[main] Existing session: ${session != null ? "EXISTS" : "NULL"}');
  if (session != null) {
    log('[main] Existing user: ${session.user.email}');
  }

  runApp(const ProviderScope(child: DevCollabApp()));
  log('[main] App started');
}
