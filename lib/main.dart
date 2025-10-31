import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/notifications/notification_service.dart';
import 'firebase_messaging_handler.dart';
import 'firebase_options.dart'; // Generado por flutterfire configure

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar handler de mensajes en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Inicializar servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.init();

  // Crear canal por defecto para FCM
  await _ensureFcmDefaultChannel();

  // Solicitar permisos
  await _requestPermissions();

  // Configurar handlers de foreground
  _configureForegroundHandlers(notificationService);

  runApp(const ProviderScope(child: MyApp()));
}

/// Solicita permisos de notificaciones según la plataforma
Future<void> _requestPermissions() async {
  final messaging = FirebaseMessaging.instance;

  if (Platform.isIOS) {
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    final androidImpl = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }
}

/// Configura los handlers para mensajes cuando la app está en foreground
void _configureForegroundHandlers(NotificationService local) {
  // Cuando llega un mensaje y la app está abierta
  FirebaseMessaging.onMessage.listen((message) {
    log('🔔 Mensaje recibido en foreground');
    log('Notification: ${message.notification}');
    log('Data: ${message.data}');

    // Verificar si hay imagen en los datos
    final imageUrl = message.data['imageUrl'] as String?;

    // Obtener título y cuerpo (desde notification o data)
    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        'Mensaje';
    final body =
        message.notification?.body ??
        message.data['body'] as String? ??
        'Tienes una notificación';

    // Mostrar con imagen si existe, sino notificación simple
    if (imageUrl != null && imageUrl.isNotEmpty) {
      local.showBigPicture(title: title, body: body, imageUrl: imageUrl);
    } else {
      local.showLocal(title: title, body: body);
    }
  });

  // Cuando el usuario toca una notificación y la app se abre
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    log('🚀 App abierta desde notificación');
    log('Data: ${message.data}');

    // TODO: Implementar navegación (deep linking)
    // Por ejemplo: navegar a pantalla de detalle según message.data
  });
}

/// Crea el canal de notificaciones por defecto para FCM
Future<void> _ensureFcmDefaultChannel() async {
  const channel = AndroidNotificationChannel(
    'default_channel_fcm',
    'General (FCM)',
    description: 'Canal por defecto para mensajes FCM',
    importance: Importance.high,
    playSound: true,
  );

  final plugin = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await plugin?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turismo Notifications',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = NotificationService();
  String? token;

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    token = await FirebaseMessaging.instance.getToken();
    log('📱 FCM Token: $token');
    setState(() {});
  }

  Future<void> _subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Suscrito al tópico: $topic')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo FCM Flutter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🔔 Notificaciones Push',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botón para mostrar notificación local
            ElevatedButton.icon(
              onPressed: () {
                _service.showLocal(
                  title: 'Notificación local',
                  body: 'Hola desde Flutter 🚀',
                );
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Mostrar notificación local'),
            ),

            const SizedBox(height: 12),

            // Botón para notificación con imagen
            ElevatedButton.icon(
              onPressed: () {
                _service.showBigPicture(
                  title: '🏖️ Oferta especial',
                  body: '¡Descuento del 30% en hoteles de playa!',
                  imageUrl: 'https://picsum.photos/800/400',
                );
              },
              icon: const Icon(Icons.image),
              label: const Text('Notificación con imagen'),
            ),

            const Divider(height: 32),

            // Suscripción a tópicos
            const Text(
              'Suscribirse a tópicos:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () => _subscribeToTopic('ofertas'),
                  child: const Text('Ofertas'),
                ),
                ElevatedButton(
                  onPressed: () => _subscribeToTopic('noticias'),
                  child: const Text('Noticias'),
                ),
                ElevatedButton(
                  onPressed: () => _subscribeToTopic('playa'),
                  child: const Text('Playa'),
                ),
              ],
            ),

            const Divider(height: 32),

            // Token del dispositivo
            const Text(
              'Token FCM del dispositivo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                token ?? 'Cargando...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Usa este token para enviar notificaciones desde Firebase Console',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
