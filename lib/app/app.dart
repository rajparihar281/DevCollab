import 'package:dev_collab/features/auth/presentation/pages/auth_gate.dart';
import 'package:flutter/material.dart';

class DevCollabApp extends StatelessWidget {
  const DevCollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevCollab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
