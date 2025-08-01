import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/stat_card.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GalleryStatisticsScreen extends StatefulWidget {
  final String galleryId;
  const GalleryStatisticsScreen({Key? key, required this.galleryId})
      : super(key: key);

  @override
  State<GalleryStatisticsScreen> createState() =>
      _GalleryStatisticsScreenState();
}

class _GalleryStatisticsScreenState extends State<GalleryStatisticsScreen> {
  int totalSuites = 0;
  int totalVisits = 0;
  int totalFavorites = 0;
  int totalReviews = 0;
  Map<int, int> starRatings = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  double averageRating = 0.0;
  bool isLoading = false;
  String errorMessage = '';
  List<int> weeklyVisits = List.filled(7, 0); 
  double successRate = 0.0; 
  int totalBookingRequests = 0;
  int acceptedBookingRequests = 0;
  int rejectedBookingRequests = 0;
  double acceptedBookingPercentage = 0.0;
  double rejectedBookingPercentage = 0.0;

  Future<bool> _isWingAlreadyBooked(String wingName, String galleryId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('suite')
          .where('name', isEqualTo: wingName)
          .where('gallery id', isEqualTo: galleryId)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking wing status: $e');
      return false;
    }
  }

  Future<void> _loadBookingStatistics() async {
    try {
      final requests = await FirebaseFirestore.instance
          .collection('space_form')
          .where('adId', isEqualTo: widget.galleryId)
          .get();

      setState(() async {
        totalBookingRequests = requests.docs.length;
        acceptedBookingRequests = 0;
        rejectedBookingRequests = 0;

        for (var doc in requests.docs) {
          final wingName = doc['wingName'];
          final isAlreadyBooked =
              await _isWingAlreadyBooked(wingName, widget.galleryId);

          if (isAlreadyBooked) {
            rejectedBookingRequests++;
          } else {
            acceptedBookingRequests++;
          }
        }

        acceptedBookingPercentage = totalBookingRequests > 0
            ? (acceptedBookingRequests / totalBookingRequests * 100)
            : 0.0;
        rejectedBookingPercentage = totalBookingRequests > 0
            ? (rejectedBookingRequests / totalBookingRequests * 100)
            : 0.0;
      });
    } catch (e) {
      debugPrint('Error loading booking statistics: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGalleryStatistics();
    _loadBookingStatistics();
  }

  Future<void> _loadGalleryStatistics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final suiteCount = await _fetchSuitesCount();
      final visitsCount = await _fetchVisitsCount();
      final favoritesCount = await _fetchpartnersCount();
      final reviewsCount = await _fetchReviewsCount();
      final ratings = await _fetchStarRatings();

      final totalStars =
          ratings.entries.map((e) => e.key * e.value).fold(0, (a, b) => a + b);
      final totalCounts = ratings.values.fold(0, (a, b) => a + b);

      setState(() {
        totalSuites = suiteCount!;
        totalVisits = visitsCount!;
        totalFavorites = favoritesCount!;
        totalReviews = reviewsCount!;
        starRatings = ratings;
        averageRating = totalCounts > 0 ? totalStars / totalCounts : 0.0;
        successRate = _calculateSuccessRate(
            totalVisits: totalVisits, averageRating: averageRating);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ في جلب البيانات: ${e.toString()}';
      });
      debugPrint('خطأ في تحميل إحصائيات المعرض: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateSuccessRate({
    required int totalVisits,
    required double averageRating,
  }) {
    const double visitsWeight = 0.5;
    const double ratingWeight = 0.5;

    const int maxVisits = 200;

    double visitsScore = (totalVisits / maxVisits) * 100;
    visitsScore = visitsScore.clamp(0, 100);

    double ratingScore = (averageRating / 5.0) * 100;
    ratingScore = ratingScore.clamp(0, 100);

    double successRate =
        (visitsScore * visitsWeight) + (ratingScore * ratingWeight);

    return successRate.clamp(0, 100);
  }

  Future<int?> _fetchSuitesCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('suite')
        .where('gallery id', isEqualTo: widget.galleryId)
        .count()
        .get();
    return snapshot.count;
  }

  Future<int?> _fetchVisitsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('visit')
        .where('galleryId', isEqualTo: widget.galleryId)
        .count()
        .get();
    return snapshot.count;
  }

  Future<int?> _fetchpartnersCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('partners')
        .where('gallery id', isEqualTo: widget.galleryId)
        .count()
        .get();
    return snapshot.count;
  }

  Future<int?> _fetchReviewsCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('gallery id', isEqualTo: widget.galleryId)
        .count()
        .get();
    return snapshot.count;
  }

  Future<Map<int, int>> _fetchStarRatings() async {
    final ratings = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('gallery id', isEqualTo: widget.galleryId)
        .get();

    for (var doc in snapshot.docs) {
      final stars = doc['number of stars'];
      if (stars is int || stars is double) {
        final intStars = (stars as num).round();
        if (intStars >= 1 && intStars <= 5) {
          ratings[intStars] = (ratings[intStars] ?? 0) + 1;
        }
      }
    }

    return ratings;
  }

  List<PieChartSectionData> _prepareStarRatingChartData() {
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.lightGreen,
      Colors.green
    ];

    int totalRatings = starRatings.values.fold(0, (sum, count) => sum + count);
    if (totalRatings == 0) return sections;

    starRatings.forEach((stars, count) {
      if (count > 0) {
        final percentage = (count / totalRatings * 100);
        sections.add(
          PieChartSectionData(
            color: colors[stars - 1],
            value: percentage,
            title: '$stars نجوم\n${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );
      }
    });

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final chartHeight = isDesktop ? 250.0 : 200.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إحصائيات المعرض',
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              fontFamily: mainFont,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadGalleryStatistics,
              tooltip: 'تحديث البيانات',
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            Container(
                              width: isWide
                                  ? constraints.maxWidth / 2 - 30
                                  : double.infinity,
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                childAspectRatio: isWide ? 1.9 : 1.3,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 10,
                                padding: EdgeInsets.zero,
                                children: [
                                  StatCard('عدد الأجنحة', totalSuites,
                                      Icons.room_preferences, Colors.amber),
                                  StatCard('عدد الزيارات', totalVisits,
                                      Icons.people, Colors.amber),
                                  StatCard('عدد الشركاء', totalFavorites,
                                      Icons.diversity_3, Colors.amber),
                                  StatCard('عدد المقيمين', totalReviews,
                                      Icons.star, Colors.amber),
                                ],
                              ),
                            ),
                            Container(
                              width: isWide
                                  ? constraints.maxWidth / 2 - 30
                                  : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نسبة نجاح المعرض',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 18 : 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: mainFont,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Container(
                                    height: 250,
                                    child: SfRadialGauge(
                                      axes: <RadialAxis>[
                                        RadialAxis(
                                          minimum: 0,
                                          maximum: 100,
                                          showLabels: false,
                                          showTicks: false,
                                          startAngle: 180,
                                          endAngle: 0,
                                          radiusFactor: 0.8,
                                          axisLineStyle: AxisLineStyle(
                                            thickness: 0.2,
                                            color: Colors.grey.shade300,
                                            thicknessUnit: GaugeSizeUnit.factor,
                                          ),
                                          pointers: <GaugePointer>[
                                            RangePointer(
                                              value: successRate,
                                              width: 0.2,
                                              color: const Color.fromARGB(
                                                  255, 171, 15, 4),
                                              cornerStyle:
                                                  CornerStyle.bothCurve,
                                              sizeUnit: GaugeSizeUnit.factor,
                                            ),
                                          ],
                                          annotations: <GaugeAnnotation>[
                                            GaugeAnnotation(
                                              angle: 10,
                                              positionFactor: 0.0,
                                              widget: Text(
                                                '${successRate.toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Container(
                            //   width: isWide
                            //       ? constraints.maxWidth / 2 - 30
                            //       : double.infinity,
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text(
                            //         'إحصائيات طلبات الحجز',
                            //         style: TextStyle(
                            //           fontSize: isDesktop ? 18 : 15,
                            //           fontWeight: FontWeight.bold,
                            //           fontFamily: mainFont,
                            //           color: primaryColor,
                            //         ),
                            //       ),
                            //       SizedBox(height: 20),
                            //       Container(
                            //         padding: const EdgeInsets.all(16),
                            //         decoration: BoxDecoration(
                            //           color: const Color.fromARGB(
                            //               255, 255, 255, 255),
                            //           borderRadius: BorderRadius.circular(12),
                            //         ),
                            //         child: Column(
                            //           children: [
                            //             const SizedBox(height: 16),
                            //             Row(
                            //               mainAxisAlignment:
                            //                   MainAxisAlignment.spaceEvenly,
                            //               children: [
                            //                 Column(
                            //                   children: [
                            //                     Text(
                            //                       ' مقبولة',
                            //                       style: TextStyle(
                            //                         fontSize: 14,
                            //                         fontFamily: mainFont,
                            //                         color: Colors.grey[700],
                            //                       ),
                            //                     ),
                            //                     const SizedBox(height: 8),
                            //                     Text(
                            //                       '${rejectedBookingPercentage.toStringAsFixed(0)}%',
                            //                       style: const TextStyle(
                            //                         fontSize: 24,
                            //                         fontFamily: mainFont,
                            //                         fontWeight: FontWeight.bold,
                            //                         color: Colors.green,
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //                 Column(
                            //                   children: [
                            //                     Text(
                            //                       'غير مقبولة',
                            //                       style: TextStyle(
                            //                         fontSize: 14,
                            //                         fontFamily: mainFont,
                            //                         color: Colors.grey[700],
                            //                       ),
                            //                     ),
                            //                     const SizedBox(height: 8),
                            //                     Text(
                            //                       '${acceptedBookingPercentage.toStringAsFixed(0)}%',
                            //                       style: const TextStyle(
                            //                         fontSize: 24,
                            //                         fontFamily: mainFont,
                            //                         fontWeight: FontWeight.bold,
                            //                         color: Color.fromARGB(
                            //                             255, 112, 112, 112),
                            //                       ),
                            //                     ),
                            //                   ],
                            //                 ),
                            //               ],
                            //             ),
                            //             const SizedBox(height: 16),
                            //             SizedBox(
                            //               height: 20,
                            //               child: Row(
                            //                 children: [
                            //                   Expanded(
                            //                     flex: rejectedBookingPercentage
                            //                         .round(),
                            //                     child: Container(
                            //                       decoration:
                            //                           const BoxDecoration(
                            //                               color: Colors.green),
                            //                     ),
                            //                   ),
                            //                   Expanded(
                            //                     flex: acceptedBookingPercentage
                            //                         .round(),
                            //                     child: Container(
                            //                       decoration:
                            //                           const BoxDecoration(
                            //                         color: Color.fromARGB(
                            //                             255, 212, 210, 210),
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Container(
                              width: isWide
                                  ? constraints.maxWidth / 2 - 30
                                  : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'توزيع التقييمات',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 18 : 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: mainFont,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              averageRating.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'متوسط\nالتقييمات',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: mainFont,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            children: List.generate(5, (index) {
                                              final star = 5 - index;
                                              final count =
                                                  starRatings[star] ?? 0;
                                              final total = starRatings.values
                                                  .fold(0, (a, b) => a + b);
                                              final percent = total > 0
                                                  ? count / total
                                                  : 0.0;

                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 3),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      star.toString(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily: mainFont,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6),
                                                    Expanded(
                                                      child: Stack(
                                                        children: [
                                                          Container(
                                                            height: 12,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.grey
                                                                  .shade300,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          FractionallySizedBox(
                                                            widthFactor:
                                                                percent,
                                                            child: Container(
                                                              height: 12,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .amber,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
