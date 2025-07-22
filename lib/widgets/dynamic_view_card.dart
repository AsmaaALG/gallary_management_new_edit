import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class DynamicViewCard extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final String startDate;
  final String endDate;
  final String stopAd;
  final String cityId;
  final DocumentReference? classificationRef;
  final String qrCode;
  final int suitesCount;
  final String imageUrl;
  final String mapUrl;
  final String companyName;

  const DynamicViewCard({
    Key? key,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.stopAd,
    required this.cityId,
    required this.classificationRef,
    required this.qrCode,
    required this.suitesCount,
    required this.imageUrl,
    required this.mapUrl,
    required this.companyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // بطاقة المعلومات الأساسية
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildInfoRow('الشركة المنظمة', companyName),
                  _buildInfoRow('العنوان', title),
                  _buildInfoRow('الوصف', description),
                  _buildLinkRow('الموقع', location),
                  _buildInfoRow('تاريخ البدء', startDate),
                  _buildInfoRow('تاريخ الانتهاء', endDate),
                  if (stopAd.isNotEmpty)
                    _buildInfoRow('تاريخ إيقاف الإعلان', stopAd),
                ],
              ),
            ),
          ),

          // بطاقة معلومات المدينة والتصنيف
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCityInfo(cityId),
                  _buildClassificationInfo(classificationRef),
                  _buildInfoRow('كود QR', qrCode),
                  _buildInfoRow('عدد الأجنحة', suitesCount.toString()),
                ],
              ),
            ),
          ),

          // بطاقة عرض الصور
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'صور المعرض',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: mainFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNetworkImage('صورة المعرض', imageUrl),
                  const SizedBox(height: 20),
                  _buildNetworkImage('خريطة المعرض', mapUrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontFamily: mainFont,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
            softWrap: true,
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (url != null && url.isNotEmpty) {
                launch(url);
              }
            },
            child: Text(
              url ?? 'غير متاح',
              style: TextStyle(
                fontSize: 14,
                fontFamily: mainFont,
                color: url != null ? Colors.blue : Colors.black87,
                decoration: url != null ? TextDecoration.underline : null,
              ),
              textAlign: TextAlign.right,
              softWrap: true,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildCityInfo(String? cityId) {
    if (cityId == null || cityId.isEmpty) {
      return _buildInfoRow('المدينة', 'غير متاح');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('city').doc(cityId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildInfoRow('المدينة', 'غير متاح');
        }

        final cityData = snapshot.data!.data() as Map<String, dynamic>;
        return _buildInfoRow(
            'المدينة', cityData['name']?.toString() ?? 'غير متاح');
      },
    );
  }

  Widget _buildClassificationInfo(DocumentReference? classificationRef) {
    if (classificationRef == null) {
      return _buildInfoRow('التصنيف', 'غير متاح');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: classificationRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return _buildInfoRow('التصنيف', 'غير متاح');
        }

        final classificationData =
            snapshot.data!.data() as Map<String, dynamic>;
        return _buildInfoRow(
            'التصنيف', classificationData['name']?.toString() ?? 'غير متاح');
      },
    );
  }

  Widget _buildNetworkImage(String title, String? imageUrl) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 800;
        final imageHeight = isDesktop ? 500.0 : 250.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontFamily: mainFont,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('تعذر تحميل الصورة',
                            style: TextStyle(color: Colors.red));
                      },
                    ),
                  )
                : const Text('لا توجد صورة متاحة',
                    style: TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }
}
