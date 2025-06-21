import 'package:flutter/material.dart';
import 'package:memorii/controllers/menu_semanal_controller.dart';
import 'package:memorii/models/menu_semanal_model.dart';

class EditarMenuSemanalPage extends StatefulWidget {
  final int idUsuario;
  final String nombreDia;
  final DiaSemanal dia;

  const EditarMenuSemanalPage({
    Key? key,
    required this.idUsuario,
    required this.nombreDia,
    required this.dia,
  }) : super(key: key);

  @override
  _EditarMenuSemanalPageState createState() => _EditarMenuSemanalPageState();
}

class _EditarMenuSemanalPageState extends State<EditarMenuSemanalPage> {
  late MenuSemanalController _controller;
  late Map<String, Comida> _comidas;
  final TextEditingController _nuevoItemController = TextEditingController();
  final TextEditingController _nuevaComidaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = MenuSemanalController();
    _comidas = Map.from(widget.dia.comidas);
  }

  @override
  void dispose() {
    _nuevoItemController.dispose();
    _nuevaComidaController.dispose();
    super.dispose();
  }

  void _mostrarDialogoAgregarComida() {
    String iconoSeleccionado = 'restaurant';
    String colorSeleccionado = '#F44336';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                      minWidth: 300,
                      maxWidth: 400,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.pink.shade50,
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header con icono
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 40,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            SizedBox(height: 16),
                            
                            Text(
                              'Agregar Nueva Comida',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Campo de nombre
                            TextField(
                              controller: _nuevaComidaController,
                              cursorColor: Colors.pinkAccent,
                              decoration: InputDecoration(
                                labelText: 'Nombre de la comida',
                                labelStyle: TextStyle(color: Colors.pinkAccent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.pinkAccent),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                                ),
                                prefixIcon: Icon(Icons.edit, color: Colors.pinkAccent),
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Selector de icono
                            Text(
                              'Selecciona un icono:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: 8,
                                itemBuilder: (context, index) {
                                  List<IconData> iconos = [
                                    Icons.wb_sunny,
                                    Icons.restaurant,
                                    Icons.nightlight_round,
                                    Icons.apple,
                                    Icons.local_pizza,
                                    Icons.icecream,
                                    Icons.local_cafe,
                                    Icons.cake,
                                  ];
                                  
                                  List<String> iconosNombres = [
                                    'wb_sunny',
                                    'restaurant',
                                    'nightlight_round',
                                    'apple',
                                    'local_pizza',
                                    'icecream',
                                    'local_cafe',
                                    'cake',
                                  ];
                                  
                                  bool isSelected = iconosNombres[index] == iconoSeleccionado;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        iconoSeleccionado = iconosNombres[index];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.pinkAccent : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        iconos[index],
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Selector de color
                            Text(
                              'Selecciona un color:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.pinkAccent,
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: 6,
                                itemBuilder: (context, index) {
                                  List<String> colores = [
                                    '#FF9800',
                                    '#F44336',
                                    '#4CAF50',
                                    '#9C27B0',
                                    '#2196F3',
                                    '#FF6B6B',
                                  ];
                                  
                                  bool isSelected = colores[index] == colorSeleccionado;
                                  Color color = Color(int.parse(colores[index].replaceAll('#', '0xFF')));
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        colorSeleccionado = colores[index];
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
                                          width: isSelected ? 3 : 1,
                                        ),
                                        boxShadow: isSelected ? [
                                          BoxShadow(
                                            color: Colors.pinkAccent.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ] : null,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 24),
                            
                            // Botones
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.pinkAccent,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      if (_nuevaComidaController.text.isNotEmpty) {
                                        this.setState(() {
                                          _comidas[_nuevaComidaController.text] = Comida(
                                            nombre: _nuevaComidaController.text,
                                            icono: iconoSeleccionado,
                                            color: colorSeleccionado,
                                            items: [],
                                          );
                                        });
                                        _nuevaComidaController.clear();
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pinkAccent,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Text(
                                      'Agregar',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoAgregarItem(String nombreComida) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.pink.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: Colors.pinkAccent,
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  'Agregar Item a $nombreComida',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                
                // Campo de texto
                TextField(
                  controller: _nuevoItemController,
                  cursorColor: Colors.pinkAccent,
                  decoration: InputDecoration(
                    labelText: 'Nuevo item',
                    labelStyle: TextStyle(color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.pinkAccent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                    ),
                    prefixIcon: Icon(Icons.edit_note, color: Colors.pinkAccent),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 24),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nuevoItemController.text.isNotEmpty) {
                            setState(() {
                              _comidas[nombreComida]!.items.add(_nuevoItemController.text);
                            });
                            _nuevoItemController.clear();
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Agregar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _eliminarItem(String nombreComida, int index) {
    setState(() {
      _comidas[nombreComida]!.items.removeAt(index);
    });
  }

  void _eliminarComida(String nombreComida) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.red.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con icono de advertencia
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  'Eliminar Comida',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                
                Text(
                  '¿Estás seguro de que quieres eliminar "$nombreComida"?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _comidas.remove(nombreComida);
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          'Eliminar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _moverComidaArriba(String nombreComida) {
    List<String> nombresComidas = _comidas.keys.toList();
    int index = nombresComidas.indexOf(nombreComida);
    
    if (index > 0) {
      setState(() {
        // Crear un nuevo mapa con el orden corregido
        Map<String, Comida> nuevoMapa = {};
        
        // Reordenar las claves
        for (int i = 0; i < nombresComidas.length; i++) {
          if (i == index - 1) {
            nuevoMapa[nombreComida] = _comidas[nombreComida]!;
          } else if (i == index) {
            nuevoMapa[nombresComidas[index - 1]] = _comidas[nombresComidas[index - 1]]!;
          } else {
            nuevoMapa[nombresComidas[i]] = _comidas[nombresComidas[i]]!;
          }
        }
        
        _comidas = nuevoMapa;
      });
    }
  }

  void _moverComidaAbajo(String nombreComida) {
    List<String> nombresComidas = _comidas.keys.toList();
    int index = nombresComidas.indexOf(nombreComida);
    
    if (index < nombresComidas.length - 1) {
      setState(() {
        // Crear un nuevo mapa con el orden corregido
        Map<String, Comida> nuevoMapa = {};
        
        // Reordenar las claves
        for (int i = 0; i < nombresComidas.length; i++) {
          if (i == index) {
            nuevoMapa[nombresComidas[index + 1]] = _comidas[nombresComidas[index + 1]]!;
          } else if (i == index + 1) {
            nuevoMapa[nombreComida] = _comidas[nombreComida]!;
          } else {
            nuevoMapa[nombresComidas[i]] = _comidas[nombresComidas[i]]!;
          }
        }
        
        _comidas = nuevoMapa;
      });
    }
  }

  void _guardarCambios() async {
    try {
      DiaSemanal diaActualizado = DiaSemanal(
        nombre: widget.nombreDia,
        comidas: _comidas,
      );

      await _controller.actualizarDia(widget.idUsuario, widget.nombreDia, diaActualizado);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menú actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar que se actualizó
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el menú: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      case 'local_pizza':
        return Icons.local_pizza;
      case 'icecream':
        return Icons.icecream;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'cake':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  Color _obtenerColor(String colorHex) {
    return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Editar ${widget.nombreDia}',
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
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _guardarCambios,
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
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Comidas del ${widget.nombreDia}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Usa las flechas ↑↓ para ordenar las comidas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de comidas
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Comidas existentes
                  ..._comidas.entries.map((entry) {
                    String nombreComida = entry.key;
                    Comida comida = entry.value;

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
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
                          children: [
                            // Header de la comida
                            Container(
                              padding: EdgeInsets.all(16),
                              child: Row(
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
                                  Expanded(
                                    child: Text(
                                      nombreComida,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Botones de ordenamiento
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón subir
                                      Container(
                                        margin: EdgeInsets.only(right: 4),
                                        child: IconButton(
                                          icon: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                                          onPressed: () => _moverComidaArriba(nombreComida),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            minimumSize: Size(36, 36),
                                          ),
                                        ),
                                      ),
                                      // Botón bajar
                                      Container(
                                        margin: EdgeInsets.only(right: 8),
                                        child: IconButton(
                                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                          onPressed: () => _moverComidaAbajo(nombreComida),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            minimumSize: Size(36, 36),
                                          ),
                                        ),
                                      ),
                                      // Botón eliminar
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.white),
                                        onPressed: () => _eliminarComida(nombreComida),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.2),
                                          minimumSize: Size(36, 36),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Lista de items
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                children: [
                                  ...comida.items.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    String item = entry.value;
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
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.white, size: 20),
                                            onPressed: () => _eliminarItem(nombreComida, index),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),

                                  // Botón para agregar item
                                  Container(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _mostrarDialogoAgregarItem(nombreComida),
                                      icon: Icon(Icons.add, size: 18),
                                      label: Text('Agregar Item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                  // Botón para agregar nueva comida al final
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: _mostrarDialogoAgregarComida,
                      icon: Icon(Icons.add_circle_outline, size: 24),
                      label: Text(
                        'Agregar Nueva Comida',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  // Espacio adicional al final
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 