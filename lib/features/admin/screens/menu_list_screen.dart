import 'package:flutter/material.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/models/menu_item_model.dart';

class AdminMenuListScreen extends StatelessWidget {
  const AdminMenuListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/admin/menu/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export_csv' || v == 'export_pdf') {
                // Export current stock list (as an example export action)
                final stockSnap = await service.getStockItems().first;
                final exporter = ExportService();
                try {
                  if (v == 'export_csv') {
                    await exporter.exportStockToCSV(stockSnap);
                  } else {
                    await exporter.exportStockToPDF(stockSnap);
                  }
                  // Notify success
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export terminé (Documents)')));
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e')));
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export_csv', child: Text('Exporter stock (CSV)')),
              PopupMenuItem(value: 'export_pdf', child: Text('Exporter stock (PDF)')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/admin/menu'),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: service.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucun élément'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = items[i];
              return ListTile(
                title: Text(it.name),
                subtitle: Text('${it.price.toStringAsFixed(2)} TND • ${it.category}'),
                trailing: Switch(
                  value: it.available,
                  onChanged: (v) {
                    service.updateMenuItem(MenuItemModel(
                      id: it.id,
                      name: it.name,
                      description: it.description,
                      price: it.price,
                      images: it.images,
                      category: it.category,
                      available: v,
                      rating: it.rating,
                      recipe: it.recipe,
                    ));
                  },
                ),
                onTap: () => Navigator.pushNamed(context, '/admin/menu/edit', arguments: it),
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete'),
                      content: const Text('Confirm deletion?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await service.deleteMenuItem(it.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}


