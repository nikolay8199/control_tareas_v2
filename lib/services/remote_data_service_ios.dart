import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/comentario.dart';
import '../models/empresa.dart';
import '../models/estado_tarea.dart';
import '../models/task_filter.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';
import '../models/rol.dart';

import '../mappers/usuario_mapper.dart';
import '../mappers/empresa_mapper.dart';
import '../mappers/tarea_mapper.dart';
import '../mappers/comentario_mapper.dart';

import 'api_client.dart';
import '../config/api_config.dart';

class RemoteDataService extends ChangeNotifier {
  static final RemoteDataService instance = RemoteDataService._internal();
  RemoteDataService._internal();

  final ApiClient api = ApiClient();

  bool _initialized = false;
  bool get initialized => _initialized;

  final List<Usuario> _usuarios = [];
  final List<Empresa> _empresas = [];
  final List<Tarea> _tareas = [];

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);
  List<Empresa> get empresas => List.unmodifiable(_empresas);
  List<Tarea> get tareas => List.unmodifiable(_tareas);

  Future<void> refrescar() async {
    await syncAll();
  }

  Future<void> init() async {
    if (_initialized) return;

    await syncAll();
    _initialized = true;
    notifyListeners();

    debugPrint('🍎 RemoteDataService.init() en iOS');
  }

  Future<void> syncAll() async {
    final u = await api.getList('/usuarios');
    final e = await api.getList('/empresas');
    final t = await api.getList('/tareas');

    _usuarios
      ..clear()
      ..addAll(u.map((x) => UsuarioMapper.fromJson((x as Map).cast<String, dynamic>())));

    _empresas
      ..clear()
      ..addAll(e.map((x) => EmpresaMapper.fromJson((x as Map).cast<String, dynamic>())));

    _tareas
      ..clear()
      ..addAll(t.map((x) => TareaMapper.fromJson((x as Map).cast<String, dynamic>())));

    notifyListeners();
  }

  Future<Usuario?> login(String username, String password) async {
    final res = await api.postJson('/auth/login', {
      'username': username,
      'password': password,
    });

    final userJson = res['user'];
    if (userJson == null) return null;

    return UsuarioMapper.fromJson((userJson as Map).cast<String, dynamic>());
  }

  Future<void> subirImagenComentario({
    required int tareaId,
    required int userId,
    required File file,
  }) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}/tareas/$tareaId/comentarios/imagen");

    final request = http.MultipartRequest("POST", uri)
      ..fields["userId"] = "$userId"
      ..files.add(await http.MultipartFile.fromPath("imagen", file.path));

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception("Error subiendo imagen: ${response.statusCode}");
    }
  }
}