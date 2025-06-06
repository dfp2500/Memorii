import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:memorii/models/usuario_model.dart';

class CambiarFotoPerfilPage extends StatefulWidget {
  final int idUsuario;

  const CambiarFotoPerfilPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _CambiarFotoPerfilPageState createState() => _CambiarFotoPerfilPageState();
}

class _CambiarFotoPerfilPageState extends State<CambiarFotoPerfilPage> {
  final UsuarioController _usuarioController = UsuarioController();
  String? _fotoPerfilUrl;
  File? _imagenSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarFotoPerfil();
  }

  Future<void> _cargarFotoPerfil() async {
    String? fotoUrl = await _usuarioController.obtenerFotoPerfilUsuario(widget.idUsuario);
    setState(() {
      _fotoPerfilUrl = fotoUrl;
    });
  }

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = File(imagen.path);
      });
    }
  }

  Future<void> _subirImagen() async {
    if (_imagenSeleccionada != null) {
      Usuario usuario = await _usuarioController.obtenerUsuario(widget.idUsuario) as Usuario;
      if (await _usuarioController.subirFotoPerfil( _imagenSeleccionada!, usuario)) {
        setState(() {
        _fotoPerfilUrl = usuario.fotoPerfil;
        _imagenSeleccionada = null;
        });
        // Volver automáticamente a la pantalla del calendario después de aceptar la solicitud
        Navigator.pop(context, true); // Enviamos "true" para indicar que hubo un cambio
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cambiar Foto de Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        iconTheme: IconThemeData(
          color: Colors.white, // Cambia la flecha de atrás a blanco
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 150,
              backgroundImage: _imagenSeleccionada != null
                  ? FileImage(_imagenSeleccionada!)
                  : (_fotoPerfilUrl != null && _fotoPerfilUrl != 'assets/imagen_perfil_default.png' ? NetworkImage(_fotoPerfilUrl!) : AssetImage('assets/imagen_perfil_default.png')) as ImageProvider,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _seleccionarImagen,
              child: Text("Seleccionar Imagen",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _subirImagen,
              child: Text("Guardar",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            ),
          ],
        ),
      ),
    );
  }
}