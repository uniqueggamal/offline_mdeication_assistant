import 'package:flutter/material.dart';

import 'core/services/app_services.dart';
import 'ui/screens/home_screen.dart';
import 'ui/widgets/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final services = AppServices();
  await services.notifications.init();

  // MVP: offline-first local user id. Later replaced by Firebase Auth user uid.
  const userId = 'local_patient';

  runApp(
    AppScope(
      services: services,
      userId: userId,
      child: const OfflineMedicationAssistantApp(),
    ),
  );
}

class OfflineMedicationAssistantApp extends StatelessWidget {
  const OfflineMedicationAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Medication Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
