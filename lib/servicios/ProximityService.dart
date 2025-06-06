// services/proximity_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProximityService {
  static const String _serviceUUID = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
  static const String _characteristicUUID = "6ba7b811-9dad-11d1-80b4-00c04fd430c8";
  static const String _appIdentifier = "Memorii";

  static Timer? _scanTimer;
  static Timer? _advertisingTimer;
  static int? _currentUserId;
  static bool _isInitialized = false;
  static bool _isScanning = false;
  static Set<int> _detectedPartners = {};

  // Inicializar el servicio de proximidad
  static Future<bool> initialize(int userId) async {
    try {
      _currentUserId = userId;

      // Verificar si el usuario ya dio consentimiento
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool? consent = prefs.getBool('proximity_consent_$userId');

      if (consent != true) {
        print('Proximity service not initialized - no consent');
        return false;
      }

      // Solicitar permisos
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('Proximity service not initialized - permissions denied');
        return false;
      }

      // Configurar WorkManager para tareas en segundo plano
      await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode
      );

      // Registrar tarea periódica cada 30 minutos (mínimo en Android)
      await Workmanager().registerPeriodicTask(
        "proximity_scan_$userId",
        "proximityScanning",
        frequency: const Duration(minutes: 30),
        inputData: {'user_id': userId},
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      _isInitialized = true;

      // Iniciar inmediatamente
      await _startProximityDetection();

      return true;
    } catch (e) {
      print('Error initializing proximity service: $e');
      return false;
    }
  }

  // Solicitar consentimiento del usuario
  static Future<bool> requestConsent(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('proximity_consent_$userId', true);
    return true;
  }

  // Solicitar permisos necesarios
  static Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> permissions = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();

    bool allGranted = true;
    permissions.forEach((permission, status) {
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        print('Permission $permission denied: $status');
        allGranted = false;
      }
    });

    return allGranted;
  }

  // Iniciar detección de proximidad
  static Future<void> _startProximityDetection() async {
    if (!_isInitialized || _currentUserId == null) return;

    try {
      // Verificar que Bluetooth esté disponible
      if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return;
      }

      // Iniciar advertising y scanning en paralelo
      await Future.wait([
        _startAdvertising(),
        _startScanning(),
      ]);

      // Programar escaneos periódicos cada 5 minutos
      _scanTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        _performScan();
      });

    } catch (e) {
      print('Error starting proximity detection: $e');
    }
  }

  // Iniciar advertising (anunciar presencia)
  static Future<void> _startAdvertising() async {
    try {
      // Crear datos de advertising con ID de usuario
      String advertisingData = "$_appIdentifier:$_currentUserId";

      // En Flutter Blue Plus, el advertising es limitado
      // Usaremos el nombre del dispositivo para identificarnos
      print('Starting advertising for user $_currentUserId');

      // Nota: El advertising real en móviles es muy limitado
      // La detección principal será por scanning

    } catch (e) {
      print('Error starting advertising: $e');
    }
  }

  // Iniciar scanning
  static Future<void> _startScanning() async {
    if (_isScanning) return;

    try {
      _isScanning = true;

      // Iniciar escaneo BLE
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30),
        androidUsesFineLocation: false,
      );

      // Listener para resultados de escaneo
      FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      print('Bluetooth scanning started');

    } catch (e) {
      print('Error starting scan: $e');
      _isScanning = false;
    }
  }

  // Procesar resultados de escaneo
  static void _processScanResults(List<ScanResult> results) {
    for (ScanResult result in results) {
      // Buscar dispositivos que contengan nuestro identificador
      String deviceName = result.advertisementData.localName ?? '';

      if (deviceName.contains(_appIdentifier)) {
        // Extraer ID de usuario del nombre
        try {
          String userIdStr = deviceName.split(':')[1];
          int partnerId = int.parse(userIdStr);

          if (partnerId != _currentUserId) {
            _handlePartnerDetected(partnerId, result.rssi);
          }
        } catch (e) {
          print('Error parsing device name: $deviceName');
        }
      }

      // También buscar por servicios UUIDs conocidos
      if (result.advertisementData.serviceUuids.contains(_serviceUUID)) {
        print('Found device with our service UUID');
        // Intentar conectar para obtener más información
        _tryGetPartnerInfo(result.device);
      }
    }
  }

  // Intentar obtener información de la pareja
  static Future<void> _tryGetPartnerInfo(BluetoothDevice device) async {
    try {
      // Conectar brevemente para leer características
      await device.connect(timeout: const Duration(seconds: 5));

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUUID.toLowerCase()) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == _characteristicUUID.toLowerCase()) {
              // Leer ID de usuario
              List<int> value = await characteristic.read();
              String data = String.fromCharCodes(value);

              if (data.startsWith(_appIdentifier)) {
                int partnerId = int.parse(data.split(':')[1]);
                _handlePartnerDetected(partnerId, -50); // RSSI estimado
              }
            }
          }
        }
      }

      await device.disconnect();

    } catch (e) {
      print('Error getting partner info: $e');
      try {
        await device.disconnect();
      } catch (disconnectError) {
        print('Error disconnecting: $disconnectError');
      }
    }
  }

  // Manejar detección de pareja
  static void _handlePartnerDetected(int partnerId, int rssi) {
    print('Partner detected: $partnerId with RSSI: $rssi');

    // Verificar que el RSSI indique proximidad cercana (menos de 10 metros aprox)
    if (rssi > -70) { // RSSI > -70 dBm indica proximidad cercana
      _detectedPartners.add(partnerId);
      _recordEncounter(partnerId, rssi);
    }
  }

  // Registrar encuentro en Firebase
  static Future<void> _recordEncounter(int partnerId, int rssi) async {
    if (_currentUserId == null) return;

    try {
      // Verificar que son pareja
      bool areCouples = await _verifyCouple(_currentUserId!, partnerId);
      if (!areCouples) {
        print('Users $_currentUserId and $partnerId are not a couple');
        return;
      }

      // Registrar encuentro
      await FirebaseFirestore.instance.collection('encounters').add({
        'user1_id': _currentUserId,
        'user2_id': partnerId,
        'rssi': rssi,
        'method': 'bluetooth',
        'timestamp': DateTime.now(),
        'date': DateTime.now().toIso8601String().split('T')[0], // Solo la fecha
      });

      print('Encounter recorded: User $_currentUserId and $partnerId (RSSI: $rssi)');

    } catch (e) {
      print('Error recording encounter: $e');
    }
  }

  // Verificar si dos usuarios son pareja
  static Future<bool> _verifyCouple(int user1, int user2) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parejas')
          .where('id_user1', isEqualTo: user1)
          .where('id_user2', isEqualTo: user2)
          .get();

      if (snapshot.docs.isNotEmpty) return true;

      snapshot = await FirebaseFirestore.instance
          .collection('parejas')
          .where('id_user1', isEqualTo: user2)
          .where('id_user2', isEqualTo: user1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error verifying couple: $e');
      return false;
    }
  }

  // Realizar escaneo periódico
  static Future<void> _performScan() async {
    if (!_isInitialized) return;

    print('Performing periodic scan...');

    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(const Duration(seconds: 2));
      await _startScanning();
    } catch (e) {
      print('Error in periodic scan: $e');
    }
  }

  // Reanudar servicio
  static Future<void> resume() async {
    if (_isInitialized && _currentUserId != null) {
      await _startProximityDetection();
    }
  }

  // Detener el servicio
  static Future<void> stop() async {
    try {
      _scanTimer?.cancel();
      _advertisingTimer?.cancel();

      await FlutterBluePlus.stopScan();
      await Workmanager().cancelAll();

      _isInitialized = false;
      _isScanning = false;
      _detectedPartners.clear();

      print('Proximity service stopped');
    } catch (e) {
      print('Error stopping proximity service: $e');
    }
  }

  // Obtener estado del servicio
  static bool get isRunning => _isInitialized;

  // Obtener parejas detectadas hoy
  static Set<int> get detectedPartnersToday => Set.from(_detectedPartners);
}

// Callback para WorkManager (tareas en segundo plano)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('Background proximity task executing...');

      int? userId = inputData?['user_id'];
      if (userId != null) {
        // Realizar escaneo rápido en segundo plano
        await ProximityService._performScan();
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}