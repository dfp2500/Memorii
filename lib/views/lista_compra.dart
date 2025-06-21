import 'package:flutter/material.dart';
import 'package:memorii/controllers/lista_compra_controller.dart';
import 'package:memorii/models/lista_compra_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListaCompraPage extends StatefulWidget {
  final int idUsuario;

  const ListaCompraPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _ListaCompraPageState createState() => _ListaCompraPageState();
}

class _ListaCompraPageState extends State<ListaCompraPage> {
  final ListaCompraController _controller = ListaCompraController();
  List<ProductoListaCompra> _productos = [];
  bool _isLoading = true;
  final TextEditingController _nuevoProductoController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nuevoProductoController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar y resetear lista si es lunes
      await _controller.verificarYResetearLista(widget.idUsuario);
      
      // Inicializar lista por defecto si es necesario
      await _controller.inicializarListaPorDefecto(widget.idUsuario);
      
      // Cargar productos del usuario
      final productos = await _controller.obtenerProductosUsuario(widget.idUsuario);
      
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleProduct(ProductoListaCompra producto) async {
    try {
      // Actualizar en la base de datos
      await _controller.cambiarEstadoCompra(
        idProducto: producto.id,
        comprado: !producto.comprado,
      );
      
      // Actualizar solo el estado local sin recargar
      setState(() {
        final index = _productos.indexWhere((p) => p.id == producto.id);
        if (index != -1) {
          _productos[index] = producto.copyWith(comprado: !producto.comprado);
        }
      });
    } catch (e) {
      print('Error al cambiar estado del producto: $e');
      // Si hay error, recargar para mantener consistencia
      await _cargarDatos();
    }
  }

  Future<void> _eliminarProducto(ProductoListaCompra producto) async {
    try {
      // Eliminar de la base de datos
      await _controller.eliminarProducto(producto.id);
      
      // Actualizar solo el estado local sin recargar
      setState(() {
        _productos.removeWhere((p) => p.id == producto.id);
      });
    } catch (e) {
      print('Error al eliminar producto: $e');
      // Si hay error, recargar para mantener consistencia
      await _cargarDatos();
    }
  }

  void _mostrarDialogoAgregar() {
    _nuevoProductoController.clear();
    _cantidadController.clear();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_shopping_cart,
                  color: Colors.pinkAccent,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Agregar Producto',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _nuevoProductoController,
                    cursorColor: Colors.pinkAccent,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Nombre del producto',
                      labelStyle: TextStyle(color: Colors.pinkAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.pinkAccent.withOpacity(0.05),
                      prefixIcon: Icon(Icons.shopping_basket, color: Colors.pinkAccent),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _cantidadController,
                    cursorColor: Colors.pinkAccent,
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      labelStyle: TextStyle(color: Colors.pinkAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.pinkAccent.withOpacity(0.05),
                      prefixIcon: Icon(Icons.format_list_numbered, color: Colors.pinkAccent),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.pinkAccent,
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pinkAccent.withOpacity(0.8)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  if (_nuevoProductoController.text.isNotEmpty) {
                    try {
                      // Agregar a la base de datos y obtener el ID
                      final nuevoId = await _controller.agregarProducto(
                        idUsuario: widget.idUsuario,
                        nombre: _nuevoProductoController.text,
                        cantidad: _cantidadController.text.isNotEmpty 
                            ? _cantidadController.text 
                            : '1 unidad',
                      );
                      
                      if (nuevoId.isNotEmpty) {
                        // Crear el nuevo producto con el ID correcto
                        final nuevoProducto = ProductoListaCompra(
                          id: nuevoId,
                          idUsuario: widget.idUsuario,
                          nombre: _nuevoProductoController.text,
                          cantidad: _cantidadController.text.isNotEmpty 
                              ? _cantidadController.text 
                              : '1 unidad',
                          comprado: false,
                          fechaCreacion: Timestamp.now(),
                        );
                        
                        // Actualizar estado local inmediatamente
                        setState(() {
                          _productos.add(nuevoProducto);
                        });
                      }
                      
                      // Cerrar el diálogo
                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Error al agregar producto: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Agregar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(24, 0, 24, 16),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    final productosComprados = _productos.where((p) => p.comprado).length;
    final totalProductos = _productos.length;
    double percentage = totalProductos > 0 ? (productosComprados / totalProductos) : 0.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.pinkAccent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$productosComprados/$totalProductos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar productos: no comprados primero, comprados al final
    final productosOrdenados = List<ProductoListaCompra>.from(_productos);
    productosOrdenados.sort((a, b) {
      if (a.comprado == b.comprado) return 0;
      return a.comprado ? 1 : -1;
    });

    final infoSemana = _controller.obtenerInfoSemanaActual();
    final esLunes = infoSemana['esLunes'] as bool;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        title: Text(
          'Lista de la Compra',
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
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
              )
            : Column(
                children: [
                  // Mensaje informativo si es lunes
                  if (esLunes)
                    Container(
                      margin: EdgeInsets.all(16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Nueva semana! La lista se ha reseteado automáticamente.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Barra de progreso compacta
                  _buildProgressBar(),

                  // Lista de productos
                  Expanded(
                    child: productosOrdenados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No hay productos en tu lista',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Toca el botón + para agregar productos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: productosOrdenados.length,
                            itemBuilder: (context, index) {
                              final producto = productosOrdenados[index];
                              final isChecked = producto.comprado;
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: GestureDetector(
                                    onTap: () => _toggleProduct(producto),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isChecked ? Colors.pinkAccent : Colors.transparent,
                                        border: Border.all(
                                          color: Colors.pinkAccent,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: isChecked
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                  ),
                                  title: Text(
                                    producto.nombre,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: isChecked 
                                          ? TextDecoration.lineThrough 
                                          : TextDecoration.none,
                                      color: isChecked ? Colors.grey : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    producto.cantidad,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isChecked ? Colors.grey : Colors.grey[600],
                                      decoration: isChecked 
                                          ? TextDecoration.lineThrough 
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[300],
                                    ),
                                    onPressed: () => _eliminarProducto(producto),
                                  ),
                                  onTap: () => _toggleProduct(producto),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: Colors.pinkAccent,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}