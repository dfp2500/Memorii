import 'package:cloud_firestore/cloud_firestore.dart';

class ProductoListaCompra {
  final String id;
  final int idUsuario;
  final String nombre;
  final String cantidad;
  final bool comprado;
  final Timestamp fechaCreacion;
  final Timestamp? fechaCompra;

  ProductoListaCompra({
    required this.id,
    required this.idUsuario,
    required this.nombre,
    required this.cantidad,
    required this.comprado,
    required this.fechaCreacion,
    this.fechaCompra,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      "id_usuario": idUsuario,
      "nombre": nombre,
      "cantidad": cantidad,
      "comprado": comprado,
      "fecha_creacion": fechaCreacion,
      "fecha_compra": fechaCompra,
    };
  }

  // Crear una instancia desde un documento Firestore
  factory ProductoListaCompra.fromMap(String id, Map<String, dynamic> map) {
    return ProductoListaCompra(
      id: id,
      idUsuario: map["id_usuario"],
      nombre: map["nombre"],
      cantidad: map["cantidad"],
      comprado: map["comprado"] ?? false,
      fechaCreacion: map["fecha_creacion"],
      fechaCompra: map["fecha_compra"],
    );
  }

  // Crear una copia con cambios
  ProductoListaCompra copyWith({
    String? id,
    int? idUsuario,
    String? nombre,
    String? cantidad,
    bool? comprado,
    Timestamp? fechaCreacion,
    Timestamp? fechaCompra,
  }) {
    return ProductoListaCompra(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      comprado: comprado ?? this.comprado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaCompra: fechaCompra ?? this.fechaCompra,
    );
  }
} 