import 'package:flutter/foundation.dart';

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

class RemoteDataService extends ChangeNotifier {
  static final RemoteDataService instance = RemoteDataService._internal();
  RemoteDataService._internal();

  final ApiClient api = ApiClient();

  bool _initialized = false;
  bool get initialized => _initialized;

  // Cache en RAM (la UI consume esto)
  final List<Usuario> _usuarios = [];
  final List<Empresa> _empresas = [];
  final List<Tarea> _tareas = [];

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);
  List<Empresa> get empresas => List.unmodifiable(_empresas);
  List<Tarea> get tareas => List.unmodifiable(_tareas);

  /// Defaults (igual a tu DataService actual)
  void _seedDefaults() {
    _usuarios
      ..clear()
      ..addAll([
        Usuario(id: 1, username: 'admin', password: '1234', rol: Rol.admin),
        Usuario(
          id: 2,
          username: 'juan',
          password: '1234',
          rol: Rol.trabajador,
          empresaIds: [1],
        ),
        Usuario(
          id: 3,
          username: 'maria',
          password: '1234',
          rol: Rol.trabajador,
          empresaIds: [1],
        ),
        Usuario(
          id: 4,
          username: 'super1',
          password: '1234',
          rol: Rol.supervisor,
          empresaIds: [1],
        ),
      ]);

    _empresas
      ..clear()
      ..addAll([
        Empresa(
          id: 1,
          nombre: "Empresa Default",
          descripcion: "Empresa creada por defecto",
          ruc: "0000000000",
          dv: "00",
          direccion: "No definida",
          correo: "default@empresa.com",
          telefonoCelular: "00000000",
          telefonoFijo: "00000000",
        ),
      ]);

    _tareas.clear();
  }
  /// 🔄 Refresca manualmente todos los datos desde el backend
  Future<void> refrescar() async {
    try {
      await syncAll();
      debugPrint('🔄 RemoteDataService.refrescar() ejecutado');
    } catch (e, st) {
      debugPrint('❌ Error al refrescar datos');
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }
  /// Carga inicial desde backend
  Future<void> init() async {
    if (_initialized) return;

    try {
      await syncAll();
      _initialized = true;
      notifyListeners();
    } catch (e, st) {
      debugPrint('❌ RemoteDataService.init() fallo al sincronizar con el API');
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: st);

      // ✅ Solo usa defaults en debug. En release, NO lo ocultes.
      if (kDebugMode) {
        _seedDefaults();
        _initialized = true;
        notifyListeners();
        return;
      }

      // ❌ En producción: propaga el error para que lo veas y la app no "finja" que todo está ok
      rethrow;
    }
    debugPrint('🚀 RemoteDataService.init() ejecutado');
  }

  /// Sincroniza todo (usuarios, empresas, tareas)
  Future<void> syncAll() async {
    try {
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
    } catch (e) {
      debugPrint('❌ syncAll() fallo. Posible endpoint con respuesta no esperada.');
      debugPrint('Error: $e');
      rethrow;
    }
  }
  // ======================
  // AUTH
  // ======================

  Future<Usuario?> login(String username, String password) async {
    final res = await api.postJson('/auth/login', {
      'username': username,
      'password': password,
    });

    final userJson = res['user'];
    if (userJson == null) return null;

    final user = UsuarioMapper.fromJson((userJson as Map).cast<String, dynamic>());

    // (Opcional) refresca cache luego de login
    // await syncAll();

    return user;
  }

  // ======================
  // USUARIOS
  // ======================

  Future<void> agregarUsuario(Usuario usuario) async {
    await api.postJson('/usuarios', UsuarioMapper.toJson(usuario));
    await syncAll();
  }

  Future<void> actualizarUsuario(Usuario usuarioActualizado) async {
    await api.patchJson('/usuarios/${usuarioActualizado.id}', UsuarioMapper.toJson(usuarioActualizado));
    await syncAll();
  }

  Future<void> eliminarUsuario(int id) async {
    await api.deleteObj('/usuarios/$id');
    await syncAll();
  }

  // ======================
  // EMPRESAS
  // ======================

  Future<void> crearEmpresa(Empresa empresa) async {
    await api.postJson('/empresas', EmpresaMapper.toJson(empresa));
    await syncAll();
  }

  Future<void> editarEmpresa(Empresa empresaActualizada) async {
    await api.patchJson('/empresas/${empresaActualizada.id}', EmpresaMapper.toJson(empresaActualizada));
    await syncAll();
  }

  Future<void> eliminarEmpresa(int id) async {
    await api.deleteObj('/empresas/$id');
    await syncAll();
  }

  // ======================
  // TAREAS (mismo comportamiento que tu DataService, pero persistiendo en backend)
  // ======================

  Future<void> crearTarea({
    required Usuario actor,
    required Tarea tarea,
  }) async {
    // Validaciones frontend (porque frontend manda)
    if (!actor.esAdminGlobal && !actor.perteneceAEmpresa(tarea.empresaId)) {
      throw Exception('No tiene permiso para crear tareas en esta empresa');
    }

    for (final uid in tarea.asignadoAIds) {
      final user = _usuarios.firstWhere((u) => u.id == uid);
      if (!user.esAdminGlobal && !user.perteneceAEmpresa(tarea.empresaId)) {
        throw Exception('Usuario asignado inválido');
      }
    }

    await api.postJson('/tareas', TareaMapper.toJson(tarea));
    await syncAll();
  }

  Future<void> eliminarTarea(int id) async {
    await api.deleteObj('/tareas/$id');
    await syncAll();
  }

  Future<void> cambiarEstadoTarea({
    required int tareaId,
    required EstadoTarea nuevoEstado,
  }) async {
    await api.patchJson('/tareas/$tareaId/estado', {
      'estado': nuevoEstado.name,
    });
    await syncAll();
  }

  Future<void> agregarComentarioATarea({
    required int tareaId,
    required Comentario comentario,
  }) async {
    await api.postJson('/tareas/$tareaId/comentarios', ComentarioMapper.toJson(comentario));
    await syncAll();
  }

  // ======================
  // Helpers (iguales a tu DataService)
  // ======================

  List<Tarea> tareasPorUsuario(int usuarioId) =>
      _tareas.where((t) => t.asignadoAIds.contains(usuarioId)).toList();

  List<Tarea> filtrarTareas(TaskFilter filter) =>
      _tareas.where(filter.matches).toList();

  List<Usuario> usuariosAsignables({
    required Usuario actor,
    required int empresaId,
  }) {
    return _usuarios.where((u) {
      if (u.esAdminGlobal) return true;
      return u.perteneceAEmpresa(empresaId);
    }).toList();
  }
}