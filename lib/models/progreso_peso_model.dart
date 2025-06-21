class ProgresoPeso {
  final int idProgreso;
  final int idUsuario;
  final double peso;
  final DateTime fecha;
  final String? notas;

  ProgresoPeso({
    required this.idProgreso,
    required this.idUsuario,
    required this.peso,
    required this.fecha,
    this.notas,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "id_progreso": idProgreso,
      "id_usuario": idUsuario,
      "peso": peso,
      "fecha": fecha.toIso8601String(),
      "notas": notas,
    };
  }

  // Crear una instancia desde un documento Firestore
  factory ProgresoPeso.fromMap(Map<String, dynamic> map) {
    return ProgresoPeso(
      idProgreso: map["id_progreso"],
      idUsuario: map["id_usuario"],
      peso: map["peso"].toDouble(),
      fecha: DateTime.parse(map["fecha"]),
      notas: map["notas"],
    );
  }
} 