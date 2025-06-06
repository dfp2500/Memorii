import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudPareja {
  int idEmisor;
  String correoReceptor;

  SolicitudPareja({
    required this.idEmisor,
    required this.correoReceptor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_emisor': idEmisor,
      'correo_receptor': correoReceptor,
    };
  }

  static SolicitudPareja fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return SolicitudPareja(
      idEmisor: data['id_emisor'],
      correoReceptor: data['correo_receptor'],
    );
  }
}
