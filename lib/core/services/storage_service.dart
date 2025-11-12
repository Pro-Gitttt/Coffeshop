import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload image to Firebase Storage (works on mobile and web, supports File or XFile)
  Future<String> uploadImage(dynamic imageFile, String itemId) async {
    try {
      final String path = 'stock/$itemId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(path);

      TaskSnapshot snapshot;
      if (kIsWeb) {
        // On web, prefer reading bytes
        if (imageFile is XFile) {
          final Uint8List bytes = await imageFile.readAsBytes();
          snapshot = await ref.putData(bytes);
        } else {
          final Uint8List bytes = await (imageFile as dynamic).readAsBytes();
          snapshot = await ref.putData(bytes);
        }
      } else {
        if (imageFile is File) {
          snapshot = await ref.putFile(imageFile);
        } else if (imageFile is XFile) {
          final Uint8List bytes = await imageFile.readAsBytes();
          snapshot = await ref.putData(bytes);
        } else {
          final Uint8List bytes = await (imageFile as dynamic).readAsBytes();
          snapshot = await ref.putData(bytes);
        }
      }

      // getDownloadURL can occasionally race; retry briefly if needed
      int attempts = 0;
      while (true) {
        try {
          final String url = await snapshot.ref.getDownloadURL();
          return url;
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found' && attempts < 4) {
            attempts += 1;
            await Future.delayed(Duration(milliseconds: 200 * attempts));
            continue;
          }
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Erreur d\'upload d\'image: ${e.toString()}');
    }
  }

  // Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if image doesn't exist
    }
  }

  // Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de sélection d\'image: ${e.toString()}');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur de capture d\'image: ${e.toString()}');
    }
  }

  // Upload complaint image to Firebase Storage
  Future<String> uploadComplaintImage(dynamic imageFile, String fileName) async {
    try {
      final String path = 'complaints/$fileName.jpg';
      final Reference ref = _storage.ref().child(path);

      TaskSnapshot snapshot;
      if (kIsWeb) {
        // On web imageFile is expected to be XFile. Read bytes and use putData.
        if (imageFile is XFile) {
          final Uint8List bytes = await imageFile.readAsBytes();
          snapshot = await ref.putData(bytes);
        } else {
          final Uint8List bytes = await (imageFile as dynamic).readAsBytes();
          snapshot = await ref.putData(bytes);
        }
      } else {
        if (imageFile is File) {
          snapshot = await ref.putFile(imageFile);
        } else if (imageFile is XFile) {
          final Uint8List bytes = await imageFile.readAsBytes();
          snapshot = await ref.putData(bytes);
        } else {
          final Uint8List bytes = await (imageFile as dynamic).readAsBytes();
          snapshot = await ref.putData(bytes);
        }
      }

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage error (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Error uploading complaint image: ${e.toString()}');
    }
  }
}

