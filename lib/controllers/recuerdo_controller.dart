import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:memorii/models/recuerdo_model.dart';

class RecuerdoController {
  final CollectionReference _recuerdosCollection =
  FirebaseFirestore.instance.collection('recuerdos');

  // Obtener todos los recuerdos de un mes específico para un idPareja
  Future<List<Recuerdo>> obtenerRecuerdosPorMes(int mes, int idPareja) async {
    try {
      final QuerySnapshot snapshot = await _recuerdosCollection
          .where('id_pareja', isEqualTo: idPareja)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(DateTime.now().year, mes, 1)))
          .where('fecha', isLessThan: Timestamp.fromDate(DateTime(DateTime.now().year, mes + 1, 1)))
          .get();

      return snapshot.docs
          .map((doc) => Recuerdo.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error al obtener recuerdos por mes: $e');
      return [];
    }
  }

  // Obtener el recuerdo de un día específico para un idPareja
  Future<Recuerdo?> obtenerRecuerdoPorDia(DateTime dia, int idPareja) async {
    try {
      final QuerySnapshot snapshot = await _recuerdosCollection
          .where('id_pareja', isEqualTo: idPareja)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(dia.year, dia.month, dia.day)))
          .where('fecha', isLessThan: Timestamp.fromDate(DateTime(dia.year, dia.month, dia.day + 1)))
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Recuerdo.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error al obtener recuerdo por día: $e');
    }
    return null;
  }

  // Obtener el ID del recuerdo en base a la fecha y el idPareja
  Future<String> obtenerIdRecuerdoPorFecha(DateTime fecha, int idPareja) async {
    try {
      final QuerySnapshot snapshot = await _recuerdosCollection
          .where('id_pareja', isEqualTo: idPareja)
          .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day)))
          .where('fecha', isLessThan: Timestamp.fromDate(DateTime(fecha.year, fecha.month, fecha.day + 1)))
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      print('Error al obtener ID del recuerdo: $e');
    }
    return "";
  }

  // Agregar un recuerdo para un día específico
  Future<void> agregarRecuerdo({
    required DateTime fecha,
    required String texto,
    required List<String> fotos,
    required int idPareja,
    Valoracion? valoracionUsuario1,
    Valoracion? valoracionUsuario2,
  }) async {
    try {
      Recuerdo nuevoRecuerdo = Recuerdo(
        fecha: Timestamp.fromDate(fecha),
        texto: texto,
        fotos: fotos,
        idPareja: idPareja,
        valoracionUsuario1: valoracionUsuario1 ?? Valoracion.Nose,
        valoracionUsuario2: valoracionUsuario2 ?? Valoracion.Nose,
      );

      await _recuerdosCollection.add(nuevoRecuerdo.toMap());
    } catch (e) {
      print('Error al agregar recuerdo: $e');
    }
  }

  Future<void> modificarRecuerdo({
    required String idRecuerdo,
    required String texto,
    required List<String> fotos,
  }) async {
    try {
      // Actualizar el documento del recuerdo en Firestore
      await _recuerdosCollection.doc(idRecuerdo).update({
        'texto': texto,
        'fotos': fotos,
      });
    } catch (e) {
      print('Error al modificar recuerdo: $e');
    }
  }

  // Modificar la valoración del usuario 1 y registrar quién la hizo (como int)
  Future<void> modificarValoracionUsuario1(
      String idRecuerdo, Valoracion nuevaValoracion, int usuarioId) async {
    try {
      await _recuerdosCollection.doc(idRecuerdo).update({
        'valoracion_usuario1': nuevaValoracion.name,
        'usuario_ultima_valoracion': usuarioId, // Ahora es int
      });
    } catch (e) {
      print('Error al modificar valoración usuario 1: $e');
    }
  }

  // Modificar la valoración del usuario 2 y registrar quién la hizo (como int)
  Future<void> modificarValoracionUsuario2(
      String idRecuerdo, Valoracion nuevaValoracion, int usuarioId) async {
    try {
      await _recuerdosCollection.doc(idRecuerdo).update({
        'valoracion_usuario2': nuevaValoracion.name,
        'usuario_ultima_valoracion': usuarioId, // Ahora es int
      });
    } catch (e) {
      print('Error al modificar valoración usuario 2: $e');
    }
  }

  // Eliminar una imagen de Firebase Storage
  Future<void> eliminarImagenDeStorage(String urlImagen) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(urlImagen);
      await ref.delete();  // Borra la imagen de Firebase Storage
    } catch (e) {
      print('Error al eliminar imagen de Firebase Storage: $e');
    }
  }

}
