class RemoteMessage {
  final Map<String, dynamic> data;

  RemoteMessage({this.data = const {}});
}

class FirebaseMessaging {
  static void onBackgroundMessage(Function handler) {}

  static FirebaseMessaging get instance => FirebaseMessaging();

  Future<RemoteMessage?> getInitialMessage() async => null;

  /// Debe ser STATIC porque así lo usa tu código real
  static Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream.empty();
}

class Firebase {
  static Future<void> initializeApp() async {}
}