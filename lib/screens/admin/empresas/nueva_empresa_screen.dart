import 'package:flutter/material.dart';
import '../../../models/empresa.dart';
import '../../../services/remote_data_service.dart';

class NuevaEmpresaScreen extends StatefulWidget {
  const NuevaEmpresaScreen({super.key});

  @override
  State<NuevaEmpresaScreen> createState() => _NuevaEmpresaScreenState();
}

class _NuevaEmpresaScreenState extends State<NuevaEmpresaScreen> {
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  final rucCtrl = TextEditingController();
  final dvCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final celularCtrl = TextEditingController();
  final fijoCtrl = TextEditingController();

  final data = RemoteDataService.instance;

  Future<void> _guardar() async {
    if (nombreCtrl.text.trim().isEmpty) return;
    if (rucCtrl.text.isEmpty || dvCtrl.text.length != 2) return;

    final nueva = Empresa(
      id: 0, // backend asigna id
      nombre: nombreCtrl.text.trim(),
      descripcion: descCtrl.text.trim(),
      ruc: rucCtrl.text.trim(),
      dv: dvCtrl.text.trim(),
      direccion: direccionCtrl.text.trim(),
      correo: correoCtrl.text.trim(),
      telefonoCelular: celularCtrl.text.trim(),
      telefonoFijo: fijoCtrl.text.trim(),
    );

    try {
      await data.crearEmpresa(nueva);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando empresa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Empresa")),
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

            // ---------------- RUC / DV ----------------
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
              child: const Text("Guardar Empresa"),
            ),
          ],
        ),
      ),
    );
  }
}