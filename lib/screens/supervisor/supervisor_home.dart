import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../models/estado_tarea.dart';
import '../../models/prioridad.dart';
import '../../services/remote_data_service.dart';
import '../auth/login_screen.dart';
import '../admin/crear_tarea_screen.dart';
import '../admin/tarea_detalle_admin.dart';
import '../admin/kanban/kanban_screen.dart';
import '../admin/usuarios/usuarios_screen.dart';

class SupervisorHome extends StatefulWidget {
  final Usuario user;

  const SupervisorHome({
    super.key,
    required this.user,
  });

  @override
  State<SupervisorHome> createState() => _SupervisorHomeState();
}

class _SupervisorHomeState extends State<SupervisorHome> {
  final data = RemoteDataService.instance;

  Widget _resumenSupervisor(List<Tarea> tareas) {
    final total = tareas.length;

    final enProceso =
        tareas.where((t) => t.estado == EstadoTarea.enProceso).length;

    final completadas =
        tareas.where((t) => t.estado == EstadoTarea.completada).length;

    final vencidas = tareas.where(
          (t) => t.estaVencida && t.estado != EstadoTarea.completada,
    ).length;

    final progreso = total == 0 ? 0.0 : completadas / total;

    Color color;
    String mensaje;

    if (vencidas > 0) {
      color = Colors.red;
      mensaje = "⚠ Hay tareas vencidas";
    } else if (progreso == 1 && total > 0) {
      color = Colors.green;
      mensaje = "✔ Todo al día";
    } else {
      color = Colors.orange;
      mensaje = "⏳ Tareas en progreso";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumen",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _indicador("Total", total, Colors.blue),
                  _indicador("En proceso", enProceso, Colors.orange),
                  _indicador("Completadas", completadas, Colors.green),
                  _indicador("Vencidas", vencidas, Colors.red),
                ],
              ),

              const SizedBox(height: 14),

              LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(color),
              ),

              const SizedBox(height: 8),

              Text(
                mensaje,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await data.refrescar();
    if (mounted) setState(() {});
  }

  Widget _indicador(String texto, int valor, Color color) {
    return Column(
      children: [
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          texto,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // 🔒 Tareas SOLO de las empresas del supervisor
    final tareasEmpresa = data.tareas
        .where((t) => widget.user.empresaIds.contains(t.empresaId))
        .toList();

    final tareasAsignadasAMi = tareasEmpresa
        .where((t) => t.asignadoAIds.contains(widget.user.id))
        .toList();

    final tareasCreadasPorMi = tareasEmpresa
        .where((t) => t.creadoPorId == widget.user.id)
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Supervisor · ${_empresasTexto()}"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Todas"),
              Tab(text: "Asignadas a mí"),
              Tab(text: "Creadas por mí"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Crear tarea",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CrearTareaScreen(user: widget.user),
                  ),
                );
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.view_kanban),
              tooltip: "Kanban",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KanbanScreen(user: widget.user),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: "Usuarios",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsuariosScreen(user: widget.user),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Cerrar sesión",
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),

        body: Column(
          children: [
            // 🔵 RESUMEN VISUAL
            _resumenSupervisor(tareasEmpresa),

            // 🔵 TABS
            Expanded(
              child: TabBarView(
                children: [

                  // ===== TAB 1: TODAS =====
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _listaTareas(tareasEmpresa),
                  ),

                  // ===== TAB 2: ASIGNADAS A MI =====
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _listaTareas(tareasAsignadasAMi),
                        ),
                      ],
                    ),
                  ),

                  // ===== TAB 3: CREADAS POR MI =====
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: _listaTareas(tareasCreadasPorMi),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= LISTA =================

  Widget _listaTareas(List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return const Center(
        child: Text("No hay tareas"),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tareas.length,
      itemBuilder: (_, i) {
        final t = tareas[i];

        return ListTile(
          title: Text(t.titulo),
          subtitle: Text(
            "Empresa: ${_empresaNombre(t.empresaId)}\n"
                "Asignado: ${_textoAsignados(t)}\n"
                "Estado: ${_estadoTexto(t.estado)}\n"
                "Prioridad: ${_prioridadTexto(t.prioridad)}",
          ),
          trailing: Icon(
            t.estado == EstadoTarea.completada
                ? Icons.check_circle
                : Icons.chevron_right,
            color: t.estado == EstadoTarea.completada
                ? Colors.green
                : Colors.grey,
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TareaDetalleAdmin(
                  tarea: t,
                  user: widget.user,
                ),
              ),
            );
            setState(() {});
          },
        );
      },
    );
  }

  // ================= HELPERS =================

  String _empresasTexto() {
    final empresas = data.empresas
        .where((e) => widget.user.empresaIds.contains(e.id))
        .map((e) => e.nombre)
        .toList();

    if (empresas.isEmpty) return "Sin empresas";
    if (empresas.length == 1) return empresas.first;
    return "${empresas.first} + ${empresas.length - 1}";
  }

  String _empresaNombre(int empresaId) {
    return data.empresas
        .firstWhere((e) => e.id == empresaId)
        .nombre;
  }

  String _textoAsignados(Tarea t) {
    if (t.asignadoAIds.isEmpty) return "Sin asignar";

    final usuarios = data.usuarios
        .where((u) => t.asignadoAIds.contains(u.id))
        .toList();

    if (usuarios.isEmpty) return "Sin asignar";
    if (usuarios.length == 1) return usuarios.first.username;

    return "${usuarios.first.username} + ${usuarios.length - 1}";
  }

  String _estadoTexto(EstadoTarea e) {
    switch (e) {
      case EstadoTarea.sinIniciar:
        return "Sin iniciar";
      case EstadoTarea.enProceso:
        return "En proceso";
      case EstadoTarea.completada:
        return "Completada";
    }
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
