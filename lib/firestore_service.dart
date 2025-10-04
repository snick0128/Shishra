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
    });
  }

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<DocumentSnapshot> getUser(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Product methods
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList());
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
    await _db
        .collection('users')
        .doc(order.userId)
        .collection('orders')
        .add(order.toMap());
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