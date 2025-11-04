import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';



class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File file, String folder) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('$folder/$fileName.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
