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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Después de Firebase.initializeApp()
  FirebaseMessaging messaging = FirebaseMessaging.instance;

// Crear canal de notificaciones para Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'memorii_channel', // mismo ID que usas en _showLocalNotification
    'Memorii Notifications',
    description: 'Notificaciones de la app Memorii',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configurar notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? idUsuario = prefs.getInt('usuario_id');

  await initializeDateFormatting();

  print('Locale: ${Intl.getCurrentLocale()}');
  print('System Locale: ${Intl.systemLocale}');

  await dotenv.load();
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

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initDeepLinks();
    _initFirebaseMessaging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
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
        break;
      case AppLifecycleState.paused:
        print('📱 App paused');
        // App pasa a segundo plano - el servicio debe seguir funcionando
        break;
      case AppLifecycleState.detached:
        print('📱 App detached');
        break;
      case AppLifecycleState.inactive:
        print('📱 App inactive');
        break;
      case AppLifecycleState.hidden:
        print('📱 App hidden');
        break;
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

  Future<void> _initFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'memorii_channel',
      'Memorii Notifications',
      description: 'Notificaciones de la app Memorii',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Solicitar permisos
    NotificationSettings settings = await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificación concedidos');

      // Obtener token del dispositivo
      String? token = await _messaging!.getToken();
      print('📱 FCM Token: $token');

      // Registrar token en Firestore automáticamente
      if (token != null) {
        await _registrarTokenEnFirestore(token);
      }

      // Configurar manejo de notificaciones
      _configureNotificationHandlers();
    } else {
      print('❌ Permisos de notificación denegados');
    }
  }

  Future<void> _registrarTokenEnFirestore(String token) async {
    try {
      // Obtener referencia al documento de tokens
      final firestore = FirebaseFirestore.instance;
      final tokensRef = firestore.collection('app_settings').doc('device_tokens');

      // Obtener documento actual
      final doc = await tokensRef.get();
      List<String> tokens = [];

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['tokens'] != null) {
          tokens = List<String>.from(data['tokens']);
        }
      }

      // Añadir token si no existe
      if (!tokens.contains(token)) {
        tokens.add(token);

        await tokensRef.set({
          'tokens': tokens,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('✅ Token registrado en Firestore: $token');
      } else {
        print('ℹ️ Token ya existe en Firestore');
      }

    } catch (error) {
      print('❌ Error registrando token en Firestore: $error');
    }
  }

  void _configureNotificationHandlers() {
    // Cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Mensaje recibido en primer plano: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Cuando se toca una notificación y la app se abre
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App abierta desde notificación: ${message.notification?.title}');
      // Aquí puedes navegar a una pantalla específica si necesitas
    });

    // Verificar si la app se abrió desde una notificación al iniciarla
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 App iniciada desde notificación: ${message.notification?.title}');
        // Aquí puedes navegar a una pantalla específica si necesitas
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'memorii_channel',
      'Memorii Notifications',
      channelDescription: 'Notificaciones de la app Memorii',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin!.show(
      0,
      message.notification?.title ?? 'Memorii',
      message.notification?.body ?? 'Tienes una nueva notificación',
      platformChannelSpecifics,
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