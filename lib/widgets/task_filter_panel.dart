import 'package:flutter/material.dart';
import '../models/estado_tarea.dart';
import '../models/prioridad.dart';
import '../models/task_filter.dart';
import '../models/rol.dart';
import '../services/remote_data_service.dart';

class TaskFilterPanel extends StatefulWidget {
  final TaskFilter filter;
  final VoidCallback onFilterChange;
  final bool isAdmin;

  const TaskFilterPanel({
    super.key,
    required this.filter,
    required this.onFilterChange,
    this.isAdmin = false,
  });

  @override
  State<TaskFilterPanel> createState() => _TaskFilterPanelState();
}

class _TaskFilterPanelState extends State<TaskFilterPanel> {
  final data = RemoteDataService.instance;

  @override
  Widget build(BuildContext context) {
    final empresas = data.empresas;
    final usuarios = data.usuarios.where((u) => u.rol == Rol.trabajador).toList();

    return ExpansionTile(
      title: const Text("Filtros"),
      children: [
        // 🔵 Filtro por Empresa (solo admin)
        if (widget.isAdmin) Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Empresa"),
            DropdownButton<int?>(
              value: widget.filter.empresaId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("Todas"))
              ] +
                  empresas.map((e) {
                    return DropdownMenuItem<int?>(
                      value: e.id,
                      child: Text(e.nombre),
                    );
                  }).toList(),
              onChanged: (v) {
                setState(() => widget.filter.empresaId = v);
                widget.onFilterChange();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),

        // 🔵 Filtro por Usuario (solo admin)
        if (widget.isAdmin) Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Usuario"),
            DropdownButton<int?>(
              value: widget.filter.usuarioId,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("Todos"))
              ] +
                  usuarios.map((u) {
                    return DropdownMenuItem<int?>(
                      value: u.id,
                      child: Text(u.username),
                    );
                  }).toList(),
              onChanged: (v) {
                setState(() => widget.filter.usuarioId = v);
                widget.onFilterChange();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),

        // 🔵 Filtro por Prioridad
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Prioridad"),
            DropdownButton<Prioridad?>(
              value: widget.filter.prioridad,
              items: [
                const DropdownMenuItem<Prioridad?>(value: null, child: Text("Todas"))
              ] +
                  Prioridad.values.map((p) {
                    return DropdownMenuItem<Prioridad?>(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (v) {
                setState(() => widget.filter.prioridad = v);
                widget.onFilterChange();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),

        // 🔵 Filtro por Estado de tarea
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Estado"),
            DropdownButton<EstadoTarea?>(
              value: widget.filter.estado,
              items: [
                const DropdownMenuItem<EstadoTarea?>(value: null, child: Text("Todos"))
              ] +
                  EstadoTarea.values.map((e) {
                    return DropdownMenuItem<EstadoTarea?>(
                      value: e,
                      child: Text(e.name),
                    );
                  }).toList(),
              onChanged: (v) {
                setState(() => widget.filter.estado = v);
                widget.onFilterChange();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}