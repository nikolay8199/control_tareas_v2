import 'dart:io';

import '../notifications/notification_service_ios.dart' as ios;
import '../notifications/notification_service_android.dart' as android;


class NotificationService {
  static Future<void> init() async {
    if (Platform.isIOS) {
      await ios.NotificationService.init();
    } else {
      await android.NotificationService.init();
    }
  }
}