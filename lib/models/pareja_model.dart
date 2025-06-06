import 'package:cloud_firestore/cloud_firestore.dart';

class Pareja {
  final int idPareja;
  final int idUser1;
  final int idUser2;
  final Timestamp fechaInicio; // Nuevo atributo para la fecha de inicio

  Pareja({
    required this.idPareja,
    required this.idUser1,
    required this.idUser2,
    required this.fechaInicio,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "id_pareja": idPareja,
      "id_user1": idUser1,
      "id_user2": idUser2,
      "fechaInicio": fechaInicio, // Almacenar como Timestamp en Firestore
    };
  }

  // Crear una instancia desde un documento Firestore
  factory Pareja.fromMap(Map<String, dynamic> map) {
    return Pareja(
      idPareja: map["id_pareja"],
      idUser1: map["id_user1"],
      idUser2: map["id_user2"],
      fechaInicio: map["fechaInicio"], // Convierte el Timestamp de Firestore
    );
  }
}
