import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler para mensajes FCM cuando la app está cerrada o en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📱 Mensaje en background recibido');
  log('ID: ${message.messageId}');
  log('Título: ${message.notification?.title}');
  log('Cuerpo: ${message.notification?.body}');
  log('Data: ${message.data}');
  log('ImageUrl: ${message.data['imageUrl']}');
}
