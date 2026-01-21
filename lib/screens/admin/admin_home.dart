import 'package:control_tareas/screens/admin/tarea_detalle_admin.dart';
import 'package:control_tareas/screens/admin/usuarios/usuarios_screen.dart';
import 'package:control_tareas/widgets/task_filter_panel.dart';   // 🔥 AÑADIR
import 'package:control_tareas/models/task_filter.dart';          // 🔥 AÑADIR
import 'package:flutter/material.dart';
import '../../models/prioridad.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../models/estado_tarea.dart';
import '../../services/remote_data_service.dart';
import '../auth/login_screen.dart';
import 'crear_tarea_screen.dart';
import 'dashboard_screen.dart';
import 'empresas/empresas_screen.dart';
import 'kanban/kanban_screen.dart';

class AdminHome extends StatefulWidget {
  final Usuario user;

  const AdminHome({super.key, required this.user});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final data = RemoteDataService.instance;

  // 🔥 Instancia del filtro
  final TaskFilter filter = TaskFilter();

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

  Widget _resumenAdmin(List<Tarea> tareas) {
    final total = tareas.length;

    final sinIniciar =
        tareas.where((t) => t.estado == EstadoTarea.sinIniciar).length;

    final enProceso =
        tareas.where((t) => t.estado == EstadoTarea.enProceso).length;

    final completadas =
        tareas.where((t) => t.estado == EstadoTarea.completada).length;

    final vencidas = tareas.where(
          (t) => t.estaVencida && t.estado != EstadoTarea.completada,
    ).length;

    final progreso = total == 0 ? 0.0 : completadas / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resumen General",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _indicador("Total", total.toString(), Colors.blue),
                  _indicador("Sin iniciar", sinIniciar.toString(), Colors.grey),
                  _indicador("En proceso", enProceso.toString(), Colors.orange),
                  _indicador("Completadas", completadas.toString(), Colors.green),
                  _indicador("Vencidas", vencidas.toString(), Colors.red),
                ],
              ),

              const SizedBox(height: 16),

              LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  vencidas > 0 ? Colors.red : Colors.green,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Progreso: ${(progreso * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: vencidas > 0 ? Colors.red : Colors.green,
                ),
              ),

              if (vencidas > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "⚠ Hay tareas vencidas que requieren atención",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _indicador(String titulo, String valor, Color color) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  Widget _estadoChip(EstadoTarea e) {
    final map = {
      EstadoTarea.sinIniciar: Colors.grey,
      EstadoTarea.enProceso: Colors.orange,
      EstadoTarea.completada: Colors.green,
    };

    return Chip(
      label: Text(_estadoTexto(e)),
      backgroundColor: map[e]!.withOpacity(0.15),
      labelStyle: TextStyle(color: map[e]),
    );
  }

  Widget _prioridadChip(Prioridad p) {
    final map = {
      Prioridad.alta: Colors.red,
      Prioridad.media: Colors.orange,
      Prioridad.baja: Colors.green,
    };

    return Chip(
      label: Text(_prioridadTexto(p)),
      backgroundColor: map[p]!.withOpacity(0.15),
      labelStyle: TextStyle(color: map[p]),
    );
  }
  Color _colorPrioridadCard(Prioridad p) {
    switch (p) {
      case Prioridad.alta:
        return Colors.red.withOpacity(0.08);
      case Prioridad.media:
        return Colors.orange.withOpacity(0.08);
      case Prioridad.baja:
        return Colors.green.withOpacity(0.08);
    }
  }

  Widget _listaTareas(List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return const Center(
        child: Text("No hay tareas"),
      );
    }

    return ListView.builder(
      itemCount: tareas.length,
      itemBuilder: (_, i) {
        final t = tareas[i];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _colorPrioridadCard(t.prioridad),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              title: Text(
                t.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        "Asignado a: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _textoAsignados(t),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _estadoChip(t.estado),
                      _prioridadChip(t.prioridad),
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
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TareaDetalleAdmin(
                      tarea: t,
                      user: widget.user,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await data.refrescar();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Aplicar filtros
    final tareasFiltradas = data.filtrarTareas(filter);

    final creadasPorMi = tareasFiltradas
        .where((t) => t.creadoPorId == widget.user.id)
        .toList();

    final asignadasAMi = tareasFiltradas
        .where((t) => t.asignadoAIds.contains(widget.user.id))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
      appBar: AppBar(
        title: Text("${widget.user.username}"),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.list), text: "Todas"),
            Tab(icon: Icon(Icons.edit_note), text: "Creadas por mí"),
            Tab(icon: Icon(Icons.assignment_ind), text: "Asignadas a mí"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
            icon: const Icon(Icons.business),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmpresasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
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
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DashboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_kanban),
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
            icon: const Icon(Icons.logout),
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

      body: TabBarView(
        children: [
          // ================= TAB 1: TODAS =================
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                TaskFilterPanel(
                  filter: filter,
                  isAdmin: true,
                  onFilterChange: () => setState(() {}),
                ),
                _resumenAdmin(tareasFiltradas),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.65,
                  child: _listaTareas(tareasFiltradas),
                ),
              ],
            ),
          ),

          // ================= TAB 2: CREADAS POR MI =================
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _resumenAdmin(creadasPorMi),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: _listaTareas(creadasPorMi),
                ),
              ],
            ),
          ),

          // ================= TAB 3: ASIGNADAS A MI =================
          RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _resumenAdmin(asignadasAMi),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: _listaTareas(asignadasAMi),
                ),
              ],
            ),
          ),
        ],
      ),
     )
    );
  }
}