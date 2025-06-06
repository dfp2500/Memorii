// services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Callback para cuando se toca una notificación de proximidad
  static Function(Map<String, dynamic>)? onProximityNotificationTapped;

  // Inicializar notificaciones
  static Future<void> initialize() async {
    // Solicitar permisos de notificación
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional notification permission');
    } else {
      print('❌ User declined or has not accepted notification permission');
      return; // No continuar si no hay permisos
    }

    // Configurar notificaciones locales
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificación para Android
    await _createNotificationChannel();

    // Configurar manejo de mensajes
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Manejar notificaciones cuando la app está completamente cerrada
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Obtener token FCM y guardarlo
    await _saveTokenToDatabase();

    // Configurar renovación automática del token
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

    print('🔔 NotificationService initialized successfully');
  }

  // Crear canal de notificación para Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel proximityChannel = AndroidNotificationChannel(
      'proximity_channel',
      'Detección de Proximidad',
      description: 'Notificaciones cuando tu pareja está cerca',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_channel',
      'Notificaciones Generales',
      description: 'Notificaciones generales de la app',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(proximityChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  // Guardar token FCM en la base de datos
  static Future<void> _saveTokenToDatabase([String? token]) async {
    try {
      token ??= await _messaging.getToken();
      if (token == null) {
        print('❌ No FCM token available');
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('usuario_id');

      if (userId != null) {
        // Buscar el documento del usuario y actualizar el token
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('id_usuario', isEqualTo: userId)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          await userQuery.docs.first.reference.update({
            'fcm_token': token,
            'token_updated_at': FieldValue.serverTimestamp(),
            'platform': Theme.of(navigatorKey.currentContext!).platform.name,
          });
          print('✅ FCM Token saved for user $userId');
        } else {
          print('❌ User document not found for ID: $userId');
        }
      } else {
        print('⚠️ No user ID found in SharedPreferences');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  // GlobalKey para acceder al contexto (debe ser configurado desde main.dart)
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Manejar mensajes en primer plano
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Received foreground message: ${message.notification?.title}');

    // Solo mostrar notificación local si no es de proximidad (las de proximidad se manejan diferente)
    if (message.data['type'] != 'proximity_detected') {
      _showLocalNotification(
        message.notification?.title ?? 'Nueva notificación',
        message.notification?.body ?? '',
        message.data,
        channelId: 'general_channel',
      );
    } else {
      // Para notificaciones de proximidad, mostrar directamente el diálogo
      _handleProximityNotification(message.data);
    }
  }

  // Manejar cuando se abre la app desde una notificación
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 Message clicked! Data: ${message.data}');
    Future.delayed(const Duration(milliseconds: 500), () {
      _handleNotificationData(message.data);
    });
  }

  // Callback para iOS cuando la app está en primer plano
  static Future<void> _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    print('📱 iOS foreground notification: $title');
  }

  // Manejar tap en notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        Map<String, dynamic> data;

        if (response.payload!.startsWith('{')) {
          // Si es JSON válido
          data = json.decode(response.payload!);
        } else {
          // Si es string simple, crear estructura básica
          data = {
            'type': 'proximity_detected',
            'partner_name': 'tu pareja',
          };
        }

        _handleNotificationData(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
        // Fallback: asumir que es notificación de proximidad
        _handleNotificationData({'type': 'proximity_detected'});
      }
    }
  }

  // Manejar datos de notificación
  static void _handleNotificationData(Map<String, dynamic> data) {
    print('🔄 Handling notification data: $data');

    if (data['type'] == 'proximity_detected') {
      _handleProximityNotification(data);
    } else if (data['type'] == 'calendar_reminder') {
      _handleCalendarReminder(data);
    } else {
      print('⚠️ Unknown notification type: ${data['type']}');
    }
  }

  // Manejar notificación de proximidad
  static void _handleProximityNotification(Map<String, dynamic> data) {
    print('💕 Handling proximity notification');

    if (onProximityNotificationTapped != null) {
      onProximityNotificationTapped!(data);
    } else if (navigatorKey.currentContext != null) {
      _showProximityDialog(navigatorKey.currentContext!, data);
    } else {
      print('⚠️ No context available for proximity dialog');
    }
  }

  // Manejar recordatorio de calendario
  static void _handleCalendarReminder(Map<String, dynamic> data) {
    if (navigatorKey.currentContext != null) {
      // Navegar directamente al calendario
      Navigator.of(navigatorKey.currentContext!).pushNamed('/calendar');
    }
  }

  // Mostrar diálogo de proximidad
  static void _showProximityDialog(BuildContext context, Map<String, dynamic> data) {
    final partnerName = data['partner_name'] ?? 'tu pareja';
    final detectionTime = data['detection_time'] ?? 'hoy';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Ahora no',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
        );
      },
    );
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(
      String title,
      String body,
      Map<String, dynamic> data, {
        String channelId = 'proximity_channel',
        int notificationId = 0,
      }) async {

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'proximity_channel' ? 'Detección de Proximidad' : 'General',
      channelDescription: channelId == 'proximity_channel'
          ? 'Notificaciones cuando tu pareja está cerca'
          : 'Notificaciones generales',
      importance: channelId == 'proximity_channel' ? Importance.high : Importance.defaultImportance,
      priority: channelId == 'proximity_channel' ? Priority.high : Priority.defaultPriority,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Colors.pink,
      enableVibration: true,
      playSound: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: json.encode(data),
    );
  }

  // Mostrar diálogo de consentimiento
  static Future<bool> showConsentDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.security, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🔒 Detección de Proximidad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para detectar cuando estás con tu pareja, la app necesita:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Acceso a tu ubicación en segundo plano')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.bluetooth, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Usar Bluetooth para detectar dispositivos')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Enviar notificaciones')),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '🔐 Tus datos están seguros y solo se usan para esta función.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'No, gracias',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Acepto'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Verificar si los permisos están concedidos
  static Future<bool> areNotificationPermissionsGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Solicitar permisos específicos (llamar después del consentimiento)
  static Future<bool> requestNotificationPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Programar notificación de prueba (para testing)
  static Future<void> scheduleTestNotification() async {
    await _showLocalNotification(
      '💕 Momento especial detectado',
      'Has estado con tu pareja hoy. ¿Quieres crear un recuerdo?',
      {
        'type': 'proximity_detected',
        'partner_name': 'tu pareja',
        'detection_time': 'hoy',
      },
    );
  }

  // Cancelar todas las notificaciones
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancelar notificación específica
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Obtener notificaciones pendientes
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Limpiar token FCM (para logout)
  static Future<void> clearTokenFromDatabase() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('usuario_id');

      if (userId != null) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('id_usuario', isEqualTo: userId)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          await userQuery.docs.first.reference.update({
            'fcm_token': FieldValue.delete(),
            'token_updated_at': FieldValue.serverTimestamp(),
          });
          print('✅ FCM Token cleared for user $userId');
        }
      }
    } catch (e) {
      print('❌ Error clearing FCM token: $e');
    }
  }
}