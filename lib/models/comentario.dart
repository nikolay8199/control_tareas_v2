class Comentario {
  final int userId;
  final String texto;
  final DateTime fecha;

  Comentario({
    required this.userId,
    required this.texto,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}