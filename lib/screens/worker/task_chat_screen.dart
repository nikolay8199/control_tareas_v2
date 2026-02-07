import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../models/comentario.dart';
import '../../models/rol.dart';
import '../../services/remote_data_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/api_config.dart';
import '../../widgets/fullscreen_image_viewer.dart';

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
  final picker = ImagePicker();
  bool _pickerAbierto = false;

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

  Future<void> _enviarImagen(ImageSource source) async {
    if (!_puedeComentar) return;
    if (_pickerAbierto) return;

    _pickerAbierto = true;

    try {
      final XFile? file = await picker.pickImage(source: source);
      if (file == null) return;

      final comentarioTemp = Comentario(
        userId: widget.user.id,
        texto: '',
        imagen: file.path,
        tipo: 'imagen',
      );

      setState(() => _comentarios.add(comentarioTemp));

      await data.subirImagenComentario(
        tareaId: widget.tarea.id,
        userId: widget.user.id,
        file: File(file.path),
      );
      await data.syncAll();

      // 🔎 obtener la tarea actualizada desde el cache del servicio
      final tareaActualizada =
      data.tareas.firstWhere((t) => t.id == widget.tarea.id);

      setState(() {
        _comentarios = List.from(tareaActualizada.comentarios);
      });
    } catch (e) {
      debugPrint("❌ Error subiendo imagen: $e");
    } finally {
      _pickerAbierto = false;
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

                        // 🔥 TEXTO O IMAGEN
                        if (c.tipo == 'imagen' && c.imagen != null)
                          c.imagen!.startsWith('/uploads')
                          // 🌐 Imagen del servidor
                              ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImageViewer(
                                    imageUrl: "${ApiConfig.uploadsUrl}${c.imagen}",
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                "${ApiConfig.uploadsUrl}${c.imagen}",
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                          // 📱 Imagen local temporal
                              : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(c.imagen!),
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  // 📎 BOTÓN WHATSAPP (IMAGEN)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_camera),
                                title: const Text("Tomar foto"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _enviarImagen(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo),
                                title: const Text("Elegir de galería"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _enviarImagen(ImageSource.gallery);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ✏️ INPUT DE TEXTO
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      decoration: const InputDecoration(
                        hintText: "Escribir mensaje...",
                      ),
                    ),
                  ),

                  // 📤 BOTÓN ENVIAR TEXTO
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