import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:memorii/controllers/lista_compra_controller.dart';
import 'perfil.dart';
import 'calendario.dart';
import 'vacaciones.dart';
import 'solicitud_pareja.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'fitness.dart';

class InicioPage extends StatefulWidget {
  final int idUsuario;

  const InicioPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _InicioPageState createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  final UsuarioController _usuarioController = UsuarioController();
  final ListaCompraController _listaCompraController = ListaCompraController();
  String? _fotoPerfilUrl;
  int _idPareja = -1;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    int idPareja = await _usuarioController.get_idPareja(idUsuario: widget.idUsuario);
    String? fotoUrl = await _usuarioController.obtenerFotoPerfilUsuario(widget.idUsuario);

    // Verificar y resetear lista de compra si es lunes
    await _listaCompraController.verificarResetAutomatico(widget.idUsuario);

    setState(() {
      _idPareja = idPareja;
      _fotoPerfilUrl = fotoUrl;
    });
  }

  void _navegarAPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilPage(idUsuario: widget.idUsuario),
      ),
    ).then((_) async {
      await _cargarDatos(); // Recargar datos al volver
    });
  }

  void _navegarACalendario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarioPage(idUsuario: widget.idUsuario),
      ),
    ).then((_) async {
      await _cargarDatos(); // Recargar datos al volver
    });
  }

  void _navegarAVacaciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VacacionesPage(idUsuario: widget.idUsuario,),
      ),
    ).then((_) async {
      await _cargarDatos(); // Recargar datos al volver
    });
  }

  void _navegarAFitness() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FitnessPage(idUsuario: widget.idUsuario,),
      ),
    ).then((_) async {
      await _cargarDatos(); // Recargar datos al volver
    });
  }

  void _navegarASolicitudPareja() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SolicitudParejaPage(idUsuario: widget.idUsuario),
      ),
    ).then((_) async {
      await _cargarDatos();
    });
  }

  Future<void> _enviarNotificacionPrueba() async {
    try {
      print('📤 Enviando notificación de prueba...');

      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'memorii_channel',
        'Memorii Notifications',
        channelDescription: 'Notificaciones de la app Memorii',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        '¡Notificación de prueba! 📱',
        'Esta es una prueba local',
        notificationDetails,
      );

      print('✅ Notificación local enviada');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📤 Notificación enviada')),
      );
    } catch (e) {
      print('❌ Error enviando notificación: $e');
    }
  }

  // Widget para crear botones consistentes con el estilo de la app
  Widget _buildMenuButton({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  backgroundColor ?? Colors.pinkAccent,
                  (backgroundColor ?? Colors.pinkAccent).withOpacity(0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                // Ya estamos en la página de inicio, no necesitamos navegar
                // Podrías agregar una animación o feedback visual aquí si quieres
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
        automaticallyImplyLeading: false, // Quita la flecha de retroceso
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Header con saludo
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido a Memorii!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Guarda y comparte tus recuerdos más especiales junto a tu pareja',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Indicador de estado de pareja
            if (_idPareja != -1)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Conectado con tu pareja',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.orange.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Conecta con tu pareja para empezar',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            if (_idPareja == -1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _navegarASolicitudPareja();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  child: Text('Solicitudes de pareja', style: TextStyle(color: Colors.white)),
                ),
              ),
            if (_idPareja != -1)
              // Sección de botones del menú
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Menú Principal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      // Botón del Calendario
                      _buildMenuButton(
                        title: 'Calendario',
                        description: 'Ve y administra tus recuerdos por fechas',
                        icon: Icons.calendar_today,
                        onPressed: _navegarACalendario,
                        backgroundColor: Colors.pinkAccent,
                      ),

                      _buildMenuButton(
                        title: 'Vacaciones',
                        description: 'Itinerario de nuestras super vacaciones',
                        icon: Icons.beach_access,
                        onPressed: _navegarAVacaciones,
                        backgroundColor: Colors.pinkAccent,
                      ),

                      _buildMenuButton(
                        title: 'Rutina Fit',
                        description: 'Todo lo necesario para nuestra puesta en forma',
                        icon: Icons.fitness_center_rounded,
                        onPressed: _navegarAFitness,
                        backgroundColor: Colors.pinkAccent,
                      ),

                      /*
                      ElevatedButton.icon(
                        onPressed: _enviarNotificacionPrueba,
                        icon: Icon(Icons.notifications),
                        label: Text('Probar Notificación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      */

                      /*
                      _buildMenuButton(
                        title: 'Estadísticas',
                        description: 'Ve estadísticas de tus recuerdos',
                        icon: Icons.bar_chart,
                        onPressed: () {
                          // Navigator.push(...);
                        },
                        backgroundColor: Colors.teal,
                      ),
                      */

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}