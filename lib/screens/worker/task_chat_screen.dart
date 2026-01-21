import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../models/comentario.dart';
import '../../models/rol.dart';
import '../../services/remote_data_service.dart';

class TaskChatScreen extends StatefulWidget {
  final Tarea tarea;
  final Usuario user;

  const TaskChatScreen({
    super.key,
    required this.tarea,
    required this.user,
  });

  @override
  State<TaskChatScreen> createState() => _TaskChatScreenState();
}

class _TaskChatScreenState extends State<TaskChatScreen> {
  final msgCtrl = TextEditingController();
  final data = RemoteDataService.instance;
  late List<Comentario> _comentarios;

  bool get _puedeComentar {
    if (widget.user.rol == Rol.admin) return true;

    if (widget.user.rol == Rol.supervisor &&
        widget.user.empresaIds.contains(widget.tarea.empresaId)) {
      return true;
    }

    if (widget.tarea.asignadoAIds.contains(widget.user.id)) {
      return true;
    }

    if (widget.tarea.creadoPorId == widget.user.id) {
      return true;
    }

    return false;
  }

  Future<void> _enviarMensaje() async {
    if (!_puedeComentar) return;

    final texto = msgCtrl.text.trim();
    if (texto.isEmpty) return;

    final nuevo = Comentario(
      userId: widget.user.id,
      texto: texto,
      fecha: DateTime.now(),
    );

    // 1️⃣ MOSTRAR INMEDIATAMENTE EN UI
    setState(() {
      _comentarios.add(nuevo);
      msgCtrl.clear();
    });

    // 2️⃣ ENVIAR AL BACKEND EN SEGUNDO PLANO
    try {
      await data.agregarComentarioATarea(
        tareaId: widget.tarea.id,
        comentario: nuevo,
      );
    } catch (e) {
      debugPrint("❌ Error enviando comentario: $e");
      // (opcional) aquí podrías marcar el mensaje como fallido
    }
  }

  String _fechaCompleta(DateTime f) {
    return "${f.day.toString().padLeft(2, '0')}/"
        "${f.month.toString().padLeft(2, '0')}/"
        "${f.year} "
        "${f.hour.toString().padLeft(2, '0')}:"
        "${f.minute.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _comentarios = List.from(widget.tarea.comentarios);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Comentarios - ${widget.tarea.titulo}"),
      ),
      body: Column(
        children: [
          // ---------- MENSAJES ----------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _comentarios.length,
              itemBuilder: (_, i) {
                final c = _comentarios[i];
                final esMio = c.userId == widget.user.id;

                final usuario = data.usuarios
                    .where((u) => u.id == c.userId)
                    .cast<Usuario?>()
                    .firstWhere(
                      (u) => u != null,
                  orElse: () => null,
                );

                final nombre =
                    usuario?.username ?? "Usuario eliminado";

                return Align(
                  alignment:
                  esMio ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: esMio
                          ? Colors.blue.shade100
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: esMio
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.texto,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _fechaCompleta(c.fecha),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ---------- INPUT ----------
          if (_puedeComentar)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      decoration: const InputDecoration(
                        hintText: "Escribir mensaje...",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _enviarMensaje,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade200,
              child: const Text(
                "No tienes permisos para comentar en esta tarea.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}