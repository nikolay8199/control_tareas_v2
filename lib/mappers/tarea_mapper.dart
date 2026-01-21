import '../models/tarea.dart';
import '../models/prioridad.dart';
import '../models/estado_tarea.dart';
import 'comentario_mapper.dart';

class TareaMapper {
  static Map<String, dynamic> toJson(Tarea t) => {
    'id': t.id,
    'titulo': t.titulo,
    'descripcion': t.descripcion,
    'empresaId': t.empresaId,
    'asignadoAIds': t.asignadoAIds,
    'creadoPorId': t.creadoPorId,
    'creadaEn': t.creadaEn.toIso8601String(),
    'fechaLimite': t.fechaLimite?.toIso8601String(),
    'completadaEn': t.completadaEn?.toIso8601String(),
    'prioridad': t.prioridad.name,
    'estado': t.estado.name,
    'comentarios': t.comentarios.map(ComentarioMapper.toJson).toList(),
  };

  static Tarea fromJson(Map<String, dynamic> j) => Tarea(
    id: j['id'] as int,
    titulo: (j['titulo'] ?? '') as String,
    descripcion: (j['descripcion'] ?? '') as String,
    empresaId: j['empresaId'] as int,
    asignadoAIds: List<int>.from((j['asignadoAIds'] ?? const []) as List),
    creadoPorId: j['creadoPorId'] as int,
    creadaEn: j['creadaEn'] == null
        ? DateTime.now()
        : DateTime.parse(j['creadaEn'] as String),
    fechaLimite: j['fechaLimite'] == null
        ? null
        : DateTime.parse(j['fechaLimite'] as String),
    completadaEn: j['completadaEn'] == null
        ? null
        : DateTime.parse(j['completadaEn'] as String),
    prioridad: Prioridad.values.byName((j['prioridad'] ?? 'media') as String),
    estado: EstadoTarea.values.byName((j['estado'] ?? 'sinIniciar') as String),
    comentarios: ((j['comentarios'] ?? const []) as List)
        .map((x) => ComentarioMapper.fromJson((x as Map).cast<String, dynamic>()))
        .toList(),
  );
}