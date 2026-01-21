import 'package:flutter/material.dart';
import '../../models/tarea.dart';
import '../../models/prioridad.dart';
import '../../services/remote_data_service.dart';

class TareaEditarScreen extends StatefulWidget {
  final Tarea tarea;

  const TareaEditarScreen({
    super.key,
    required this.tarea,
  });

  @override
  State<TareaEditarScreen> createState() => _TareaEditarScreenState();
}

class _TareaEditarScreenState extends State<TareaEditarScreen> {
  final tituloCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

  final data = RemoteDataService.instance;

  DateTime? fechaLimite;
  Prioridad prioridad = Prioridad.media;

  @override
  void initState() {
    super.initState();
    final t = widget.tarea;

    tituloCtrl.text = t.titulo;
    descripcionCtrl.text = t.descripcion;
    fechaLimite = t.fechaLimite;
    prioridad = t.prioridad;
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: fechaLimite ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (seleccion != null) {
      setState(() => fechaLimite = seleccion);
    }
  }

  void _guardar() {
    if (tituloCtrl.text.trim().isEmpty ||
        descripcionCtrl.text.trim().isEmpty) {
      return;
    }

    final original = widget.tarea;

    final actualizada = Tarea(
      id: original.id,
      titulo: tituloCtrl.text.trim(),
      descripcion: descripcionCtrl.text.trim(),
      empresaId: original.empresaId,
      asignadoAIds: List.from(original.asignadoAIds),
      creadoPorId: original.creadoPorId,
      creadaEn: original.creadaEn,
      fechaLimite: fechaLimite,
      completadaEn: original.completadaEn,
      prioridad: prioridad,
      estado: original.estado,
      comentarios: List.from(original.comentarios),
    );

    // 🔄 reemplazo seguro
    data.eliminarTarea(original.id);
    data.crearTarea(
      actor: data.usuarios.firstWhere((u) => u.id == original.creadoPorId),
      tarea: actualizada,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String textoFecha() {
      if (fechaLimite == null) return "Sin fecha límite";
      return "${fechaLimite!.day}/${fechaLimite!.month}/${fechaLimite!.year}";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar tarea"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: "Título"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(labelText: "Descripción"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<Prioridad>(
              value: prioridad,
              items: Prioridad.values.map((p) {
                final texto =
                p == Prioridad.alta ? "Alta" : p == Prioridad.media ? "Media" : "Baja";
                return DropdownMenuItem(
                  value: p,
                  child: Text(texto),
                );
              }).toList(),
              onChanged: (v) => setState(() => prioridad = v!),
              decoration: const InputDecoration(labelText: "Prioridad"),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(textoFecha()),
                TextButton(
                  onPressed: _seleccionarFecha,
                  child: const Text("Elegir fecha"),
                ),
              ],
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _guardar,
              child: const Text("Guardar cambios"),
            ),
          ],
        ),
      ),
    );
  }
}