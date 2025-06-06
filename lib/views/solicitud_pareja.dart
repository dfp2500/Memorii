import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/solicitud_pareja_controller.dart';
import 'package:memorii/models/solicitud_pareja_model.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'pareja_card.dart';

class SolicitudParejaPage extends StatefulWidget {
  final int idUsuario; // El id del usuario actual

  SolicitudParejaPage({required this.idUsuario});

  @override
  _SolicitudParejaPageState createState() => _SolicitudParejaPageState();
}

class _SolicitudParejaPageState extends State<SolicitudParejaPage> {
  final TextEditingController _correoController = TextEditingController();
  final SolicitudParejaController _controller = SolicitudParejaController();
  final UsuarioController _usuarioController = UsuarioController();
  List<SolicitudPareja> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  // Cargar las solicitudes recibidas
  Future<void> _cargarSolicitudes() async {
    final solicitudes = await _controller.obtenerSolicitudesRecibidas(await _usuarioController.obtenerCorreoUsuario(widget.idUsuario));
    setState(() {
      _solicitudes = solicitudes;
    });
  }

  // Enviar una nueva solicitud
  void _enviarSolicitud() async {
    try {
      final correoReceptor = _correoController.text;

      if (correoReceptor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor ingresa un correo válido')));
        return;
      }

      // Comprobar si el correo es del mismo usuario
      String correoPropio = await _usuarioController.obtenerCorreoUsuario(widget.idUsuario);
      if (correoReceptor == correoPropio) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No puedes enviarte una solicitud a ti mismo')));
        return;
      }

      // Comprobar si ya existe una solicitud entre estos dos usuarios
      String? idSolicitud = await _controller.obtenerIdSolicitud(widget.idUsuario, correoReceptor);
      if (idSolicitud != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ya has enviado una solicitud a este usuario')));
        return;
      }

      // Comprobar si el usuario ya ha enviado una solicitud a este
      int idOtroUser = await _usuarioController.obtenerIdUsuario(correoReceptor);
      String? idSolicitudReversa = await _controller.obtenerIdSolicitud(idOtroUser, correoPropio);
      if (idSolicitudReversa != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Este usuario ya te ha enviado una solicitud')));
        return;
      }

      // Si pasa todas las validaciones, enviar la solicitud
      await _controller.enviarSolicitud(widget.idUsuario, correoReceptor);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solicitud enviada')));
      _correoController.clear();
      _cargarSolicitudes(); // Recargar la lista de solicitudes

    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar solicitud')));
    }
  }

  // Aceptar solicitud
  void _aceptarSolicitud(SolicitudPareja solicitud) async {
    String? idSolicitud = await _controller.obtenerIdSolicitud(solicitud.idEmisor, solicitud.correoReceptor);
    try {
      await _controller.aceptarSolicitud(idSolicitud!, solicitud.idEmisor, solicitud.correoReceptor);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solicitud aceptada')));

      // Volver automáticamente a la pantalla del calendario después de aceptar la solicitud
      Navigator.pop(context, true); // Enviamos "true" para indicar que hubo un cambio

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aceptar solicitud')));
    }
  }

  // Rechazar solicitud
  void _rechazarSolicitud(SolicitudPareja solicitud) async {
    String? idSolicitud = await _controller.obtenerIdSolicitud(solicitud.idEmisor, solicitud.correoReceptor);
    try {
      await _controller.eliminarSolicitud(idSolicitud!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solicitud rechazada')));
      _cargarSolicitudes(); // Recargar la lista de solicitudes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar solicitud')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.pinkAccent, title: Text('Solicitudes de Pareja', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),  iconTheme: IconThemeData(
    color: Colors.white, // Cambia la flecha de atrás a blanco
  ),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo para ingresar el correo
            TextField(
              controller: _correoController,
              decoration: InputDecoration(
                labelText: "Correo de la pareja",
                labelStyle: TextStyle(color: Colors.pink),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink),
                ),
              ),
              cursorColor: Colors.pink,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _enviarSolicitud,
              icon: Icon(Icons.send_rounded, size: 20, color: Colors.white),
              label: Text("Enviar solicitud"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              ),
            ),
            SizedBox(height: 16),
            // Lista de solicitudes recibidas
            Expanded(
              child: ListView.builder(
                itemCount: _solicitudes.length,
                itemBuilder: (context, index) {
                  final solicitud = _solicitudes[index];
                  return ParejaCard(
                    idUsuario: solicitud.idEmisor,
                    icono1: Icons.favorite,
                    icono2: Icons.heart_broken_rounded,
                    onPressed1: () => _aceptarSolicitud(solicitud),
                    onPressed2: () => _rechazarSolicitud(solicitud),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
