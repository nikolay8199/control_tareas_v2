import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/estado_tarea.dart';
import '../../models/prioridad.dart';
import '../../services/remote_data_service.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final data = RemoteDataService.instance;

  // -------------------- KPIs --------------------

  int get totalTareas => data.tareas.length;

  int get completadasHoy {
    final hoy = DateTime.now();
    return data.tareas.where((t) =>
    t.estado == EstadoTarea.completada &&
        t.completadaEn != null &&
        t.completadaEn!.day == hoy.day &&
        t.completadaEn!.month == hoy.month &&
        t.completadaEn!.year == hoy.year).length;
  }

  int get enProceso =>
      data.tareas.where((t) => t.estado == EstadoTarea.enProceso).length;

  int get sinIniciar =>
      data.tareas.where((t) => t.estado == EstadoTarea.sinIniciar).length;

  int get completadas =>
      data.tareas.where((t) => t.estado == EstadoTarea.completada).length;

  int get vencidas {
    final hoy = DateTime.now();
    return data.tareas.where((t) =>
    t.fechaLimite != null &&
        t.fechaLimite!.isBefore(hoy) &&
        t.estado != EstadoTarea.completada).length;
  }

  // -------------------- Ranking --------------------

  List<Map<String, dynamic>> get rankingUsuarios {
    final usuarios = data.usuarios
        .where((u) => u.rol.toString().contains("trabajador"))
        .toList();

    return usuarios
        .map((u) {
      final completadas = data.tareas.where((t) {
        return t.estado == EstadoTarea.completada &&
            t.asignadoAIds.contains(u.id);
      }).length;

      return {
        "usuario": u.username,
        "completadas": completadas,
      };
    })
        .toList()
      ..sort((a, b) {
        final int compB = (b["completadas"] ?? 0) as int;
        final int compA = (a["completadas"] ?? 0) as int;
        return compB.compareTo(compA);
      });
  }

  // -------------------- Por empresa --------------------

  List<Map<String, dynamic>> get tareasPorEmpresa {
    return data.empresas.map((e) {
      final tareasEmpresa =
          data.tareas.where((t) => t.empresaId == e.id).length;
      return {"empresa": e.nombre, "total": tareasEmpresa};
    }).toList();
  }

  // -------------------- Widgets reutilizables --------------------

  Widget _kpi(String titulo, int valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            valor.toString(),
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // -------------------- Gráfico circular (Estado de tareas) --------------------

  Widget _graficoEstados() {
    final sinIniciar = data.tareas
        .where((t) => t.estado == EstadoTarea.sinIniciar)
        .length
        .toDouble();
    final enProceso =
    data.tareas.where((t) => t.estado == EstadoTarea.enProceso).length.toDouble();
    final completadas =
    data.tareas.where((t) => t.estado == EstadoTarea.completada).length.toDouble();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: sinIniciar,
              title: "Sin iniciar",
              color: Colors.grey,
              radius: 50,
            ),
            PieChartSectionData(
              value: enProceso,
              title: "En proceso",
              color: Colors.orange,
              radius: 50,
            ),
            PieChartSectionData(
              value: completadas,
              title: "Completadas",
              color: Colors.green,
              radius: 50,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Gráfico barras (Prioridad) --------------------

  Widget _graficoPrioridad() {
    final alta =
    data.tareas.where((t) => t.prioridad == Prioridad.alta).length.toDouble();
    final media =
    data.tareas.where((t) => t.prioridad == Prioridad.media).length.toDouble();
    final baja =
    data.tareas.where((t) => t.prioridad == Prioridad.baja).length.toDouble();

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: alta,
                  color: Colors.red,
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: media,
                  color: Colors.orange,
                  width: 20,
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: baja,
                  color: Colors.green,
                  width: 20,
                ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text("Alta");
                    case 1:
                      return const Text("Media");
                    case 2:
                      return const Text("Baja");
                  }
                  return const Text("");
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard del Administrador")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // -------------------- KPIs --------------------
          const Text("Indicadores generales",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _kpi("Total tareas", totalTareas, Colors.blue),
              _kpi("Completadas hoy", completadasHoy, Colors.green),
              _kpi("En proceso", enProceso, Colors.orange),
              _kpi("Retrasadas", vencidas, Colors.red),
            ],
          ),

          const SizedBox(height: 30),

          // -------------------- Gráfico estados --------------------
          const Text("Estado de las tareas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _graficoEstados(),

          const SizedBox(height: 30),

          // -------------------- Gráfico prioridad --------------------
          const Text("Prioridad de las tareas",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          _graficoPrioridad(),

          const SizedBox(height: 30),

          // -------------------- Ranking --------------------
          const Text("Ranking de usuarios",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          ...rankingUsuarios.map(
                (r) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(r["usuario"]),
              trailing: Text(
                "${r["completadas"]} completadas",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // -------------------- Empresa --------------------
          const Text("Tareas por empresa",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

          ...tareasPorEmpresa.map(
                (e) => ListTile(
              leading: const Icon(Icons.business),
              title: Text(e["empresa"]),
              trailing: Text("${e["total"]} tareas",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}