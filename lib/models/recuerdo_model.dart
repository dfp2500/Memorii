// Enumerado para la valoración
import 'package:cloud_firestore/cloud_firestore.dart';

enum Valoracion { Nose, Fata, TaBien, Genialisaro }

class Recuerdo {
  final Timestamp fecha;
  final String texto;
  final List<String> fotos;
  final int idPareja;
  final Valoracion valoracionUsuario1;
  final Valoracion valoracionUsuario2;

  Recuerdo({
    required this.fecha,
    required this.texto,
    required this.fotos,
    required this.idPareja,
    required this.valoracionUsuario1,
    required this.valoracionUsuario2,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "fecha": fecha,
      "texto": texto,
      "fotos": fotos,
      "id_pareja": idPareja,
      "valoracion_usuario1": valoracionUsuario1.name,
      "valoracion_usuario2": valoracionUsuario2.name,
      "usuario_ultima_valoracion": -1,
    };
  }

  // Crear una instancia desde un documento Firestore
  factory Recuerdo.fromMap(Map<String, dynamic> map) {
    return Recuerdo(
      fecha: map["fecha"],
      texto: map["texto"],
      fotos: List<String>.from(map["fotos"]),
      idPareja: map["id_pareja"],
      valoracionUsuario1: Valoracion.values.firstWhere(
              (e) => e.name == map["valoracion_usuario1"], orElse: () => Valoracion.Nose),
      valoracionUsuario2: Valoracion.values.firstWhere(
              (e) => e.name == map["valoracion_usuario2"], orElse: () => Valoracion.Nose),
    );
  }
}
