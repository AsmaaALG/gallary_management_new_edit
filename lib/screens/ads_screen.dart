// screens/ads_management/ads_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/edit_ads_screen.dart';
import 'package:gallery_management/services/firestore_service.dart';
import 'package:gallery_management/screens/add_ads_screen.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.045;

    return Directionality(
      textDirection: rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إدارة الإعلانات',
            style: TextStyle(
              fontFamily: mainFont,
              color: Colors.white,
              fontSize: titleFontSize.clamp(14, 18),
            ),
          ),
          backgroundColor: primaryColor,
        ),
        body: CustomScrollView(
          slivers: [
            // العنوان والوصف (يختفي عند التمرير)
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: screenWidth * 0.4,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding,
                    vertical: screenWidth * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenWidth * 0.05),
                      Text(
                        'إدارة الإعلانات',
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(18, 22),
                          fontFamily: mainFont,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'من خلال هذه اللوحة يمكنك متابعة أحدث التغيرات وإضافة مقالات وفعاليات جديدة',
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(12, 14),
                          fontFamily: mainFont,
                          color: const Color.fromARGB(255, 35, 35, 35),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth * 0.03),
                    ],
                  ),
                ),
              ),
            ),

            // مربع البحث
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: cardPadding.clamp(35, 35),
                  vertical: 3,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم المعرض',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontFamily: mainFont,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 18,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 228, 226, 226),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: mainFont,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 10),
            ),

            // قائمة الإعلانات مع فلترة حسب البحث
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getAds(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'حدث خطأ: ${snapshot.error}',
                        style: TextStyle(
                          fontFamily: mainFont,
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  );
                }

                final ads = snapshot.data!.docs.where((ad) {
                  final data = ad.data() as Map<String, dynamic>;
                  final title = data['title']?.toString().toLowerCase() ?? '';
                  return title.contains(_searchQuery);
                }).toList();

                if (ads.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'لا توجد إعلانات متاحة'
                            : 'لا توجد نتائج بحث',
                        style: TextStyle(
                          fontFamily: mainFont,
                          color: Colors.grey[600],
                          fontSize: titleFontSize,
                        ),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ad = ads[index];
                      final data = ad.data() as Map<String, dynamic>;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardPadding.clamp(35, 35),
                          vertical: screenWidth * 0.02,
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: const Color.fromARGB(255, 218, 142, 146)
                                  .withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          color: const Color.fromARGB(255, 250, 237, 237),
                          child: Padding(
                            padding: EdgeInsets.all(cardPadding.clamp(15, 25)),
                            child: Column(
                              children: [
                                Center(
                                  child: Text(
                                    data['title'] ?? 'لا يوجد عنوان',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: titleFontSize.clamp(14, 16),
                                      fontFamily: mainFont,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: screenWidth * 0.03),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: secondaryColor,
                                          size: screenWidth * 0.07),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditAdsScreen(adId: ad.id),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: screenWidth * 0.05),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: secondaryColor,
                                          size: screenWidth * 0.07),
                                      onPressed: () =>
                                          _confirmDelete(context, ad.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: ads.length,
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAdsScreen()),
            );
          },
          backgroundColor: primaryColor,
          child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.07),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String adId) async {
    final screenWidth = MediaQuery.of(context).size.width;
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
              'هل أنت متأكد من حذف هذا الإعلان؟',
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
      await _firestoreService.deleteAd(adId);
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
}
