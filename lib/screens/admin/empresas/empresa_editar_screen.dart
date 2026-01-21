import 'package:flutter/material.dart';
import '../../../models/empresa.dart';
import '../../../services/remote_data_service.dart';

class EmpresaEditarScreen extends StatefulWidget {
  final Empresa empresa;

  const EmpresaEditarScreen({
    super.key,
    required this.empresa,
  });

  @override
  State<EmpresaEditarScreen> createState() => _EmpresaEditarScreenState();
}

class _EmpresaEditarScreenState extends State<EmpresaEditarScreen> {
  final data = RemoteDataService.instance;

  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final rucCtrl = TextEditingController();
  final dvCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final celularCtrl = TextEditingController();
  final fijoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final e = widget.empresa;

    nombreCtrl.text = e.nombre;
    descCtrl.text = e.descripcion;
    rucCtrl.text = e.ruc;
    dvCtrl.text = e.dv;
    direccionCtrl.text = e.direccion;
    correoCtrl.text = e.correo;
    celularCtrl.text = e.telefonoCelular;
    fijoCtrl.text = e.telefonoFijo;
  }

  void _guardar() {
    if (nombreCtrl.text.trim().isEmpty) return;
    if (rucCtrl.text.trim().isEmpty || dvCtrl.text.length != 2) return;

    final actualizada = Empresa(
      id: widget.empresa.id,
      nombre: nombreCtrl.text.trim(),
      descripcion: descCtrl.text.trim(),
      ruc: rucCtrl.text.trim(),
      dv: dvCtrl.text.trim(),
      direccion: direccionCtrl.text.trim(),
      correo: correoCtrl.text.trim(),
      telefonoCelular: celularCtrl.text.trim(),
      telefonoFijo: fijoCtrl.text.trim(),
    );

    data.editarEmpresa(actualizada);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Empresa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Descripción"),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // -------- RUC / DV --------
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: rucCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "RUC"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: dvCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    decoration: const InputDecoration(
                      labelText: "DV",
                      counterText: "",
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            TextField(
              controller: direccionCtrl,
              decoration: const InputDecoration(labelText: "Dirección"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
              const InputDecoration(labelText: "Correo electrónico"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: celularCtrl,
              keyboardType: TextInputType.phone,
              decoration:
              const InputDecoration(labelText: "Teléfono celular"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: fijoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Teléfono fijo"),
            ),
            const SizedBox(height: 30),

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