import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/edit_gallery_screen.dart';
import 'package:gallery_management/screens/Admin/suite_management_screen.dart';
import 'package:gallery_management/screens/Admin/partner_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GallerySuiteScreen extends StatelessWidget {
  final String galleryId;

  const GallerySuiteScreen({super.key, required this.galleryId});

  bool isWeb(BuildContext context) => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = isWeb(context)
        ? screenWidth / 2 - 40 // مساحة لبطاقتين في صف واحد مع فراغ
        : double.infinity;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: primaryColor,
          title: FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection('2').doc(galleryId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('تحميل...');
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!.exists) {
                return const Text('حدث خطأ');
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final name = data['title'] ?? 'المعرض';
              return Text(
                name,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  fontFamily: mainFont,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 30),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  OptionCard(
                    width: cardWidth,
                    title: 'تعديل بيانات المعرض',
                    description:
                        'من خلال هذه اللوحة يمكنك متابعة أحدث التغيرات وإضافة مقالات وفعاليات جديدة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditGalleryScreen(galleryId: galleryId),
                        ),
                      );
                    },
                  ),
                  OptionCard(
                    width: cardWidth,
                    title: 'التعديل على الأجنحة',
                    description:
                        'من خلال هذه اللوحة يمكنك رؤية جميع الأجنحة التابعة للمعرض والتعديل عليها',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SuiteManagementScreen(galleryId: galleryId),
                        ),
                      );
                    },
                  ),
                  OptionCard(
                    width: cardWidth,
                    title: 'التعديل على الشركاء',
                    description:
                        'من خلال هذه اللوحة يمكنك تعديل الشركاء المرتبطين بالمعرض',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PartnerManagementScreen(galleryId: galleryId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OptionCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;
  final double width;

  const OptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 250, 237, 237),
          border: Border.all(
            color: const Color.fromARGB(255, 218, 142, 146).withOpacity(0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: mainFont,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: mainFont,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
