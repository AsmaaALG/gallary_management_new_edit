import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/services/firestore_service.dart';

class MainCard extends StatelessWidget {
  const MainCard({
    super.key,
    required this.title,
    required this.buttons,
  });

  final String title;
  final List<Map<String, dynamic>> buttons;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // شكل بيضاوي
          side: BorderSide(
            color: const Color.fromARGB(255, 218, 142, 146).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        color: const Color.fromARGB(255, 250, 237, 237),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: mainFont,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: buttons.map((button) {
                  return IconButton(
                    onPressed: button['action'],
                    icon: Icon(
                      button['icon'],
                      color: secondaryColor, // تغيير لون الأيقونة
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> confirmDelete(BuildContext context,String collection, String documentId) async {
  final screenWidth = MediaQuery.of(context).size.width;
  final FirestoreService _firestoreService = FirestoreService();

  final fontSize = screenWidth * 0.04;

  final confirmed = await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      contentPadding: EdgeInsets.all(screenWidth * 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'تأكيد الحذف',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize.clamp(16, 20),
              color: primaryColor,
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            'هل أنت متأكد من عملية الحذف؟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize.clamp(14, 18),
              color: Colors.black87,
              fontFamily: mainFont,
            ),
          ),
          SizedBox(height: screenWidth * 0.06),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontSize: fontSize.clamp(12, 16),
                    color: const Color.fromARGB(255, 72, 71, 71),
                    fontFamily: mainFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.08),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'حذف',
                  style: TextStyle(
                    fontSize: fontSize.clamp(12, 16),
                    color: primaryColor,
                    fontFamily: mainFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  if (confirmed == true) {
    _firestoreService.deleteDocument(collection, documentId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم حذف الإعلان بنجاح',
          style: TextStyle(fontFamily: mainFont),
        ),
        backgroundColor: Color.fromARGB(255, 146, 149, 146),
      ),
    );
  }
}
