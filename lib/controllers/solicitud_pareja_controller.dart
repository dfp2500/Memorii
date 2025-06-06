import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solicitud_pareja_model.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class SolicitudParejaController {
  final CollectionReference _solicitudesRef =
  FirebaseFirestore.instance.collection('solicitudes_pareja');
  final CollectionReference _usuariosRef =
  FirebaseFirestore.instance.collection('usuarios');

  UsuarioController _usuarioController = UsuarioController();

  Future<bool> tienePareja(int idUsuario) async {
    return await _usuarioController.get_idPareja(idUsuario: idUsuario) != -1;
  }

  Future<void> enviarSolicitud(int idEmisor, String correoReceptor) async {
    int idReceptor = await _usuarioController.obtenerIdUsuario(correoReceptor);

    if (idReceptor != -1) {
      if (await tienePareja(idEmisor) || await tienePareja(idReceptor)) {
        throw Exception('Uno de los usuarios ya tiene pareja.');
      }
    }
    else {
      throw Exception('El usuario no existe.');
    }

    await _solicitudesRef.add({
      'id_emisor': idEmisor,
      'correo_receptor': correoReceptor,
    });
  }

  Future<List<SolicitudPareja>> obtenerSolicitudesRecibidas(String correoReceptor) async {
    try {
      final QuerySnapshot snapshot = await _solicitudesRef
          .where('correo_receptor', isEqualTo: correoReceptor)
          .get();

      // Convertimos los documentos en una lista de SolicitudPareja
      return snapshot.docs.map((doc) => SolicitudPareja.fromSnapshot(doc)).toList();
    } catch (e) {
      print('Error obteniendo solicitudes: $e');
      return [];
    }
  }

  Future<void> aceptarSolicitud(String idSolicitud, int idEmisor, String correoReceptor) async {
    int idReceptor = await _usuarioController.obtenerIdUsuario(correoReceptor);
    if (await tienePareja(idEmisor) || await tienePareja(idReceptor)) {
      print("ya tien pareja");
      throw Exception('Uno de los usuarios ya tiene pareja.');
    }
    
    List<String> solicitudesEmisor = await obtenerSolicitudesPorIdEmisor(idEmisor);
    // Elimina todas las solicitudes del emisor
    for (String solicitudId in solicitudesEmisor) {
      await eliminarSolicitud(solicitudId);
    }

    List<String> solicitudesReceptor = await obtenerSolicitudesPorCorreoReceptor(correoReceptor);
    // Elimina todas las solicitudes del receptor
    for (String solicitudId in solicitudesReceptor) {
      await eliminarSolicitud(solicitudId);
    }
    
    _usuarioController.agregarPareja(idUser1: idEmisor, idUser2: idReceptor);
  }
  
  Future<void> eliminarSolicitud(String idSolicitud) async {
    await _solicitudesRef.doc(idSolicitud).delete();
  }

  Future<String?> obtenerIdSolicitud(int idEmisor, String correoReceptor) async {
    try {
      final QuerySnapshot snapshot = await _solicitudesRef
          .where('id_emisor', isEqualTo: idEmisor)
          .where('correo_receptor', isEqualTo: correoReceptor)
          .limit(1) // Solo buscamos una solicitud
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Devuelve el ID del documento
      } else {
        return null; // No se encontró la solicitud
      }
    } catch (e) {
      print("Error obteniendo ID de solicitud: $e");
      return null;
    }
  }

  Future<List<String>> obtenerSolicitudesPorIdEmisor(int idEmisor) async {
    try {
      final QuerySnapshot snapshot = await _solicitudesRef
          .where('id_emisor', isEqualTo: idEmisor)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print("Error obteniendo solicitudes por idEmisor: $e");
      return [];
    }
  }

  Future<List<String>> obtenerSolicitudesPorCorreoReceptor(String correoReceptor) async {
    int idReceptor = await _usuarioController.obtenerIdUsuario(correoReceptor);
    return obtenerSolicitudesPorIdEmisor(idReceptor);
  }
}
