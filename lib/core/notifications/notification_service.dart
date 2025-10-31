import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'default_channel_v2';
  static const _channelName = 'General';
  static const _channelDesc = 'Canal de notificaciones generales';

  /// Inicializa el servicio de notificaciones locales
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_stat_notify',
    );
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(settings);

    // Crear canal de notificaciones para Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Muestra una notificación local simple
  Future<void> showLocal({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Muestra notificación con imagen remota (Big Picture)
  /// Descarga la imagen primero y luego la muestra
  Future<void> showBigPicture({
    required String title,
    required String body,
    required String imageUrl,
  }) async {
    try {
      // Descargar la imagen
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception('Error al descargar imagen: ${response.statusCode}');
      }

      // Guardar en directorio temporal
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/notification_image_$timestamp.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // Crear notificación con Big Picture
      final bigPicture = BigPictureStyleInformation(
        FilePathAndroidBitmap(file.path),
        contentTitle: title,
        summaryText: body,
        hideExpandedLargeIcon: false,
      );

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        styleInformation: bigPicture,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        largeIcon: FilePathAndroidBitmap(file.path),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      // Si falla la descarga, mostrar notificación simple
      print('❌ Error al mostrar Big Picture: $e');
      await showLocal(title: title, body: body);
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAll() async {
    await _local.cancelAll();
  }

  /// Cancela una notificación específica por ID
  Future<void> cancel(int id) async {
    await _local.cancel(id);
  }
}
