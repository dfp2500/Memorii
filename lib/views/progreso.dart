import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memorii/controllers/progreso_peso_controller.dart';
import 'package:memorii/models/progreso_peso_model.dart';
import 'grafico_progreso.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class ProgresoPage extends StatefulWidget {
  final int idUsuario;

  const ProgresoPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _ProgresoPageState createState() => _ProgresoPageState();
}

class _ProgresoPageState extends State<ProgresoPage> {
  final ProgresoPesoController _controller = ProgresoPesoController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  final FocusNode _notasFocusNode = FocusNode();
  
  List<ProgresoPeso> _progresos = [];
  Map<String, dynamic> _estadisticas = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _notasFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notasFocusNode.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<ProgresoPeso> progresos = await _controller.obtenerProgresosOrdenados(widget.idUsuario);
      Map<String, dynamic> estadisticas = await _controller.calcularEstadisticas(widget.idUsuario);

      setState(() {
        _progresos = progresos;
        _estadisticas = estadisticas;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoAgregarPeso(DateTime fecha) async {
    _pesoController.clear();
    _notasController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.weightHanging, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registrar Peso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido del diálogo
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _pesoController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          cursorColor: Colors.pinkAccent,
                          style: TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Peso (kg)',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                            ),
                            prefixIcon: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: FaIcon(FontAwesomeIcons.weightHanging, color: Colors.pinkAccent, size: 20),
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _notasFocusNode.hasFocus ? Colors.pinkAccent : Colors.grey.shade400,
                              width: _notasFocusNode.hasFocus ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _notasController,
                            focusNode: _notasFocusNode,
                            maxLines: 2,
                            cursorColor: Colors.pinkAccent,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Notas (opcional)',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botones del diálogo
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar', style: TextStyle(color: Colors.pinkAccent),),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _agregarPeso(fecha);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Guardar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditarPeso(DateTime fecha, ProgresoPeso progresoActual) {
    _pesoController.text = progresoActual.peso.toString();
    _notasController.text = progresoActual.notas ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Editar Peso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido del diálogo
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          controller: _pesoController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          cursorColor: Colors.pinkAccent,
                          style: TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Peso (kg)',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                            ),
                            prefixIcon: SizedBox(
                              width: 48,
                              height: 48,
                              child: Center(
                                child: FaIcon(FontAwesomeIcons.weightHanging, color: Colors.pinkAccent, size: 20),
                              ),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _notasFocusNode.hasFocus ? Colors.pinkAccent : Colors.grey.shade400,
                              width: _notasFocusNode.hasFocus ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _notasController,
                            focusNode: _notasFocusNode,
                            maxLines: 2,
                            cursorColor: Colors.pinkAccent,
                            style: TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Notas (opcional)',
                              labelStyle: TextStyle(color: Colors.grey.shade600),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botones del diálogo
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancelar', style: TextStyle(color: Colors.pinkAccent),),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _editarPeso(fecha);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Actualizar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarConfirmacionBorrar(DateTime fecha) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.pinkAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'Confirmar Borrado',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres borrar el registro de peso del ${DateFormat('dd/MM/yyyy').format(fecha)}?\n\nEsta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: Colors.pinkAccent),),
            ),
            ElevatedButton(
              onPressed: () async {
                await _borrarPeso(fecha);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editarPeso(DateTime fecha) async {
    if (_pesoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa tu peso'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      double peso = double.parse(_pesoController.text);
      String? documentId = await _controller.obtenerDocumentId(widget.idUsuario, fecha);
      
      if (documentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el registro'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success = await _controller.actualizarProgresoPeso(
        documentId: documentId,
        peso: peso,
        notas: _notasController.text.isNotEmpty ? _notasController.text : null,
      );

      if (success) {
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el peso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa un peso válido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _borrarPeso(DateTime fecha) async {
    try {
      String? documentId = await _controller.obtenerDocumentId(widget.idUsuario, fecha);
      
      if (documentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: No se encontró el registro'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      bool success = await _controller.borrarProgresoPeso(documentId);

      if (success) {
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al borrar el registro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al borrar el registro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _agregarPeso(DateTime fecha) async {
    if (_pesoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa tu peso'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si ya existe un registro para esta fecha
    bool existeRegistro = await _controller.existeRegistroParaFecha(widget.idUsuario, fecha);
    
    if (existeRegistro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya existe un registro para el día de hoy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      double peso = double.parse(_pesoController.text);
      bool success = await _controller.agregarProgresoPeso(
        idUsuario: widget.idUsuario,
        peso: peso,
        fecha: fecha,
        notas: _notasController.text.isNotEmpty ? _notasController.text : null,
      );

      if (success) {
        await _cargarDatos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar el peso'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa un peso válido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ProgresoPeso? _obtenerPesoParaFecha(DateTime fecha) {
    return _progresos.firstWhere(
      (progreso) => progreso.fecha.year == fecha.year &&
                    progreso.fecha.month == fecha.month &&
                    progreso.fecha.day == fecha.day,
      orElse: () => ProgresoPeso(
        idProgreso: 0,
        idUsuario: 0,
        peso: 0,
        fecha: fecha,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Mi Progreso',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : Container(
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
              child: SafeArea(
                child: Column(
                  children: [
                    // Header con estadísticas principales - más compacto
                    _buildEstadisticasHeader(),
                    
                    // Calendario - más espacio
                    Expanded(
                      child: _buildCalendario(),
                    ),
                    
                    // Botones de acción
                    _buildBotonesAccion(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEstadisticasHeader() {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Resumen de Progreso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GraficoProgresoPage(idUsuario: widget.idUsuario),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Gráfico',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // Primera fila de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaCard(
                  'Peso Actual',
                  '${_estadisticas['pesoActual']?.toStringAsFixed(1) ?? '0.0'} kg',
                  FaIcon(FontAwesomeIcons.weightHanging, color: Colors.blue, size: 18),
                  Colors.blue,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildEstadisticaCard(
                  'Peso Perdido',
                  '${_estadisticas['pesoPerdido']?.toStringAsFixed(1) ?? '0.0'} kg',
                  Icons.trending_down,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Segunda fila de estadísticas
          Row(
            children: [
              Expanded(
                child: _buildEstadisticaCard(
                  'Promedio Diario',
                  '${_estadisticas['tendenciaPromedio'] ?? ''}${_estadisticas['promedioDiario']?.toStringAsFixed(1) ?? '0.0'} kg',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 4),
              Expanded(
                child: _buildEstadisticaCard(
                  'Días Transcurridos',
                  '${_estadisticas['diasTranscurridos'] ?? 0}',
                  Icons.schedule,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaCard(String titulo, String valor, dynamic icono, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icono is IconData 
                ? Icon(icono, color: color, size: 18)
                : icono is Widget 
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: icono,
                      )
                    : Container(),
            SizedBox(height: 2),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1),
            Text(
              valor,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendario() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              // Header del calendario
              _buildCalendarioHeader(),
              SizedBox(height: 12),
              // Días de la semana
              _buildDiasSemana(),
              SizedBox(height: 8),
              // Días del mes
              Expanded(
                child: _buildDiasMes(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarioHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
            });
          },
          icon: Icon(Icons.chevron_left, color: Colors.pinkAccent, size: 20),
        ),
        Text(
          DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay).replaceFirst(
            DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay)[0],
            DateFormat('MMMM yyyy', 'es_ES').format(_focusedDay)[0].toUpperCase(),
          ),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.pinkAccent,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
            });
          },
          icon: Icon(Icons.chevron_right, color: Colors.pinkAccent, size: 20),
        ),
      ],
    );
  }

  Widget _buildDiasSemana() {
    List<String> diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return Row(
      children: diasSemana.map((dia) {
        return Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              dia,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDiasMes() {
    DateTime primerDia = DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime ultimoDia = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    
    // Ajustar para que la semana empiece en lunes
    int primerDiaSemana = primerDia.weekday - 1;
    if (primerDiaSemana == 0) primerDiaSemana = 7;
    
    int totalDias = ultimoDia.day;
    int totalCeldas = primerDiaSemana + totalDias;
    int semanas = (totalCeldas / 7).ceil();

    return Column(
      children: List.generate(semanas, (semanaIndex) {
        return Expanded(
          child: Row(
            children: List.generate(7, (diaIndex) {
              int celdaIndex = semanaIndex * 7 + diaIndex;
              int diaMes = celdaIndex - primerDiaSemana + 1;
              
              if (diaMes < 1 || diaMes > totalDias) {
                return Expanded(child: Container());
              }
              
              DateTime fecha = DateTime(_focusedDay.year, _focusedDay.month, diaMes);
              return Expanded(
                child: _buildDiaCalendario(fecha),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDiaCalendario(DateTime fecha) {
    ProgresoPeso? progreso = _obtenerPesoParaFecha(fecha);
    double? diferencia = _controller.calcularDiferenciaPeso(_progresos, fecha);
    bool esHoy = fecha.year == DateTime.now().year &&
                 fecha.month == DateTime.now().month &&
                 fecha.day == DateTime.now().day;
    
    // Verificar si es el primer día con peso registrado
    DateTime? primerDiaConPeso = _controller.obtenerPrimerDiaConPeso(_progresos);
    bool esPrimerDiaConPeso = primerDiaConPeso != null &&
                             fecha.year == primerDiaConPeso.year &&
                             fecha.month == primerDiaConPeso.month &&
                             fecha.day == primerDiaConPeso.day;

    // Determinar el color del recuadro
    Color colorRecuadro = Colors.transparent;
    if (esHoy) {
      colorRecuadro = Colors.pinkAccent.withOpacity(0.3);
    } else if (progreso?.peso != 0) {
      if (esPrimerDiaConPeso) {
        colorRecuadro = Colors.pink.withOpacity(0.2); // Rosa para el primer día
      } else if (diferencia != null) {
        colorRecuadro = diferencia > 0 ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2);
      } else {
        colorRecuadro = Colors.green.withOpacity(0.1);
      }
    }

    return GestureDetector(
      onTap: () {
        if (progreso?.peso != 0) {
          _mostrarDetallePeso(progreso!);
        }
        // No hacer nada si no hay registro
      },
      child: Container(
        margin: EdgeInsets.all(1),
        padding: EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
        decoration: BoxDecoration(
          color: colorRecuadro,
          borderRadius: BorderRadius.circular(8),
          border: progreso?.peso != 0 ? Border.all(
            color: esPrimerDiaConPeso ? Colors.pink : 
                   diferencia != null && diferencia > 0 ? Colors.red : Colors.green, 
            width: 1
          ) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              fecha.day.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: esHoy ? Colors.pinkAccent :
                       progreso?.peso != 0 ? 
                         (esPrimerDiaConPeso ? Colors.pink.shade700 : 
                          diferencia != null && diferencia > 0 ? Colors.red : Colors.green) : 
                       Colors.black87,
              ),
            ),
            if (diferencia != null) ...[
              SizedBox(height: 0.5),
              Container(
                constraints: BoxConstraints(maxHeight: 10),
                child: Text(
                  diferencia > 0 ? '+${diferencia.toStringAsFixed(1)}' : '${diferencia.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: diferencia > 0 ? Colors.red : Colors.green,
                    height: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (esPrimerDiaConPeso && progreso?.peso != 0) ...[
              SizedBox(height: 0.5),
              Container(
                constraints: BoxConstraints(maxHeight: 10),
                child: Text(
                  '${progreso!.peso.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700,
                    height: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarDetallePeso(ProgresoPeso progreso) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header del diálogo
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FaIcon(FontAwesomeIcons.weightHanging, color: Colors.white, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registro de Peso',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(progreso.fecha),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido del diálogo
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Peso principal
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.pinkAccent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.weightHanging, color: Colors.pinkAccent, size: 28),
                            SizedBox(width: 12),
                            Text(
                              '${progreso.peso.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notas si existen
                      if (progreso.notas != null && progreso.notas!.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(maxHeight: 150),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Notas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Flexible(
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  thickness: 6,
                                  radius: Radius.circular(3),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      progreso.notas!,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Botón de cerrar
                Container(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotonesAccion() {
    // Verificar si hoy ya tiene un registro
    DateTime hoy = DateTime.now();
    ProgresoPeso? progresoHoy = _obtenerPesoParaFecha(hoy);
    bool tieneRegistroHoy = progresoHoy?.peso != 0;

    return Container(
      padding: EdgeInsets.all(16),
      child: tieneRegistroHoy ? _buildBotonesEditarBorrar() : _buildBotonAgregar(),
    );
  }

  Widget _buildBotonAgregar() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _mostrarDialogoAgregarPeso(DateTime.now()),
        icon: Icon(Icons.add, size: 20),
        label: Text('Agregar Peso de Hoy'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildBotonesEditarBorrar() {
    DateTime hoy = DateTime.now();
    ProgresoPeso? progresoHoy = _obtenerPesoParaFecha(hoy);
    
    return Column(
      children: [
        // Información del registro actual
        Container(
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.pinkAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Peso registrado: ${progresoHoy!.peso.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ],
          ),
        ),
        // Botones de editar y borrar
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarDialogoEditarPeso(hoy, progresoHoy!),
                icon: Icon(Icons.edit, size: 18),
                label: Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarConfirmacionBorrar(hoy),
                icon: Icon(Icons.delete, size: 18),
                label: Text('Borrar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
