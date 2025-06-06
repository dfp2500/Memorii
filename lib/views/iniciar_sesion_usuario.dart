import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inicio.dart';
import 'recuperar_contrasenia.dart';

class IniciarSesionUsuario extends StatefulWidget {
  @override
  _IniciarSesionUsuarioState createState() => _IniciarSesionUsuarioState();
}

class _IniciarSesionUsuarioState extends State<IniciarSesionUsuario> {
  bool _esRegistro = false;
  bool _mostrarCampos = false;
  double _imagenPosicionY = 250;
  bool _mostrarImagen = true;
  String? usuarioEmail = null;

  UsuarioController _usuarioController = UsuarioController();

  TextEditingController _nombreController = TextEditingController();
  TextEditingController _correoController = TextEditingController();
  TextEditingController _contraseniaController = TextEditingController();
  bool _mostrarContrasenia = false;

  @override
  void initState() {
    super.initState();
    _verificarSesion();

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _imagenPosicionY = 30;
      });

      if (usuarioEmail != null) {
        Navigator.pushReplacementNamed(context, '/home'); // Redirigir a la pantalla principal
      }

      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _mostrarCampos = true;
        });
      });
    });
  }

  void _verificarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    usuarioEmail = prefs.getString('usuario_email');
  }

  void _iniciarSesion() async {
    String email = _correoController.text;
    String contrasenia = _contraseniaController.text;

    bool resultado = await _usuarioController.iniciarSesion(email: email, contrasenia: contrasenia);

    if (resultado) {
      int idUsuario = await _usuarioController.obtenerIdUsuario(email);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('usuario_email', email); // Guardar usuario en almacenamiento local
      await prefs.setInt('usuario_id', idUsuario); // Guardar ID de usuario

      Fluttertoast.showToast(
        msg: "Inicio de sesión exitoso",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InicioPage(idUsuario: idUsuario),
        ),
      );

    } else {
      Fluttertoast.showToast(
        msg: "Correo o contraseña incorrectos",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _registrarUsuario() async {
    String nombre = _nombreController.text;
    String email = _correoController.text;
    String contrasenia = _contraseniaController.text;

    bool resultado = await _usuarioController.agregarUsuario(
      nombre: nombre,
      email: email,
      contrasenia: contrasenia,
    );

    Fluttertoast.showToast(
      msg: resultado ? "Registro exitoso" : "Error al registrar el usuario",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _irARecuperarContrasenia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecuperarContrasenia(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ocultar teclado al tocar fuera
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Evita que la pantalla se desplace con el teclado
        backgroundColor: Colors.pink,
        body: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              top: _imagenPosicionY,
              left: -10,
              right: 0,
              child: AnimatedOpacity(
                duration: Duration(seconds: 1),
                opacity: _mostrarImagen ? 1.0 : 0.0,
                child: Center(
                  child: Image.asset(
                    'assets/memorii_logo.png',
                    width: 350,
                    height: 350,
                  ),
                ),
              ),
            ),
            if (_mostrarCampos)
              Positioned(
                bottom: _esRegistro ? 100 : 120,
                left: 20,
                right: 20,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_esRegistro) ...[
                        TextField(
                          controller: _nombreController,
                          cursorColor: Colors.pink,
                          decoration: InputDecoration(
                            hintText: 'Nombre',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), // Bordes redondeados
                              borderSide: BorderSide.none, // Sin borde por defecto
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.pink, width: 2), // Borde rosa al seleccionar
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.pinkAccent, width: 1.5), // Borde rosa normal
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _correoController,
                        cursorColor: Colors.pink,
                        decoration: InputDecoration(
                          hintText: 'Correo electrónico',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // Bordes redondeados
                            borderSide: BorderSide.none, // Sin borde por defecto
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.pink, width: 2), // Borde rosa al seleccionar
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.pinkAccent, width: 1.5), // Borde rosa normal
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _contraseniaController,
                        cursorColor: Colors.pink,
                        obscureText: !_mostrarContrasenia,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), // Bordes redondeados
                            borderSide: BorderSide.none, // Sin borde por defecto
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.pink, width: 2), // Borde rosa al seleccionar
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.pinkAccent, width: 1.5), // Borde rosa normal
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _mostrarContrasenia ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _mostrarContrasenia = !_mostrarContrasenia;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _esRegistro ? _registrarUsuario : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent, // Color de fondo del botón
                          foregroundColor: Colors.white, // Color del texto
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Esquinas redondeadas
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40), // Tamaño del botón
                        ),
                        child: Text(
                          _esRegistro ? 'Registrarse' : 'Iniciar sesión',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _esRegistro = !_esRegistro;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Color de fondo del botón
                          foregroundColor: Colors.pinkAccent, // Color del texto
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Esquinas redondeadas
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40), // Tamaño del botón
                        ),
                        child: Text(
                          _esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, ),
                        ),
                      ),
                      // Botón de recuperar contraseña - solo aparece en modo login
                      if (!_esRegistro) ...[
                        SizedBox(height: 5),
                        TextButton(
                          onPressed: _irARecuperarContrasenia,
                          child: Text(
                            '¿Has olvidado tu contraseña?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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