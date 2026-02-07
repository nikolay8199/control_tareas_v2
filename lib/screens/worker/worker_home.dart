import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../models/estado_tarea.dart';
import '../../models/prioridad.dart';
import '../../services/remote_data_service.dart';
import '../admin/crear_tarea_screen.dart';
import '../auth/login_screen.dart';
import 'kanban_worker_screen.dart';
import 'worker_task_detail.dart';
import 'package:control_tareas/models/task_filter.dart';
import '../../services/notification_intent_store.dart';

class WorkerHome extends StatefulWidget {
  final Usuario user;

  const WorkerHome({super.key, required this.user});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome> {
  final data = RemoteDataService.instance;

  bool _esMismaFecha(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  int _pesoPrioridad(prioridad) {
    switch (prioridad) {
      case Prioridad.alta:
        return 0;
      case Prioridad.media:
        return 1;
      case Prioridad.baja:
        return 2;
      default:
        return 3;
    }
  }

  int _compararTareas(Tarea a, Tarea b) {
    final pa = _pesoPrioridad(a.prioridad);
    final pb = _pesoPrioridad(b.prioridad);
    if (pa != pb) return pa.compareTo(pb);

    final fa = a.fechaLimite;
    final fb = b.fechaLimite;

    if (fa == null && fb == null) return 0;
    if (fa == null) return 1;
    if (fb == null) return -1;

    return fa.compareTo(fb);
  }

  @override
  void initState() {
    super.initState();

    // Ejecutar después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationIntent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = TaskFilter(usuarioId: widget.user.id);
    final tareas = data.filtrarTareas(filter);

    // 🔵 MÉTRICAS
    final total = tareas.length;
    final completadas =
        tareas.where((t) => t.estado == EstadoTarea.completada).length;
    final enProceso =
        tareas.where((t) => t.estado == EstadoTarea.enProceso).length;
    final vencidas =
        tareas.where((t) => t.estaVencida && t.estado != EstadoTarea.completada).length;

    final progreso = total == 0 ? 0.0 : completadas / total;

    final hoy = _soloFecha(DateTime.now());

    final listaVencidas = tareas
        .where((t) => t.estaVencida)
        .toList()
      ..sort(_compararTareas);

    final tareasHoy = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite != null &&
        _esMismaFecha(_soloFecha(t.fechaLimite!), hoy))
        .toList()
      ..sort(_compararTareas);

    final proximas = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite != null &&
        _soloFecha(t.fechaLimite!).isAfter(hoy))
        .toList()
      ..sort(_compararTareas);

    final sinFecha = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite == null)
        .toList()
      ..sort(_compararTareas);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Tareas de ${widget.user.username}"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Mis tareas"),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KanbanWorkerScreen(user: widget.user),
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
            // ===== TAB 1: MIS TAREAS =====
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildMisTareasTab(),
            ),

            // ===== TAB 2: CREADAS POR MI =====
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: _buildCreadasPorMiTab(),
                  ),
                ],
              ),
            ),
          ],
        ),

      ),
    );
  }

  Future<void> _handleNotificationIntent() async {
    final intent = NotificationIntentStore.pending;
    if (intent == null) return;

    // Consumir una sola vez
    NotificationIntentStore.pending = null;

    if (intent.tipo == 'tarea' && intent.tareaId != null) {
      final tareaId = int.tryParse(intent.tareaId!);
      if (tareaId == null) return;

      // 🔄 Asegurar datos frescos antes de navegar
      await data.refrescar();

      Tarea? tarea;
      try {
        tarea = data.tareas.firstWhere((t) => t.id == tareaId);
      } catch (_) {
        tarea = null;
      }

      if (tarea == null) return;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerTaskDetail(
            tarea: tarea!,
            user: widget.user,
          ),
        ),
      );
    }
  }

  Future<void> _onRefresh() async {
    await data.refrescar();
    if (mounted) setState(() {});
  }

  Widget _buildMisTareasTab() {
    final filter = TaskFilter(usuarioId: widget.user.id);
    final tareas = data.filtrarTareas(filter);

    // 🔵 MÉTRICAS (idéntico a tu código actual)
    final total = tareas.length;
    final completadas =
        tareas.where((t) => t.estado == EstadoTarea.completada).length;
    final enProceso =
        tareas.where((t) => t.estado == EstadoTarea.enProceso).length;
    final vencidas = tareas
        .where((t) => t.estaVencida && t.estado != EstadoTarea.completada)
        .length;

    final progreso = total == 0 ? 0.0 : completadas / total;

    final hoy = _soloFecha(DateTime.now());

    final listaVencidas = tareas.where((t) => t.estaVencida).toList()
      ..sort(_compararTareas);

    final tareasHoy = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite != null &&
        _esMismaFecha(_soloFecha(t.fechaLimite!), hoy))
        .toList()
      ..sort(_compararTareas);

    final proximas = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite != null &&
        _soloFecha(t.fechaLimite!).isAfter(hoy))
        .toList()
      ..sort(_compararTareas);

    final sinFecha = tareas
        .where((t) =>
    !t.estaVencida &&
        t.estado != EstadoTarea.completada &&
        t.fechaLimite == null)
        .toList()
      ..sort(_compararTareas);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // ✅ TU RESUMEN (no se toca)
        _resumenProgreso(
          total: total,
          enProceso: enProceso,
          completadas: completadas,
          vencidas: vencidas,
          progreso: progreso,
        ),

        if (listaVencidas.isEmpty &&
            tareasHoy.isEmpty &&
            proximas.isEmpty &&
            sinFecha.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                "No tienes tareas pendientes 🎉",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),

        _seccion(
          titulo: "Vencidas",
          icono: Icons.warning,
          tareas: listaVencidas,
        ),
        _seccion(
          titulo: "Hoy",
          icono: Icons.today,
          tareas: tareasHoy,
        ),
        _seccion(
          titulo: "Próximas",
          icono: Icons.schedule,
          tareas: proximas,
        ),
        _seccion(
          titulo: "Sin fecha",
          icono: Icons.folder_open,
          tareas: sinFecha,
        ),
      ],
    );
  }

  Widget _buildCreadasPorMiTab() {
    final tareasCreadas = data.tareas
        .where((t) => t.creadoPorId == widget.user.id)
        .toList()
      ..sort(_compararTareas);

    if (tareasCreadas.isEmpty) {
      return const Center(
        child: Text(
          "No has creado tareas aún ✍️",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Tareas creadas por ti (${tareasCreadas.length})",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ...tareasCreadas.map(_tarjetaTareaCreador).toList(),
      ],
    );
  }

  Widget _tarjetaTareaCreador(Tarea t) {
    final asignados = data.usuarios
        .where((u) => t.asignadoAIds.contains(u.id))
        .map((u) => u.username)
        .join(", ");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.edit_note),
        title: Text(
          t.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Asignado a: ${asignados.isEmpty ? "Sin asignar" : asignados}\n"
              "Estado: ${_estadoTexto(t.estado)}\n"
              "Prioridad: ${_prioridadTexto(t.prioridad)}",
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerTaskDetail(
                tarea: t,
                user: widget.user,
              ),
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  Widget _resumenProgreso({
    required int total,
    required int enProceso,
    required int completadas,
    required int vencidas,
    required double progreso,
  }) {
    final porcentaje = (progreso * 100).round();

    Color color;
    String mensaje;

    if (vencidas > 0) {
      color = Colors.red;
      mensaje = "⚠ Tienes tareas vencidas";
    } else if (porcentaje == 100 && total > 0) {
      color = Colors.green;
      mensaje = "✔ Todo al día, buen trabajo";
    } else {
      color = Colors.orange;
      mensaje = "⏳ Vas avanzando";
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _fila("Total", total),
            _fila("En proceso", enProceso),
            _fila("Completadas", completadas),
            _fila("Vencidas", vencidas),

            const SizedBox(height: 12),
            Text("Progreso: $porcentaje%"),
            const SizedBox(height: 6),

            LinearProgressIndicator(
              value: progreso,
              color: color,
              backgroundColor: Colors.grey.shade300,
            ),

            const SizedBox(height: 8),
            Text(
              mensaje,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(String texto, int valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(texto),
          Text(
            valor.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _seccion({
    required String titulo,
    required IconData icono,
    required List<Tarea> tareas,
  }) {
    if (tareas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icono, size: 20),
              const SizedBox(width: 6),
              Text(
                "$titulo (${tareas.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...tareas.map(_tarjetaTarea).toList(),
      ],
    );
  }

  Widget _tarjetaTarea(Tarea t) {
    final color = _colorUrgencia(t);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(_iconoUrgencia(t), color: color),
        title: Text(
          t.titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color == Colors.grey ? null : color,
          ),
        ),
        subtitle: Text(
          "Prioridad: ${_prioridadTexto(t.prioridad)}\n"
              "Estado: ${_estadoTexto(t.estado)}\n"
              "Fecha límite: ${_fecha(t.fechaLimite)}",
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
              builder: (_) => WorkerTaskDetail(
                tarea: t,
                user: widget.user,
              ),
            ),
          );
          setState(() {});
        },
      ),
    );
  }

  Color _colorUrgencia(Tarea t) {
    if (t.estaVencida) return Colors.red;
    if (t.fechaLimite != null &&
        _esMismaFecha(
            _soloFecha(t.fechaLimite!), _soloFecha(DateTime.now()))) {
      return Colors.orange;
    }
    if (t.fechaLimite != null) return Colors.green;
    return Colors.grey;
  }

  IconData _iconoUrgencia(Tarea t) {
    if (t.estaVencida) return Icons.warning;
    if (t.fechaLimite != null &&
        _esMismaFecha(
            _soloFecha(t.fechaLimite!), _soloFecha(DateTime.now()))) {
      return Icons.access_time;
    }
    if (t.fechaLimite != null) return Icons.event;
    return Icons.folder_open;
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
}
