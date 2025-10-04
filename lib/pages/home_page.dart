import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shishra/components/app_drawer.dart';
import 'package:shishra/components/product_card.dart';
import 'package:shishra/firestore_service.dart';
import 'package:shishra/pages/cart_page.dart';
import 'package:shishra/pages/products_list_page.dart';
import 'package:shishra/product.dart';

class HomePageData {
  final List<HomeBanner> banners;
  final List<Category> categories;
  final List<Product> newArrivals;
  final List<Product> recentlyViewed;
  final List<GiftingGuideItem> giftingItems;

  HomePageData({
    required this.banners,
    required this.categories,
    required this.newArrivals,
    required this.recentlyViewed,
    required this.giftingItems,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  late final Future<HomePageData> _homePageDataFuture;
  late final PageController _bannerController;
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _homePageDataFuture = _loadHomePageData();
    _bannerController = PageController();
  }

  Future<HomePageData> _loadHomePageData() async {
    final results = await Future.wait([
      _firestoreService.getBanners().first,
      _firestoreService.getCategories().first,
      _firestoreService.getProducts().first,
      _firestoreService.getGiftingGuideItems().first,
    ]);

    final banners = results[0] as List<HomeBanner>;
    final categories = results[1] as List<Category>;
    final products = results[2] as List<Product>;
    final giftingItems = results[3] as List<GiftingGuideItem>;

    final newArrivals = products.where((p) => p.isNewArrival).toList();
    // Dummy logic for recently viewed
    final recentlyViewed = products.reversed.take(10).toList();

    // Start banner timer only after data is loaded
    _startBannerTimer(banners.length);

    return HomePageData(
      banners: banners,
      categories: categories,
      newArrivals: newArrivals,
      recentlyViewed: recentlyViewed,
      giftingItems: giftingItems,
    );
  }

  void _startBannerTimer(int bannerCount) {
    _bannerTimer?.cancel(); // Cancel existing timer
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentBannerPage < bannerCount - 1) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: FutureBuilder<HomePageData>(
        future: _homePageDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingUI();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final homeData = snapshot.data!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildAutoScrollingBanner(homeData.banners),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              _buildCategoryNavigation(homeData.categories),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _buildForWhomSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _buildSectionHeader('Latest New Arrivals', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductsListPage(
                            title: 'New Arrivals', category: 'New Arrivals')));
              }),
              _buildProductCarousel(homeData.newArrivals),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _buildSectionHeader('Discover by Price Range', () {}),
              _buildDiscoverByRange(),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _buildSectionHeader('Gifting Guide', () {}),
              _buildGiftingGuide(homeData.giftingItems),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
              _buildSectionHeader('Recently Viewed', () {}),
              _buildProductCarousel(homeData.recentlyViewed),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              _buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 100, color: Colors.white), // AppBar
            Container(height: 200, color: Colors.white), // Banner
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(height: 24, width: 150, color: Colors.white),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(radius: 30, backgroundColor: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      floating: true,
      pinned: true,
      elevation: 1,
      centerTitle: true,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Shishira',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          SizedBox(width: 5),
          Text('💍', style: TextStyle(fontSize: 20)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartPage()));
          },
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildAutoScrollingBanner(List<HomeBanner> banners) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(banner.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Text(
                  banner.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCategoryNavigation(List<Category> categories) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: category.iconUrl.isNotEmpty
                        ? NetworkImage(category.iconUrl)
                        : null,
                    child: category.iconUrl.isEmpty
                        ? const Icon(Icons.category, color: Colors.black)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildForWhomSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Container(
                  height: 200,
                  color: Colors.pink[100],
                  child: const Center(
                    child: Text(
                      'Women',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Container(
                  height: 200,
                  color: Colors.blue[100],
                  child: const Center(
                    child: Text(
                      'Men',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeader(String title, VoidCallback onViewAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            )
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProductCarousel(List<Product> products) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 200,
                child: ProductCard(product: products[index]),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDiscoverByRange() {
    final ranges = [
      {'label': 'Under ₹999', 'color': Colors.purple[100]},
      {'label': 'Under ₹2999', 'color': Colors.green[100]},
      {'label': 'Under ₹4999', 'color': Colors.orange[100]},
      {'label': 'Premium Gifts', 'color': Colors.red[100]},
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: ranges.length,
          itemBuilder: (context, index) {
            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                color: ranges[index]['color'] as Color?,
                child: Center(
                  child: Text(
                    ranges[index]['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildGiftingGuide(List<GiftingGuideItem> gifts) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: gifts.length,
          itemBuilder: (context, index) {
            final gift = gifts[index];
            return Container(
              width: 120,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(gift.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Text(
                  gift.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, backgroundColor: Colors.black45),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildFooter() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Text(
              'Follow us on Instagram',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '@Shishira',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined, color: Colors.white)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline, color: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }
}