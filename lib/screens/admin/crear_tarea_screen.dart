import 'package:flutter/material.dart';
import '../../models/prioridad.dart';
import '../../models/rol.dart';
import '../../models/usuario.dart';
import '../../models/tarea.dart';
import '../../services/remote_data_service.dart';

class CrearTareaScreen extends StatefulWidget {
  final int? empresaForzadaId;
  final Usuario user;

  const CrearTareaScreen({
    super.key,
    this.empresaForzadaId,
    required this.user,
  });

  @override
  State<CrearTareaScreen> createState() => _CrearTareaScreenState();
}

class _CrearTareaScreenState extends State<CrearTareaScreen> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  int? empresaSeleccionada;
  List<int> usuariosSeleccionados = [];

  Prioridad prioridadSeleccionada = Prioridad.media;
  DateTime? fechaLimite;

  final data = RemoteDataService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.empresaForzadaId != null) {
      empresaSeleccionada = widget.empresaForzadaId;
    }
  }

  Future<void> _seleccionarFechaLimite() async {
    final ahora = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: DateTime(2100),
    );

    if (seleccion != null) {
      setState(() => fechaLimite = seleccion);
    }
  }

  Future<void> _guardar() async {
    if (tituloCtrl.text.isEmpty ||
        descripcionCtrl.text.isEmpty ||
        empresaSeleccionada == null ||
        usuariosSeleccionados.isEmpty) {
      return;
    }
    if (widget.user.rol == Rol.trabajador &&
        !widget.user.empresaIds.contains(empresaSeleccionada)) {
      return;
    }

    final nuevaTarea = Tarea(
      id: DateTime.now().millisecondsSinceEpoch,
      titulo: tituloCtrl.text.trim(),
      descripcion: descripcionCtrl.text.trim(),
      empresaId: empresaSeleccionada!,
      asignadoAIds: usuariosSeleccionados,
      creadoPorId: widget.user.id,
      fechaLimite: fechaLimite,
      prioridad: prioridadSeleccionada,
    );

    try {
      await data.crearTarea(
        actor: widget.user,
        tarea: nuevaTarea,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando tarea: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 Empresas visibles según rol
    final empresas = data.empresas;

// 🔒 Empresas disponibles según rol
    final empresasDisponibles = widget.user.rol == Rol.admin
        ? empresas
        : empresas
        .where((e) => widget.user.empresaIds.contains(e.id))
        .toList();

// 🔒 Usuarios asignables
    final asignables = empresaSeleccionada == null
        ? <Usuario>[]
        : data.usuarios.where((u) {
      // Debe pertenecer a la empresa
      if (!u.esAdminGlobal &&
          !u.empresaIds.contains(empresaSeleccionada)) {
        return false;
      }

      // ADMIN puede asignar a cualquiera
      if (widget.user.rol == Rol.admin) return true;

      // SUPERVISOR puede asignar a usuarios de sus empresas
      if (widget.user.rol == Rol.supervisor) {
        return widget.user.empresaIds.contains(empresaSeleccionada);
      }

      // 👷 TRABAJADOR (NUEVO)
      if (widget.user.rol == Rol.trabajador) {
        return true; // admins, supervisores o compañeros
      }

      return false;
    }).toList();

    String textoFecha() {
      if (fechaLimite == null) return "Sin fecha límite";
      return "${fechaLimite!.day}/${fechaLimite!.month}/${fechaLimite!.year}";
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Crear Tarea")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // -------- Empresa --------
              if (widget.empresaForzadaId == null)
                DropdownButtonFormField<int>(
                  value: empresaSeleccionada,
                  items: empresasDisponibles.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(e.nombre),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      empresaSeleccionada = v;
                      usuariosSeleccionados.clear(); // 🔥 CLAVE
                    });
                  },
                  decoration: const InputDecoration(labelText: "Empresa"),
                ),

              const SizedBox(height: 16),

              // -------- Usuarios (MULTI) --------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Asignar a:",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),

              ...asignables.map((u) {
                final checked =
                usuariosSeleccionados.contains(u.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(
                    u.esAdminGlobal
                        ? "${u.username} (Admin)"
                        : u.username,
                  ),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        usuariosSeleccionados.add(u.id);
                      } else {
                        usuariosSeleccionados.remove(u.id);
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 16),

              // -------- Título --------
              TextField(
                controller: tituloCtrl,
                decoration:
                const InputDecoration(labelText: "Título"),
              ),

              const SizedBox(height: 10),

              // -------- Descripción --------
              TextField(
                controller: descripcionCtrl,
                maxLines: 3,
                decoration:
                const InputDecoration(labelText: "Descripción"),
              ),

              const SizedBox(height: 16),

              // -------- Prioridad --------
              DropdownButtonFormField<Prioridad>(
                value: prioridadSeleccionada,
                items: Prioridad.values.map((p) {
                  final texto =
                  p == Prioridad.alta ? "Alta" : p == Prioridad.media ? "Media" : "Baja";
                  return DropdownMenuItem(
                    value: p,
                    child: Text(texto),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => prioridadSeleccionada = v!),
                decoration:
                const InputDecoration(labelText: "Prioridad"),
              ),

              const SizedBox(height: 16),

              // -------- Fecha límite --------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(textoFecha()),
                  TextButton(
                    onPressed: _seleccionarFechaLimite,
                    child: const Text("Elegir fecha"),
                  )
                ],
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _guardar,
                child: const Text("Guardar Tarea"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}