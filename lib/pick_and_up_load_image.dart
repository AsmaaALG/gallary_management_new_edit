import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<String?> pickAndUploadImage({required String imgbbApiKey}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
      final response = await http.post(url, body: {'image': base64Image});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['data']['url'];
        print(' تم رفع الصورة: $imageUrl');
        return imageUrl;
      } else {
        print(' فشل في رفع الصورة: ${response.body}');
        return null;
      }
    } catch (e) {
      print(' خطأ أثناء رفع الصورة: $e');
      return null;
    }
  }