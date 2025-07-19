import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class SuiteImageScreen extends StatefulWidget {
  final String suiteId;

  const SuiteImageScreen({super.key, required this.suiteId});

  @override
  State<SuiteImageScreen> createState() => _SuiteImageScreenState();
}

class _SuiteImageScreenState extends State<SuiteImageScreen> {
  final TextEditingController _newImageController = TextEditingController();

  bool _isValidImageUrl(String url) {
    final RegExp regex = RegExp(
      r'^(https?:\/\/.*\.(?:png|jpg|jpeg|gif|bmp))$',
      caseSensitive: false,
    );
    return regex.hasMatch(url);
  }

  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        elevation: 90,
        backgroundColor: const Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Directionality(
          textDirection: TextDirection.rtl,
          child:
              Text("إضافة صورة جديدة", style: TextStyle(fontFamily: mainFont)),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newImageController,
                decoration: InputDecoration(
                  hintText: 'رابط الصورة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 228, 182, 199), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 244, 210, 221), width: 2),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (await canLaunchUrl(imgurUrl)) {
                    await launchUrl(imgurUrl,
                        mode: LaunchMode.externalApplication);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      'افتح Imgur لرفع صورة',
                      style: TextStyle(fontFamily: mainFont, fontSize: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء",
                style: TextStyle(fontFamily: mainFont, color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              final imageUrl = _newImageController.text.trim();
              if (!_isValidImageUrl(imageUrl)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال رابط صورة صحيح')),
                );
                return;
              }
              if (imageUrl.isEmpty) return;

              await FirebaseFirestore.instance.collection('suite image').add({
                'suite id': widget.suiteId,
                'image url': imageUrl,
              });

              _newImageController.clear();
              Navigator.pop(context);
            },
            child: Text("إضافة",
                style: TextStyle(
                    fontFamily: mainFont,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteImageDialog(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("هل أنت متأكد من حذف هذه الصورة؟",
                  style: TextStyle(fontFamily: mainFont)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('suite image')
                          .doc(docId)
                          .delete();
                      Navigator.pop(context);
                    },
                    child: Text("حذف",
                        style: TextStyle(
                            color: primaryColor,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("إلغاء",
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: mainFont,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> uploadImageToImgbb(Uint8List bytes, String apiKey) async {
    try {
      final base64Image = base64Encode(bytes);
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');
      final response = await http.post(url, body: {'image': base64Image});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      } else {
        print('فشل رفع الصورة: ${response.body}');
        return null;
      }
    } catch (e) {
      print('خطأ أثناء رفع الصورة: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: primaryColor,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )),

        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final picker = ImagePicker();
            final images = await picker.pickMultiImage();

            if (images == null || images.isEmpty) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(child: CircularProgressIndicator()),
            );

            final imgbbApiKey = '95daff58b10157f2de7ddd93301132e2';

            for (final pickedFile in images) {
              final bytes = await pickedFile.readAsBytes();
              final imageUrl = await uploadImageToImgbb(bytes, imgbbApiKey);
              if (imageUrl != null) {
                await FirebaseFirestore.instance.collection('suite image').add({
                  'suite id': widget.suiteId,
                  'image url': imageUrl,
                });
              }
            }

            Navigator.pop(context);
          },
          backgroundColor: primaryColor,
          child: Icon(Icons.add, color: Colors.white, size: 30),
        ),

        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تعديل صور الجناح',
                style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 15,
                    color: primaryColor,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "يمكنك من خلال هذه الواجهة إضافة صور جديدة للأجنحة",
                style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('suite image')
                      .where('suite id', isEqualTo: widget.suiteId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final images = snapshot.data!.docs;

                    if (images.isEmpty) {
                      return Center(
                        child: Text("لا توجد صور بعد",
                            style: TextStyle(fontFamily: mainFont)),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: images.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final data = images[index];
                        final imageUrl = data['image url'];

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.black,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: InteractiveViewer(
                                    child: Image.network(imageUrl),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 7,
                                  right: 7,
                                  child: GestureDetector(
                                    onTap: () => _showDeleteImageDialog(data.id),
                                    child: Icon(Icons.close,
                                        color: Color(0xFFF9C33A), size: 27),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
