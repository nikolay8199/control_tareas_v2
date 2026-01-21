import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/rol.dart';
import '../../../services/remote_data_service.dart';

class UsuarioEditarScreen extends StatefulWidget {
  final Usuario usuario;

  const UsuarioEditarScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<UsuarioEditarScreen> createState() => _UsuarioEditarScreenState();
}

class _UsuarioEditarScreenState extends State<UsuarioEditarScreen> {
  final data = RemoteDataService.instance;

  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  late Rol rolSeleccionado;
  final List<int> empresasSeleccionadas = [];

  @override
  void initState() {
    super.initState();

    usernameCtrl.text = widget.usuario.username;
    passwordCtrl.text = widget.usuario.password;

    rolSeleccionado = widget.usuario.rol;
    empresasSeleccionadas.addAll(widget.usuario.empresaIds);
  }

  void _guardar() {
    if (usernameCtrl.text.trim().isEmpty ||
        passwordCtrl.text.trim().isEmpty) {
      return;
    }

    // 🔒 Validación: roles no admin deben tener empresa
    if (rolSeleccionado != Rol.admin &&
        empresasSeleccionadas.isEmpty) {
      return;
    }

    final actualizado = Usuario(
      id: widget.usuario.id,
      username: usernameCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
      rol: rolSeleccionado,
      empresaIds:
      rolSeleccionado == Rol.admin ? [] : List.from(empresasSeleccionadas),
    );

    data.actualizarUsuario(actualizado);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final empresas = data.empresas;

    return Scaffold(
      appBar: AppBar(title: const Text("Editar Usuario")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // -------- Username --------
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              const SizedBox(height: 12),

              // -------- Password --------
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 20),

              // -------- Rol --------
              DropdownButtonFormField<Rol>(
                value: rolSeleccionado,
                items: Rol.values.map((r) {
                  return DropdownMenuItem<Rol>(
                    value: r,
                    child: Text(
                      r == Rol.admin
                          ? "Administrador"
                          : r == Rol.supervisor
                          ? "Supervisor"
                          : "Trabajador",
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    rolSeleccionado = v!;
                    if (rolSeleccionado == Rol.admin) {
                      empresasSeleccionadas.clear();
                    }
                  });
                },
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

                ...empresas.map((e) {
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
                child: const Text("Guardar cambios"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}