import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<DashboardScreen> {
  int totalGalleries = 0;
  int totalUsers = 0;
  int totalFavorites = 0;
  int totalReservations = 0;
  int pendingReservations = 0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final galleriesSnapshot =
        await FirebaseFirestore.instance.collection('2').get();
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
    final favSnapshot =
        await FirebaseFirestore.instance.collection('favorite').get();
    final resSnapshot =
        await FirebaseFirestore.instance.collection('space_form').get();
    final pendingSnapshot = await FirebaseFirestore.instance
        .collection('space_form')
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      totalGalleries = galleriesSnapshot.docs.length;
      totalUsers = usersSnapshot.docs.length;
      totalFavorites = favSnapshot.docs.length;
      totalReservations = resSnapshot.docs.length;
      pendingReservations = pendingSnapshot.docs.length;
    });
  }

  Widget buildStatCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPieChart() {
    if (totalReservations == 0) return Text("لا توجد بيانات للحجوزات");

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: pendingReservations.toDouble(),
            color: Colors.purple,
            title: 'معلّقة',
            radius: 60,
            titleStyle: TextStyle(color: Colors.white),
          ),
          PieChartSectionData(
            value: (totalReservations - pendingReservations).toDouble(),
            color: Colors.green,
            title: 'مكتملة',
            radius: 60,
            titleStyle: TextStyle(color: Colors.white),
          ),
        ],
        sectionsSpace: 4,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return Text('المعارض');
                case 1:
                  return Text('المستخدمين');
                case 2:
                  return Text('المفضلات');
                default:
                  return Text('');
              }
            },
          )),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(toY: totalGalleries.toDouble(), color: Colors.blue)
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(toY: totalUsers.toDouble(), color: Colors.teal)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(toY: totalFavorites.toDouble(), color: Colors.red)
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('لوحة التقارير'),
        backgroundColor: Colors.indigo,
      ),
      body: RefreshIndicator(
        onRefresh: fetchStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildStatCard(
                'عدد المعارض', totalGalleries, Icons.museum, Colors.blue),
            buildStatCard(
                'عدد المستخدمين', totalUsers, Icons.person, Colors.teal),
            buildStatCard(
                'عدد المفضلات', totalFavorites, Icons.favorite, Colors.red),
            buildStatCard('إجمالي الحجوزات', totalReservations, Icons.event,
                Colors.orange),
            buildStatCard('الحجوزات المعلّقة', pendingReservations,
                Icons.pending_actions, Colors.purple),
            const SizedBox(height: 24),
            Text("🔸 توزيع حالة الحجوزات",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 200, child: buildPieChart()),
            const SizedBox(height: 24),
            Text("🔸 نظرة عامة على البيانات",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 200, child: buildBarChart()),
          ],
        ),
      ),
    );
  }
}
