import 'package:flutter/material.dart';

import 'src/app_controller.dart';
import 'src/data/local_store.dart';
import 'src/data/record_repository.dart';
import 'src/data/remote_api.dart';
import 'src/home_page.dart';
import 'src/sync/sync_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = LocalStore();
  final repository = RecordRepository(localStore: localStore);
  final remoteApi = MockRemoteApi(failureEvery: 4);
  final syncEngine = SyncEngine(localStore: localStore, remoteApi: remoteApi);
  final controller = AppController(repository: repository, syncEngine: syncEngine);
  await controller.initialize();

  runApp(OfflineSyncApp(controller: controller));
}

class OfflineSyncApp extends StatelessWidget {
  const OfflineSyncApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Offline Sync Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF28C76F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: HomePage(controller: controller),
    );
  }
}
