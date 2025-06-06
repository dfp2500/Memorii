class Usuario {
  final String nombre;
  final String email;
  final String contrasenia;
  final int idUsuario;
  final String fotoPerfil;

  Usuario({required this.nombre, required this.email, required this.contrasenia, required this.idUsuario, required this.fotoPerfil});

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "email": email,
      "contrasenia": contrasenia,
      "id_usuario": idUsuario,
      "foto_perfil": fotoPerfil,
    };
  }

  // Crear una instancia desde un documento Firestore
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      nombre: map["nombre"],
      email: map["email"],
      contrasenia: map["contrasenia"],
      idUsuario: map["id_usuario"],
      fotoPerfil: map["foto_perfil"]
    );
  }
}
