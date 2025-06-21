import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:memorii/controllers/recuerdo_controller.dart';
import 'package:memorii/models/recuerdo_model.dart';
import 'solicitud_pareja.dart';
import 'perfil.dart';
import 'agregar_recuerdo.dart';
import 'ver_recuerdo.dart';
import 'inicio.dart';

class CalendarioPage extends StatefulWidget {
  final int idUsuario;

  const CalendarioPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _CalendarioPageState createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  late CalendarFormat _calendarFormat;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Set<DateTime> _recuerdoFechas = {};
  Map<DateTime, Recuerdo> _recuerdosDelDia = {};
  final UsuarioController _usuarioController = UsuarioController();
  final RecuerdoController _recuerdoController = RecuerdoController();
  int _idPareja = -1;
  String? _fotoPerfilUrl;

  int usuario1Id = -1;
  int usuario2Id = -1;
  String nombreUser1 = "";
  String nombreUser2 = "";

  // Valoración seleccionada para los usuarios
  Valoracion? valoracionUsuario1;
  Valoracion? valoracionUsuario2;

  int _numeroDeSemanas = 5;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _cargarDatos();
    _numeroDeSemanas = _calcularNumeroDeSemanas(_focusedDay);
  }

  Future<void> _cargarDatos() async {
    int idPareja = await _usuarioController.get_idPareja(idUsuario: widget.idUsuario);
    String? fotoUrl = await _usuarioController.obtenerFotoPerfilUsuario(widget.idUsuario);

    setState(() {
      _idPareja = idPareja;
      _fotoPerfilUrl = fotoUrl;
    });

    if (_idPareja != -1) {
      await _cargarRecuerdos(_idPareja);
    }

    usuario1Id = await _usuarioController.getIdUser1Pareja(_idPareja);
    usuario2Id = await _usuarioController.getIdUser2Pareja(_idPareja);
    nombreUser1 = await _usuarioController.obtenerNombreUsuario(usuario1Id);
    nombreUser2 = await _usuarioController.obtenerNombreUsuario(usuario2Id);

    // Cargar las valoraciones actuales
    if (_recuerdosDelDia[_selectedDay] != null) {
      valoracionUsuario1 = _recuerdosDelDia[_selectedDay]!.valoracionUsuario1;
      valoracionUsuario2 = _recuerdosDelDia[_selectedDay]!.valoracionUsuario2;
    }

    setState(() {});

    print(nombreUser1);
    print(nombreUser2);
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
        return 'assets/rata_nose.png';
    }
  }

  // Método mejorado para obtener dimensiones responsivas
  Map<String, double> _obtenerDimensionesResponsivas() {
    // Calcular la altura disponible de la pantalla
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = kToolbarHeight;
    double statusBarHeight = MediaQuery.of(context).padding.top;
    double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Altura aproximada del calendario (esto puede variar según el número de semanas)
    double calendarioHeight = _numeroDeSemanas * 40.0 + 100; // aproximado

    // Altura disponible para la card inferior
    double alturaDisponible = screenHeight - appBarHeight - statusBarHeight - bottomPadding - calendarioHeight - 100;

    // Calcular tamaños basados en la altura disponible y número de semanas
    double imagenSize;
    int maxLineasTexto;

    if (_numeroDeSemanas <= 4) {
      // Más espacio disponible
      imagenSize = alturaDisponible > 350 ? 70.0 : 50.0;
      maxLineasTexto = 10;
    } else if (_numeroDeSemanas == 5) {
      // Espacio moderado
      imagenSize = alturaDisponible > 300 ? 60.0 : 45.0;
      maxLineasTexto = 8;
    } else {
      // Menos espacio (6 semanas)
      imagenSize = alturaDisponible > 250 ? 50.0 : 35.0;
      maxLineasTexto = 6;
    }

    return {
      'imagenSize': imagenSize,
      'maxLineasTexto': maxLineasTexto.toDouble(),
    };
  }

  Future<void> _cargarRecuerdos(int idPareja) async {
    List<Recuerdo> recuerdos = await _recuerdoController.obtenerRecuerdosPorMes(_focusedDay.month, idPareja);

    setState(() {
      _recuerdoFechas = recuerdos.map((r) {
        if (r.fecha is Timestamp) {
          return (r.fecha).toDate().toLocal();
        } else {
          throw Exception('Tipo de fecha desconocido: ${r.fecha.runtimeType}');
        }
      }).map((fecha) => DateTime(fecha.year, fecha.month, fecha.day)).toSet();

      _recuerdosDelDia = {
        for (var recuerdo in recuerdos)
          DateTime(
              (recuerdo.fecha as Timestamp).toDate().toLocal().year,
              (recuerdo.fecha as Timestamp).toDate().toLocal().month,
              (recuerdo.fecha as Timestamp).toDate().toLocal().day
          ): recuerdo
      };
    });

    print("Recuerdos cargados: $_recuerdosDelDia");
    print("Selected Day (Local): ${_selectedDay.toLocal()}");
  }

  void _navegarACrearRecuerdo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarRecuerdoPage(fechaSeleccionada: _selectedDay, idPareja: _idPareja),
      ),
    ).then((_) async {
      _idPareja = await _usuarioController.get_idPareja(idUsuario: widget.idUsuario);
      setState(() {});
      await _cargarRecuerdos(_idPareja);
      await _cargarDatos();
    });
  }

  void _navegarAVerRecuerdo(Recuerdo recuerdo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerRecuerdoPage(fechaSeleccionada: _selectedDay, recuerdo: _recuerdosDelDia[_selectedDay]!),
      ),
    ).then((_) async {
      _idPareja = await _usuarioController.get_idPareja(idUsuario: widget.idUsuario);
      setState(() {});
      await _cargarRecuerdos(_idPareja);
      await _cargarDatos();
    });
  }

  void _navegarAPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilPage(idUsuario: widget.idUsuario),
      ),
    ).then((_) async {
      _idPareja = await _usuarioController.get_idPareja(idUsuario: widget.idUsuario);
      setState(() {});
      await _cargarRecuerdos(_idPareja);
      await _cargarDatos();
    });
  }

  bool _esMismaFecha(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year && fecha1.month == fecha2.month && fecha1.day == fecha2.day;
  }

  int _calcularNumeroDeSemanas(DateTime month) {
    // Primer día del mes
    DateTime primerDiaDelMes = DateTime(month.year, month.month, 1);

    // Último día del mes
    DateTime ultimoDiaDelMes = DateTime(month.year, month.month + 1, 0);

    // Día de la semana del primer día del mes (1 = lunes, 7 = domingo)
    int diaDeLaSemanaDelPrimerDia = primerDiaDelMes.weekday;

    // Número total de días del mes
    int diasEnElMes = ultimoDiaDelMes.day;

    // Calcular el número de días vacíos antes del primer día del mes
    int diasVacios = diaDeLaSemanaDelPrimerDia == 7 ? 0 : diaDeLaSemanaDelPrimerDia;

    // Calcular el número total de días para completar el calendario (con días vacíos)
    int totalDias = diasEnElMes + diasVacios;

    // Calcular el número de semanas
    int semanas = (totalDias / 7).ceil();

    return semanas;
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones responsivas
    Map<String, double> dimensiones = _obtenerDimensionesResponsivas();
    double imagenSize = dimensiones['imagenSize']!;
    int maxLineasTexto = dimensiones['maxLineasTexto']!.toInt();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.pinkAccent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InicioPage(idUsuario: widget.idUsuario),
                  ),
                );
              },
              child: Image.asset('assets/memorii_logo_texto.png', height: 40),
            ),
            GestureDetector(
              onTap: _navegarAPerfil,
              child: CircleAvatar(
                backgroundImage: _fotoPerfilUrl != null && _fotoPerfilUrl != 'assets/imagen_perfil_default.png'
                    ? NetworkImage(_fotoPerfilUrl!)
                    : Image.asset('assets/imagen_perfil_default.png').image,
                radius: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => _esMismaFecha(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateTime(selectedDay.toLocal().year, selectedDay.toLocal().month, selectedDay.toLocal().day);
                      _focusedDay = focusedDay;
                      if (_idPareja != -1 && _recuerdosDelDia[_selectedDay] != null) {
                        valoracionUsuario1 = _recuerdosDelDia[_selectedDay]!.valoracionUsuario1;
                        valoracionUsuario2 = _recuerdosDelDia[_selectedDay]!.valoracionUsuario2;
                      }
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _recuerdoFechas.clear();
                      _recuerdosDelDia.clear();
                      _numeroDeSemanas = _calcularNumeroDeSemanas(_focusedDay);

                      Future.delayed(Duration(milliseconds: 100), () {
                        if (_idPareja != -1) {
                          _cargarRecuerdos(_idPareja);
                        }
                      });
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.redAccent),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    dowTextFormatter: (date, locale) {
                      return ['LU', 'MA', 'MI', 'JU', 'VI', 'SA', 'DO'][date.weekday - 1];
                    },
                    weekdayStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.0,
                    ),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.redAccent,
                      height: 1.0,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      bool isRecuerdo = _idPareja != -1 && _recuerdoFechas.any((d) => _esMismaFecha(d, day));

                      return Stack(
                        children: [
                          Center(
                            child: Text(
                              day.day.toString(),
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          if (isRecuerdo)
                            Positioned(
                              bottom: 4,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.pinkAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (date, locale) =>
                        DateFormat('MMMM yyyy', locale).format(date).replaceFirstMapped(
                            RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase()),
                    titleTextStyle: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                color: Colors.pinkAccent,
                child: Column(
                  children: [
                    if (_idPareja != -1 && _recuerdosDelDia[_selectedDay] != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(11.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Columna que ocupa 2/3 de la tarjeta
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Recuerdo del día",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          _recuerdosDelDia[_selectedDay]!.texto,
                                          style: TextStyle(fontSize: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Línea divisoria entre las columnas
                              Container(
                                width: 1,
                                height: double.infinity,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                color: Colors.white.withOpacity(0.3),
                              ),
                              // Columna que ocupa 1/3 de la tarjeta
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Usuario 1 con imagen
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              nombreUser1,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: imagenSize,
                                              maxHeight: imagenSize,
                                            ),
                                            child: Image.asset(
                                              _obtenerImagenPorValoracion(valoracionUsuario1 ?? Valoracion.Nose),
                                              width: imagenSize,
                                              height: imagenSize,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    // Usuario 2 con imagen
                                    Flexible(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              nombreUser2,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            constraints: BoxConstraints(
                                              maxWidth: imagenSize,
                                              maxHeight: imagenSize,
                                            ),
                                            child: Image.asset(
                                              _obtenerImagenPorValoracion(valoracionUsuario2 ?? Valoracion.Nose),
                                              width: imagenSize,
                                              height: imagenSize,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_idPareja != -1 && _recuerdosDelDia[_selectedDay] == null)
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "No hay recuerdo para este día",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Botón "Ver recuerdo" solo si hay un recuerdo
          if (_idPareja != -1 && _recuerdosDelDia[_selectedDay] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _navegarAVerRecuerdo(_recuerdosDelDia[_selectedDay]!);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                child: Text('Ver recuerdo', style: TextStyle(color: Colors.white)),
              ),
            ),
          // Botón "Agregar recuerdo" solo si no hay recuerdo
          if (_idPareja != -1 && _recuerdosDelDia[_selectedDay] == null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _navegarACrearRecuerdo();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                child: Text('Agregar recuerdo', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}