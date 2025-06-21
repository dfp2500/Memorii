import 'package:cloud_firestore/cloud_firestore.dart';

class Comida {
  final String nombre;
  final String icono;
  final String color;
  final List<String> items;

  Comida({
    required this.nombre,
    required this.icono,
    required this.color,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'icono': icono,
      'color': color,
      'items': items,
    };
  }

  factory Comida.fromMap(Map<String, dynamic> map) {
    return Comida(
      nombre: map['nombre'] ?? '',
      icono: map['icono'] ?? 'restaurant',
      color: map['color'] ?? '#FF6B6B',
      items: List<String>.from(map['items'] ?? []),
    );
  }
}

class DiaSemanal {
  final String nombre;
  final Map<String, Comida> comidas;

  DiaSemanal({
    required this.nombre,
    required this.comidas,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'comidas': comidas.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory DiaSemanal.fromMap(Map<String, dynamic> map) {
    Map<String, Comida> comidasMap = {};
    if (map['comidas'] != null) {
      (map['comidas'] as Map<String, dynamic>).forEach((key, value) {
        comidasMap[key] = Comida.fromMap(value);
      });
    }
    
    return DiaSemanal(
      nombre: map['nombre'] ?? '',
      comidas: comidasMap,
    );
  }
}

class MenuSemanal {
  final int idUsuario;
  final Map<String, DiaSemanal> dias;
  final Timestamp fechaCreacion;
  final Timestamp fechaActualizacion;

  MenuSemanal({
    required this.idUsuario,
    required this.dias,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'dias': dias.map((key, value) => MapEntry(key, value.toMap())),
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
    };
  }

  factory MenuSemanal.fromMap(Map<String, dynamic> map) {
    Map<String, DiaSemanal> diasMap = {};
    if (map['dias'] != null) {
      (map['dias'] as Map<String, dynamic>).forEach((key, value) {
        diasMap[key] = DiaSemanal.fromMap(value);
      });
    }
    
    return MenuSemanal(
      idUsuario: map['id_usuario'] ?? 0,
      dias: diasMap,
      fechaCreacion: map['fecha_creacion'] ?? Timestamp.now(),
      fechaActualizacion: map['fecha_actualizacion'] ?? Timestamp.now(),
    );
  }
} 