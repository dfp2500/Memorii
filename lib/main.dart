import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:memorii/views/inicio.dart';
import 'package:memorii/views/restablecer_contrasenia.dart';
import 'dart:async';
import 'views/calendario.dart';
import 'firebase_options.dart';
import 'views/registrar_usuario.dart';
import 'views/iniciar_sesion_usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:memorii/providers/usuario_provider.dart';
// Nuevas importaciones para proximidad
import 'servicios/ProximityService.dart';
import 'servicios/NotificationService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? idUsuario = prefs.getInt('usuario_id');

  await initializeDateFormatting();

  // Inicializar servicios de notificaciones primero
  await NotificationService.initialize();

  // Si hay usuario logueado, inicializar proximidad
  if (idUsuario != null) {
    await ProximityService.initialize(idUsuario);
  }

  print('Locale: ${Intl.getCurrentLocale()}');
  print('System Locale: ${Intl.systemLocale}');

  runApp(
    // Envolver la app con MultiProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        // Agregar más providers aquí si necesitas
      ],
      child: MyApp(idUsuario: idUsuario),
    ),
  );
}

class MyApp extends StatefulWidget {
  final int? idUsuario;
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({Key? key, this.idUsuario}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _appInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Configurar el navigatorKey en el NotificationService
    NotificationService.navigatorKey = MyApp.navigatorKey;

    _initDeepLinks();

    // Configurar listener para notificaciones de proximidad
    NotificationService.onProximityNotificationTapped = _handleProximityNotification;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    // Detener servicio de proximidad al cerrar la app
    ProximityService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print('📱 App resumed');
        // App vuelve a primer plano
        _checkForPendingLinks();
        // Reanudar servicio de proximidad si hay usuario logueado
        if (widget.idUsuario != null) {
          ProximityService.resume();
        }
        break;
      case AppLifecycleState.paused:
        print('📱 App paused');
        // App pasa a segundo plano - el servicio debe seguir funcionando
        break;
      case AppLifecycleState.detached:
        print('📱 App detached');
        // App se está cerrando
        ProximityService.stop();
        break;
      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;
      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
    }
  }

  // Manejar notificación de proximidad tocada
  void _handleProximityNotification(Map<String, dynamic> data) {
    print('💕 Handling proximity notification in main: $data');

    if (MyApp.navigatorKey.currentContext != null) {
      final partnerName = data['partner_name'] ?? 'tu pareja';
      final detectionTime = data['detection_time'] ?? 'hoy';

      // Mostrar diálogo para crear entrada de calendario
      showDialog(
        context: MyApp.navigatorKey.currentContext!,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.pink, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '💕 Momento Especial',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has pasado tiempo con $partnerName $detectionTime.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Quieres crear un recuerdo especial en vuestro calendario?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Ahora no',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navegar al calendario
                Navigator.of(context).pushNamed('/calendar');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Crear recuerdo'),
            ),
          ],
        ),
      );
    } else {
      print('⚠️ No context available for proximity dialog');
    }
  }

  Future<void> _checkForPendingLinks() async {
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('🔗 Found pending link when resuming: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('❌ Error checking pending links: $e');
    }
  }

  Future<void> _initDeepLinks() async {
    // Esperamos a que la app se inicialice completamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _appInitialized = true;
      });
    });

    // Manejo de deep links cuando la app está cerrada
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('🔗 Initial link found: $initialLink');
        // Esperamos más tiempo para que la app se inicialice completamente
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (_appInitialized) {
            _handleDeepLink(initialLink);
          }
        });
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Manejo de deep links cuando la app está abierta o en segundo plano
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (Uri uri) {
        print('🔗 Deep link stream received: $uri');
        // Pequeño delay para asegurar que el contexto esté disponible
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(uri);
        });
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    print('🔗 Handling deep link: $uri');

    if (uri.scheme == 'memorii') {
      if (uri.host == 'reset-password') {
        // Extraer parámetros
        final token = uri.queryParameters['token'];
        final email = uri.queryParameters['email'];

        if (token != null && email != null) {
          print('🔐 Navigating to ResetPasswordScreen with token: $token, email: $email');

          // Verificar que el navigatorKey y el contexto estén disponibles
          if (MyApp.navigatorKey.currentState != null &&
              MyApp.navigatorKey.currentContext != null) {

            // Navegar a la pantalla de restablecimiento
            MyApp.navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => RestablecerContrasenia(
                  token: token,
                  email: email,
                ),
              ),
                  (route) => false, // Elimina todas las rutas anteriores
            );
          } else {
            // Si no hay contexto disponible, intentar de nuevo después de un delay
            print('⚠️ Navigator not ready, retrying...');
            Future.delayed(const Duration(milliseconds: 1000), () {
              _handleDeepLink(uri);
            });
          }
        } else {
          print('❌ Missing parameters in deep link');
          _showErrorDialog('Enlace inválido: faltan parámetros');
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    if (MyApp.navigatorKey.currentContext != null) {
      showDialog(
        context: MyApp.navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      title: 'Memorii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      initialRoute: widget.idUsuario != null ? '/home' : '/login',
      routes: {
        '/login': (context) => IniciarSesionUsuario(),
        '/register': (context) => RegistrarUsuario(),
        '/home': (context) => InicioPage(idUsuario: widget.idUsuario ?? 0),
        '/calendar': (context) => CalendarioPage(idUsuario: widget.idUsuario ?? 0), // Añadir ruta al calendario
        // Agregar ruta para el restablecimiento de contraseña
        '/reset-password': (context) {
          // Esta ruta se puede usar como fallback
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
          if (args != null) {
            return RestablecerContrasenia(
              token: args['token'] ?? '',
              email: args['email'] ?? '',
            );
          }
          return IniciarSesionUsuario();
        },
      },
      // Manejo de rutas no encontradas
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => IniciarSesionUsuario(),
        );
      },
    );
  }
}