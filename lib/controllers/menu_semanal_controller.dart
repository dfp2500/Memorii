import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memorii/models/menu_semanal_model.dart';

class MenuSemanalController {
  final CollectionReference _menuSemanalCollection =
      FirebaseFirestore.instance.collection('menu_semanal');

  // Obtener el menú semanal de un usuario
  Future<MenuSemanal?> obtenerMenuSemanal(int idUsuario) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return MenuSemanal.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error al obtener menú semanal: $e');
    }
    return null;
  }

  // Crear un menú semanal para un usuario
  Future<void> crearMenuSemanal(int idUsuario) async {
    try {
      // Menú por defecto
      Map<String, DiaSemanal> diasPorDefecto = {
        'Lunes': DiaSemanal(
          nombre: 'Lunes',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['2 rebanadas de pan integral + 2 huevos revueltos'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Lentejas guisadas con verduras'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Crema de calabacín + tortilla de espinacas'],
            ),
          },
        ),
        'Martes': DiaSemanal(
          nombre: 'Martes',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['Batido de plátano con leche'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Pollo al curry con arroz integral'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Salteado de pollo y verduras'],
            ),
          },
        ),
        'Miércoles': DiaSemanal(
          nombre: 'Miércoles',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['2 tostadas integrales + 2 huevos'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Ensalada de garbanzos con atún'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Sopa de verduras + 2 huevos cocidos'],
            ),
          },
        ),
        'Jueves': DiaSemanal(
          nombre: 'Jueves',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['Batido con plátano y crema de cacahuete'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Guiso de lentejas con pollo'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Crema de verduras + tortilla de pimientos'],
            ),
          },
        ),
        'Viernes': DiaSemanal(
          nombre: 'Viernes',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['2 tostadas integrales + 2 huevos'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Pollo al curry con arroz integral'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Salteado de verduras con tofu'],
            ),
          },
        ),
        'Sábado': DiaSemanal(
          nombre: 'Sábado',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['2 huevos cocidos + 2 rebanadas de pan'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Opción libre (controlar cantidades)'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Crema ligera + tortilla de verduras'],
            ),
          },
        ),
        'Domingo': DiaSemanal(
          nombre: 'Domingo',
          comidas: {
            'Desayuno': Comida(
              nombre: 'Desayuno',
              icono: 'wb_sunny',
              color: '#FF9800',
              items: ['Batido con fruta + bebida vegetal'],
            ),
            'Comida': Comida(
              nombre: 'Comida',
              icono: 'restaurant',
              color: '#F44336',
              items: ['Lentejas o garbanzos con verduras'],
            ),
            'Cena': Comida(
              nombre: 'Cena',
              icono: 'nightlight_round',
              color: '#4CAF50',
              items: ['Sopa de verduras + 2 huevos cocidos'],
            ),
          },
        ),
      };

      MenuSemanal menuSemanal = MenuSemanal(
        idUsuario: idUsuario,
        dias: diasPorDefecto,
        fechaCreacion: Timestamp.now(),
        fechaActualizacion: Timestamp.now(),
      );

      await _menuSemanalCollection.add(menuSemanal.toMap());
    } catch (e) {
      print('Error al crear menú semanal: $e');
    }
  }

  // Actualizar el menú semanal completo
  Future<void> actualizarMenuSemanal(MenuSemanal menuSemanal) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: menuSemanal.idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias': menuSemanal.dias.map((key, value) => MapEntry(key, value.toMap())),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al actualizar menú semanal: $e');
    }
  }

  // Actualizar un día específico del menú
  Future<void> actualizarDia(int idUsuario, String nombreDia, DiaSemanal dia) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias.$nombreDia': dia.toMap(),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al actualizar día del menú: $e');
    }
  }

  // Agregar una comida a un día específico
  Future<void> agregarComida(int idUsuario, String nombreDia, String nombreComida, Comida comida) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias.$nombreDia.comidas.$nombreComida': comida.toMap(),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al agregar comida: $e');
    }
  }

  // Eliminar una comida de un día específico
  Future<void> eliminarComida(int idUsuario, String nombreDia, String nombreComida) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias.$nombreDia.comidas.$nombreComida': FieldValue.delete(),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al eliminar comida: $e');
    }
  }

  // Agregar un item a una comida específica
  Future<void> agregarItem(int idUsuario, String nombreDia, String nombreComida, String item) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias.$nombreDia.comidas.$nombreComida.items': FieldValue.arrayUnion([item]),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al agregar item: $e');
    }
  }

  // Eliminar un item de una comida específica
  Future<void> eliminarItem(int idUsuario, String nombreDia, String nombreComida, String item) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await _menuSemanalCollection.doc(snapshot.docs.first.id).update({
          'dias.$nombreDia.comidas.$nombreComida.items': FieldValue.arrayRemove([item]),
          'fecha_actualizacion': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error al eliminar item: $e');
    }
  }

  // Obtener el ID del documento del menú semanal
  Future<String> obtenerIdMenuSemanal(int idUsuario) async {
    try {
      final QuerySnapshot snapshot = await _menuSemanalCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (e) {
      print('Error al obtener ID del menú semanal: $e');
    }
    return "";
  }
} 