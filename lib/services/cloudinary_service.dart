import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dpdlq3gc1";
  static const String uploadPreset = "YOUR_UPLOAD_PRESET"; // à configurer (voir plus bas)

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', url)
      ..fields['ml_default'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      return data['secure_url']; // ✅ retourne l’URL publique
    } else {
      print("Upload failed: ${response.statusCode}");
      return null;
    }
  }
}
