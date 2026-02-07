import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static Future<void> init() async {
    print('🔔 NotificationService.init()');

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      print('🔐 Notification permission: $status');

      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    // 🔥 Obtener token explícitamente
    final token = await FirebaseMessaging.instance.getToken();
    print('🔥 FCM TOKEN (getToken): $token');

    // 🔁 Escuchar cuando el token se genera o cambia
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('♻️ FCM TOKEN REFRESHED: $newToken');
    });
  }
}