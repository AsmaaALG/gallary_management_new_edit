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

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _controller.loadData();
      setState(() {
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء جلب البيانات: ${e.toString()}';
      });
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirectionRTL,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'لوحة الاحصائيات',
            style: TextStyle(
              fontSize: 16,
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
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 600;
                      final isLargeScreen = constraints.maxWidth > 1200;
                      final isSmallScreen = constraints.maxWidth < 400;

                      final horizontalPadding = isLargeScreen
                          ? 60.0
                          : isDesktop
                              ? 40.0
                              : 16.0;
                      final verticalPadding = isDesktop ? 24.0 : 16.0;
                      final cardPadding = isDesktop ? 16.0 : 12.0;
                      final chartHeight = isDesktop
                          ? 280.0
                          : isSmallScreen
                              ? 200.0
                              : 240.0;
                      final sectionSpacing = isDesktop ? 40.0 : 24.0;

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_controller.lastUpdated != null)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    'آخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(_controller.lastUpdated!)}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 14 : 12,
                                      color: Colors.grey,
                                      fontFamily: mainFont,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 16),

                              // بطاقات الإحصائيات
                              GridView.count(
                                crossAxisCount: isDesktop ? 4 : 2,
                                crossAxisSpacing: 30,
                                mainAxisSpacing: 12,
                                childAspectRatio: isDesktop ? 1.0 : 1.1,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
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
                                      'الإعلانات',
                                      _controller.totalAds,
                                      Icons.ads_click,
                                      const Color.fromARGB(255, 244, 177, 7)),
                                  StatCard(
                                    'الشركات',
                                    _controller.totalCompanies,
                                    Icons.business,
                                    const Color.fromARGB(255, 244, 177, 7),
                                  ),
                                ],
                              ),

                              SizedBox(height: sectionSpacing),
                              Text(
                                'أكثر التصنيفات زيارة',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: mainFont,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: SizedBox(
                                      height: chartHeight,
                                      child: MostVisitedChart(
                                          context, _controller)),
                                ),
                              ),
                              SizedBox(height: sectionSpacing),
                              /*Text(
                                'تحليل الطلبات المستلمة (أسبوعي)',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: mainFont,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: SizedBox(
                                    height: chartHeight,
                                    child: WeeklyChart(_controller.weeklyData),
                                  ),
                                ),
                              ),
                              SizedBox(height: sectionSpacing),*/
// قسم التسجيلات الجديدة
                              SizedBox(height: sectionSpacing),
                              Text(
                                'معدل التسجيلات الجديدة (أسبوعي)',
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: mainFont,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: EdgeInsets.all(cardPadding),
                                  child: SizedBox(
                                    height: chartHeight,
                                    child: WeeklyChart(
                                        _controller.weeklyRegistrations,
                                        isRegistrations: true),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
