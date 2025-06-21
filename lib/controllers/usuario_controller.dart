import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:memorii/models/usuario_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:memorii/models/pareja_model.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UsuarioController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<bool> subirFotoPerfil(File imagen, Usuario usuario) async {
    try {
      // Comprimir la imagen antes de subirla
      File? imagenComprimida =
          await _comprimirImagen(imagen, usuario.idUsuario);

      if (imagenComprimida == null) {
        print("Error al comprimir la imagen.");
        return false;
      }

      // Ruta de almacenamiento en Firebase Storage
      String rutaStorage = 'fotos_perfil/${usuario.idUsuario}.png';
      Reference ref = _storage.ref().child(rutaStorage);

      // Subir imagen comprimida a Firebase Storage
      await ref.putFile(imagenComprimida);

      // Obtener URL de descarga
      String urlImagen = await ref.getDownloadURL();

      // Actualizar el objeto Usuario con la nueva URL de la imagen
      Usuario usuarioActualizado = Usuario(
        nombre: usuario.nombre,
        email: usuario.email,
        contrasenia: usuario.contrasenia,
        idUsuario: usuario.idUsuario,
        fotoPerfil: urlImagen,
      );

      // Guardar URL en Firestore
      await _firestore
          .collection('usuarios')
          .where('id_usuario', isEqualTo: usuario.idUsuario)
          .get()
          .then((querySnapshot) async {
        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'foto_perfil': urlImagen,
          });
        }
      });

      print("Foto de perfil actualizada con éxito.");
      return true;
    } catch (e) {
      print("Error al subir la foto de perfil: $e");
      return false;
    }
  }

  Future<File?> _comprimirImagen(File imagen, int idUsuario) async {
    try {
      // Obtener directorio temporal
      final dir = await getTemporaryDirectory();
      String rutaTemporal = '${dir.path}/$idUsuario-comprimido.png';

      // Comprimir imagen
      var resultado = await FlutterImageCompress.compressAndGetFile(
        imagen.absolute.path,
        rutaTemporal,
        quality: 1,
        format: CompressFormat.png,
      );

      return resultado != null ? File(resultado.path) : null;
    } catch (e) {
      print("Error al comprimir la imagen: $e");
      return null;
    }
  }

  String cifrarContrasenia(String contrasenia) {
    var bytes = utf8.encode(contrasenia);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> agregarUsuario({
    required String nombre,
    required String email,
    required String contrasenia,
  }) async {
    try {
      // Obtener el primer documento de la colección 'metadata' (asumiendo que solo hay uno)
      QuerySnapshot metadataQuery =
          await _firestore.collection('metadata').limit(1).get();

      if (metadataQuery.docs.isNotEmpty) {
        // Tomamos el primer documento de la consulta
        DocumentSnapshot metadataDoc = metadataQuery.docs.first;

        // Obtener el valor de 'ultimo_id' y asignarlo a idUsuario
        int ultimoId = metadataDoc['ultimo_id'];

        // Incrementar el 'ultimo_id' para el nuevo usuario
        int nuevoId = ultimoId + 1;

        // Cifrar la contraseña
        String contraseniaCifrada = cifrarContrasenia(contrasenia);

        // Crear el objeto usuario con el nuevo idUsuario
        Usuario nuevoUsuario = Usuario(
            nombre: nombre,
            email: email,
            contrasenia: contraseniaCifrada,
            idUsuario: nuevoId,
            fotoPerfil: "assets/imagen_perfil_default.png");

        // Agregar el nuevo usuario a la colección 'usuarios'
        await _firestore.collection('usuarios').add(nuevoUsuario.toMap());

        // Actualizar el campo 'ultimo_id' en el documento de metadata
        await metadataDoc.reference.update({
          'ultimo_id': nuevoId,
        });

        print('Usuario agregado con éxito');
        return true;
      } else {
        print('No se encontró el documento en la colección "metadata"');
        return false;
      }
    } catch (e) {
      print('Error al agregar usuario: $e');
      return false;
    }
  }

  Future<bool> iniciarSesion(
      {required String email, required String contrasenia}) async {
    try {
      // Buscar el usuario en la colección 'usuarios' con el email proporcionado
      QuerySnapshot userQuery = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        // Si se encuentra un usuario con ese email, tomar el primer documento
        DocumentSnapshot userDoc = userQuery.docs.first;

        // Obtener la contraseña cifrada del documento
        String contraseniaGuardada = userDoc['contrasenia'];

        // Cifrar la contraseña ingresada por el usuario
        String contraseniaCifrada = cifrarContrasenia(contrasenia);

        // Comparar la contraseña cifrada ingresada con la almacenada
        if (contraseniaCifrada == contraseniaGuardada) {
          print('Inicio de sesión exitoso');
          return true; // Inicio de sesión exitoso
        } else {
          print('Contraseña incorrecta');
          return false; // Contraseña incorrecta
        }
      } else {
        print('Usuario no encontrado');
        return false; // Usuario no encontrado
      }
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return false; // Error en la consulta
    }
  }

  Future<int> get_idPareja({required int idUsuario}) async {
    QuerySnapshot user1 = await _firestore
        .collection('parejas')
        .where('id_user1', isEqualTo: idUsuario)
        .get();

    if (user1.docs.isNotEmpty) {
      DocumentSnapshot userDoc1 = user1.docs.first;

      print("tiene pareja");
      print(userDoc1['id_pareja']);
      return userDoc1['id_pareja'];
    } else {
      QuerySnapshot user2 = await _firestore
          .collection('parejas')
          .where('id_user2', isEqualTo: idUsuario)
          .get();

      if (user2.docs.isNotEmpty) {
        DocumentSnapshot userDoc2 = user2.docs.first;

        print("tiene pareja");
        print(userDoc2['id_pareja']);
        return userDoc2['id_pareja'];
      } else {
        print("No tiene pareja");
        return -1;
      }
    }
  }

  Future<String?> obtenerFechaInicioPareja(int idPareja) async {
    try {
      // Buscar la pareja en la colección 'parejas' con el idPareja proporcionado
      QuerySnapshot parejaQuery = await _firestore
          .collection('parejas')
          .where('id_pareja', isEqualTo: idPareja)
          .limit(1)
          .get();

      if (parejaQuery.docs.isNotEmpty) {
        // Obtener el documento de la pareja
        DocumentSnapshot parejaDoc = parejaQuery.docs.first;

        // Obtener el campo 'fecha_inicio' como Timestamp
        Timestamp fechaTimestamp = parejaDoc['fechaInicio'];

        // Convertir el Timestamp a DateTime
        DateTime fechaInicio = fechaTimestamp.toDate();

        // Formatear la fecha a un formato legible (opcional)
        String fechaFormateada =
            "${fechaInicio.day}-${fechaInicio.month}-${fechaInicio.year}";

        return fechaFormateada;
      } else {
        print('No se encontró pareja con ese idPareja');
        return null;
      }
    } catch (e) {
      print('Error al obtener fecha de inicio de pareja: $e');
      return null;
    }
  }

  Future<String?> obtenerTiempoTranscurridoPareja(int idPareja) async {
    try {
      // Buscar la pareja en la colección 'parejas' con el idPareja proporcionado
      QuerySnapshot parejaQuery = await _firestore
          .collection('parejas')
          .where('id_pareja', isEqualTo: idPareja)
          .limit(1)
          .get();

      if (parejaQuery.docs.isNotEmpty) {
        // Obtener el documento de la pareja
        DocumentSnapshot parejaDoc = parejaQuery.docs.first;

        // Obtener el campo 'fecha_inicio' como Timestamp
        Timestamp fechaTimestamp = parejaDoc['fechaInicio'];

        // Convertir el Timestamp a DateTime
        DateTime fechaInicio = fechaTimestamp.toDate();
        DateTime fechaActual = DateTime.now();

        // Calcular la diferencia
        Duration diferencia = fechaActual.difference(fechaInicio);

        // Calcular años, meses, días, horas, minutos y segundos
        int anios = fechaActual.year - fechaInicio.year;
        int meses = fechaActual.month - fechaInicio.month;
        int dias = fechaActual.day - fechaInicio.day;
        int horas = fechaActual.hour - fechaInicio.hour;
        int minutos = fechaActual.minute - fechaInicio.minute;
        int segundos = fechaActual.second - fechaInicio.second;

        // Ajustes para evitar valores negativos
        if (segundos < 0) {
          segundos += 60;
          minutos--;
        }
        if (minutos < 0) {
          minutos += 60;
          horas--;
        }
        if (horas < 0) {
          horas += 24;
          dias--;
        }
        if (dias < 0) {
          // Calcular los días del mes anterior
          DateTime mesAnterior = DateTime(
              fechaActual.year, fechaActual.month - 1, fechaInicio.day);
          dias += DateTime(fechaActual.year, fechaActual.month, 0).day;
          meses--;
        }
        if (meses < 0) {
          meses += 12;
          anios--;
        }

        // Formatear el resultado
        String tiempoTranscurrido =
            "$anios años, $meses meses, $dias días, $horas horas, $minutos minutos, $segundos segundos";

        return tiempoTranscurrido;
      } else {
        print('No se encontró pareja con ese idPareja');
        return null;
      }
    } catch (e) {
      print('Error al obtener tiempo transcurrido de pareja: $e');
      return null;
    }
  }

  Future<bool> agregarPareja({
    required int idUser1,
    required int idUser2,
  }) async {
    try {
      // Obtener el primer documento de la colección 'metadata' (asumiendo que solo hay uno)
      QuerySnapshot metadataQuery =
          await _firestore.collection('metadata').limit(1).get();

      if (metadataQuery.docs.isNotEmpty) {
        // Tomamos el primer documento de la consulta
        DocumentSnapshot metadataDoc = metadataQuery.docs.first;

        // Obtener el valor de 'ultimo_id_pareja' y asignarlo a idPareja
        int ultimoId = metadataDoc['ultimo_id_pareja'];

        // Incrementar el 'ultimo_id' para la nueva pareja
        int nuevoId = ultimoId + 1;

        // Obtener la fecha actual como Timestamp de Firebase
        Timestamp fechaActual = Timestamp.now();

        // Crear el objeto pareja con el nuevo idPareja y fechaInicio
        Pareja nuevaPareja = Pareja(
          idPareja: nuevoId,
          idUser1: idUser1,
          idUser2: idUser2,
          fechaInicio: fechaActual,
        );

        // Agregar la nueva pareja a la colección 'parejas'
        await _firestore.collection('parejas').add(nuevaPareja.toMap());

        // Actualizar el campo 'ultimo_id_pareja' en el documento de metadata
        await metadataDoc.reference.update({
          'ultimo_id_pareja': nuevoId,
        });

        print('Pareja agregada con éxito');
        return true;
      } else {
        print('No se encontró el documento en la colección "metadata"');
        return false;
      }
    } catch (e) {
      print('Error al agregar pareja: $e');
      return false;
    }
  }

  Future<void> eliminarPareja(int idPareja) async {
    try {
      // Busca el documento en la colección 'parejas' que tenga el campo id_pareja igual al valor dado
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parejas')
          .where('id_pareja', isEqualTo: idPareja)
          .get();

      // Si se encuentra el documento, se elimina
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          await FirebaseFirestore.instance
              .collection('parejas')
              .doc(doc.id)
              .delete();
        }
        print("Pareja eliminada correctamente.");
      } else {
        print("No se encontró pareja con ese id_pareja.");
      }
    } catch (e) {
      print("Error al eliminar la pareja: $e");
    }
  }

  Future<int> obtenerIdUsuario(String email) async {
    var query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['id_usuario'];
    } else {
      return -1;
    }
  }

  Future<String> obtenerCorreoUsuario(int idUsuario) async {
    var query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['email'];
    } else {
      return "";
    }
  }

  Future<String> obtenerNombreUsuario(int idUsuario) async {
    var query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['nombre'];
    } else {
      return "";
    }
  }

  Future<String> obtenerContraseniaUsuario(int idUsuario) async {
    var query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['contrasenia'];
    } else {
      return "";
    }
  }

  Future<String?> obtenerFotoPerfilUsuario(int idUsuario) async {
    var query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      String ruta = query.docs.first.data()['foto_perfil'];

      if (ruta == "") {
        return null;
      } else {
        return ruta;
      }
    } else {
      return null;
    }
  }

  Future<Usuario?> obtenerUsuario(int idUsuario) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return Usuario.fromMap(doc.data());
    }
    return null;
  }

  Future<int> getIdParejaUser(int idPareja, int idUsuario) async {
    QuerySnapshot pareja = await _firestore
        .collection('parejas')
        .where('id_pareja', isEqualTo: idPareja)
        .get();

    if (pareja.docs.isNotEmpty) {
      var data = pareja.docs.first.data() as Map<String, dynamic>;
      if (data['id_user1'] == idUsuario) {
        return data['id_user2'];
      } else if (data['id_user2'] == idUsuario) {
        return data['id_user1'];
      } else {
        throw Exception("ID de usuario incorrecto");
      }
    } else {
      throw Exception("Pareja no encontrada");
    }
  }

  Future<int> getIdUser1Pareja(int idPareja) async {
    QuerySnapshot pareja = await _firestore
        .collection('parejas')
        .where('id_pareja', isEqualTo: idPareja)
        .get();

    if (pareja.docs.isNotEmpty) {
      var data = pareja.docs.first.data() as Map<String, dynamic>;
      return data['id_user1'];
    } else {
      throw Exception("Pareja no encontrada");
    }
  }

  Future<int> getIdUser2Pareja(int idPareja) async {
    QuerySnapshot pareja = await _firestore
        .collection('parejas')
        .where('id_pareja', isEqualTo: idPareja)
        .get();

    if (pareja.docs.isNotEmpty) {
      var data = pareja.docs.first.data() as Map<String, dynamic>;
      return data['id_user2'];
    } else {
      throw Exception("Pareja no encontrada");
    }
  }

  Future<void> actualizarNombre(String nombre, int idUsuario) async {
    await _firestore
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'nombre': nombre,
        });
        print("cambiado");
      }
    });
  }

  Future<void> actualizarCorreo(String correo, int idUsuario) async {
    await _firestore
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'email': correo,
        });
      }
    });
  }

  Future<void> actualizarContrasenia(String contrasenia, int idUsuario) async {
    String contraseniaCifrada = cifrarContrasenia(contrasenia);

    await _firestore
        .collection('usuarios')
        .where('id_usuario', isEqualTo: idUsuario)
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'contrasenia': contraseniaCifrada,
        });
      }
    });
  }

  // Función para cambiar contraseña existente
  Future<bool> cambiarContrasenia({
    required int idUsuario,
    required String contraseniaActual,
    required String nuevaContrasenia,
  }) async {
    try {
      // Obtener la contraseña actual del usuario
      String contraseniaGuardada = await obtenerContraseniaUsuario(idUsuario);

      if (contraseniaGuardada.isEmpty) {
        print('Usuario no encontrado');
        return false;
      }

      // Cifrar la contraseña actual ingresada
      String contraseniaActualCifrada = cifrarContrasenia(contraseniaActual);

      // Verificar que la contraseña actual sea correcta
      if (contraseniaActualCifrada != contraseniaGuardada) {
        print('La contraseña actual es incorrecta');
        return false;
      }

      // Si la contraseña actual es correcta, actualizar con la nueva
      await actualizarContrasenia(nuevaContrasenia, idUsuario);

      print('Contraseña cambiada exitosamente');
      return true;
    } catch (e) {
      print('Error al cambiar la contraseña: $e');
      return false;
    }
  }

