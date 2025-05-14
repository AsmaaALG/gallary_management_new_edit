import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/edit_gallery_screen.dart';
import 'package:gallery_management/screens/gallery_management_screen.dart';

class GallerySuiteScreen extends StatelessWidget {
  final String galleryId;

  const GallerySuiteScreen({super.key, required this.galleryId});

  void _onContainerTap(BuildContext context) {
    // هنا يمكنك إضافة الإجراء الذي تود تنفيذه عند النقر على الـ Container
    print('Container tapped!'); // يمكنك تعديل هذا حسب الحاجة
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: primaryColor,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 15),
          child: Column(
            children: [
              const Text(
                'يمكنك من خلال هذه الواجهة تعديل المعارض عبر تعبئة الحقول التالية',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: mainFont,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                height: 30,
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          EditGalleryScreen(galleryId: galleryId)),
                ), // الإجراء عند النقر
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 250, 237, 237),
                    border: Border.all(
                      color: const Color.fromARGB(255, 218, 142, 146)
                          .withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textAlign: TextAlign.right,
                          'تعديل بيانات المعرض',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: mainFont,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'من خلال هذه اللوحة يمكنك متابعة أحدث التغيرات وإضافة مقالات وفعاليات جديدة',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: mainFont,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GalleryManagementScreen()),
                ), // الإجراء عند النقر
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 250, 237, 237),
                    border: Border.all(
                      color: const Color.fromARGB(255, 218, 142, 146)
                          .withOpacity(0.5),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textAlign: TextAlign.right,
                          'التعديل على الأجنحة',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: mainFont,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'من خلال هذه اللوحة يمكنك رؤية جميع الجنحة التابعة للمعرض والتعديل عليها',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: mainFont,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
