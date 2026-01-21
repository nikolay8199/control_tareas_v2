import 'prioridad.dart';
import 'estado_tarea.dart';
import 'comentario.dart';

class Tarea {
  final int id;
  final String titulo;
  final String descripcion;

  /// Empresa a la que pertenece la tarea (UNA sola)
  final int empresaId;

  /// Usuarios asignados (UNO o VARIOS)
  final List<int> asignadoAIds;

  /// Usuario que creó la tarea (auditoría y permisos)
  final int creadoPorId;

  final DateTime creadaEn;

  DateTime? fechaLimite;
  DateTime? completadaEn;

  Prioridad prioridad;
  EstadoTarea estado;

  List<Comentario> comentarios;

  Tarea({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.empresaId,
    required this.asignadoAIds,
    required this.creadoPorId,
    DateTime? creadaEn,
    this.fechaLimite,
    this.completadaEn,
    this.prioridad = Prioridad.media,
    this.estado = EstadoTarea.sinIniciar,
    List<Comentario>? comentarios,
  })  : creadaEn = creadaEn ?? DateTime.now(),
        comentarios = comentarios ?? [];

  /// ─────────────────────────────
  /// Helpers de negocio
  /// ─────────────────────────────

  bool get estaVencida {
    if (fechaLimite == null) return false;
    if (estado == EstadoTarea.completada) return false;
    return DateTime.now().isAfter(fechaLimite!);
  }

  bool estaAsignadoA(int usuarioId) =>
      asignadoAIds.contains(usuarioId);
}