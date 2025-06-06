// views/perfil_optimizado.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memorii/providers/usuario_provider.dart';
import 'package:memorii/views/tiempo_pareja.dart';
import 'cambiar_foto_perfil.dart';
import 'pareja_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'iniciar_sesion_usuario.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class PerfilPage extends StatefulWidget {
  final int idUsuario;

  const PerfilPage({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _PerfilPageState createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final UsuarioController _usuarioController = UsuarioController();
  bool _controladoresInicializados = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos usando el Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsuarioProvider>().inicializarDatosUsuario(widget.idUsuario);
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _guardaCambios() async {
    // Quitar el foco de los campos de texto
    FocusScope.of(context).unfocus();

    final provider = context.read<UsuarioProvider>();
    String nuevoNombre = _nombreController.text;
    String nuevoCorreo = _correoController.text;

    try {
      // Actualizar usando el Provider (automáticamente actualiza la UI)
      await provider.actualizarNombre(nuevoNombre);
      await provider.actualizarCorreo(nuevoCorreo);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cambios guardados exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cambios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Limpiar datos del Provider
    context.read<UsuarioProvider>().limpiarDatos();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => IniciarSesionUsuario()),
          (Route<dynamic> route) => false,
    );
  }

  void _mostrarDialogoSeparacion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "¿Deseas separarte de tu pareja?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/rata_llorando.png'),
              SizedBox(height: 10),
              Text(
                "¿Estás seguro de que quieres continuar?",
                style: TextStyle(color: Colors.pinkAccent),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await context.read<UsuarioProvider>().eliminarPareja();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pareja eliminada exitosamente')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar pareja: $e')),
                  );
                }
              },
              child: Text(
                "Sí",
                style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "No",
                style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navegarTiempoPareja() {
    final provider = context.read<UsuarioProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TiempoPareja(idPareja: provider.idPareja),
      ),
    );
  }

  void _mostrarPopupCambiarContrasena() {
    final TextEditingController _contrasenaActualController = TextEditingController();
    final TextEditingController _nuevaContrasenaController = TextEditingController();
    final TextEditingController _confirmarContrasenaController = TextEditingController();
    bool _esPrimeraPantalla = true;
    String _mensajeError = '';

    bool _ocultarContrasenaActual = true;
    bool _ocultarNuevaContrasena = true;
    bool _ocultarConfirmarContrasena = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                "Cambiar contraseña",
                style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
              ),
              content: _esPrimeraPantalla
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _contrasenaActualController,
                    obscureText: _ocultarContrasenaActual,
                    decoration: InputDecoration(
                      labelText: "Contraseña actual",
                      labelStyle: TextStyle(color: Colors.pinkAccent),
                      errorText: _mensajeError.isNotEmpty ? _mensajeError : null,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarContrasenaActual ? Icons.visibility_off : Icons.visibility,
                          color: Colors.pinkAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _ocultarContrasenaActual = !_ocultarContrasenaActual;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ],
              )
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nuevaContrasenaController,
                    obscureText: _ocultarNuevaContrasena,
                    decoration: InputDecoration(
                      labelText: "Nueva contraseña",
                      labelStyle: TextStyle(color: Colors.pinkAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarNuevaContrasena ? Icons.visibility_off : Icons.visibility,
                          color: Colors.pinkAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _ocultarNuevaContrasena = !_ocultarNuevaContrasena;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                  TextField(
                    controller: _confirmarContrasenaController,
                    obscureText: _ocultarConfirmarContrasena,
                    decoration: InputDecoration(
                      labelText: "Confirmar nueva contraseña",
                      labelStyle: TextStyle(color: Colors.pinkAccent),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.pinkAccent),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarConfirmarContrasena ? Icons.visibility_off : Icons.visibility,
                          color: Colors.pinkAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _ocultarConfirmarContrasena = !_ocultarConfirmarContrasena;
                          });
                        },
                      ),
                    ),
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_esPrimeraPantalla) {
                      String antigua = await _usuarioController.obtenerContraseniaUsuario(widget.idUsuario);
                      bool esValida = _usuarioController.cifrarContrasenia(_contrasenaActualController.text) == antigua;

                      if (esValida) {
                        setState(() {
                          _esPrimeraPantalla = false;
                          _mensajeError = '';
                        });
                      } else {
                        setState(() {
                          _mensajeError = 'Contraseña incorrecta';
                        });
                      }
                    } else {
                      if (_nuevaContrasenaController.text == _confirmarContrasenaController.text) {
                        await _usuarioController.actualizarContrasenia(
                          _nuevaContrasenaController.text,
                          widget.idUsuario,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('¡Contraseña actualizada con éxito!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Las contraseñas no coinciden')),
                        );
                      }
                    }
                  },
                  child: Text(
                    "Continuar",
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset('assets/memorii_logo_texto.png', height: 40),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Consumer<UsuarioProvider>(
          builder: (context, provider, child) {
            // Inicializar controladores cuando los datos estén disponibles
            if (provider.datosInicializados && !_controladoresInicializados) {
              _nombreController.text = provider.nombre;
              _correoController.text = provider.correo;
              _controladoresInicializados = true;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar con loading state
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CambiarFotoPerfilPage(idUsuario: widget.idUsuario),
                          ),
                        ).then((_) {
                          // Recargar datos después de cambiar foto
                          provider.recargarDatos();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            backgroundImage: provider.fotoPerfilUrl != null
                                ? NetworkImage(provider.fotoPerfilUrl!)
                                : AssetImage('assets/imagen_perfil_default.png') as ImageProvider,
                            radius: 50,
                          ),
                          if (provider.cargandoDatos)
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                color: Colors.pinkAccent,
                                strokeWidth: 2,
                              ),
                            ),
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Icon(Icons.edit, color: Colors.pinkAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Campos de texto con loading state
                  TextField(
                    controller: _nombreController,
                    enabled: provider.datosInicializados,
                    decoration: InputDecoration(
                      labelText: "Nombre",
                      suffixIcon: provider.cargandoDatos
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : null,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  TextField(
                    controller: _correoController,
                    enabled: provider.datosInicializados,
                    decoration: InputDecoration(
                      labelText: "Correo",
                      suffixIcon: provider.cargandoDatos
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : null,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 20),

                  // Información de pareja
                  provider.idPareja != -1
                      ? Column(
                    children: [
                      Text(
                        "Tu pareja:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      ParejaCard(
                        idUsuario: provider.idParejaUsuario,
                        icono1: Icons.favorite,
                        icono2: Icons.heart_broken_rounded,
                        onPressed1: _navegarTiempoPareja,
                        onPressed2: _mostrarDialogoSeparacion,
                      ),
                    ],
                  )
                      : Text(
                    "No tienes pareja.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Botones de acción
                  ElevatedButton.icon(
                    onPressed: _mostrarPopupCambiarContrasena,
                    icon: Icon(Icons.lock, size: 20, color: Colors.white),
                    label: Text("Cambiar contraseña"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.picture_as_pdf, size: 20, color: Colors.white),
                    label: Text("Exportar a PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Botón guardar cambios
                  ElevatedButton(
                    onPressed: provider.datosInicializados ? _guardaCambios : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    ),
                    child: provider.cargandoDatos
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      "Guardar cambios",
                      style: TextStyle(fontSize: 19),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Botón cerrar sesión
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: cerrarSesion,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}