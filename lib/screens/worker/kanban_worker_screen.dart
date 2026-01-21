import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/estado_tarea.dart';
import '../../models/prioridad.dart';
import '../../models/usuario.dart';
import '../../services/remote_data_service.dart';
import 'worker_task_detail.dart';

class KanbanWorkerScreen extends StatelessWidget {
  final Usuario user;

  KanbanWorkerScreen({
    super.key,
    required this.user,
  });

  final data = RemoteDataService.instance;

  @override
  Widget build(BuildContext context) {
    final tareas = data.tareasPorUsuario(user.id);

    final sinIniciar =
    tareas.where((t) => t.estado == EstadoTarea.sinIniciar).toList();
    final enProceso =
    tareas.where((t) => t.estado == EstadoTarea.enProceso).toList();
    final completadas =
    tareas.where((t) => t.estado == EstadoTarea.completada).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kanban"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _columna(context, "Sin iniciar", sinIniciar),
            _columna(context, "En proceso", enProceso),
            _columna(context, "Completadas", completadas),
          ],
        ),
      ),
    );
  }

  Widget _columna(
      BuildContext context,
      String titulo,
      List<Tarea> tareas,
      ) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              "$titulo (${tareas.length})",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (_, i) {
                final t = tareas[i];
                return _tarjetaTarea(context, t);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTarea(BuildContext context, Tarea t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(
          t.titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.estaVencida ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          "Prioridad: ${_prioridadTexto(t.prioridad)}\n"
              "Fecha límite: ${_fecha(t.fechaLimite)}",
        ),
        trailing: Icon(
          t.estaVencida
              ? Icons.warning
              : t.estado == EstadoTarea.completada
              ? Icons.check_circle
              : Icons.timelapse,
          color: t.estaVencida
              ? Colors.red
              : t.estado == EstadoTarea.completada
              ? Colors.green
              : Colors.orange,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerTaskDetail(
                tarea: t,
                user: user,
              ),
            ),
          );
        },
      ),
    );
  }

  String _fecha(DateTime? f) {
    if (f == null) return "Sin fecha";
    return "${f.day}/${f.month}/${f.year}";
  }

  String _prioridadTexto(Prioridad p) {
    switch (p) {
      case Prioridad.alta:
        return "Alta";
      case Prioridad.media:
        return "Media";
      case Prioridad.baja:
        return "Baja";
    }
  }
}