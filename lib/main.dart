
import 'package:dev_collab/app/app.dart';
import 'package:dev_collab/core/supabase/supabase_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();





  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );



  final session = Supabase.instance.client.auth.currentSession;

  if (session != null) {

  }

  runApp(const ProviderScope(child: DevCollabApp()));

}
