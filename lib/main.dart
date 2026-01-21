import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'screens/auth/login_screen.dart';
import 'services/remote_data_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final remote = RemoteDataService.instance;
  await remote.init();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(
    ChangeNotifierProvider.value(
      value: remote,
      child: const ControlTareasApp(),
    ),
  );
}

class ControlTareasApp extends StatelessWidget {
  const ControlTareasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Tareas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6EFD)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
