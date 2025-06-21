import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memorii/models/lista_compra_model.dart';

class ListaCompraController {
  final CollectionReference _listaCompraCollection =
      FirebaseFirestore.instance.collection('lista_compra');

  // Obtener todos los productos de un usuario
  Future<List<ProductoListaCompra>> obtenerProductosUsuario(int idUsuario) async {
    try {
      final QuerySnapshot snapshot = await _listaCompraCollection
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      // Ordenar en memoria en lugar de en la base de datos
      final productos = snapshot.docs
          .map((doc) => ProductoListaCompra.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Ordenar por fecha de creación (más antiguos primero)
      productos.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
      
      return productos;
    } catch (e) {
      print('Error al obtener productos del usuario: $e');
      return [];
    }
  }

  // Agregar un nuevo producto
  Future<String> agregarProducto({
    required int idUsuario,
    required String nombre,
    required String cantidad,
  }) async {
    try {
      ProductoListaCompra nuevoProducto = ProductoListaCompra(
        id: '',
        idUsuario: idUsuario,
        nombre: nombre,
        cantidad: cantidad,
        comprado: false,
        fechaCreacion: Timestamp.now(),
      );

      final docRef = await _listaCompraCollection.add(nuevoProducto.toMap());
      return docRef.id;
    } catch (e) {
      print('Error al agregar producto: $e');
      return '';
    }
  }

  // Cambiar el estado de compra de un producto
  Future<void> cambiarEstadoCompra({
    required String idProducto,
    required bool comprado,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'comprado': comprado,
      };

      if (comprado) {
        updateData['fecha_compra'] = Timestamp.now();
      } else {
        updateData['fecha_compra'] = null;
      }

      await _listaCompraCollection.doc(idProducto).update(updateData);
    } catch (e) {
      print('Error al cambiar estado de compra: $e');
    }
  }

  // Eliminar un producto
  Future<void> eliminarProducto(String idProducto) async {
    try {
      await _listaCompraCollection.doc(idProducto).delete();
    } catch (e) {
      print('Error al eliminar producto: $e');
    }
  }

  // Obtener el lunes de la semana actual
  DateTime _obtenerLunesSemanaActual() {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  // Verificar si es lunes y resetear productos comprados
  Future<void> verificarYResetearLista(int idUsuario) async {
    try {
      final lunesActual = _obtenerLunesSemanaActual();
      final ahora = DateTime.now();
      
      // Solo resetear si es lunes y después de las 00:00
      if (ahora.weekday == DateTime.monday && 
          ahora.isAfter(DateTime(lunesActual.year, lunesActual.month, lunesActual.day))) {
        
        // Obtener todos los productos del usuario
        final productos = await obtenerProductosUsuario(idUsuario);
        
        // Resetear solo los productos comprados
        for (var producto in productos) {
          if (producto.comprado) {
            await cambiarEstadoCompra(
              idProducto: producto.id,
              comprado: false,
            );
          }
        }
        
        print('Lista de compra reseteada para el usuario $idUsuario');
      }
    } catch (e) {
      print('Error al verificar y resetear lista: $e');
    }
  }

  // Función pública para verificar reset automático (se puede llamar desde otras partes de la app)
  Future<void> verificarResetAutomatico(int idUsuario) async {
    await verificarYResetearLista(idUsuario);
  }

  // Inicializar lista con productos por defecto
  Future<void> inicializarListaPorDefecto(int idUsuario) async {
    try {
      final productosExistentes = await obtenerProductosUsuario(idUsuario);
      
      // Solo inicializar si el usuario no tiene productos
      if (productosExistentes.isEmpty) {
        final productosPorDefecto = [
          {'nombre': 'Huevos', 'cantidad': '20 unidades'},
          {'nombre': 'Pechuga de pollo', 'cantidad': '700-800g'},
          {'nombre': 'Atún al natural', 'cantidad': '3 latas'},
          {'nombre': 'Pan integral', 'cantidad': '14 rebanadas'},
          {'nombre': 'Avena en copos', 'cantidad': '100g'},
          {'nombre': 'Arroz integral', 'cantidad': '300g'},
          {'nombre': 'Cebollas', 'cantidad': '4 medianas'},
          {'nombre': 'Zanahorias', 'cantidad': '4 grandes'},
          {'nombre': 'Pimientos', 'cantidad': '3 unidades'},
          {'nombre': 'Espinacas', 'cantidad': '300g'},
          {'nombre': 'Tomates', 'cantidad': '3-4 unidades'},
          {'nombre': 'Plátanos', 'cantidad': '6 unidades'},
          {'nombre': 'Manzanas', 'cantidad': '7-10 unidades'},
          {'nombre': 'Yogures naturales', 'cantidad': '10 unidades'},
          {'nombre': 'Leche desnatada', 'cantidad': '1 litro'},
          {'nombre': 'Crema de cacahuete', 'cantidad': '250g'},
          {'nombre': 'Almendras', 'cantidad': '100g'},
          {'nombre': 'Aceite de oliva', 'cantidad': '50ml'},
        ];

        for (var producto in productosPorDefecto) {
          await agregarProducto(
            idUsuario: idUsuario,
            nombre: producto['nombre']!,
            cantidad: producto['cantidad']!,
          );
        }
        
        print('Lista por defecto inicializada para el usuario $idUsuario');
      }
    } catch (e) {
      print('Error al inicializar lista por defecto: $e');
    }
  }

  // Obtener estadísticas de la lista
  Future<Map<String, int>> obtenerEstadisticas(int idUsuario) async {
    try {
      final productos = await obtenerProductosUsuario(idUsuario);
      final totalProductos = productos.length;
      final productosComprados = productos.where((p) => p.comprado).length;
      
      return {
        'total': totalProductos,
        'comprados': productosComprados,
      };
    } catch (e) {
      print('Error al obtener estadísticas: $e');
      return {'total': 0, 'comprados': 0};
    }
  }

  // Verificar si es lunes (función de utilidad)
  bool esLunes() {
    return DateTime.now().weekday == DateTime.monday;
  }

  // Obtener información de la semana actual
  Map<String, dynamic> obtenerInfoSemanaActual() {
    final ahora = DateTime.now();
    final lunes = _obtenerLunesSemanaActual();
    final domingo = lunes.add(Duration(days: 6));
    
    return {
      'esLunes': ahora.weekday == DateTime.monday,
      'lunes': lunes,
      'domingo': domingo,
      'diaActual': ahora,
    };
  }
} 