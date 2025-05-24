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
    final screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: const Color.fromARGB(255, 218, 142, 146).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        color: const Color.fromARGB(255, 250, 237, 237),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 8.0), // قللنا vertical
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: mainFont,
                  color: primaryColor,
                  fontSize: 16,
                ),
              ),
              // const SizedBox(height: 4), // قللنا الفراغ هنا أيضا
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: buttons.map((button) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 9.0),
                    child: IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: button['action'],
                      icon: Icon(
                        button['icon'],
                        color: secondaryColor,
                        size: 20,
                      ),
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

Future<void> confirmDelete(
    BuildContext context, String collection, String documentId) async {
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
              SizedBox(width: screenWidth * 0.05),
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
          'تم الحذف بنجاح',
          style: TextStyle(fontFamily: mainFont),
        ),
        backgroundColor: Color.fromARGB(255, 146, 149, 146),
      ),
    );
  }
}
