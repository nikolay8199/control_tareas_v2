import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 Firebase condicional (Android real / iOS stub)
import 'firebase_stub.dart'
if (dart.library.io) 'package:firebase_core/firebase_core.dart';

import 'firebase_stub.dart'
if (dart.library.io) 'package:firebase_messaging/firebase_messaging.dart';

import 'services/notification_service.dart';
import 'services/notification_intent_store.dart';
import 'services/notification_intent.dart';

import 'models/usuario.dart';
import 'models/rol.dart';
import 'screens/admin/admin_home.dart';
import 'screens/supervisor/supervisor_home.dart';
import 'screens/worker/worker_home.dart';
import 'screens/auth/login_screen.dart';
import 'services/remote_data_service.dart';

import 'dart:io';

/// 🔔 Handler para notificaciones en background / terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase SOLO si NO es iOS
  if (!Platform.isIOS) {
    await Firebase.initializeApp();

    // 🔔 Registrar handler background
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 1️⃣ App abierta desde notificación (cerrada)
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      NotificationIntentStore.pending =
          NotificationIntent.fromData(initialMessage.data);
    }

    // 2️⃣ App abierta desde background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationIntentStore.pending =
          NotificationIntent.fromData(message.data);
    });

    // 🔔 Inicializar permisos + token
    await NotificationService.init();
  }

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

Future<Usuario?> recuperarSesion() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');

  if (userId == null) return null;

  final data = RemoteDataService.instance;

  try {
    return data.usuarios.firstWhere((u) => u.id == userId);
  } catch (_) {
    return null;
  }
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
      home: FutureBuilder<Usuario?>(
        future: recuperarSesion(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }

          final user = snapshot.data!;

          // 🧭 Consumir intención DESPUÉS del login
          final intent = NotificationIntentStore.pending;
          if (intent != null) {
            NotificationIntentStore.pending = null;

            if (intent.tipo == 'tarea' && intent.tareaId != null) {
              debugPrint('➡️ Intención: abrir tarea ${intent.tareaId}');
              // navegación real vendrá después
            }
          }

          switch (user.rol) {
            case Rol.admin:
              return AdminHome(user: user);
            case Rol.supervisor:
              return SupervisorHome(user: user);
            case Rol.trabajador:
              return WorkerHome(user: user);
          }
        },
      ),
    );
  }
}
