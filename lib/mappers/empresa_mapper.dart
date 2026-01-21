import '../models/empresa.dart';

class EmpresaMapper {
  static Map<String, dynamic> toJson(Empresa e) => {
    'id': e.id,
    'nombre': e.nombre,
    'descripcion': e.descripcion,
    'ruc': e.ruc,
    'dv': e.dv,
    'direccion': e.direccion,
    'correo': e.correo,
    'telefonoCelular': e.telefonoCelular,
    'telefonoFijo': e.telefonoFijo,
  };

  static Empresa fromJson(Map<String, dynamic> j) => Empresa(
    id: j['id'] as int,
    nombre: (j['nombre'] ?? '') as String,
    descripcion: (j['descripcion'] ?? '') as String,
    ruc: (j['ruc'] ?? '') as String,
    dv: (j['dv'] ?? '') as String,
    direccion: (j['direccion'] ?? '') as String,
    correo: (j['correo'] ?? '') as String,
    telefonoCelular: (j['telefonoCelular'] ?? '') as String,
    telefonoFijo: (j['telefonoFijo'] ?? '') as String,
  );
}