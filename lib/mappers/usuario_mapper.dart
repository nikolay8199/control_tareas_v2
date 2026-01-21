import '../models/usuario.dart';
import '../models/rol.dart';

class UsuarioMapper {
  static Map<String, dynamic> toJson(Usuario u) => {
    'id': u.id,
    'username': u.username,
    'password': u.password,
    'rol': u.rol.name,
    'empresaIds': u.empresaIds,
  };

  static Usuario fromJson(Map<String, dynamic> j) => Usuario(
    id: j['id'] as int,
    username: (j['username'] ?? '') as String,
    password: (j['password'] ?? '') as String,
    rol: Rol.values.byName((j['rol'] ?? 'trabajador') as String),
    empresaIds: List<int>.from((j['empresaIds'] ?? const []) as List),
  );
}