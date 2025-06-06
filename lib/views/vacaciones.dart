import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'perfil.dart'; // Asegúrate de importar la página de perfil
import 'package:memorii/controllers/usuario_controller.dart';

class VacacionesPage extends StatefulWidget {
  final int idUsuario; // Añadimos el parámetro idUsuario

  const VacacionesPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _VacacionesPageState createState() => _VacacionesPageState();
}

class _VacacionesPageState extends State<VacacionesPage> {
  final Map<String, List<Map<String, String>>> itinerary = {
    'Día 1: Granada → Torremolinos': [
      {'time': '08:15', 'icon': '🚌', 'desc': 'Salida en ALSA desde estación de Granada'},
      {'time': '10:15', 'icon': '🚌', 'desc': 'Llegada a estación de Málaga'},
      {'time': '10:20–11:00', 'icon': '🚏', 'desc': 'Bus M‑110 a Torremolinos'},
      {'time': '11:30–15:00', 'icon': '🍴', 'desc': 'Tiempo libre y comida'},
      {'time': '15:00', 'icon': '🏨', 'desc': 'Entrada al hotel y descanso'},
    ],
    'Día 2: Benalmádena y vuelta': [
      {'time': '08:00–13:30', 'icon': '🥐', 'desc': 'Desayuno libre'},
      {'time': '12:00', 'icon': '🚪', 'desc': 'Salida del hotel'},
      {'time': '12:35–12:55', 'icon': '🚌', 'desc': 'Bus M‑110 a Benalmádena'},
      {'time': '13:30–15:00', 'icon': '🍽️', 'desc': 'Comida en Benalmádena'},
      {'time': '15:00–18:30', 'icon': '🐠', 'desc': 'Visita a Sea Life'},
      {'time': '18:33–18:55', 'icon': '🚌', 'desc': 'Bus M‑110 a Málaga'},
      {'time': '20:00', 'icon': '🚌', 'desc': 'ALSA de vuelta a Granada'},
      {'time': '21:30', 'icon': '🏁', 'desc': 'Llegada a estación de Granada'},
    ],
  };

  final List<Map<String, dynamic>> busRoute = [
    {
      'zone': '🌆 Málaga',
      'stops': [
        {'name': 'Estación de Muelle Heredia', 'isImportant': false},
        {'name': 'Estación Tren Málaga', 'isImportant': true},
        {'name': 'Isla', 'isImportant': false},
        {'name': 'Goya', 'isImportant': false},
        {'name': 'Alaska', 'isImportant': false},
        {'name': 'El Torcal', 'isImportant': false},
        {'name': 'Flex', 'isImportant': false},
        {'name': 'Porcelanosa', 'isImportant': false},
        {'name': 'Puerta Blanca', 'isImportant': false},
        {'name': 'Málaga Nostrum', 'isImportant': false},
        {'name': 'Villarosa', 'isImportant': false},
        {'name': 'Cruce Aeropuerto', 'isImportant': false},
        {'name': 'Base Aérea', 'isImportant': false},
        {'name': 'Cruce Churriana', 'isImportant': false},
        {'name': 'Campamento Benítez', 'isImportant': false},
      ]
    },
    {
      'zone': '🏖️ Torremolinos',
      'stops': [
        {'name': 'Los Álamos', 'isImportant': false},
        {'name': 'La Colina', 'isImportant': false},
        {'name': 'El Pinar', 'isImportant': false},
        {'name': 'Playamar', 'isImportant': false},
        {'name': 'Las Estrellas', 'isImportant': false},
        {'name': 'Hoyo / Terminal Torremolinos', 'isImportant': true},
        {'name': 'Isabel Manoja', 'isImportant': false},
        {'name': 'Torremolinos Centro', 'isImportant': false},
        {'name': 'Casablanca', 'isImportant': false},
        {'name': 'Hotel Royal Al Andalus', 'isImportant': false},
        {'name': 'Carihuela', 'isImportant': false},
        {'name': 'Carlota Alessandri', 'isImportant': false},
        {'name': 'Montemar', 'isImportant': false},
        {'name': 'Rotonda Pez Espada', 'isImportant': false},
      ]
    },
    {
      'zone': '🌊 Benalmádena Costa',
      'stops': [
        {'name': 'Centro de Salud Carihuela', 'isImportant': false},
        {'name': 'Puerto Marina V', 'isImportant': true},
        {'name': 'Hotel Tritón', 'isImportant': false},
        {'name': 'Antonio Machado', 'isImportant': false},
        {'name': 'Selwo Marina', 'isImportant': false},
        {'name': 'Bil-Bil', 'isImportant': false},
        {'name': 'Los Maités', 'isImportant': false},
        {'name': 'Residencia Marymar', 'isImportant': false},
        {'name': 'Sunset Beach Club', 'isImportant': false},
        {'name': 'Torrequebrada', 'isImportant': false},
        {'name': 'Flatotel', 'isImportant': false},
        {'name': 'Torrenueva', 'isImportant': false},
      ]
    },
  ];

