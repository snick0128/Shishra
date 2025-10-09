import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/product.dart';
import 'package:shishra/order.dart' as app_order;

// Data Models for Homepage Content
class HomeBanner {
  final String imageUrl;
  final String label;
  final String target;

  HomeBanner({required this.imageUrl, required this.label, required this.target});

  factory HomeBanner.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeBanner(
      imageUrl: data['imageUrl'] ?? '',
      label: data['label'] ?? '',
      target: data['target'] ?? '',
    );
  }
}

class Category {
  final String name;
  final String iconUrl;

  Category({required this.name, required this.iconUrl});

  factory Category.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      name: data['name'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
    );
  }
}

class GiftingGuideItem {
  final String name;
  final String imageUrl;

  GiftingGuideItem({required this.name, required this.imageUrl});

  factory GiftingGuideItem.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftingGuideItem(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class ForWhomItem {
  final String name;
  final String imageUrl;

  ForWhomItem({required this.name, required this.imageUrl});

  factory ForWhomItem.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForWhomItem(
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class PriceRangeItem {
  final String label;
  final String imageUrl;

  PriceRangeItem({required this.label, required this.imageUrl});

  factory PriceRangeItem.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceRangeItem(
      label: data['label'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class DynamicSection {
  final String title;
  final String type; // 'gift_guide', 'occasion', 'price_range', 'material', 'style'
  final List<CategoryItem> items;
  final int productCount;

  DynamicSection({
    required this.title,
    required this.type,
    required this.items,
    required this.productCount,
  });
}

class CategoryItem {
  final String name;
  final String imageUrl;
  final int productCount;

  CategoryItem({
    required this.name,
    required this.imageUrl,
    required this.productCount,
  });
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User methods
  Future<void> createUser({
    required String uid,
    required String phone,
    required String name,
    required String dob,
    required String gender,
    String? email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'phone': phone,
      'name': name,
      'dob': dob,
      'gender': gender,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'wishlist': [],
      'addresses': [],
      'orders': [],
      'totalOrders': 0,
      'totalSpent': 0,
      'isBlocked': false,
    });
  }

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Get all users as stream of document snapshots
  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _db.collection('users').snapshots();
  }
  
  // Get all users as a future
  Future<List<Map<String, dynamic>>> getUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // Product methods
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList());
  }

  // Get new arrivals (products added in last 7 days)
  Future<List<Product>> getNewArrivals() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _db
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      
      // Filter in memory to avoid complex Firestore queries
      return products.where((p) => 
          p.isAvailable && 
          p.createdAt.isAfter(sevenDaysAgo)
      ).take(20).toList();
    } catch (e) {
      print('Error getting new arrivals: $e');
      return [];
    }
  }

  // Get products for women (jewelry typically worn by women)
  Future<List<Product>> getForHer() async {
    try {
      final womenCategories = ['Necklaces', 'Earrings', 'Bracelets', 'Anklets', 'For Women'];
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      return products.where((p) => 
          p.isAvailable &&
          (womenCategories.any((cat) => p.category.contains(cat)) ||
           p.tags.any((tag) => ['women', 'her', 'female'].contains(tag.toLowerCase())))
      ).take(15).toList();
    } catch (e) {
      print('Error getting products for her: $e');
      return [];
    }
  }

  // Get products for men
  Future<List<Product>> getForHim() async {
    try {
      final menCategories = ['Rings', 'Chains', 'Bracelets', 'For Men'];
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      return products.where((p) => 
          p.isAvailable &&
          (menCategories.any((cat) => p.category.contains(cat)) ||
           p.tags.any((tag) => ['men', 'him', 'male'].contains(tag.toLowerCase())))
      ).take(15).toList();
    } catch (e) {
      print('Error getting products for him: $e');
      return [];
    }
  }

  // Get trending products (most viewed/popular)
  Future<List<Product>> getTrendingProducts() async {
    try {
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      return products.where((p) => 
          p.isAvailable && (p.isBestSeller ?? false)
      ).take(15).toList();
    } catch (e) {
      print('Error getting trending products: $e');
      return [];
    }
  }

  // Get best sellers
  Future<List<Product>> getBestSellers() async {
    try {
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      final bestSellers = products.where((p) => 
          p.isAvailable && (p.isBestSeller ?? false)
      ).toList();
      
      // Sort by price (affordable first)
      bestSellers.sort((a, b) => a.price.compareTo(b.price));
      return bestSellers.take(15).toList();
    } catch (e) {
      print('Error getting best sellers: $e');
      return [];
    }
  }

  // Get featured collections
  Future<List<Product>> getFeaturedCollection() async {
    try {
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      final availableProducts = products.where((p) => p.isAvailable).toList();
      
      // Sort by price (premium first)
      availableProducts.sort((a, b) => b.price.compareTo(a.price));
      return availableProducts.take(12).toList();
    } catch (e) {
      print('Error getting featured collection: $e');
      return [];
    }
  }

  // Get affordable picks (under certain price)
  Future<List<Product>> getAffordablePicks({double maxPrice = 999.0}) async {
    try {
      final snapshot = await _db
          .collection('products')
          .limit(50)
          .get();
      
      final products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      final affordableProducts = products.where((p) => 
          p.isAvailable && p.price <= maxPrice
      ).toList();
      
      // Sort by price (cheapest first)
      affordableProducts.sort((a, b) => a.price.compareTo(b.price));
      return affordableProducts.take(15).toList();
    } catch (e) {
      print('Error getting affordable picks: $e');
      return [];
    }
  }

  // Homepage content methods
  Stream<List<HomeBanner>> getBanners() {
    return _db.collection('banners').orderBy('priority').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => HomeBanner.fromSnapshot(doc)).toList());
  }

  Stream<List<Category>> getCategories() {
    return _db.collection('categories').orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Category.fromSnapshot(doc)).toList());
  }

  Stream<List<GiftingGuideItem>> getGiftingGuideItems() {
    return _db.collection('gifting_guide').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GiftingGuideItem.fromSnapshot(doc)).toList());
  }

  Stream<List<ForWhomItem>> getForWhomItems() {
    return _db.collection('for_whom').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ForWhomItem.fromSnapshot(doc)).toList());
  }

  Stream<List<PriceRangeItem>> getPriceRangeItems() {
    return _db.collection('price_ranges').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PriceRangeItem.fromSnapshot(doc)).toList());
  }

  // Dynamic sections based on actual data
  Future<List<DynamicSection>> getDynamicSections() async {
    final List<DynamicSection> sections = [];
    
    try {
      // Get all categories
      final categoriesSnapshot = await _db.collection('categories').get();
      final categories = categoriesSnapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      
      // Get all products to count by category
      final productsSnapshot = await _db.collection('products').get();
      final products = productsSnapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
      
      // Group categories by type
      final Map<String, List<String>> categoryGroups = {
        'Gift Guide': [],
        'Occasions': [],
        'Price Ranges': [],
        'Materials': [],
        'Styles': [],
        'Product Types': [],
      };
      
      // Categorize based on category names
      for (final category in categories) {
        if (category.startsWith('For ')) {
          categoryGroups['Gift Guide']!.add(category);
        } else if (['Wedding', 'Engagement', 'Anniversary', 'Birthday', 'Festival', 'Party', 'Daily Wear', 'Office Wear'].contains(category)) {
          categoryGroups['Occasions']!.add(category);
        } else if (category.startsWith('Under ₹') || category.contains('Collection')) {
          categoryGroups['Price Ranges']!.add(category);
        } else if (['Gold', 'Silver', 'Diamond', 'Platinum', 'Rose Gold', 'Artificial'].contains(category)) {
          categoryGroups['Materials']!.add(category);
        } else if (['Traditional', 'Modern', 'Vintage', 'Contemporary', 'Ethnic', 'Western'].contains(category)) {
          categoryGroups['Styles']!.add(category);
        } else {
          categoryGroups['Product Types']!.add(category);
        }
      }
      
      // Create sections only for groups that have categories with products
      for (final entry in categoryGroups.entries) {
        if (entry.value.isEmpty) continue;
        
        final List<CategoryItem> items = [];
        int totalProductCount = 0;
        
        for (final categoryName in entry.value) {
          final categoryProducts = products.where((p) => p.category == categoryName).length;
          if (categoryProducts > 0) {
            items.add(CategoryItem(
              name: categoryName,
              imageUrl: _getDefaultImageForCategory(categoryName),
              productCount: categoryProducts,
            ));
            totalProductCount += categoryProducts;
          }
        }
        
        // Only add section if it has items with products
        if (items.isNotEmpty) {
          sections.add(DynamicSection(
            title: entry.key,
            type: _getSectionType(entry.key),
            items: items,
            productCount: totalProductCount,
          ));
        }
      }
      
      return sections;
    } catch (e) {
      print('Error getting dynamic sections: $e');
      return [];
    }
  }
  
  String _getSectionType(String title) {
    switch (title) {
      case 'Gift Guide': return 'gift_guide';
      case 'Occasions': return 'occasion';
      case 'Price Ranges': return 'price_range';
      case 'Materials': return 'material';
      case 'Styles': return 'style';
      case 'Product Types': return 'product_type';
      default: return 'other';
    }
  }
  
  String _getDefaultImageForCategory(String categoryName) {
    // Return appropriate placeholder images based on category
    if (categoryName.startsWith('For ')) {
      return 'https://source.unsplash.com/random/200x200?gifts,${categoryName.replaceAll('For ', '').toLowerCase()}';
    } else if (categoryName.startsWith('Under ₹')) {
      return 'https://source.unsplash.com/random/200x200?jewelry,affordable';
    } else if (categoryName.contains('Collection')) {
      return 'https://source.unsplash.com/random/200x200?jewelry,premium';
    } else {
      return 'https://source.unsplash.com/random/200x200?jewelry,${categoryName.toLowerCase()}';
    }
  }

  // Order methods
  Stream<List<app_order.Order>> getOrders(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('orders')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_order.Order.fromSnapshot(doc))
            .toList());
  }

  Future<void> addOrder(app_order.Order order) async {
    // Add order to user's subcollection
    await _db
        .collection('users')
        .doc(order.userId)
        .collection('orders')
        .add(order.toMap());
    
    // Update user's total orders and total spent
    await _db.collection('users').doc(order.userId).update({
      'totalOrders': FieldValue.increment(1),
      'totalSpent': FieldValue.increment(order.total),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Data seeding method
  Future<void> seedInitialDatabase() async {
    final productsCollection = _db.collection('products');
    final bannersCollection = _db.collection('banners');
    final categoriesCollection = _db.collection('categories');
    final giftingGuideCollection = _db.collection('gifting_guide');
    final forWhomCollection = _db.collection('for_whom');
    final priceRangesCollection = _db.collection('price_ranges');

    // Check if products collection is empty to decide on seeding
    final productsSnapshot = await productsCollection.limit(1).get();
    if (productsSnapshot.docs.isNotEmpty) {
      // print('Database is not empty. Skipping seeding.');
      return;
    }

    // print('Database is empty. Seeding data...');
    final batch = _db.batch();
    final random = Random();

    // Seed Products
    final productCategories = ['Rings', 'Pendants', 'Bracelets', 'Earrings', 'Necklaces'];
    for (final category in productCategories) {
      for (int i = 1; i <= 10; i++) {
        final docRef = productsCollection.doc();
        final price = (random.nextDouble() * 5000) + 500;
        final oldPrice = price * (1 + (random.nextDouble() * 0.5) + 0.1);
        final product = Product(
          id: docRef.id,
          name: '$category Name $i',
          description: 'This is a beautiful $category, crafted with 92.5 Sterling Silver. Perfect for any occasion, from everyday wear to special events. A great gift for your loved ones.',
          category: category,
          subCategory: random.nextBool() ? 'Women' : 'Men',
          images: [
            'https://source.unsplash.com/random/600x600?jewelry,$category,$i',
            'https://source.unsplash.com/random/600x600?jewelry,$category,alt,$i',
          ],
          price: price,
          oldPrice: oldPrice,
          stock: random.nextInt(50) + 10,
          isNewArrival: random.nextBool(),
          isBestSeller: random.nextBool(),
          tags: ['gift', 'silver', category.toLowerCase()],
          material: '92.5 Sterling Silver',
          size: 'Free Size',
          weight: random.nextDouble() * 20 + 5,
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        batch.set(docRef, product.toMap());
      }
    }

    // Seed Banners
    final banners = [
      {
        'imageUrl': 'https://source.unsplash.com/random/800x400?jewelry,festive',
        'label': 'New Festive Collection',
        'target': '/category/Festive',
        'priority': 1
      },
      {
        'imageUrl': 'https://source.unsplash.com/random/800x400?jewelry,silver',
        'label': 'Silver Everyday Wear',
        'target': '/category/Everyday',
        'priority': 2
      },
      {
        'imageUrl': 'https://source.unsplash.com/random/800x400?jewelry,gifts',
        'label': 'Premium Gifts',
        'target': '/category/Gifts',
        'priority': 3
      },
    ];
    for (var data in banners) {
      final docRef = bannersCollection.doc();
      batch.set(docRef, data);
    }

    // Seed Categories (using product categories for consistency)
    for (var categoryName in productCategories) {
      final docRef = categoriesCollection.doc(categoryName);
      batch.set(docRef, {'name': categoryName, 'iconUrl': ''}); // Icon URLs can be added manually later
    }

    // Seed Gifting Guide
    final giftingGuide = [
      {'name': 'Mom', 'imageUrl': 'https://source.unsplash.com/random/200x200?gifts,mom'},
      {'name': 'Sister', 'imageUrl': 'https://source.unsplash.com/random/200x200?gifts,sister'},
      {'name': 'Husband & Wife', 'imageUrl': 'https://source.unsplash.com/random/200x200?gifts,couple'},
      {'name': 'Men', 'imageUrl': 'https://source.unsplash.com/random/200x200?gifts,men'},
      {'name': 'Friends', 'imageUrl': 'https://source.unsplash.com/random/200x200?gifts,friends'},
    ];
    for (var data in giftingGuide) {
      final docRef = giftingGuideCollection.doc(data['name']);
      batch.set(docRef, data);
    }

    // Seed For Whom
    final forWhom = [
      {'name': 'Women', 'imageUrl': 'https://source.unsplash.com/random/400x300?jewelry,women'},
      {'name': 'Men', 'imageUrl': 'https://source.unsplash.com/random/400x300?jewelry,men'},
    ];
    for (var data in forWhom) {
      final docRef = forWhomCollection.doc(data['name']);
      batch.set(docRef, data);
    }

    // Seed Price Ranges
    final priceRanges = [
      {'label': 'Under ₹999', 'imageUrl': 'https://source.unsplash.com/random/300x200?jewelry,cheap'},
      {'label': 'Under ₹2999', 'imageUrl': 'https://source.unsplash.com/random/300x200?jewelry,affordable'},
      {'label': 'Under ₹4999', 'imageUrl': 'https://source.unsplash.com/random/300x200?jewelry,midrange'},
      {'label': 'Premium Gifts', 'imageUrl': 'https://source.unsplash.com/random/300x200?jewelry,premium'},
    ];
    for (var data in priceRanges) {
      final docRef = priceRangesCollection.doc(data['label']);
      batch.set(docRef, data);
    }

    await batch.commit();
    // print('Finished seeding database.');
  }
}