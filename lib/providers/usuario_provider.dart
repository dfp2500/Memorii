// providers/usuario_provider.dart
import 'package:flutter/material.dart';
import 'package:memorii/controllers/usuario_controller.dart';
import 'package:memorii/models/usuario_model.dart';

class UsuarioProvider extends ChangeNotifier {
  final UsuarioController _usuarioController = UsuarioController();

  // Datos del usuario
  Usuario? _usuario;
  String? _fotoPerfilUrl;
  int _idPareja = -1;
  int _idParejaUsuario = -1;

  // Control de caché
  bool _datosInicializados = false;
  bool _cargandoDatos = false;
  DateTime? _ultimaActualizacion;

  // Getters
  Usuario? get usuario => _usuario;
  String? get fotoPerfilUrl => _fotoPerfilUrl;
  int get idPareja => _idPareja;
  int get idParejaUsuario => _idParejaUsuario;
  bool get datosInicializados => _datosInicializados;
  bool get cargandoDatos => _cargandoDatos;

  // Getters de datos específicos del usuario
  String get nombre => _usuario?.nombre ?? "Cargando...";
  String get correo => _usuario?.email ?? "Cargando...";
  int get idUsuario => _usuario?.idUsuario ?? -1;

  /// Inicializa los datos del usuario desde Firebase
  /// Solo carga si no están inicializados o si han pasado más de 5 minutos
  Future<void> inicializarDatosUsuario(int idUsuario) async {
    // Si ya están cargados y son recientes, no recargar
    if (_datosInicializados &&
        _ultimaActualizacion != null &&
        DateTime.now().difference(_ultimaActualizacion!).inMinutes < 5) {
      return;
    }

    if (_cargandoDatos) return; // Evitar cargas simultáneas

    _cargandoDatos = true;
    notifyListeners();

    try {
      // Cargar datos en paralelo para mayor eficiencia
      final futures = await Future.wait([
        _usuarioController.obtenerUsuario(idUsuario),
        _usuarioController.obtenerFotoPerfilUsuario(idUsuario),
        _usuarioController.get_idPareja(idUsuario: idUsuario),
      ]);

      _usuario = futures[0] as Usuario?;
      _fotoPerfilUrl = futures[1] as String?;
      _idPareja = futures[2] as int;

      // Si tiene pareja, obtener ID de la pareja
      if (_idPareja != -1) {
        _idParejaUsuario = await _usuarioController.getIdParejaUser(_idPareja, idUsuario);
      }

      _datosInicializados = true;
      _ultimaActualizacion = DateTime.now();

    } catch (e) {
      print('Error al cargar datos del usuario: $e');
      // En caso de error, usar datos por defecto
      _usuario ??= Usuario(
          nombre: "Error al cargar",
          email: "Error al cargar",
          contrasenia: "",
          idUsuario: idUsuario,
          fotoPerfil: "assets/imagen_perfil_default.png"
      );
    } finally {
      _cargandoDatos = false;
      notifyListeners();
    }
  }

  /// Actualiza el nombre del usuario
  Future<void> actualizarNombre(String nuevoNombre) async {
    if (_usuario == null) return;

    try {
      await _usuarioController.actualizarNombre(nuevoNombre, _usuario!.idUsuario);

      // Actualizar caché local
      _usuario = Usuario(
        nombre: nuevoNombre,
        email: _usuario!.email,
        contrasenia: _usuario!.contrasenia,
        idUsuario: _usuario!.idUsuario,
        fotoPerfil: _usuario!.fotoPerfil,
      );

      notifyListeners();
    } catch (e) {
      print('Error al actualizar nombre: $e');
      throw e;
    }
  }

  /// Actualiza el correo del usuario
  Future<void> actualizarCorreo(String nuevoCorreo) async {
    if (_usuario == null) return;

    try {
      await _usuarioController.actualizarCorreo(nuevoCorreo, _usuario!.idUsuario);

      // Actualizar caché local
      _usuario = Usuario(
        nombre: _usuario!.nombre,
        email: nuevoCorreo,
        contrasenia: _usuario!.contrasenia,
        idUsuario: _usuario!.idUsuario,
        fotoPerfil: _usuario!.fotoPerfil,
      );

      notifyListeners();
    } catch (e) {
      print('Error al actualizar correo: $e');
      throw e;
    }
  }

  /// Actualiza la foto de perfil
  Future<void> actualizarFotoPerfil(String nuevaUrl) async {
    _fotoPerfilUrl = nuevaUrl;

    // También actualizar en el objeto usuario si existe
    if (_usuario != null) {
      _usuario = Usuario(
        nombre: _usuario!.nombre,
        email: _usuario!.email,
        contrasenia: _usuario!.contrasenia,
        idUsuario: _usuario!.idUsuario,
        fotoPerfil: nuevaUrl,
      );
    }

    notifyListeners();
  }

  /// Elimina la pareja actual
  Future<void> eliminarPareja() async {
    if (_idPareja == -1) return;

    try {
      await _usuarioController.eliminarPareja(_idPareja);

      // Actualizar caché local
      _idPareja = -1;
      _idParejaUsuario = -1;

      notifyListeners();
    } catch (e) {
      print('Error al eliminar pareja: $e');
      throw e;
    }
  }

  /// Fuerza una recarga de datos desde Firebase
  Future<void> recargarDatos() async {
    if (_usuario == null) return;

    _datosInicializados = false;
    _ultimaActualizacion = null;
    await inicializarDatosUsuario(_usuario!.idUsuario);
  }

  /// Limpia todos los datos (útil al cerrar sesión)
  void limpiarDatos() {
    _usuario = null;
    _fotoPerfilUrl = null;
    _idPareja = -1;
    _idParejaUsuario = -1;
    _datosInicializados = false;
    _cargandoDatos = false;
    _ultimaActualizacion = null;
    notifyListeners();
  }
}