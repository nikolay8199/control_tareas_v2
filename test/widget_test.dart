import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:control_tareas/main.dart';

void main() {
  testWidgets('App carga correctamente', (WidgetTester tester) async {
    // Construye la app
    await tester.pumpWidget(const ControlTareasApp());

    // Verifica que el texto inicial exista
    expect(find.text('Control de Tareas – base cargada'), findsOneWidget);
  });
}
