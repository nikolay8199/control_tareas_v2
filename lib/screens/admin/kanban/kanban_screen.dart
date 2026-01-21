import 'package:flutter/material.dart';
import '../../../models/tarea.dart';
import '../../../models/estado_tarea.dart';
import '../../../models/prioridad.dart';
import '../../../models/usuario.dart';
import '../../../services/remote_data_service.dart';
import '../tarea_detalle_admin.dart';

class KanbanScreen extends StatefulWidget {
  final Usuario user; // admin actual

  const KanbanScreen({
    super.key,
    required this.user,
  });

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final data = RemoteDataService.instance;

  @override
  Widget build(BuildContext context) {
    final sinIniciar =
    data.tareas.where((t) => t.estado == EstadoTarea.sinIniciar).toList();
    final enProceso =
    data.tareas.where((t) => t.estado == EstadoTarea.enProceso).toList();
    final completadas =
    data.tareas.where((t) => t.estado == EstadoTarea.completada).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista Kanban"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _columna(
              context,
              titulo: "Sin iniciar",
              estadoDestino: EstadoTarea.sinIniciar,
              tareas: sinIniciar,
            ),
            _columna(
              context,
              titulo: "En proceso",
              estadoDestino: EstadoTarea.enProceso,
              tareas: enProceso,
            ),
            _columna(
              context,
              titulo: "Completadas",
              estadoDestino: EstadoTarea.completada,
              tareas: completadas,
            ),
          ],
        ),
      ),
    );
  }

  // ================= COLUMNA =================

  Widget _columna(
      BuildContext context, {
        required String titulo,
        required EstadoTarea estadoDestino,
        required List<Tarea> tareas,
      }) {
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: DragTarget<Tarea>(
              onWillAccept: (_) => true,
              onAccept: (tarea) {
                setState(() {
                  data.cambiarEstadoTarea(
                    tareaId: tarea.id,
                    nuevoEstado: estadoDestino,
                  );
                });
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.builder(
                  itemCount: tareas.length,
                  itemBuilder: (_, i) {
                    final t = tareas[i];

                    return Draggable<Tarea>(
                      data: t,
                      feedback: Material(
                        elevation: 6,
                        child: _kanbanCard(t),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: _kanbanCard(t),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TareaDetalleAdmin(
                                tarea: t,
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                        child: _kanbanCard(t),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= TARJETA =================

  Widget _kanbanCard(Tarea t) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: t.estaVencida ? Colors.red : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.titulo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: t.estaVencida ? Colors.red.shade800 : null,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              "Asignado: ${_textoAsignados(t)}",
              style: const TextStyle(fontSize: 13),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                _prioridadChip(t.prioridad),
                const SizedBox(width: 6),
                if (t.estaVencida)
                  Chip(
                    label: const Text("VENCIDA"),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= ASIGNADOS =================

  String _textoAsignados(Tarea t) {
    if (t.asignadoAIds.isEmpty) return "Sin asignar";

    final usuarios = data.usuarios
        .where((u) => t.asignadoAIds.contains(u.id))
        .toList();

    if (usuarios.isEmpty) return "Sin asignar";

    if (usuarios.length == 1) {
      return usuarios.first.username;
    }

    return "${usuarios.first.username} + ${usuarios.length - 1}";
  }

  // ================= PRIORIDAD =================

  Widget _prioridadChip(Prioridad p) {
    Color color;
    String texto;

    switch (p) {
      case Prioridad.alta:
        color = Colors.red;
        texto = "Alta";
        break;
      case Prioridad.media:
        color = Colors.orange;
        texto = "Media";
        break;
      case Prioridad.baja:
        color = Colors.green;
        texto = "Baja";
        break;
    }

    return Chip(
      label: Text(texto),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}
