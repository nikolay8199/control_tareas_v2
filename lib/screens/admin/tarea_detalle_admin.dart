import 'package:flutter/material.dart';
import '../../models/estado_tarea.dart';
import '../../models/tarea.dart';
import '../../models/empresa.dart';
import '../../models/usuario.dart';
import '../../services/remote_data_service.dart';
import '../worker/task_chat_screen.dart';
import 'tarea_editar_screen.dart';

class TareaDetalleAdmin extends StatefulWidget {
  final Tarea tarea;
  final Usuario user; // admin actual

  const TareaDetalleAdmin({
    super.key,
    required this.tarea,
    required this.user,
  });

  @override
  State<TareaDetalleAdmin> createState() => _TareaDetalleAdminState();
}

class _TareaDetalleAdminState extends State<TareaDetalleAdmin> {
  final data = RemoteDataService.instance;

  late List<int> usuariosSeleccionados;

  @override
  void initState() {
    super.initState();
    usuariosSeleccionados = List.from(widget.tarea.asignadoAIds);
  }

  String _fecha(DateTime? f) {
    if (f == null) return "Sin fecha";
    return "${f.day}/${f.month}/${f.year}";
  }

  @override
  Widget build(BuildContext context) {
    final Empresa empresa =
    data.empresas.firstWhere((e) => e.id == widget.tarea.empresaId);

    // 🔥 USUARIO CREADOR
    final creador = data.usuarios
        .where((u) => u.id == widget.tarea.creadoPorId)
        .cast<Usuario?>()
        .firstWhere(
          (u) => u != null,
      orElse: () => null,
    );

    final nombreCreador = creador?.username ?? "Usuario eliminado";

    // 🔒 usuarios asignables según reglas centrales
    final usuariosAsignables = data.usuariosAsignables(
      actor: widget.user,
      empresaId: widget.tarea.empresaId,
    );

    final t = widget.tarea;

// 👤 permisos según relación con la tarea
    final soyCreador = t.creadoPorId == widget.user.id;
    final estoyAsignado = t.asignadoAIds.contains(widget.user.id);

// 🔒 reglas finales
    final puedeEditar = soyCreador;
    final puedeEliminar = soyCreador;
    final puedeCambiarEstado = soyCreador || estoyAsignado;
    final puedeComentar = soyCreador || estoyAsignado;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de tarea"),
        actions: [
          if (puedeEditar)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TareaEditarScreen(tarea: widget.tarea),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          if (puedeEliminar)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Eliminar tarea"),
                    content: const Text(
                      "¿Estás seguro de que deseas eliminar esta tarea?",
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
                  data.eliminarTarea(widget.tarea.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Título", style: Theme.of(context).textTheme.titleLarge),
            Text(widget.tarea.titulo),

            const SizedBox(height: 16),

            Text("Descripción", style: Theme.of(context).textTheme.titleLarge),
            Text(widget.tarea.descripcion),

            const SizedBox(height: 16),

            Text("Empresa: ${empresa.nombre}"),
            Text("Creada por: $nombreCreador"), // ✅ NUEVO
            Text("Prioridad: ${widget.tarea.prioridad.name}"),
            Text("Estado: ${widget.tarea.estado.name}"),
            Text("Creada en: ${_fecha(widget.tarea.creadaEn)}"),
            Text("Fecha límite: ${_fecha(widget.tarea.fechaLimite)}"),

            const SizedBox(height: 24),

            // =========================
            // ASIGNADOS (MULTI)
            // =========================
            if (soyCreador) ...[
              Text(
                "Usuarios asignados",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              ...usuariosAsignables.map((u) {
                final checked = usuariosSeleccionados.contains(u.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(
                    u.esAdminGlobal ? "${u.username} (Admin)" : u.username,
                  ),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        usuariosSeleccionados.add(u.id);
                      } else {
                        usuariosSeleccionados.remove(u.id);
                      }
                    });

                    final actualizada = Tarea(
                      id: widget.tarea.id,
                      titulo: widget.tarea.titulo,
                      descripcion: widget.tarea.descripcion,
                      empresaId: widget.tarea.empresaId,
                      asignadoAIds: usuariosSeleccionados,
                      creadoPorId: widget.tarea.creadoPorId,
                      creadaEn: widget.tarea.creadaEn,
                      fechaLimite: widget.tarea.fechaLimite,
                      completadaEn: widget.tarea.completadaEn,
                      prioridad: widget.tarea.prioridad,
                      estado: widget.tarea.estado,
                      comentarios: List.from(widget.tarea.comentarios),
                    );

                    data.eliminarTarea(widget.tarea.id);
                    data.crearTarea(
                      actor: widget.user,
                      tarea: actualizada,
                    );
                  },
                );
              }),
            ],
            if (puedeCambiarEstado) ...[
              const SizedBox(height: 24),

              Text(
                "Cambiar estado",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: [
                  if (widget.tarea.estado != EstadoTarea.sinIniciar)
                    ElevatedButton(
                      onPressed: () {
                        data.cambiarEstadoTarea(
                          tareaId: widget.tarea.id,
                          nuevoEstado: EstadoTarea.sinIniciar,
                        );
                        setState(() {});
                      },
                      child: const Text("Sin iniciar"),
                    ),

                  if (widget.tarea.estado != EstadoTarea.enProceso)
                    ElevatedButton(
                      onPressed: () {
                        data.cambiarEstadoTarea(
                          tareaId: widget.tarea.id,
                          nuevoEstado: EstadoTarea.enProceso,
                        );
                        setState(() {});
                      },
                      child: const Text("En proceso"),
                    ),

                  if (widget.tarea.estado != EstadoTarea.completada)
                    ElevatedButton(
                      onPressed: () {
                        data.cambiarEstadoTarea(
                          tareaId: widget.tarea.id,
                          nuevoEstado: EstadoTarea.completada,
                        );
                        setState(() {});
                      },
                      child: const Text("Completada"),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskChatScreen(
                      tarea: widget.tarea,
                      user: widget.user,
                    ),
                  ),
                );
              },
              child: const Text("Ver comentarios"),
            ),
          ],
        ),
      ),
    );
  }
}
