import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

class SuiteImageScreen extends StatefulWidget {
  final String suiteId;

  const SuiteImageScreen({super.key, required this.suiteId});

  @override
  State<SuiteImageScreen> createState() => _SuiteImageScreenState();
}

class _SuiteImageScreenState extends State<SuiteImageScreen> {
  final TextEditingController _newImageController = TextEditingController();

  // حوار إضافة صورة جديدة
  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Directionality(
          textDirection: TextDirection.rtl,
          child:
              Text("إضافة صورة جديدة", style: TextStyle(fontFamily: mainFont)),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: TextField(
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

  // حوار تأكيد حذف الصورة
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

  @override
  Widget build(BuildContext context) {
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

        // زر الإضافة العائم
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddImageDialog,
          backgroundColor: primaryColor,
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 30,
          ),
        ),

        // محتوى الشاشة
        body: Padding(
          padding: const EdgeInsets.all(20.0), // Padding من جميع الجهات
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
              Center(
                child: Text(
                  "يمكنك من خلال هذه الواجهة إضافة صور جديدة للأجنحة",
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // عرض الصور من قاعدة البيانات
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
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // عرض الصورة من الرابط
                              Positioned.fill(
                                child: Image.network(
                                  'https://drive.google.com/uc?id=${data['image url']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),

                              // زر الحذف
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
