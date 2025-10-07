import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shishra/components/app_drawer.dart';
import 'package:shishra/components/product_card.dart';
import 'package:shishra/firestore_service.dart';
import 'package:shishra/pages/cart_page.dart';
import 'package:shishra/pages/products_list_page.dart';
import 'package:shishra/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get(),
      _firestoreService.getGiftingGuideItems().first,
    ]);

    final banners = results[0] as List<HomeBanner>;
    final categories = results[1] as List<Category>;
    final productsSnapshot = results[2] as QuerySnapshot;
    final products =
        productsSnapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
    final giftingItems = results[3] as List<GiftingGuideItem>;

    final availableProducts = products.where((p) => p.stock > 0).toList();
    final newArrivals = availableProducts.where((p) => p.isNewArrival).toList();
    final recentlyViewed = availableProducts.take(10).toList();

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
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final homeData = snapshot.data!;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildAutoScrollingBanner(homeData.banners),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildCategoryNavigation(homeData.categories),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              _buildForWhomSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              _buildSectionHeader('New Arrivals', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductsListPage(
                            title: 'New Arrivals')));
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildProductCarousel(homeData.newArrivals),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              _buildSectionHeader('Shop by Price', () {}),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildDiscoverByRange(),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              _buildSectionHeader('Gift Guide', () {}),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildGiftingGuide(homeData.giftingItems),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              _buildSectionHeader('Recently Viewed', () {}),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _buildProductCarousel(homeData.recentlyViewed),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(height: 24, width: 150, color: Colors.white),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      CircleAvatar(radius: 30, backgroundColor: Colors.white),
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
      snap: true,
      elevation: 0,
      surfaceTintColor: Colors.white,
      centerTitle: true,
      title: const Text(
        'SHISHRA',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          letterSpacing: 3,
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 24),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black, size: 24),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 24),
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const CartPage()));
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAutoScrollingBanner(List<HomeBanner> banners) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        child: PageView.builder(
          controller: _bannerController,
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade200, Colors.grey.shade300],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.diamond_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        banner.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
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
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              width: 85,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: category.iconUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              category.iconUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.diamond_outlined,
                                color: Colors.grey.shade600,
                                size: 32,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.diamond_outlined,
                            color: Colors.grey.shade600,
                            size: 32,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsListPage(
                        title: 'Women\'s Collection',
                        gender: 'Women',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade300, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 120,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Women',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Explore Collection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductsListPage(
                        title: 'Men\'s Collection',
                        gender: 'Men',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.cyan.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.diamond_outlined,
                          size: 120,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Men',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Explore Collection',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                letterSpacing: 0.3,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProductCarousel(List<Product> products) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.diamond_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No products available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 320,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return Container(
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              child: ProductCard(product: products[index]),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildDiscoverByRange() {
    final ranges = [
      {'label': 'Under ₹999', 'gradient': [Colors.purple.shade300, Colors.purple.shade500], 'icon': Icons.attach_money},
      {'label': 'Under ₹2999', 'gradient': [Colors.green.shade300, Colors.green.shade500], 'icon': Icons.card_giftcard},
      {'label': 'Under ₹4999', 'gradient': [Colors.orange.shade300, Colors.orange.shade500], 'icon': Icons.star},
      {'label': 'Premium Gifts', 'gradient': [Colors.red.shade300, Colors.red.shade500], 'icon': Icons.diamond},
    ];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
          ),
          itemCount: ranges.length,
          itemBuilder: (context, index) {
            final range = ranges[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: range['gradient'] as List<Color>,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (range['gradient'] as List<Color>)[0].withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          range['icon'] as IconData,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          range['label'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: gifts.length,
          itemBuilder: (context, index) {
            final gift = gifts[index];
            return Container(
              width: 130,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              gift.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.primaries[index % Colors.primaries.length].shade300,
                                      Colors.primaries[index % Colors.primaries.length].shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gift.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 13,
                    ),
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
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white)),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
