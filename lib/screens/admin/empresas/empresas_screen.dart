import 'package:flutter/material.dart';
import '../../../services/remote_data_service.dart';
import 'empresa_detalle_screen.dart';
import 'nueva_empresa_screen.dart';

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  final data = RemoteDataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Empresas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NuevaEmpresaScreen()),
              );
              setState(() {});
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: data.empresas.length,
        itemBuilder: (_, i) {
          final e = data.empresas[i];
          return ListTile(
            title: Text(e.nombre),
            subtitle: Text(e.descripcion),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmpresaDetalleScreen(empresa: e),
                ),
              );
            },
          );
        },
      ),
    );
  }
}