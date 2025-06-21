import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:memorii/controllers/progreso_peso_controller.dart';
import 'package:memorii/models/progreso_peso_model.dart';

class GraficoProgresoPage extends StatefulWidget {
  final int idUsuario;

  const GraficoProgresoPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _GraficoProgresoPageState createState() => _GraficoProgresoPageState();
}

class _GraficoProgresoPageState extends State<GraficoProgresoPage> {
  final ProgresoPesoController _controller = ProgresoPesoController();
  List<ProgresoPeso> _progresos = [];
  bool _isLoading = true;
  String _periodoSeleccionado = '30'; // días por defecto

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<ProgresoPeso> progresos = await _controller.obtenerProgresoPesoUsuario(widget.idUsuario);
      
      // Ordenar por fecha
      progresos.sort((a, b) => a.fecha.compareTo(b.fecha));
      
      setState(() {
        _progresos = progresos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ProgresoPeso> _obtenerProgresosFiltrados() {
    if (_progresos.isEmpty) return [];
    
    if (_periodoSeleccionado == 'all') {
      return _progresos;
    }
    
    int dias = int.parse(_periodoSeleccionado);
    DateTime fechaLimite = DateTime.now().subtract(Duration(days: dias));
    
    return _progresos.where((progreso) => progreso.fecha.isAfter(fechaLimite)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Gráfico de Progreso',
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
                    Flexible(
                      child: _buildSelectorPeriodo(),
                    ),
                    Expanded(
                      child: _progresos.isEmpty
                          ? _buildMensajeSinDatos()
                          : _buildGrafico(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSelectorPeriodo() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📈 Período de Análisis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPeriodoButton('7', '7 días'),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: _buildPeriodoButton('30', '30 días'),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: _buildPeriodoButton('90', '90 días'),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: _buildPeriodoButton('all', 'Todo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodoButton(String valor, String texto) {
    bool isSelected = _periodoSeleccionado == valor;
    return GestureDetector(
      onTap: () {
        setState(() {
          _periodoSeleccionado = valor;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildMensajeSinDatos() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 60,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12),
            Text(
              'No hay datos de progreso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primer registro de peso para ver el gráfico',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrafico() {
    List<ProgresoPeso> progresosFiltrados = _obtenerProgresosFiltrados();
    
    if (progresosFiltrados.isEmpty) {
      return _buildMensajeSinDatos();
    }

    return Container(
      margin: EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📊 Evolución del Peso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              SizedBox(height: 12),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 25,
                          interval: progresosFiltrados.length > 7 ? (progresosFiltrados.length / 7).ceil().toDouble() : 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= 0 && value.toInt() < progresosFiltrados.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  DateFormat('dd/MM').format(progresosFiltrados[value.toInt()].fecha),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(''),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calcularIntervaloPeso(progresosFiltrados),
                          reservedSize: 35,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${value.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    minX: 0,
                    maxX: (progresosFiltrados.length - 1).toDouble(),
                    minY: _calcularMinY(progresosFiltrados),
                    maxY: _calcularMaxY(progresosFiltrados),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _crearSpots(progresosFiltrados),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent,
                            Colors.pinkAccent.withOpacity(0.8),
                          ],
                        ),
                        barWidth: 2.5,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.pinkAccent,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              Colors.pinkAccent.withOpacity(0.3),
                              Colors.pinkAccent.withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              _buildEstadisticasGrafico(progresosFiltrados),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _crearSpots(List<ProgresoPeso> progresos) {
    return progresos.asMap().entries.map((entry) {
      int index = entry.key;
      ProgresoPeso progreso = entry.value;
      return FlSpot(index.toDouble(), progreso.peso);
    }).toList();
  }

  double _calcularMinY(List<ProgresoPeso> progresos) {
    if (progresos.isEmpty) return 0;
    double minPeso = progresos.map((p) => p.peso).reduce((a, b) => a < b ? a : b);
    return minPeso - 2; // Margen inferior
  }

  double _calcularMaxY(List<ProgresoPeso> progresos) {
    if (progresos.isEmpty) return 100;
    double maxPeso = progresos.map((p) => p.peso).reduce((a, b) => a > b ? a : b);
    return maxPeso + 2; // Margen superior
  }

  double _calcularIntervaloPeso(List<ProgresoPeso> progresos) {
    if (progresos.isEmpty) return 10;
    double minPeso = _calcularMinY(progresos);
    double maxPeso = _calcularMaxY(progresos);
    double rango = maxPeso - minPeso;
    return rango / 5; // 5 líneas horizontales
  }

  Widget _buildEstadisticasGrafico(List<ProgresoPeso> progresos) {
    if (progresos.length < 2) return SizedBox.shrink();

    double pesoInicial = progresos.first.peso;
    double pesoFinal = progresos.last.peso;
    double diferencia = pesoInicial - pesoFinal;
    String tendencia = diferencia > 0 ? '📉 Perdiendo' : diferencia < 0 ? '📈 Ganando' : '➡️ Manteniendo';

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peso inicial: ${pesoInicial.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Peso actual: ${pesoFinal.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tendencia,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: diferencia > 0 ? Colors.green : diferencia < 0 ? Colors.red : Colors.orange,
                  ),
                  textAlign: TextAlign.end,
                ),
                Text(
                  '${diferencia.abs().toStringAsFixed(1)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 