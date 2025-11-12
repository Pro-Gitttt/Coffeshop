import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/event_model.dart';
import '../../../core/services/event_service.dart';
import 'reservation_screen.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/custom_app_bar.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = EventService();
    final route = ModalRoute.of(context)?.settings.name ?? '/user/events';

    void _goBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/user/menu');
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Events',
        currentRoute: route,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: _goBack,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: route),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.streamAllEvents(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error loading events: ${snap.error}'),
            );
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No upcoming events.'));
          }
          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final event = EventModel.fromMap(d.id, d.data());
              final local = event.dateTime.toLocal();
              final dateLabel =
                  '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
              return Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateLabel),
                      const SizedBox(height: 6),
                      Text(event.description),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                    ),
                    child: const Text('RSVP'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReservationScreen(
                            initialDateTime: event.dateTime.toLocal(),
                            initialNotes: event.title,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
