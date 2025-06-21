import 'package:flutter/material.dart';
import 'package:memorii/controllers/menu_semanal_controller.dart';
import 'package:memorii/models/menu_semanal_model.dart';
import 'package:memorii/views/editar_menu_semanal.dart';

class MenuSemanalPage extends StatefulWidget {
  final int idUsuario;

  const MenuSemanalPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _MenuSemanalPageState createState() => _MenuSemanalPageState();
}

class _MenuSemanalPageState extends State<MenuSemanalPage> {
  late int _selectedDayIndex;
  late ScrollController _scrollController;
  late MenuSemanalController _controller;
  MenuSemanal? _menuSemanal;
  bool _isLoading = true;

  final List<String> _diasSemana = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = MenuSemanalController();
    
    // Obtener el día actual (0 = Lunes, 6 = Domingo)
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Lunes, 7 = Domingo
    _selectedDayIndex = currentWeekday - 1; // Convertir a índice 0-6
    
    _cargarMenuSemanal();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarMenuSemanal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      MenuSemanal? menu = await _controller.obtenerMenuSemanal(widget.idUsuario);
      
      if (menu == null) {
        // Si no existe, crear uno por defecto
        await _controller.crearMenuSemanal(widget.idUsuario);
        menu = await _controller.obtenerMenuSemanal(widget.idUsuario);
      }

      setState(() {
        _menuSemanal = menu;
        _isLoading = false;
      });

      // Desplazar al día actual después de que se construya el widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDay();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error al cargar menú semanal: $e');
    }
  }

  // Función para desplazar al día seleccionado
  void _scrollToSelectedDay() {
    if (_scrollController.hasClients) {
      final itemWidth = 88.0; // 80 de ancho + 8 de margen
      final screenWidth = MediaQuery.of(context).size.width;
      final centerOffset = (screenWidth - itemWidth) / 2;
      final targetOffset = (_selectedDayIndex * itemWidth) - centerOffset;
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Función para obtener el número de día de la semana actual
  int _getDayNumber(int dayIndex) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Lunes de esta semana
    final targetDate = startOfWeek.add(Duration(days: dayIndex));
    return targetDate.day;
  }

  void _editarDia() async {
    if (_menuSemanal == null) return;

    String nombreDia = _diasSemana[_selectedDayIndex];
    DiaSemanal? dia = _menuSemanal!.dias[nombreDia];

    // Si el día no existe, crear uno vacío
    if (dia == null) {
      dia = DiaSemanal(
        nombre: nombreDia,
        comidas: {},
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarMenuSemanalPage(
          idUsuario: widget.idUsuario,
          nombreDia: nombreDia,
          dia: dia!, // Ahora sabemos que dia no es null
        ),
      ),
    );

    // Si se actualizó el menú, recargar los datos
    if (result == true) {
      _cargarMenuSemanal();
    }
  }

  final Map<String, String> _sustituciones = {
    'Pollo': 'Pescado blanco (merluza, dorada), Huevos, Tofu firme, Sardinas en lata al natural',
    'Lentejas': 'Garbanzos cocidos, Judías pintas, Soja texturizada',
    'Avena': 'Pan integral, Fruta extra + frutos secos',
    'Arroz': 'Cous cous, Patata cocida, Quinoa',
    'Espinacas': 'Acelgas, Judías verdes, Calabacín',
    'Fruta': 'Cualquier fruta fresca que te guste y esté en temporada'
  };

  Widget _buildDaySelector() {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _diasSemana.length,
        itemBuilder: (context, index) {
          final dia = _diasSemana[index];
          final isSelected = _selectedDayIndex == index;
          final dayNumber = _getDayNumber(index);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
              _scrollToSelectedDay();
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [Colors.pinkAccent, Colors.pinkAccent.withOpacity(0.8)]
                      : [Colors.grey.shade300, Colors.grey.shade200],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dia,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealCard(String mealName, Comida comida) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _obtenerColor(comida.color),
                _obtenerColor(comida.color).withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _obtenerIcono(comida.icono),
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    mealName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ...comida.items.map<Widget>((item) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _obtenerIcono(String icono) {
    switch (icono) {
      case 'wb_sunny':
        return Icons.wb_sunny;
      case 'restaurant':
        return Icons.restaurant;
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.restaurant;
    }
  }

  Color _obtenerColor(String colorHex) {
    return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
  }

  Widget _buildSustituciones() {
    return Container(
      margin: EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal,
                Colors.teal.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Sustituciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Usa estas alternativas si algún ingrediente no está disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              ..._sustituciones.entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward,
                            color: Colors.white.withOpacity(0.7),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.pinkAccent,
          title: Text(
            'Menú Semanal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
        ),
      );
    }

    final selectedDayName = _diasSemana[_selectedDayIndex];
    final selectedDay = _menuSemanal?.dias[selectedDayName];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Menú Semanal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _editarDia,
            tooltip: 'Editar ${selectedDayName}',
          ),
        ],
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
            SizedBox(height: 16),
            // Selector de días
            _buildDaySelector(),

            // Contenido del día seleccionado
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 16),

                    // Título del día seleccionado
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        selectedDayName,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.pinkAccent,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Comidas del día
                    if (selectedDay != null && selectedDay.comidas.isNotEmpty)
                      ...selectedDay.comidas.entries.map((entry) {
                        return _buildMealCard(entry.key, entry.value);
                      }).toList()
                    else
                      Container(
                        margin: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay comidas configuradas para este día',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Toca el botón de editar para agregar comidas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: 20),

                    // Sección de sustituciones
                    _buildSustituciones(),

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