  final String mapaUrl = 'https://www.google.com/maps/d/u/0/edit?mid=1qZOCDjNGZ8Zwi6ptsLrMM_KDNWX5tiY&usp=sharing';
  final Color rosaPrincipal = Colors.pinkAccent;
  final Color rosaClaro = Colors.pink.shade50;
  String? _fotoPerfilUrl;
  final UsuarioController _usuarioController = UsuarioController();

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

  Future<void> _openMapa() async {
    final Uri url = Uri.parse(mapaUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir el mapa';
    }
  }

  void _navegarAPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PerfilPage(idUsuario: widget.idUsuario),
      ),
    ).then((_) async {
      await _cargarFotoPerfil(); // Recargar foto al volver
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: rosaPrincipal,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
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
        automaticallyImplyLeading: false,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              rosaClaro,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                child: Text(
                  'Nuestras Vacaciones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: rosaPrincipal,
                  ),
                ),
              ),
              ...itinerary.entries.map((entry) {
                final dayTitle = entry.key;
                final events = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.white,
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: rosaPrincipal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calendar_today, color: rosaPrincipal),
                      ),
                      title: Text(
                        dayTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: events.asMap().entries.map((e) {
                              final idx = e.key;
                              final ev = e.value;
                              return TimelineTile(
                                alignment: TimelineAlign.start,
                                isFirst: idx == 0,
                                isLast: idx == events.length - 1,
                                beforeLineStyle: LineStyle(
                                  color: rosaPrincipal.withOpacity(0.3),
                                  thickness: 2,
                                ),
                                afterLineStyle: LineStyle(
                                  color: rosaPrincipal.withOpacity(0.3),
                                  thickness: 2,
                                ),
                                indicatorStyle: IndicatorStyle(
                                  width: 28,
                                  height: 28,
                                  color: rosaPrincipal,
                                  padding: const EdgeInsets.all(4),
                                  iconStyle: IconStyle(
                                    iconData: _getIconForEvent(ev['icon']!),
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                endChild: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: rosaClaro.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ev['time']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: rosaPrincipal,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        ev['desc']!,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Sección del recorrido del bus
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: rosaPrincipal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.directions_bus, color: rosaPrincipal),
                    ),
                    title: Text(
                      '🚌 Recorrido Bus M-110',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: busRoute.map((zone) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                                  child: Text(
                                    zone['zone'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: rosaPrincipal,
                                    ),
                                  ),
                                ),
                                ...zone['stops'].map<Widget>((stop) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(right: 8, top: 2),
                                          child: Icon(
                                            Icons.fiber_manual_record,
                                            size: 12,
                                            color: stop['isImportant'] ? rosaPrincipal : Colors.grey.shade400,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            stop['name'],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: stop['isImportant'] ? FontWeight.bold : FontWeight.normal,
                                              color: stop['isImportant'] ? rosaPrincipal : Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        if (stop['isImportant'])
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.star,
                                              size: 16,
                                              color: rosaPrincipal,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                  height: 24,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _openMapa,
                  icon: Icon(Icons.map, color: Colors.white),
                  label: Text(
                    'Ver mapa completo',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rosaPrincipal,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: rosaPrincipal.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForEvent(String emoji) {
    switch (emoji) {
      case '🚌':
        return Icons.directions_bus;
      case '🍴':
      case '🍽️':
        return Icons.restaurant;
      case '🏨':
        return Icons.hotel;
      case '🚪':
        return Icons.exit_to_app;
      case '🐠':
        return Icons.visibility;
      case '🥐':
        return Icons.breakfast_dining;
      case '🏁':
        return Icons.flag;
      case '🚏':
      default:
        return Icons.place;
    }
  }
}