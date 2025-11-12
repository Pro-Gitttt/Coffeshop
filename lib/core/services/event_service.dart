import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('events');

  Future<String> createEvent(Map<String, dynamic> data) async {
    final doc = await _col.add({
      'title': data['title'],
      'description': data['description'],
      'dateTime': (data['dateTime'] is Timestamp)
          ? (data['dateTime'] as Timestamp)
          : Timestamp.fromDate((data['dateTime'] as DateTime).toUtc()),
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
    });
    return doc.id;
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      'title': data['title'],
      'description': data['description'],
      'dateTime': (data['dateTime'] is Timestamp)
          ? (data['dateTime'] as Timestamp)
          : Timestamp.fromDate((data['dateTime'] as DateTime).toUtc()),
    });
  }

  Future<void> deleteEvent(String id) async {
    await _col.doc(id).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllEvents() {
    return _col.orderBy('dateTime', descending: false).snapshots();
  }

  Future<List<EventModel>> fetchUpcomingEvents() async {
    final now = DateTime.now().toUtc();
    final snap = await _col
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dateTime')
        .get();
    return snap.docs.map((d) => EventModel.fromMap(d.id, d.data())).toList();
  }
}
