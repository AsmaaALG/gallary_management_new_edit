import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/screens/add_ads_screen.dart';
import 'package:gallery_management/widgets/main_card.dart'; // تأكد من استيراد MainCard

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.title,
    required this.description,
    required this.cards,
    required this.addScreen, // قائمة من MainCard
  });

  final String title;
  final String description;
  final List<MainCard> cards; // قائمة MainCard
  final Widget addScreen;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.045;

    // فلترة البطاقات بناءً على البحث
    final filteredCards = widget.cards.where((card) {
      final title = card.title.toLowerCase();
      return title.contains(_searchQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 100,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding,
                    // vertical: screenWidth * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenWidth * 0.05),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(18, 22),
                          fontFamily: mainFont,
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: titleFontSize.clamp(12, 14),
                          fontFamily: mainFont,
                          color: const Color.fromARGB(255, 35, 35, 35),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    height: 60,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث',
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
            // قائمة MainCard باستخدام ListView
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    (screenWidth * 0.4 +
                        60 +
                        cardPadding * 2), // تخصيص الارتفاع
                child: ListView.builder(
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    return filteredCards[index]; // عرض MainCard
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => widget.addScreen),
            );
          },
          backgroundColor: primaryColor,
          child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.07),
        ),
      ),
    );
  }
}
