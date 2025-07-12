import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';

class ViewSuitePhotoScreen extends StatelessWidget {
  final String suiteId;

  const ViewSuitePhotoScreen({super.key, required this.suiteId});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'عرض صور الجناح',
            style: TextStyle(
              fontSize: 16,
              fontFamily: mainFont,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'صور الجناح',
                style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "يمكنك من خلال هذه الواجهة عرض صور الجناح",
                style: TextStyle(
                  fontFamily: mainFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('suite image')
                      .where('suite id', isEqualTo: suiteId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final images = snapshot.data!.docs;

                    if (images.isEmpty) {
                      return Center(
                        child: Text(
                          "لا توجد صور متاحة",
                          style: TextStyle(fontFamily: mainFont),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: images.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWeb ? 4 : 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final data = images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['image url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
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
