import 'package:flutter/material.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class ParejaCard extends StatefulWidget {
  final int idUsuario;
  final IconData icono1;
  final IconData icono2;
  final VoidCallback onPressed1;
  final VoidCallback onPressed2;

  const ParejaCard({
    Key? key,
    required this.idUsuario,
    required this.icono1,
    required this.icono2,
    required this.onPressed1,
    required this.onPressed2,
  }) : super(key: key);

  @override
  _ParejaCardState createState() => _ParejaCardState();
}

class _ParejaCardState extends State<ParejaCard> {
  final UsuarioController _usuarioController = UsuarioController();
  String _nombreUsuario = "Aun no tienes pareja";
  String? _fotoUsuarioUrl;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    if (widget.idUsuario != -1) {
      String nombreUsuario = await _usuarioController.obtenerNombreUsuario(widget.idUsuario);
      String? fotoUsuarioUrl = await _usuarioController.obtenerFotoPerfilUsuario(widget.idUsuario);

      setState(() {
        _nombreUsuario = nombreUsuario;
        _fotoUsuarioUrl = fotoUsuarioUrl;
        print(_nombreUsuario);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.pinkAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: _fotoUsuarioUrl != null
                      ? NetworkImage(_fotoUsuarioUrl!)
                      : AssetImage('assets/imagen_perfil_default.png') as ImageProvider,
                  radius: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _nombreUsuario,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(widget.icono1, color: Colors.white),
                  onPressed: widget.onPressed1,
                ),
                IconButton(
                  icon: Icon(widget.icono2, color: Colors.white),
                  onPressed: widget.onPressed2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
