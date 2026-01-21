import '../models/comentario.dart';

class ComentarioMapper {
  static Map<String, dynamic> toJson(Comentario c) => {
    'userId': c.userId,
    'texto': c.texto,
    'fecha': c.fecha.toIso8601String(),
  };

  static Comentario fromJson(Map<String, dynamic> j) => Comentario(
    userId: j['userId'] as int,
    texto: (j['texto'] ?? '') as String,
    fecha: j['fecha'] == null ? null : DateTime.parse(j['fecha'] as String),
  );
}