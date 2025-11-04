import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuService {
  final _db = FirebaseFirestore.instance;

  Stream<List<MenuItem>> getMenuItems() {
    return _db.collection('menuItems').orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => MenuItem.fromSnapshot(doc)).toList(),
    );
  }

  Future<void> addItem(MenuItem item) async {
    await _db.collection('menuItems').add(item.toMap());
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _db.collection('menuItems').doc(id).update(data);
  }

  Future<void> deleteItem(String id) async {
    await _db.collection('menuItems').doc(id).delete();
  }
}
