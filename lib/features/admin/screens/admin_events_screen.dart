import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/event_service.dart';
import '../../../core/widgets/app_drawer.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _service = EventService();

  Future<void> _showEditDialog({String? id, Map<String, dynamic>? data}) async {
    final titleCtrl = TextEditingController(text: data?['title'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    if (data != null && data['dateTime'] != null) {
      final dtRaw = data['dateTime'];
      DateTime? full;
      if (dtRaw is Timestamp) full = dtRaw.toDate();
      else if (dtRaw is DateTime) full = dtRaw;
      else if (dtRaw is String) full = DateTime.tryParse(dtRaw);
      if (full != null) {
  pickedDate = full.toLocal();
  pickedTime = TimeOfDay(hour: pickedDate.hour, minute: pickedDate.minute);
      }
    }

    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(id == null ? 'Add Event' : 'Edit Event'),
        content: StatefulBuilder(builder: (c2, setState2) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                      child: Text(pickedDate == null
                          ? 'Pick date'
                          : '${pickedDate!.year}-${pickedDate!.month}-${pickedDate!.day}'),
                      onPressed: () async {
                        final now = DateTime.now();
                        final p = await showDatePicker(
                          context: context,
                          initialDate: pickedDate ?? now,
                          firstDate: now.subtract(const Duration(days: 3650)),
                          lastDate: now.add(const Duration(days: 3650)),
                        );
                        if (p != null) setState2(() => pickedDate = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                      child: Text(pickedTime == null
                          ? 'Pick time'
                          : '${pickedTime!.hour.toString().padLeft(2, '0')}:${pickedTime!.minute.toString().padLeft(2, '0')}'),
                      onPressed: () async {
                        final p = await showTimePicker(context: context, initialTime: pickedTime ?? TimeOfDay.now());
                        if (p != null) setState2(() => pickedTime = p);
                      },
                    ),
                  ),
                ])
              ],
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              if (pickedDate == null && (data == null || data['dateTime'] == null)) return;

              DateTime dt;
              if (pickedDate != null) {
                final t = pickedTime ?? const TimeOfDay(hour: 20, minute: 0);
                dt = DateTime(pickedDate!.year, pickedDate!.month, pickedDate!.day, t.hour, t.minute);
              } else {
                final raw = data!['dateTime'];
                if (raw is Timestamp) dt = raw.toDate();
                else if (raw is DateTime) dt = raw;
                else dt = DateTime.parse(raw.toString());
              }

              final payload = {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'dateTime': Timestamp.fromDate(dt.toUtc()),
              };

              try {
                if (id == null) {
                  await _service.createEvent(payload);
                } else {
                  await _service.updateEvent(id, payload);
                }
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved.')));
              } catch (e) {
                debugPrint('Event save failed: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save event.')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(String id) async {
    await _service.deleteEvent(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Events'), backgroundColor: Colors.brown),
      drawer: const AppDrawer(currentRoute: '/admin/events'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('events').orderBy('dateTime', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No events created.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final m = d.data();
              final dtRaw = m['dateTime'];
              DateTime dt;
              if (dtRaw is Timestamp) dt = dtRaw.toDate().toLocal();
              else if (dtRaw is DateTime) dt = dtRaw.toLocal();
              else dt = DateTime.tryParse(dtRaw.toString())?.toLocal() ?? DateTime.now();

              final dateLabel = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              return Card(
                child: ListTile(
                  title: Text(m['title'] ?? ''),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dateLabel), const SizedBox(height: 6), Text(m['description'] ?? '')]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showEditDialog(id: d.id, data: m)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEvent(d.id)),
                  ]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown,
        child: const Icon(Icons.add),
        onPressed: () => _showEditDialog(),
      ),
    );
  }
}
