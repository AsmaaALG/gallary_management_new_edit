import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:intl/intl.dart';

class DashboardController {
  int totalGalleries = 0;
  int totalUsers = 0;
  int totalReservations = 0;
  int totalAds = 0;
  bool isLoading = false;
  String errorMessage = '';
  DateTime? lastUpdated;

  Map<String, int> categoryVisits = {};
  Map<String, int> categoryReservations = {};
  List<PieChartSectionData> pieChartSections = [];

  List<Color> categoryColors = [
    secondaryColor,
    primaryColor,
    const Color.fromARGB(255, 147, 108, 10),
    const Color.fromARGB(255, 225, 159, 161),
    const Color.fromARGB(255, 197, 180, 138),
    const Color.fromARGB(255, 62, 12, 13),
    const Color.fromARGB(255, 115, 109, 92),
    const Color.fromARGB(255, 221, 6, 13),
  ];

  List<FlSpot> weeklyData = [];

  Future<void> loadData() async {
    isLoading = true;
    errorMessage = '';

    try {
      final results = await Future.wait([
        _fetchCollectionCount('2'),
        _fetchCollectionCount('users'),
        _fetchCollectionCount('space_form'),
        _fetchCollectionCount('ads'),
      ]);

      await _fetchCategoryVisits();
      await _fetchWeeklyData();
      await _fetchCategoryReservations();

      totalGalleries = results[0]!;
      totalUsers = results[1]!;
      totalReservations = results[2]!;
      totalAds = results[3]!;
      lastUpdated = DateTime.now();
    } catch (e) {
      errorMessage = 'حدث خطأ في جلب البيانات: ${e.toString()}';
      debugPrint('خطأ في تحميل بيانات لوحة التحكم: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> _fetchWeeklyData() async {
    try {
      final now = DateTime.now();
      weeklyData.clear();

      for (int i = 0; i < 4; i++) {
        final weekStart = now.subtract(Duration(days: i * 7));
        final weekCount = await _fetchCountForWeek(weekStart);
        weeklyData.add(FlSpot(i.toDouble(), weekCount.toDouble()));
      }
    } catch (e) {
      debugPrint('خطأ في جلب البيانات الأسبوعية: $e');
    }
  }

  Future<int> _fetchCountForWeek(DateTime weekStart) async {
    final startOfWeek =
        DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endOfWeek = startOfWeek.add(Duration(days: 7));
    final snapshot = await FirebaseFirestore.instance
        .collection('space_form')
        .where('timestamp', isGreaterThan: startOfWeek, isLessThan: endOfWeek)
        .get();
    return snapshot.docs.length;
  }

  Future<int?> _fetchCollectionCount(String collectionName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .count()
          .get();
      return snapshot.count;
    } catch (e) {
      debugPrint('خطأ في جلب $collectionName: $e');
      return 0;
    }
  }

  Future<void> _fetchCategoryVisits() async {
    try {
      final tempVisits = <String, int>{};

      final categoriesSnapshot =
          await FirebaseFirestore.instance.collection('classification').get();

      for (var category in categoriesSnapshot.docs) {
        tempVisits[category['name'] as String] = 0;
      }

      final visitsSnapshot =
          await FirebaseFirestore.instance.collection('visit').get();

      for (var visit in visitsSnapshot.docs) {
        final galleryId = visit['galleryId'] as String;

        final galleryDoc = await FirebaseFirestore.instance
            .collection('2')
            .doc(galleryId)
            .get();

        if (galleryDoc.exists) {
          final classificationRef =
              galleryDoc['classification id'] as DocumentReference?;
          if (classificationRef != null) {
            final classificationDoc = await classificationRef.get();
            if (classificationDoc.exists) {
              final categoryName = classificationDoc['name'] as String;
              tempVisits[categoryName] = (tempVisits[categoryName] ?? 0) + 1;
            }
          }
        }
      }

      categoryVisits = tempVisits;
    } catch (e) {
      debugPrint('خطأ في جلب عدد زيارات التصنيفات: $e');
    }
  }

  Future<void> _fetchCategoryReservations() async {
    try {
      final tempReservations = <String, int>{};

      final categoriesSnapshot =
          await FirebaseFirestore.instance.collection('classification').get();

      for (var category in categoriesSnapshot.docs) {
        tempReservations[category['name'] as String] = 0;
      }

      final reservationsSnapshot =
          await FirebaseFirestore.instance.collection('space_form').get();

      for (var reservation in reservationsSnapshot.docs) {
        final adId = reservation['adId'] as String;

        final adDoc =
            await FirebaseFirestore.instance.collection('ads').doc(adId).get();

        if (adDoc.exists) {
          final classificationRef =
              adDoc['classification id'] as DocumentReference?;
          if (classificationRef != null) {
            final classificationDoc = await classificationRef.get();
            if (classificationDoc.exists) {
              final categoryName = classificationDoc['name'] as String;
              tempReservations[categoryName] =
                  (tempReservations[categoryName] ?? 0) + 1;
            }
          }
        }
      }

      categoryReservations = tempReservations;
      _preparePieChartData();
    } catch (e) {
      debugPrint('خطأ في جلب عدد حجوزات التصنيفات: $e');
    }
  }

  void _preparePieChartData() {
    pieChartSections.clear();
    final totalReservations =
        categoryReservations.values.fold(0, (sum, count) => sum + count);

    if (totalReservations == 0) return;

    int colorIndex = 0;
    categoryReservations.forEach((category, count) {
      if (count > 0) {
        final percentage = (count / totalReservations * 100).roundToDouble();
        pieChartSections.add(
          PieChartSectionData(
            color: categoryColors[colorIndex % categoryColors.length],
            value: percentage,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });
  }

  Map<String, double> getCategoryVisitPercentages() {
    final totalVisits =
        categoryVisits.values.fold(0, (sum, count) => sum + count);
    if (totalVisits == 0) return {};

    return categoryVisits.map((key, value) => MapEntry(
          key,
          (value / totalVisits * 100).roundToDouble(),
        ));
  }
}
