import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:memorii/controllers/recuerdo_controller.dart';
import 'package:memorii/models/recuerdo_model.dart';
import 'package:memorii/views/calendario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditarRecuerdoPage extends StatefulWidget {
  final Recuerdo recuerdo;
  final DateTime fechaSeleccionada;

  const EditarRecuerdoPage({Key? key, required this.fechaSeleccionada, required this.recuerdo}) : super(key: key);

  @override
  _EditarRecuerdoPageState createState() => _EditarRecuerdoPageState();
}

class _EditarRecuerdoPageState extends State<EditarRecuerdoPage> {
  final TextEditingController _textoController = TextEditingController();
  final RecuerdoController _recuerdoController = RecuerdoController();
  final List<Map<String, dynamic>> _imagenes = [];
  final List<String> _imagenesEliminadas = []; // Lista de URLs de imágenes eliminadas
  bool _subiendo = false;

  @override
  void initState() {
    super.initState();
    _textoController.text = widget.recuerdo.texto;

    // Guardar imágenes y sus URLs si ya existen
    widget.recuerdo.fotos.forEach((url) {
      _imagenes.add({'file': null, 'url': url});
    });
  }

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        _imagenes.add({'file': File(imagen.path), 'url': null});
      });
    }
  }

  Future<List<String>> _subirImagenes() async {
    List<String> urls = [];
    for (var imagen in _imagenes) {
      if (imagen['url'] == null) {  // Solo subir si no tiene URL
        String nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('recuerdos/$nombreArchivo');
        UploadTask uploadTask = ref.putFile(imagen['file']);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        urls.add(url);
        // Actualizar el mapa con la nueva URL
        imagen['url'] = url;
      } else {
        // Si ya tiene URL, solo la agregamos
        urls.add(imagen['url']);
      }
    }
    return urls;
  }

  Future<void> _actualizarRecuerdo() async {
    if (_textoController.text.isEmpty && _imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debes agregar texto o imágenes")),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    // Eliminar las imágenes que se hayan borrado de Firebase Storage
    for (String urlImagen in _imagenesEliminadas) {
      await _recuerdoController.eliminarImagenDeStorage(urlImagen);
    }

    List<String> urlsImagenes = await _subirImagenes();
    String idRecuerdo = await _recuerdoController.obtenerIdRecuerdoPorFecha(widget.fechaSeleccionada, widget.recuerdo.idPareja);
    await _recuerdoController.modificarRecuerdo(
      idRecuerdo: idRecuerdo,
      texto: _textoController.text,
      fotos: urlsImagenes,
    );

    setState(() {
      _subiendo = false;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Reemplaza la pantalla actual con HomePage (o cualquier otra página)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CalendarioPage(idUsuario: prefs.getInt('usuario_id')!)), // Aquí la ruta de la página de destino
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Editar Recuerdo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textoController,
              decoration: InputDecoration(
                labelText: "Edita tu recuerdo",
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
              maxLines: 4,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imagenes.map((imagen) {
                String imagenUrl = imagen['url'] ?? imagen['file']?.path ?? '';  // Usamos la URL o el path de la imagen
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imagenUrl.startsWith('http')
                          ? Image.network(imagenUrl, width: 100, height: 100, fit: BoxFit.cover)
                          : Image.file(imagen['file'], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (imagen['url'] != null) {
                            // Si tiene URL, la agregamos a la lista de imágenes eliminadas
                            _imagenesEliminadas.add(imagen['url']);
                          }
                          _imagenes.remove(imagen);
                        });
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 12,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _seleccionarImagen,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: Icon(Icons.add_a_photo, color: Colors.white),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _subiendo ? null : _actualizarRecuerdo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: _subiendo
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Actualizar Recuerdo", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
