import 'package:flutter/material.dart';
import '../../../models/empresa.dart';
import '../../../services/remote_data_service.dart';
import 'empresa_editar_screen.dart';

class EmpresaDetalleScreen extends StatelessWidget {
  final Empresa empresa;
  final data = RemoteDataService.instance;

  EmpresaDetalleScreen({
    super.key,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    // 🔹 Usuarios que pertenecen a esta empresa (NO admins globales)
    final usuarios = data.usuarios
        .where(
          (u) => !u.esAdminGlobal && u.empresaIds.contains(empresa.id),
    )
        .toList();

    // 🔹 Tareas de esta empresa
    final tareas =
    data.tareas.where((t) => t.empresaId == empresa.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(empresa.nombre),
        actions: [
          // ✏️ Editar empresa
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EmpresaEditarScreen(empresa: empresa),
                ),
              );
              Navigator.pop(context);
            },
          ),

          // 🗑️ Eliminar empresa
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Eliminar empresa"),
                  content: const Text(
                    "¿Deseas eliminar esta empresa?\n\n"
                        "• La empresa será removida de los usuarios asociados.\n"
                        "• Las tareas de esta empresa serán eliminadas.\n\n"
                        "Esta acción no se puede deshacer.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text("Eliminar"),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                data.eliminarEmpresa(empresa.id);
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
            // ================= DATOS DE LA EMPRESA =================
            Text(
              "Información de la empresa",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),

            _dato("Nombre", empresa.nombre),
            _dato("Descripción", empresa.descripcion),
            _dato("RUC", empresa.rucCompleto),
            _dato("Dirección", empresa.direccion),
            _dato("Correo electrónico", empresa.correo),
            _dato("Teléfono celular", empresa.telefonoCelular),
            _dato("Teléfono fijo", empresa.telefonoFijo),

            const SizedBox(height: 30),

            // ================= USUARIOS =================
            Text(
              "Usuarios asociados:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (usuarios.isEmpty)
              const Text("No hay usuarios asociados a esta empresa."),
            ...usuarios.map(
                  (u) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(u.username),
              ),
            ),

            const SizedBox(height: 20),

            // ================= TAREAS =================
            Text(
              "Tareas:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (tareas.isEmpty)
              const Text("No hay tareas asociadas a esta empresa."),
            ...tareas.map(
                  (t) => ListTile(
                leading: const Icon(Icons.task),
                title: Text(t.titulo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPER =================
  Widget _dato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: valor.isEmpty ? "-" : valor,
            ),
          ],
        ),
      ),
    );
  }
}