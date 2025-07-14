import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/Admin/Organizer_screen.dart';
import 'package:gallery_management/screens/Admin/company_screen.dart';
import 'package:gallery_management/screens/Organizer/edit_gallery_screen.dart';
import 'package:gallery_management/screens/Admin/suite_management_screen.dart';
import 'package:gallery_management/screens/Admin/partner_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizingCompanyScreen extends StatelessWidget {
  const OrganizingCompanyScreen({
    super.key,
  });

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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'يمكنك من خلال هذه الواجهة ادارة الشركات المنظمة للمعارض',
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
                    title: 'إدارة الشركات المنظمة',
                    description:
                        'من خلال هذه اللوحة يمكنك ادارة الشركات المنظمة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyScreen(),
                        ),
                      );
                    },
                  ),
                  OptionCard(
                    width: cardWidth,
                    title: 'إدارة المنظمين',
                    description:
                        'من خلال هذه اللوحة يمكنك إدارة منظمين المعارض',
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => OrganizerScreen(),
                      //   ),
                      // );
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
