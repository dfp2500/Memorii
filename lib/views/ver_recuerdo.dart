import 'package:flutter/material.dart';
import 'package:memorii/models/recuerdo_model.dart';
import 'editar_recuerdo.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:memorii/controllers/recuerdo_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerRecuerdoPage extends StatefulWidget {
  final Recuerdo recuerdo;
  final DateTime fechaSeleccionada;

  const VerRecuerdoPage({Key? key, required this.fechaSeleccionada, required this.recuerdo}) : super(key: key);

  @override
  _VerRecuerdoPageState createState() => _VerRecuerdoPageState();
}

class _VerRecuerdoPageState extends State<VerRecuerdoPage> {
  late PageController _pageController;
  final UsuarioController _usuarioController = UsuarioController();
  final RecuerdoController _recuerdoController = RecuerdoController();
  int usuario1Id = -1;
  int usuario2Id = -1;
  String nombreUser1 = "";
  String nombreUser2 = "";
  String idRecuerdo = "";

  // Valoración seleccionada para los usuarios
  Valoracion? valoracionUsuario1;
  Valoracion? valoracionUsuario2;

  int? idUsuario;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    cargarDatos();
  }

  void cargarDatos() async {
    usuario1Id = await _usuarioController.getIdUser1Pareja(widget.recuerdo.idPareja);
    usuario2Id = await _usuarioController.getIdUser2Pareja(widget.recuerdo.idPareja);
    nombreUser1 = await _usuarioController.obtenerNombreUsuario(usuario1Id);
    nombreUser2 = await _usuarioController.obtenerNombreUsuario(usuario2Id);

    idRecuerdo = await _recuerdoController.obtenerIdRecuerdoPorFecha(widget.fechaSeleccionada, widget.recuerdo.idPareja);

    // Cargar las valoraciones actuales
    valoracionUsuario1 = widget.recuerdo.valoracionUsuario1;
    valoracionUsuario2 = widget.recuerdo.valoracionUsuario2;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    idUsuario = prefs.getInt('usuario_id');

    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Método para obtener la imagen de acuerdo al valor de la valoración
  String _obtenerImagenPorValoracion(Valoracion valoracion) {
    switch (valoracion) {
      case Valoracion.Nose:
        return 'assets/rata_nose.png';
      case Valoracion.Fata:
        return 'assets/rata_bajo.png';
      case Valoracion.TaBien:
        return 'assets/rata_medio.png';
      case Valoracion.Genialisaro:
        return 'assets/rata_alto.png';
      default:
        return 'assets/rata_nose.png';  // En caso de que no se encuentre un valor válido
    }
  }

  // Método para actualizar la valoración
  void actualizarValoracion(Valoracion valoracion, int usuarioId) {
    setState(() {
      if (usuarioId == usuario1Id) {
        valoracionUsuario1 = valoracion;
        _recuerdoController.modificarValoracionUsuario1(idRecuerdo, valoracion, usuarioId);
      } else if (usuarioId == usuario2Id) {
        valoracionUsuario2 = valoracion;
        _recuerdoController.modificarValoracionUsuario2(idRecuerdo, valoracion, usuarioId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text("Ver Recuerdo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card para mostrar el texto del recuerdo
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.recuerdo.texto,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Carrousel para mostrar las fotos
                Container(
                  height: 300,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.recuerdo.fotos.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Image.network(
                                widget.recuerdo.fotos[index],
                                width: MediaQuery.of(context).size.width,
                                height: 300,
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        left: 0,
                        top: 100,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.pinkAccent, size: 30),
                          onPressed: () {
                            if (_pageController.hasClients) {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 100,
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward, color: Colors.pinkAccent, size: 30),
                          onPressed: () {
                            if (_pageController.hasClients) {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  "Valoraciones",
                  style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Card para mostrar las valoraciones con imágenes
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.pinkAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 150,
                              child: Text(
                                nombreUser1,
                                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 8),
                            Image.asset(
                              _obtenerImagenPorValoracion(valoracionUsuario1 ?? Valoracion.Nose),
                              width: 110,
                              height: 110,
                            ),
                            SizedBox(height: 6),
                            Opacity(
                              opacity: idUsuario == usuario1Id ? 1.0 : 0.0,
                              child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<Valoracion>(
                                  value: valoracionUsuario1,
                                  items: Valoracion.values.map((valoracion) {
                                    return DropdownMenuItem(
                                      value: valoracion,
                                      child: Text(valoracion.toString().split('.').last),
                                    );
                                  }).toList(),
                                  onChanged: (Valoracion? newValoracion) {
                                    if (newValoracion != null) {
                                      actualizarValoracion(newValoracion, usuario1Id);
                                    }
                                  },
                                  underline: SizedBox(),  // Remueve la línea de abajo
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              width: 150,
                              child: Text(
                                nombreUser2,
                                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: 8),
                            Image.asset(
                              _obtenerImagenPorValoracion(valoracionUsuario2 ?? Valoracion.Nose),
                              width: 110,
                              height: 110,
                            ),
                            SizedBox(height: 6),
                            Opacity(
                              opacity: idUsuario == usuario2Id ? 1.0 : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: DropdownButton<Valoracion>(
                                  value: valoracionUsuario2,
                                  items: Valoracion.values.map((valoracion) {
                                    return DropdownMenuItem(
                                      value: valoracion,
                                      child: Text(valoracion.toString().split('.').last),
                                    );
                                  }).toList(),
                                  onChanged: (Valoracion? newValoracion) {
                                    if (newValoracion != null) {
                                      actualizarValoracion(newValoracion, usuario2Id);
                                    }
                                  },
                                  underline: SizedBox(),  // Remueve la línea de abajo
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Botón para editar el recuerdo
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditarRecuerdoPage(
                          recuerdo: widget.recuerdo,
                          fechaSeleccionada: widget.fechaSeleccionada,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  child: Text("Editar Recuerdo", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
