class Empresa {
  final int id;
  final String nombre;
  final String descripcion;

  // 🔥 NUEVOS CAMPOS
  final String ruc;
  final String dv;
  final String direccion;
  final String correo;
  final String telefonoCelular;
  final String telefonoFijo;

  Empresa({
    required this.id,
    required this.nombre,
    this.descripcion = "",
    required this.ruc,
    required this.dv,
    required this.direccion,
    required this.correo,
    required this.telefonoCelular,
    required this.telefonoFijo,
  });

  // 🔹 Helper opcional (bonito para UI)
  String get rucCompleto => "$ruc/$dv";
}