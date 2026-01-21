import 'prioridad.dart';
import 'estado_tarea.dart';
import 'tarea.dart';

class TaskFilter {
  int? empresaId;
  int? usuarioId;
  Prioridad? prioridad;
  EstadoTarea? estado;

  TaskFilter({
    this.empresaId,
    this.usuarioId,
    this.prioridad,
    this.estado,
  });

  void clear() {
    empresaId = null;
    usuarioId = null;
    prioridad = null;
    estado = null;
  }

  bool matches(Tarea t) {
    if (empresaId != null && t.empresaId != empresaId) {
      return false;
    }

    /// 🔥 ahora es multi-asignación
    if (usuarioId != null && !t.asignadoAIds.contains(usuarioId)) {
      return false;
    }

    if (prioridad != null && t.prioridad != prioridad) {
      return false;
    }

    if (estado != null && t.estado != estado) {
      return false;
    }

    return true;
  }
}