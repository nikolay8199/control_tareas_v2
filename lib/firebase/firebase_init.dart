import 'dart:io';

import 'firebase_init_android.dart'
if (dart.library.html) 'firebase_init_ios.dart';

Future<void> initFirebasePlatform() async {
  if (Platform.isIOS) {
    return;
  } else {
    await initFirebase();
  }
}