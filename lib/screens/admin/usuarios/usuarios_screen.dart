import 'package:flutter/material.dart';
import '../../../models/rol.dart';
import '../../../models/usuario.dart';
import '../../../services/remote_data_service.dart';
import 'nuevo_usuario_screen.dart';
import 'usuario_detalle_screen.dart';

class UsuariosScreen extends StatefulWidget {
  final Usuario user; // usuario logueado

  const UsuariosScreen({
    super.key,
    required this.user,
  });

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final data = RemoteDataService.instance;

  String _textoEmpresas(Usuario u) {
    if (u.esAdminGlobal) return "Administrador global";

    final empresas = data.empresas
        .where((e) => u.empresaIds.contains(e.id))
        .toList();

    if (empresas.isEmpty) return "Sin empresas";

    return empresas.map((e) => e.nombre).join(", ");
  }

  int _ordenRol(Rol rol) {
    switch (rol) {
      case Rol.admin:
        return 0;
      case Rol.supervisor:
        return 1;
      case Rol.trabajador:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuariosVisibles = (widget.user.rol == Rol.supervisor
        ? data.usuarios
        .where((u) => u.empresaIds == widget.user.empresaIds)
        .toList()
        : List<Usuario>.from(data.usuarios))
      ..sort((a, b) {
        final rolCompare = _ordenRol(a.rol).compareTo(_ordenRol(b.rol));
        if (rolCompare != 0) return rolCompare;

        // 🔹 opcional: ordenar alfabéticamente dentro del mismo rol
        return a.username.compareTo(b.username);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuarios"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NuevoUsuarioScreen(user: widget.user),
                ),
              );
              setState(() {});
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: usuariosVisibles.length,
        itemBuilder: (_, i) {
          final u = usuariosVisibles[i];

          return ListTile(
            leading: Icon(
              u.rol == Rol.admin
                  ? Icons.admin_panel_settings
                  : u.rol == Rol.supervisor
                  ? Icons.supervisor_account
                  : Icons.person,
            ),
            title: Text(u.username),
            subtitle: Text("Empresas: ${_textoEmpresas(u)}"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UsuarioDetalleScreen(
                    usuario: u,
                    currentUser: widget.user,
                  ),
                ),
              );
              setState(() {});
            },
          );
        },
      ),
    );
  }
}