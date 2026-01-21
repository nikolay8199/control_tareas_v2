import 'package:flutter/material.dart';
import '../../../models/usuario.dart';
import '../../../models/rol.dart';
import '../../../services/remote_data_service.dart';
import '../../worker/task_chat_screen.dart';
import 'usuario_editar_screen.dart';

class UsuarioDetalleScreen extends StatelessWidget {
  final Usuario usuario;       // usuario que se está viendo
  final Usuario currentUser;   // usuario logueado

  UsuarioDetalleScreen({
    super.key,
    required this.usuario,
    required this.currentUser,
  });

  final data = RemoteDataService.instance;

  bool get _esAdminProtegido =>
      usuario.rol == Rol.admin && currentUser.rol == Rol.supervisor;

  Widget _resumenUsuario({
    required int total,
    required int enProceso,
    required int completadas,
    required int vencidas,
    required double progreso,
    required int porcentaje,
    required Color color,
    required String mensaje,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
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

  @override
  Widget build(BuildContext context) {
    // 🔹 Empresas del usuario
    final empresasUsuario = usuario.esAdminGlobal
        ? []
        : data.empresas
        .where((e) => usuario.empresaIds.contains(e.id))
        .toList();

    // 🔹 Tareas donde está asignado
    final tareas = data.tareas
        .where((t) => t.asignadoAIds.contains(usuario.id))
        .toList();

    // 🔵 MÉTRICAS DEL USUARIO
    final total = tareas.length;

    final enProceso =
        tareas.where((t) => t.estado.name == "enProceso").length;

    final completadas =
        tareas.where((t) => t.estado.name == "completada").length;

    final vencidas = tareas.where(
          (t) => t.estaVencida && t.estado.name != "completada",
    ).length;

    final progreso = total == 0 ? 0.0 : completadas / total;

    final porcentaje = (progreso * 100).round();

    Color color;
    String mensaje;

    if (vencidas > 0) {
      color = Colors.red;
      mensaje = "⚠ Tiene tareas vencidas";
    } else if (porcentaje == 100 && total > 0) {
      color = Colors.green;
      mensaje = "✔ Todo al día";
    } else {
      color = Colors.orange;
      mensaje = "⏳ En progreso";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Usuario: ${usuario.username}"),
        actions: [
          // ✏️ EDITAR
          if (!_esAdminProtegido)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UsuarioEditarScreen(usuario: usuario),
                  ),
                );
                Navigator.pop(context);
              },
            ),

          // 🗑️ ELIMINAR
          if (!_esAdminProtegido)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Eliminar usuario"),
                    content: const Text(
                      "¿Deseas eliminar este usuario?\n\n"
                          "Será removido de las tareas donde esté asignado.",
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
                  data.eliminarUsuario(usuario.id);
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
            Text("Username: ${usuario.username}"),
            Text("Rol: ${usuario.rol.name}"),

            const SizedBox(height: 8),

            // ---------- EMPRESAS ----------
            if (usuario.esAdminGlobal)
              const Text("Empresas: Administrador global")
            else ...[
              const Text(
                "Empresas:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (empresasUsuario.isEmpty)
                const Text("No tiene empresas asignadas"),
              ...empresasUsuario.map(
                    (e) => Text("• ${e.nombre}"),
              ),
            ],

            if (_esAdminProtegido)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "⚠ Este administrador no puede ser modificado por un supervisor",
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 20),

            // ---------- RESUMEN DE TAREAS ----------
            _resumenUsuario(
              total: total,
              enProceso: enProceso,
              completadas: completadas,
              vencidas: vencidas,
              progreso: progreso,
              porcentaje: porcentaje,
              color: color,
              mensaje: mensaje,
            ),

            // ---------- TAREAS ----------
            Text(
              "Tareas asignadas:",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            if (tareas.isEmpty)
              const Text("No tiene tareas asignadas"),

            ...tareas.map(
                  (t) => ListTile(
                leading: const Icon(Icons.task),
                title: Text(t.titulo),
                subtitle: Text("Empresa ID: ${t.empresaId}"),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskChatScreen(
                        tarea: t,
                        user: currentUser,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}