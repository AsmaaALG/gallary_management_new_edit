import 'package:flutter/material.dart';
import 'package:gallery_management/constants.dart';
import 'package:gallery_management/widgets/main_card.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.title,
    required this.description,
    required this.cards,
    required this.addScreen,
    this.galleryName,  this.requests, // نضيف اسم المعرض هنا اختياري
  });

  final String title;
  final String description;
  final List<MainCard> cards;
  final Widget addScreen;
  final Widget? requests;
  final String? galleryName;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool isWeb(BuildContext context) => MediaQuery.of(context).size.width > 600;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = screenWidth * 0.05;
    final titleFontSize = screenWidth * 0.045;

    final filteredCards = widget.cards.where((card) {
      final title = card.title.toLowerCase();
      return title.contains(_searchQuery);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: widget.galleryName != null
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = MediaQuery.of(context).size.width > 600;
                    return Text(
                      widget.galleryName!,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: mainFont,
                        fontWeight: FontWeight.normal,
                        fontSize: isWide ? 16 : 14, // حجم أكبر في الويب
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                )
              : null,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: widget.requests,)
          ],
          centerTitle: false,
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: cardPadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: titleFontSize.clamp(18, 22),
                        fontFamily: mainFont,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 500,
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
                            child: Icon(Icons.search,
                                color: Colors.grey[500], size: 18),
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 228, 226, 226),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          isDense: true,
                        ),
                        style:
                            const TextStyle(fontSize: 12, fontFamily: mainFont),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: cardPadding, vertical: 0),
                child: isWeb(context)
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth ~/ 300,
                          mainAxisExtent:
                              (screenWidth / (screenWidth ~/ 100) * 1.5),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) => filteredCards[index],
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCards.length,
                        itemBuilder: (context, index) => filteredCards[index],
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
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
