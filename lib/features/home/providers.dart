import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/notification_service.dart';

// Provider para el servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final svc = NotificationService();
  // Inicializar de forma asíncrona
  svc
      .init()
      .then((_) {
        print('🔔 Servicio de notificaciones listo');
      })
      .catchError((e) {
        print('❌ Error inicializando notificaciones: $e');
      });
  return svc;
});

// Notifier para manejar el contador de badges
class BadgeNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
    print('📊 Badge count: $state');
  }

  void reset() => state = 0;
}

// Provider para el contador de notificaciones (badge)
final badgeCountProvider = NotifierProvider<BadgeNotifier, int>(
  BadgeNotifier.new,
);
