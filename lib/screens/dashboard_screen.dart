import 'package:flutter/material.dart';
import 'package:gallery_management/widgets/most_visited_chart.dart';
import 'package:gallery_management/widgets/pie_chart.dart';
import 'package:gallery_management/widgets/pie_chart_legend.dart';
import 'package:gallery_management/widgets/stat_card.dart';
import 'package:gallery_management/widgets/weekly_chart.dart';
import 'package:intl/intl.dart';
import 'package:gallery_management/constants.dart';
import 'dashboard_controller.dart';

// شاشة لوحة التقارير
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController _controller =
      DashboardController(); // متحكم البيانات

  @override
  void initState() {
    super.initState();
    _loadData(); // تحميل البيانات عند بدء تشغيل الشاشة
  }

  // دالة لتحميل البيانات من المتحكم
  Future<void> _loadData() async {
    await _controller.loadData(); // استدعاء دالة تحميل البيانات
    setState(() {}); // إعادة بناء الواجهة بعد تحميل البيانات
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >
        600; // تحديد إذا كان العرض على سطح مكتب
    final cardPadding = isDesktop ? 70.0 : 10.0; // تحديد الحشو حسب نوع الشاشة
    final chartHeight = isDesktop ? 250.0 : 250.0; // تحديد ارتفاع الرسم البياني

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'لوحة التحكم',
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
          // زر لتحديث البيانات
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _loadData(); // تحميل البيانات عند الضغط
              setState(() {});
            },
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _controller.isLoading
          ? Center(
              child:
                  CircularProgressIndicator(color: primaryColor)) // مؤشر تحميل
          : _controller.errorMessage.isNotEmpty
              ? Center(
                  child:
                      Text(_controller.errorMessage)) // عرض رسالة خطأ إذا وجدت
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end, // محاذاة العناصر من اليمين
                    children: [
                      // عرض تاريخ آخر تحديث إذا كان متاحاً
                      if (_controller.lastUpdated != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25.0),
                          child: Text(
                            'آخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(_controller.lastUpdated!)}',
                            style: TextStyle(
                              fontSize: isDesktop ? 14 : 12,
                              color: Colors.grey,
                              fontFamily: mainFont,
                            ),
                            textDirection: textDirectionRTL,
                          ),
                        ),
                      // شبكة لعرض بطاقات الإحصائيات
                      GridView.count(
                        crossAxisCount: isDesktop ? 6 : 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(), // منع التمرير
                        childAspectRatio: isDesktop ? 1.9 : 1.3,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 10,
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
                      SizedBox(height: 60),
                      Text(
                        'أكثر التصنيفات زيارة',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: mainFont,
                          color: primaryColor,
                        ),
                        textDirection: textDirectionRTL, // تحديد الاتجاه
                      ),
                      SizedBox(height: 12),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                              height: chartHeight,
                              child: MostVisitedChart(context,
                                  _controller)), // رسم بياني لأكثر التصنيفات زيارة
                        ),
                      ),
                      SizedBox(height: 60),
                      Text(
                        'تحليل الطلبات المستلمة (أسبوعي)',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: mainFont,
                          color: primaryColor,
                        ),
                        textDirection: textDirectionRTL, // تحديد الاتجاه
                      ),
                      SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            height: chartHeight,
                            child: WeeklyChart(_controller
                                .weeklyData), // رسم بياني للطلبات الأسبوعية
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                      Text(
                        'نسبة الطلبات لكل تصنيف',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: mainFont,
                          color: primaryColor,
                        ),
                        textDirection: textDirectionRTL, // تحديد الاتجاه
                      ),
                      SizedBox(height: 20),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                  height: chartHeight,
                                  child: PieChartWidget(
                                      _controller)), // رسم بياني دائري
                              SizedBox(height: 16),
                              PieChartLegend(context,
                                  _controller), // وسيلة إيضاح لرسم المخطط الدائري
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                    ],
                  ),
                ),
    );
  }
}
