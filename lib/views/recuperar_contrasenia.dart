import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class RecuperarContrasenia extends StatefulWidget {
  @override
  _RecuperarContraseniaState createState() => _RecuperarContraseniaState();
}

class _RecuperarContraseniaState extends State<RecuperarContrasenia>
    with TickerProviderStateMixin {
  TextEditingController _correoController = TextEditingController();
  UsuarioController _usuarioController = UsuarioController();
  bool _cargando = false;
  bool _mostrarCampos = false;
  bool _correoEnviado = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Iniciar animación después de un breve delay
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _mostrarCampos = true;
      });
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  void _enviarCorreoRecuperacion() async {
    String email = _correoController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: "Por favor ingresa tu correo electrónico",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.white,
        textColor: Colors.pinkAccent,
      );
      return;
    }

    // Validación básica de email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      Fluttertoast.showToast(
        msg: "Por favor ingresa un correo válido",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.white,
        textColor: Colors.pinkAccent,
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      bool resultado = await _usuarioController.enviarCorreoRecuperacion(email: email);

      if (resultado) {
        setState(() {
          _correoEnviado = true;
        });

        Fluttertoast.showToast(
          msg: "Correo de recuperación enviado exitosamente",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.pinkAccent,
        );
      } else {
        Fluttertoast.showToast(
          msg: "El correo no está registrado o hubo un error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error al enviar el correo de recuperación",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }

    setState(() {
      _cargando = false;
    });
  }

  void _volverAlLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.pink,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _volverAlLogin,
          ),
          title: Text(
            'Recuperar Contraseña',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Logo en la parte superior
            Positioned(
              top: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  'assets/memorii_logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),

            // Contenido principal
            if (_mostrarCampos)
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: !_correoEnviado ? _buildFormularioRecuperacion() : _buildMensajeExito(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioRecuperacion() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_reset,
            size: 50,
            color: Colors.pink,
          ),
          SizedBox(height: 20),
          Text(
            'Recuperar Contraseña',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 30),
          TextField(
            controller: _correoController,
            cursorColor: Colors.pink,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email, color: Colors.pink),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.pink, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.pinkAccent, width: 1),
              ),
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cargando ? null : _enviarCorreoRecuperacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
                elevation: 3,
              ),
              child: _cargando
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Enviando...'),
                ],
              )
                  : Text(
                'Enviar Correo de Recuperación',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          TextButton(
            onPressed: _volverAlLogin,
            child: Text(
              'Volver al inicio de sesión',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeExito() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_read,
            size: 60,
            color: Colors.pinkAccent,
          ),
          SizedBox(height: 20),
          Text(
            '¡Correo Enviado!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Te hemos enviado un correo con las instrucciones para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Revisa tu bandeja de entrada y también la carpeta de spam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _volverAlLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: 15),
                elevation: 3,
              ),
              child: Text(
                'Volver al Inicio de Sesión',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          TextButton(
            onPressed: () {
              setState(() {
                _correoEnviado = false;
                _correoController.clear();
              });
            },
            child: Text(
              'Enviar a otro correo',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}