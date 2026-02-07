class NotificationIntent {
  final String tipo;
  final String? tareaId;

  NotificationIntent({
    required this.tipo,
    this.tareaId,
  });

  factory NotificationIntent.fromData(Map<String, dynamic> data) {
    return NotificationIntent(
      tipo: data['tipo'] ?? '',
      tareaId: data['tareaId'],
    );
  }
}