import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationService {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('reservations');

  Future<String> createReservation(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _col.add(data);
    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllReservations() {
    return _col.orderBy('reservationDateTime', descending: false).snapshots();
  }

  Future<void> updateReservation(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(id).update(data);
  }

  Future<void> deleteReservation(String id) async {
    await _col.doc(id).delete();
  }
}
