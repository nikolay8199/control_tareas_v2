import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../models/estado_tarea.dart';
import '../../models/prioridad.dart';
import '../../services/remote_data_service.dart';
import 'task_chat_screen.dart';

class WorkerTaskDetail extends StatefulWidget {
  final Tarea tarea;
  final Usuario user;

  const WorkerTaskDetail({
    super.key,
    required this.tarea,
    required this.user,
  });

  @override
  State<WorkerTaskDetail> createState() => _WorkerTaskDetailState();
}

class _WorkerTaskDetailState extends State<WorkerTaskDetail> {
  final data = RemoteDataService.instance;

  void _cambiarEstado() {
    setState(() {
      if (widget.tarea.estado == EstadoTarea.sinIniciar) {
        widget.tarea.estado = EstadoTarea.enProceso;
      } else if (widget.tarea.estado == EstadoTarea.enProceso) {
        widget.tarea.estado = EstadoTarea.completada;
        widget.tarea.completadaEn = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tarea;
    final estaVencida = t.estaVencida;

    // 🔥 USUARIO CREADOR
    final creador = data.usuarios
        .where((u) => u.id == t.creadoPorId)
        .cast<Usuario?>()
        .firstWhere(
          (u) => u != null,
      orElse: () => null,
    );

    final nombreCreador = creador?.username ?? "Usuario eliminado";
    final soyCreador = widget.user.id == t.creadoPorId;

    return Scaffold(
      appBar: AppBar(title: Text(t.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Descripción:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(t.descripcion),
            const SizedBox(height: 20),

            Text("Creada por: $nombreCreador"), // ✅ NUEVO
            Text("Prioridad: ${_prioridad(t.prioridad)}"),
            Text("Estado: ${_estado(t.estado)}"),
            Text("Creada en: ${_fecha(t.creadaEn)}"),
            Text("Fecha límite: ${_fecha(t.fechaLimite)}"),
            if (t.completadaEn != null)
              Text("Completada en: ${_fecha(t.completadaEn)}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: (t.estado == EstadoTarea.completada || estaVencida)
                  ? null
                  : _cambiarEstado,
              child: Text(_textoBoton(t.estado)),
            ),

            if (estaVencida)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "⚠ Esta tarea está vencida. Contacta al administrador.",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskChatScreen(
                      tarea: t,
                      user: widget.user,
                    ),
                  ),
                );
                setState(() {}); // refresca mensajes
              },
              child: const Text("Comentarios"),
            ),
            if (soyCreador)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text("Eliminar tarea"),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Eliminar tarea"),
                        content: const Text(
                          "¿Estás seguro de que deseas eliminar esta tarea?\n\n"
                              "Esta acción no se puede deshacer.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Eliminar"),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      data.eliminarTarea(t.id);
                      Navigator.pop(context); // salir del detalle
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  String _fecha(DateTime? f) {
    if (f == null) return "Sin fecha";
    return "${f.day}/${f.month}/${f.year}";
  }

  String _prioridad(Prioridad p) {
    return {
      Prioridad.alta: "Alta",
      Prioridad.media: "Media",
      Prioridad.baja: "Baja"
    }[p]!;
  }

  String _estado(EstadoTarea e) {
    return {
      EstadoTarea.sinIniciar: "Sin iniciar",
      EstadoTarea.enProceso: "En proceso",
      EstadoTarea.completada: "Completada",
    }[e]!;
  }

  String _textoBoton(EstadoTarea e) {
    return {
      EstadoTarea.sinIniciar: "Marcar como En proceso",
      EstadoTarea.enProceso: "Marcar como Completada",
      EstadoTarea.completada: "Ya completada",
    }[e]!;
  }
}