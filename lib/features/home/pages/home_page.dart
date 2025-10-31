import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const destinos = [
    {'nombre': 'Cancún', 'tipo': 'Playa'},
    {'nombre': 'Tulum', 'tipo': 'Zona arqueológica'},
    {'nombre': 'Bacalar', 'tipo': 'Laguna'},
    {'nombre': 'Isla Mujeres', 'tipo': 'Isla'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = ref.watch(badgeCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Destinos ($badge)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              await ref
                  .read(notificationServiceProvider)
                  .showLocal(
                    title: 'Novedad turística',
                    body: 'Nueva promo en Quintana Roo 🌴',
                  );
              // Cambio: usar el método increment() del notifier
              ref.read(badgeCountProvider.notifier).increment();
            },
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: destinos.length,
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final d = destinos[index];
          return ListTile(
            leading: const Icon(Icons.place),
            title: Text(d['nombre']!),
            subtitle: Text(d['tipo']!),
            onTap: () async {
              await ref
                  .read(notificationServiceProvider)
                  .showLocal(
                    title: 'Explora ${d['nombre']}',
                    body: 'Descubre ${d['nombre']} (${d['tipo']})',
                  );
              // Cambio: usar el método increment() del notifier
              ref.read(badgeCountProvider.notifier).increment();
            },
          );
        },
      ),
    );
  }
}
