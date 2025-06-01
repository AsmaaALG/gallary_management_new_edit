import 'package:flutter/material.dart';
import 'package:gallery_management/widgets/most_visited_chart.dart';
import 'package:gallery_management/widgets/pie_chart.dart';
import 'package:gallery_management/widgets/pie_chart_legend.dart';
import 'package:gallery_management/widgets/stat_card.dart';
import 'package:gallery_management/widgets/weekly_chart.dart';
import 'package:intl/intl.dart';
import 'package:gallery_management/constants.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller = DashboardController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 600;
    final isLargeScreen = mediaQuery.size.width > 1200;

    final horizontalPadding = isLargeScreen
        ? 120.0
        : isDesktop
            ? 80.0
            : 20.0;
    final verticalPadding = isDesktop ? 40.0 : 20.0;
    final cardPadding = isDesktop ? 24.0 : 16.0;
    final chartHeight = isDesktop ? 300.0 : 250.0;
    final sectionSpacing = isDesktop ? 80.0 : 60.0;

    return Directionality(
        textDirection: textDirectionRTL, // هذا السطر هو الأهم لتطبيق RTL
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'لوحة الاحصائيات ',
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
                onPressed: _loadData,
                tooltip: 'تحديث البيانات',
              ),
            ],
          ),
          body: _controller.isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _controller.errorMessage.isNotEmpty
                  ? Center(child: Text(_controller.errorMessage))
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_controller.lastUpdated != null)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: isDesktop ? 30.0 : 25.0),
                              child: Text(
                                'آخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(_controller.lastUpdated!)}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 15 : 13,
                                  color: Colors.grey,
                                  fontFamily: mainFont,
                                ),
                                textDirection: textDirectionRTL,
                              ),
                            ),
                          SizedBox(height: isDesktop ? 40 : 20),

                          // الشبكة الديناميكية لبطاقات الإحصائيات
                          GridView.count(
                            crossAxisCount: isDesktop
                                ? 4
                                : 2, // 4 في الديسكتوب، 2 في الهاتف
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isDesktop ? 1.0 : 1.2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            children: [
                              StatCard(
                                  'المعارض',
                                  _controller.totalGalleries,
                                  Icons.museum,
                                  const Color.fromARGB(255, 244, 177, 7)),
                              StatCard(
                                  'المستخدمين',
                                  _controller.totalUsers,
                                  Icons.people,
                                  const Color.fromARGB(255, 244, 177, 7)),
                              StatCard(
                                  'الحجوزات',
                                  _controller.totalReservations,
                                  Icons.event,
                                  const Color.fromARGB(255, 244, 177, 7)),
                              StatCard(
                                  'الإعلانات',
                                  _controller.totalAds,
                                  Icons.ads_click,
                                  const Color.fromARGB(255, 244, 177, 7)),
                            ],
                          ),

                          SizedBox(height: sectionSpacing),
                          Text(
                            'أكثر التصنيفات زيارة',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: mainFont,
                              color: primaryColor,
                            ),
                            textDirection: textDirectionRTL,
                          ),
                          SizedBox(height: isDesktop ? 20 : 12),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: SizedBox(
                                  height: chartHeight,
                                  child:
                                      MostVisitedChart(context, _controller)),
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                          Text(
                            'تحليل الطلبات المستلمة (أسبوعي)',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: mainFont,
                              color: primaryColor,
                            ),
                            textDirection: textDirectionRTL,
                          ),
                          SizedBox(height: isDesktop ? 20 : 12),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: SizedBox(
                                height: chartHeight,
                                child: WeeklyChart(_controller.weeklyData),
                              ),
                            ),
                          ),
                          SizedBox(height: sectionSpacing),
                          Text(
                            'نسبة الطلبات لكل تصنيف',
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: mainFont,
                              color: primaryColor,
                            ),
                            textDirection: textDirectionRTL,
                          ),
                          SizedBox(height: isDesktop ? 20 : 12),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                children: [
                                  SizedBox(
                                      height: chartHeight,
                                      child: PieChartWidget(_controller)),
                                  SizedBox(height: isDesktop ? 20 : 16),
                                  PieChartLegend(context, _controller),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 40 : 25),
                        ],
                      ),
                    ),
        ));
  }
}