// Función para generar token de recuperación
  String _generarTokenRecuperacion() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(Iterable.generate(
        32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

// Solo mostrando la función enviarCorreoRecuperacion actualizada
  Future<bool> enviarCorreoRecuperacion({required String email}) async {
    try {
      // Verificar que el email existe en la base de datos
      int idUsuario = await obtenerIdUsuario(email);
      if (idUsuario == -1) {
        print('El correo electrónico no está registrado');
        return false;
      }

      String nombreUsuario = await obtenerNombreUsuario(idUsuario);

      // Generar token de recuperación
      String token = _generarTokenRecuperacion();

      // Guardar el token en Firestore con timestamp de expiración (24 horas)
      await _firestore.collection('tokens_recuperacion').add({
        'email': email,
        'token': token,
        'fecha_creacion': Timestamp.now(),
        'usado': false,
      });

      // Configurar el servidor SMTP
      String username = 'noreply.memorii@gmail.com';
      String? password = dotenv.env['EMAIL_PASSWORD'];

      final smtpServer = gmail(username, password!);

      // Crear el mensaje con deep link
      final message = Message()
        ..from = Address(username, 'Memorii App')
        ..recipients.add(email)
        ..subject = 'Recuperación de Contraseña - Memorii'
        ..html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Recuperación de Contraseña - Memorii</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        
        <!-- Header con logo -->
        <div style="text-align: center; margin-bottom: 30px; padding: 20px; background: linear-gradient(135deg, #e91e63, #f48fb1); border-radius: 10px;">
            <img src="https://firebasestorage.googleapis.com/v0/b/memorii-fe062.firebasestorage.app/o/memorii_logo.png?alt=media&token=2d5c3241-9c8d-4eb1-b730-da0c0e670602" alt="Logo Memorii" style="width: 250px; height: auto; margin-bottom: 10px;" />
            <p style="color: rgba(255,255,255,0.9); margin: 5px 0 0 0; font-size: 16px;">Recuperación de Contraseña</p>
        </div>

        <!-- Contenido principal -->
        <div style="background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
            <h2 style="color: #e91e63; margin-top: 0;">¡Hola $nombreUsuario!</h2>
            <p style="font-size: 16px; margin-bottom: 20px;">Has solicitado recuperar tu contraseña en Memorii.</p>
            
            <!-- Botón principal -->
            <div style="text-align: center; margin: 30px 0;">
              <a href="https://memorii-fe062.web.app/open-app.html?token=$token&email=${Uri.encodeComponent(email)}"
                 style="background: linear-gradient(135deg, #e91e63, #f48fb1);
                        color: white;
                        padding: 16px 32px;
                        text-decoration: none;
                        border-radius: 25px;
                        display: inline-block;
                        font-weight: bold;
                        font-size: 16px;
                        box-shadow: 0 3px 15px rgba(233, 30, 99, 0.3);
                        transition: all 0.3s ease;">
                📱 Abrir en Memorii App
              </a>
            </div>
            
            <!-- JavaScript para fallback -->
            <script>
              document.addEventListener('DOMContentLoaded', function () {
                const link = document.querySelector('a[href^="memorii://"]');
                if (link) {
                  link.addEventListener('click', function (e) {
                    e.preventDefault();
                    const url = new URL(this.href);
                    const token = url.searchParams.get('token');
                    const email = url.searchParams.get('email');
            
                    // Intentar abrir la app
                    window.location.href = this.href;
            
                    // Fallback a la versión web
                    setTimeout(function () {
                      const fallbackUrl = `https://memorii-fe062.web.app/open-app.html?token=${Uri.encodeComponent(token)}&email=${Uri.encodeComponent(email)}`;
                      window.location.href = fallbackUrl;
                    }, 2000);
                  });
                }
              });
            </script>

            <!-- JavaScript para mejorar la funcionalidad del botón -->
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    const appLink = document.querySelector('a[href^="memorii://"]');
                    if (appLink) {
                        appLink.addEventListener('click', function(e) {
                            // Intentar abrir la app directamente
                            window.location.href = this.href;
                            
                            // Fallback: después de un momento, ofrecer alternativas
                            setTimeout(function() {
                                if (confirm('¿No se abrió la app automáticamente? \\n\\nPresiona OK para ver instrucciones alternativas.')) {
                                    alert('Instrucciones:\\n\\n1. Copia este enlace: memorii://reset-password?token=$token&email=${Uri.encodeComponent(email)}\\n\\n2. Pégalo en tu navegador móvil\\n\\n3. O usa el enlace web de respaldo más abajo');
                                }
                            }, 2000);
                        });
                    }
                });
            </script>

            <!-- Instrucciones alternativas -->
            <div style="background: #fce4ec; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #e91e63;">
                <h3 style="color: #e91e63; margin-top: 0;">💡 Si el botón no funciona:</h3>
                
                <p><strong>Copia y pega manualmente:</strong></p>
                <div style="background: white; padding: 15px; margin: 10px 0; border-radius: 8px; border: 2px dashed #e91e63; word-break: break-all; font-family: monospace; font-size: 14px;">
                    <strong>memorii://reset-password?token=$token&email=${Uri.encodeComponent(email)}</strong>
                </div>
                
            </div>

            <!-- Información de seguridad -->
            <div style="background: #fff3e0; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 4px solid #ff9800;">
                <h3 style="color: #ff9800; margin-top: 0;">⚠️ Información Importante:</h3>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>Este enlace <strong>expirará en 24 horas</strong></li>
                    <li>Solo funcionará si tienes la app Memorii instalada</li>
                    <li>El enlace solo se puede usar <strong>una vez</strong></li>
                </ul>
            </div>

            <!-- Footer -->
            <div style="margin-top: 30px; padding-top: 20px; border-top: 2px solid #fce4ec; text-align: center;">
                <p style="color: #666; font-size: 14px;">
                    Si no solicitaste este cambio, puedes ignorar este correo de forma segura.
                </p>
                <br>
                <p style="color: #e91e63; font-weight: bold; margin: 0;">
                    💕 Con amor, el equipo de Memorii
                </p>
            </div>
        </div>

        <!-- Pie de página -->
        <div style="text-align: center; margin-top: 20px; color: #999; font-size: 12px;">
            <p>© 2025 Memorii App. Todos los derechos reservados.</p>
            <p>Este es un correo automático, por favor no respondas a esta dirección.</p>
        </div>

    </body>
    </html>
    ''';

      // Enviar el correo
      await send(message, smtpServer);

      print('Correo de recuperación enviado exitosamente');
      return true;
    } catch (e) {
      print('Error al enviar correo de recuperación: $e');
      return false;
    }
  }

// Función para validar token de recuperación
  Future<bool> validarTokenRecuperacion({
    required String email,
    required String token,
  }) async {
    try {
      // Buscar el token en la base de datos
      QuerySnapshot tokenQuery = await _firestore
          .collection('tokens_recuperacion')
          .where('email', isEqualTo: email)
          .where('token', isEqualTo: token)
          .where('usado', isEqualTo: false)
          .limit(1)
          .get();

      if (tokenQuery.docs.isEmpty) {
        print('Token inválido o ya usado');
        return false;
      }

      DocumentSnapshot tokenDoc = tokenQuery.docs.first;
      Timestamp fechaCreacion = tokenDoc['fecha_creacion'];
      DateTime ahora = DateTime.now();
      DateTime fechaToken = fechaCreacion.toDate();

      // Verificar que el token no haya expirado (24 horas)
      if (ahora.difference(fechaToken).inHours > 24) {
        print('Token expirado');
        return false;
      }

      return true;
    } catch (e) {
      print('Error al validar token: $e');
      return false;
    }
  }

// Función para restablecer contraseña con token
  Future<bool> restablecerContraseniaConToken({
    required String email,
    required String token,
    required String nuevaContrasenia,
  }) async {
    try {
      // Validar el token primero
      bool tokenValido =
          await validarTokenRecuperacion(email: email, token: token);

      if (!tokenValido) {
        return false;
      }

      // Obtener ID del usuario
      int idUsuario = await obtenerIdUsuario(email);
      if (idUsuario == -1) {
        print('Usuario no encontrado');
        return false;
      }

      // Actualizar la contraseña
      await actualizarContrasenia(nuevaContrasenia, idUsuario);

      // Marcar el token como usado
      QuerySnapshot tokenQuery = await _firestore
          .collection('tokens_recuperacion')
          .where('email', isEqualTo: email)
          .where('token', isEqualTo: token)
          .where('usado', isEqualTo: false)
          .limit(1)
          .get();

      if (tokenQuery.docs.isNotEmpty) {
        await tokenQuery.docs.first.reference.update({'usado': true});
      }

      print('Contraseña restablecida exitosamente');
      return true;
    } catch (e) {
      print('Error al restablecer contraseña: $e');
      return false;
    }
  }

// Función para limpiar tokens expirados (opcional, para mantenimiento)
  Future<void> limpiarTokensExpirados() async {
    try {
      DateTime hace24Horas = DateTime.now().subtract(Duration(hours: 24));
      Timestamp timestamp24HorasAtras = Timestamp.fromDate(hace24Horas);

      QuerySnapshot tokensExpirados = await _firestore
          .collection('tokens_recuperacion')
          .where('fecha_creacion', isLessThan: timestamp24HorasAtras)
          .get();

      for (var doc in tokensExpirados.docs) {
        await doc.reference.delete();
      }

      print('Tokens expirados eliminados: ${tokensExpirados.docs.length}');
    } catch (e) {
      print('Error al limpiar tokens expirados: $e');
    }
  }
}
