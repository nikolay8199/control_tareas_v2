import 'rol.dart';

class Usuario {
  final int id;
  final String username;
  final String password;
  final Rol rol;

  /// Para trabajador/supervisor:
  /// lista de empresas a las que pertenece
  ///
  /// Para admin:
  /// puede ser lista vacía => admin global
  final List<int> empresaIds;

  Usuario({
    required this.id,
    required this.username,
    required this.password,
    required this.rol,
    List<int>? empresaIds,
  }) : empresaIds = empresaIds ?? const [];

  /// ─────────────────────────────
  /// Helpers de negocio (IMPORTANTES)
  /// ─────────────────────────────

  /// Admin global (no depende de empresas)
  bool get esAdminGlobal => rol == Rol.admin;

  /// Pertenece a una empresa específica
  bool perteneceAEmpresa(int empresaId) =>
      empresaIds.contains(empresaId);

  /// Puede ver/operar sobre una empresa
  bool puedeAccederAEmpresa(int empresaId) =>
      esAdminGlobal || perteneceAEmpresa(empresaId);
}
