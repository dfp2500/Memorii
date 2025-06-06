import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class TiempoPareja extends StatefulWidget {
  final int idPareja;

  const TiempoPareja({Key? key, required this.idPareja}) : super(key: key);

  @override
  State<TiempoPareja> createState() => _TiempoParejaState();
}

class _TiempoParejaState extends State<TiempoPareja> {
  String fechaInicio = '';
  int anios = 0, meses = 0, dias = 0, horas = 0, minutos = 0, segundos = 0;
  Timer? _timer;
  final UsuarioController usuarioController = UsuarioController();

  @override
  void initState() {
    super.initState();
    _cargarFechaInicio();
    _iniciarContador();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarFechaInicio() async {
    String? fecha = await usuarioController.obtenerFechaInicioPareja(widget.idPareja);
    setState(() {
      fechaInicio = fecha ?? 'Fecha no disponible';
    });
  }

  void _iniciarContador() {
    _actualizarTiempoTranscurrido();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _actualizarTiempoTranscurrido();
    });
  }

  Future<void> _actualizarTiempoTranscurrido() async {
    String? tiempo = await usuarioController.obtenerTiempoTranscurridoPareja(widget.idPareja);
    print("Tiempo transcurrido obtenido: $tiempo");
    if (tiempo != null) {
      RegExp regExp = RegExp(r"(\d+) años, (\d+) meses, (\d+) días, (\d+) horas, (\d+) minutos, (\d+) segundos");
      Match? match = regExp.firstMatch(tiempo);
      if (match != null) {
        setState(() {
          anios = int.parse(match.group(1)!);
          meses = int.parse(match.group(2)!);
          dias = int.parse(match.group(3)!);
          horas = int.parse(match.group(4)!);
          minutos = int.parse(match.group(5)!);
          segundos = int.parse(match.group(6)!);
        });
      } else {
        print("El formato del tiempo no coincide con el RegExp.");
      }
    } else {
      print("El tiempo obtenido es null.");
    }
  }

  Widget _buildTiempoItem(int valor, String etiqueta) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 800),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            valor.toString().padLeft(2, '0'),
            key: ValueKey<int>(valor),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Text(
          etiqueta,
          style: TextStyle(fontSize: 12, color: Colors.pinkAccent),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Tiempo en pareja',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Fecha de inicio:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                    ),
                    SizedBox(height: 8),
                    Text(
                      fechaInicio,
                      style: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Tiempo transcurrido:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: [
                        // Fila de Años
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$anios',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Años',
                              style: TextStyle(fontSize: 20, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Contador normal debajo con FittedBox para ajustar el tamaño si es necesario
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTiempoItem(meses, 'Meses'),
                              Transform.translate(
                                offset: Offset(0, -13), // Ajusta aquí para alinear
                                child: Text(
                                  ' : ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                              _buildTiempoItem(dias, 'Días'),
                              Transform.translate(
                                offset: Offset(0, -13),
                                child: Text(
                                  ' : ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                              _buildTiempoItem(horas, 'Horas'),
                              Transform.translate(
                                offset: Offset(0, -13),
                                child: Text(
                                  ' : ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                              _buildTiempoItem(minutos, 'Minutos'),
                              Transform.translate(
                                offset: Offset(0, -13),
                                child: Text(
                                  ' : ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              ),
                              _buildTiempoItem(segundos, 'Segundos'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/rata_manta.png',
                  height: 150,
                ),
                SizedBox(width: 20),
                Image.asset(
                  'assets/rata_manta.png',
                  height: 150,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
