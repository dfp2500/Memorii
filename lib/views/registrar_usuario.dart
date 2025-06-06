import 'package:flutter/material.dart';
import 'package:memorii/controllers/usuario_controller.dart';

class RegistrarUsuario extends StatefulWidget {
  @override
  _RegistrarUsuarioState createState() => _RegistrarUsuarioState();
}

class _RegistrarUsuarioState extends State<RegistrarUsuario> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contraseniaController = TextEditingController();
  final UsuarioController _usuarioController = UsuarioController();

  void _registrarUsuario() async {
    String nombre = _nombreController.text.trim();
    String email = _emailController.text.trim();
    String contrasenia = _contraseniaController.text.trim();

    if (nombre.isEmpty || email.isEmpty || contrasenia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Todos los campos son obligatorios")),
      );
      return;
    }

    try {
      await _usuarioController.agregarUsuario(
        nombre: nombre,
        email: email,
        contrasenia: contrasenia,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario registrado con éxito")),
      );
      _nombreController.clear();
      _emailController.clear();
      _contraseniaController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar usuario: \$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrar Usuario")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _contraseniaController,
              decoration: InputDecoration(labelText: "Contraseña"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrarUsuario,
              child: Text("Registrar"),
            ),
          ],
        ),
      ),
    );
  }
}