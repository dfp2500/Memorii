import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:memorii/controllers/recuerdo_controller.dart';
import 'package:memorii/models/recuerdo_model.dart';

class AgregarRecuerdoPage extends StatefulWidget {
  final int idPareja;
  final DateTime fechaSeleccionada;

  const AgregarRecuerdoPage({Key? key, required this.fechaSeleccionada, required this.idPareja}) : super(key: key);

  @override
  _AgregarRecuerdoPageState createState() => _AgregarRecuerdoPageState();
}

class _AgregarRecuerdoPageState extends State<AgregarRecuerdoPage> {
  final TextEditingController _textoController = TextEditingController();
  final RecuerdoController _recuerdoController = RecuerdoController();
  final List<File> _imagenes = [];
  bool _subiendo = false;

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

    if (imagen != null) {
      setState(() {
        _imagenes.add(File(imagen.path));
      });
    }
  }

  Future<List<String>> _subirImagenes() async {
    List<String> urls = [];
    for (var imagen in _imagenes) {
      String nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child('recuerdos/$nombreArchivo');
      UploadTask uploadTask = ref.putFile(imagen);
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _guardarRecuerdo() async {
    if (_textoController.text.isEmpty && _imagenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Debes agregar texto o imágenes")),
      );
      return;
    }

    setState(() {
      _subiendo = true;
    });

    List<String> urlsImagenes = await _subirImagenes();
    await _recuerdoController.agregarRecuerdo(
      fecha: widget.fechaSeleccionada,
      texto: _textoController.text,
      fotos: urlsImagenes,
      idPareja: widget.idPareja,
    );

    setState(() {
      _subiendo = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // Flecha de atrás blanca
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Agregar Recuerdo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textoController,
              decoration: InputDecoration(
                labelText: "Escribe tu recuerdo",
                labelStyle: TextStyle(color: Colors.pink), // Título en rosa
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink), // Bordes por defecto rosas
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink), // Bordes rosas cuando está enfocado
                ),
              ),
              cursorColor: Colors.pink, // Cursor rosa
              maxLines: 4,
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imagenes.map((imagen) => Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(imagen, width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
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
              )).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _seleccionarImagen,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo, color: Colors.white), // Ícono de imagen + en el botón
                  SizedBox(width: 8),
                  Text("Agregar Imagen", style: TextStyle(color: Colors.white)), // Texto adicional
                ],
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _subiendo ? null : _guardarRecuerdo,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: _subiendo
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Guardar Recuerdo", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
