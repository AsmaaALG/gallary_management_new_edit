import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/control_panal%20(2).dart';
import 'package:gallery_management/screens/Admin/gallery_requests_screen.dart';

//import 'package:gallery_management/screens/Admin/ad_request_management_screen.dart';

class RequestManagementScreen extends StatelessWidget {
  const RequestManagementScreen({super.key});

  bool isWeb(BuildContext context) => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = isWeb(context)
        ? screenWidth / 2 - 40 // بطاقتين جنب بعض مع هامش
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
          title: const Text(
            "إدارة الطلبات",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: mainFont,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'من خلال هذه الواجهة يمكنك الوصول إلى طلبات إنشاء المعارض وطلبات الإعلانات.',
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
                    title: 'طلبات إنشاء المعارض',
                    description:
                        'يمكنك إدارة الطلبات المقدمة من المنظمين لإنشاء معارض جديدة.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const GalleryRequestManagementScreen(),
                        ),
                      );
                    },
                  ),
                  OptionCard(
                    width: cardWidth,
                    title: 'طلبات الإعلانات',
                    description:
                        'يمكنك مراجعة الطلبات المتعلقة بإنشاء الإعلانات المرتبطة بالمعارض.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ControlPanel(),
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
