class Comentario {
  final int userId;
  final String texto;
  final String? imagen;
  final String tipo;
  final DateTime fecha;

  Comentario({
    required this.userId,
    required this.texto,
    this.imagen,
    this.tipo = 'texto',
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}