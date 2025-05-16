import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/edit_suite_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';

class SuiteManagementScreen extends StatefulWidget {
  final String galleryId;

  const SuiteManagementScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  _SuiteManagementScreenState createState() => _SuiteManagementScreenState();
}

class _SuiteManagementScreenState extends State<SuiteManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddSuiteDialog() {
    final _nameController = TextEditingController();
    final _descController = TextEditingController();
    final _imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 248, 243, 243),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("إضافة جناح جديد",
                    style: TextStyle(
                        fontFamily: mainFont, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                buildInput(_nameController, "اسم الجناح"),
                SizedBox(height: 10),
                buildInput(_descController, "وصف الجناح"),
                SizedBox(height: 10),
                buildInput(_imageController, "رابط صورة الجناح"),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty ||
                        _descController.text.isEmpty ||
                        _imageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('يرجى ملء جميع الحقول',
                              style: TextStyle(fontFamily: mainFont))));
                      return;
                    }

                    await _firestoreService.addSuite(
                      name: _nameController.text,
                      description: _descController.text,
                      imageUrl: _imageController.text,
                      galleryId: widget.galleryId,
                    );

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text("إضافة",
                      style:
                          TextStyle(fontFamily: mainFont, color: Colors.black)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(TextEditingController controller, String hint) {
    return Container(
      width: 250,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(color: Color.fromARGB(255, 209, 167, 181)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: BorderSide(color: Color.fromARGB(255, 207, 98, 98)),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String suiteId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 250, 230, 230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("هل أنت متأكد من حذف هذا الجناح؟",
                  style: TextStyle(fontFamily: mainFont)),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () async {
                      await _firestoreService.deleteSuiteAndImages(suiteId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حذف الجناح وصوره بنجاح'),
                          backgroundColor: primaryColor,
                        ),
                      );
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
                            color: const Color.fromARGB(255, 56, 56, 56),
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
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('تعديل الجناح',
                  style: TextStyle(
                    fontFamily: mainFont,
                    fontSize: 15,
                    color: Colors.white,
                  )),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.arrow_forward, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: _showAddSuiteDialog,
          child: Icon(Icons.add, color: Colors.white, size: 25),
        ),
        body: Padding(
          padding: const EdgeInsets.all(27.0),
          child: Column(
            children: [
              Text(
                "يمكنك من خلال هذه الواجهة تعديل الأجنحة داخل المعرض المحدد مسبقاً عبر تعبئة الحقول التالية",
                style: TextStyle(fontFamily: mainFont),
              ),
              SizedBox(height: 35),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 228, 226, 226),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestoreService.getSuitesForGallery(widget.galleryId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());

                    final suites = snapshot.data!.docs;
                    final filtered = suites
                        .where((doc) => doc['name']
                            .toString()
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList();

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final data = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Color.fromARGB(255, 237, 202, 202)),
                            ),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    data['name'],
                                    style: TextStyle(
                                      fontFamily: mainFont,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: secondaryColor),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditSuiteScreen(
                                              suiteId: data.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () =>
                                          _showDeleteDialog(data.id),
                                      icon: Icon(Icons.delete,
                                          color: secondaryColor),
                                    ),
                                  ],
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
