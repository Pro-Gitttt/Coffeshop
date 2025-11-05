// lib/screens/admin_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});
  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _nameCtl = TextEditingController();
  final CollectionReference _col = FirebaseFirestore.instance.collection('categories');

  Future<void> _addCategory() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    await _col.add({'name': name, 'order': DateTime.now().millisecondsSinceEpoch});
    _nameCtl.clear();
  }

  Future<void> _delete(String id) async {
    await _col.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories'), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: _nameCtl, decoration: const InputDecoration(labelText: 'Category name'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addCategory, child: const Text('Add'))
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _col.orderBy('order').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_,__) => const Divider(),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      return ListTile(
                        title: Text(d['name'] ?? ''),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(d.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
