import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/rol.dart';
import '../../../services/remote_data_service.dart';

class NuevoUsuarioScreen extends StatefulWidget {
  final Usuario user; // usuario logueado

  const NuevoUsuarioScreen({
    super.key,
    required this.user,
  });

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final data = RemoteDataService.instance;

  Rol rolSeleccionado = Rol.trabajador;

  /// 🔥 MULTI-EMPRESA
  final List<int> empresasSeleccionadas = [];

  String _textoRol(Rol rol) {
    switch (rol) {
      case Rol.admin:
        return "Administrador";
      case Rol.supervisor:
        return "Supervisor";
      case Rol.trabajador:
        return "Trabajador";
    }
  }

  @override
  void initState() {
    super.initState();

    // Supervisor solo crea trabajadores
    if (widget.user.rol == Rol.supervisor) {
      rolSeleccionado = Rol.trabajador;
      empresasSeleccionadas.addAll(widget.user.empresaIds);
    }
  }

  Future<void> _guardar() async {
    if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;

    if (rolSeleccionado != Rol.admin && empresasSeleccionadas.isEmpty) return;

    final nuevo = Usuario(
      id: 0, // el backend asigna el id (no uses timestamp)
      username: usernameCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
      rol: rolSeleccionado,
      empresaIds: rolSeleccionado == Rol.admin ? [] : List.from(empresasSeleccionadas),
    );

    try {
      await data.agregarUsuario(nuevo);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresas = data.empresas;

    final rolesDisponibles = widget.user.rol == Rol.admin
        ? [Rol.admin, Rol.supervisor, Rol.trabajador]
        : [Rol.trabajador];

    // 🔒 Empresas visibles según rol
    final empresasVisibles = widget.user.rol == Rol.admin
        ? empresas
        : empresas
        .where((e) => widget.user.empresaIds.contains(e.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: "Contraseña"),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // -------- Rol --------
              DropdownButtonFormField<Rol>(
                value: rolSeleccionado,
                items: rolesDisponibles.map((r) {
                  return DropdownMenuItem<Rol>(
                    value: r,
                    child: Text(_textoRol(r)),
                  );
                }).toList(),
                onChanged: widget.user.rol == Rol.admin
                    ? (v) {
                  setState(() {
                    rolSeleccionado = v!;
                    if (rolSeleccionado == Rol.admin) {
                      empresasSeleccionadas.clear();
                    }
                  });
                }
                    : null,
                decoration: const InputDecoration(labelText: "Rol"),
              ),

              const SizedBox(height: 20),

              // -------- Empresas (MULTI) --------
              if (rolSeleccionado != Rol.admin) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Empresas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 8),

                ...empresasVisibles.map((e) {
                  final checked =
                  empresasSeleccionadas.contains(e.id);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(e.nombre),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          empresasSeleccionadas.add(e.id);
                        } else {
                          empresasSeleccionadas.remove(e.id);
                        }
                      });
                    },
                  );
                }),
              ],

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _guardar,
                child: const Text("Crear Usuario"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}