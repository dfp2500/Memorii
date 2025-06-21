import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memorii/models/progreso_peso_model.dart';

class ProgresoPesoController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener el siguiente ID disponible
  Future<int> _getNextId() async {
    try {
      final snapshot = await _firestore.collection('progreso_peso').get();
      
      if (snapshot.docs.isEmpty) {
        return 1;
      }
      
      // Encontramos el ID más alto localmente
      int maxId = 0;
      for (var doc in snapshot.docs) {
        int id = doc.data()['id_progreso'] ?? 0;
        if (id > maxId) {
          maxId = id;
        }
      }
      
      return maxId + 1;
    } catch (e) {
      print('Error obteniendo siguiente ID: $e');
      return 1;
    }
  }

  // Agregar un nuevo registro de peso
  Future<bool> agregarProgresoPeso({
    required int idUsuario,
    required double peso,
    required DateTime fecha,
    String? notas,
  }) async {
    try {
      int idProgreso = await _getNextId();
      
      ProgresoPeso progreso = ProgresoPeso(
        idProgreso: idProgreso,
        idUsuario: idUsuario,
        peso: peso,
        fecha: fecha,
        notas: notas,
      );

      await _firestore.collection('progreso_peso').add(progreso.toMap());
      return true;
    } catch (e) {
      print('Error agregando progreso de peso: $e');
      return false;
    }
  }

  // Obtener todos los registros de peso de un usuario
  Future<List<ProgresoPeso>> obtenerProgresoPesoUsuario(int idUsuario) async {
    try {
      final snapshot = await _firestore
          .collection('progreso_peso')
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      List<ProgresoPeso> progresos = snapshot.docs.map((doc) => ProgresoPeso.fromMap(doc.data())).toList();
      
      // Ordenamos localmente por fecha (más reciente primero)
      progresos.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return progresos;
    } catch (e) {
      print('Error obteniendo progreso de peso: $e');
      return [];
    }
  }

  // Obtener el peso más reciente de un usuario
  Future<ProgresoPeso?> obtenerPesoMasReciente(int idUsuario) async {
    try {
      List<ProgresoPeso> progresos = await obtenerProgresoPesoUsuario(idUsuario);
      
      if (progresos.isNotEmpty) {
        return progresos.first; // Ya está ordenado por fecha descendente
      }
      return null;
    } catch (e) {
      print('Error obteniendo peso más reciente: $e');
      return null;
    }
  }

  // Obtener el peso inicial (más antiguo) de un usuario
  Future<ProgresoPeso?> obtenerPesoInicial(int idUsuario) async {
    try {
      List<ProgresoPeso> progresos = await obtenerProgresoPesoUsuario(idUsuario);
      
      if (progresos.isNotEmpty) {
        // Ordenamos por fecha ascendente para obtener el más antiguo
        progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
        return progresos.first;
      }
      return null;
    } catch (e) {
      print('Error obteniendo peso inicial: $e');
      return null;
    }
  }

  // Calcular estadísticas del progreso
  Future<Map<String, dynamic>> calcularEstadisticas(int idUsuario) async {
    try {
      List<ProgresoPeso> progresos = await obtenerProgresoPesoUsuario(idUsuario);
      
      if (progresos.isEmpty) {
        return {
          'pesoInicial': 0.0,
          'pesoActual': 0.0,
          'pesoPerdido': 0.0,
          'pesoPerdidoPorcentaje': 0.0,
          'promedioDiario': 0.0,
          'tendenciaPromedio': '', // '+' para subida, '-' para bajada
          'diasTranscurridos': 0,
        };
      }

      // Ordenar por fecha (más antiguo primero)
      progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
      
      double pesoInicial = progresos.first.peso;
      double pesoActual = progresos.last.peso;
      double pesoPerdido = pesoInicial - pesoActual;
      double pesoPerdidoPorcentaje = pesoInicial > 0 ? (pesoPerdido / pesoInicial) * 100 : 0.0;
      
      // Calcular días transcurridos (número total de días registrados)
      int diasTranscurridos = progresos.length;
      
      // Calcular promedio diario (diferencia total entre primer y último día)
      double promedioDiario = 0.0;
      String tendenciaPromedio = '';
      if (progresos.length > 1) {
        // Ordenar por fecha para asegurar primer y último
        progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
        
        double pesoInicial = progresos.first.peso;
        double pesoFinal = progresos.last.peso;
        double diferenciaTotal = pesoFinal - pesoInicial; // Positivo = ganancia, negativo = pérdida
        
        // Calcular días transcurridos entre primer y último registro
        int diasEntreRegistros = progresos.last.fecha.difference(progresos.first.fecha).inDays;
        
        if (diasEntreRegistros > 0) {
          promedioDiario = diferenciaTotal / diasEntreRegistros;
        } else {
          promedioDiario = diferenciaTotal; // Si es el mismo día
        }
        
        tendenciaPromedio = promedioDiario > 0 ? '+' : '';
      }

      return {
        'pesoInicial': pesoInicial,
        'pesoActual': pesoActual,
        'pesoPerdido': pesoPerdido,
        'pesoPerdidoPorcentaje': pesoPerdidoPorcentaje,
        'promedioDiario': promedioDiario,
        'tendenciaPromedio': tendenciaPromedio,
        'diasTranscurridos': diasTranscurridos,
      };
    } catch (e) {
      print('Error calculando estadísticas: $e');
      return {
        'pesoInicial': 0.0,
        'pesoActual': 0.0,
        'pesoPerdido': 0.0,
        'pesoPerdidoPorcentaje': 0.0,
        'promedioDiario': 0.0,
        'tendenciaPromedio': '',
        'diasTranscurridos': 0,
      };
    }
  }

  // Obtener progresos ordenados por fecha (más antiguo primero)
  Future<List<ProgresoPeso>> obtenerProgresosOrdenados(int idUsuario) async {
    try {
      List<ProgresoPeso> progresos = await obtenerProgresoPesoUsuario(idUsuario);
      progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
      return progresos;
    } catch (e) {
      print('Error obteniendo progresos ordenados: $e');
      return [];
    }
  }

  // Obtener el primer día con peso registrado
  DateTime? obtenerPrimerDiaConPeso(List<ProgresoPeso> progresos) {
    try {
      if (progresos.isEmpty) return null;
      
      // Ordenar por fecha (más antiguo primero)
      progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
      
      return progresos.first.fecha;
    } catch (e) {
      print('Error obteniendo primer día con peso: $e');
      return null;
    }
  }

  // Calcular diferencia de peso para un día específico
  double? calcularDiferenciaPeso(List<ProgresoPeso> progresos, DateTime fecha) {
    try {
      // Encontrar el progreso del día actual
      ProgresoPeso? progresoActual = progresos.firstWhere(
        (p) => p.fecha.year == fecha.year &&
               p.fecha.month == fecha.month &&
               p.fecha.day == fecha.day,
        orElse: () => ProgresoPeso(
          idProgreso: 0,
          idUsuario: 0,
          peso: 0,
          fecha: fecha,
        ),
      );

      if (progresoActual.peso == 0) return null; // No hay registro para este día

      // Encontrar el progreso del día anterior
      DateTime diaAnterior = fecha.subtract(Duration(days: 1));
      ProgresoPeso? progresoAnterior = progresos.firstWhere(
        (p) => p.fecha.year == diaAnterior.year &&
               p.fecha.month == diaAnterior.month &&
               p.fecha.day == diaAnterior.day,
        orElse: () => ProgresoPeso(
          idProgreso: 0,
          idUsuario: 0,
          peso: 0,
          fecha: diaAnterior,
        ),
      );

      if (progresoAnterior.peso == 0) return null; // No hay registro del día anterior

      // Calcular diferencia (positivo = ganancia, negativo = pérdida)
      return progresoActual.peso - progresoAnterior.peso;
    } catch (e) {
      print('Error calculando diferencia de peso: $e');
      return null;
    }
  }

  // Verificar si ya existe un registro para una fecha específica
  Future<bool> existeRegistroParaFecha(int idUsuario, DateTime fecha) async {
    try {
      // En lugar de usar consultas complejas, obtenemos todos los registros del usuario
      // y filtramos localmente. Esto evita la necesidad de índices compuestos.
      final snapshot = await _firestore
          .collection('progreso_peso')
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      DateTime inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      DateTime finDia = inicioDia.add(Duration(days: 1));
      
      // Filtramos localmente
      bool existe = snapshot.docs.any((doc) {
        DateTime fechaDoc = DateTime.parse(doc.data()['fecha']);
        return fechaDoc.isAfter(inicioDia) && fechaDoc.isBefore(finDia);
      });

      return existe;
    } catch (e) {
      print('Error verificando registro para fecha: $e');
      return false;
    }
  }

  // Obtener el documento ID de un registro para una fecha específica
  Future<String?> obtenerDocumentId(int idUsuario, DateTime fecha) async {
    try {
      final snapshot = await _firestore
          .collection('progreso_peso')
          .where('id_usuario', isEqualTo: idUsuario)
          .get();

      DateTime inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      DateTime finDia = inicioDia.add(Duration(days: 1));
      
      for (var doc in snapshot.docs) {
        DateTime fechaDoc = DateTime.parse(doc.data()['fecha']);
        if (fechaDoc.isAfter(inicioDia) && fechaDoc.isBefore(finDia)) {
          return doc.id;
        }
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo document ID: $e');
      return null;
    }
  }

  // Actualizar un registro de peso existente
  Future<bool> actualizarProgresoPeso({
    required String documentId,
    required double peso,
    String? notas,
  }) async {
    try {
      Map<String, dynamic> datosActualizados = {
        'peso': peso,
      };
      
      if (notas != null) {
        datosActualizados['notas'] = notas;
      }

      await _firestore.collection('progreso_peso').doc(documentId).update(datosActualizados);
      return true;
    } catch (e) {
      print('Error actualizando progreso de peso: $e');
      return false;
    }
  }

  // Borrar un registro de peso
  Future<bool> borrarProgresoPeso(String documentId) async {
    try {
      await _firestore.collection('progreso_peso').doc(documentId).delete();
      return true;
    } catch (e) {
      print('Error borrando progreso de peso: $e');
      return false;
    }
  }
} 