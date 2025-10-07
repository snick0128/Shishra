import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shishra/globals/themes.dart';
import 'package:shishra/cart_item.dart';
import 'package:shishra/product.dart';
import 'package:shishra/address.dart';
import 'package:provider/provider.dart';
import 'package:shishra/firestore_service.dart';
import 'package:shishra/order.dart' as app_order;
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Product> _products = [];
  List<app_order.Order> _orders = [];
  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<List<app_order.Order>>? _ordersSubscription;
  StreamSubscription<User?>? _authSubscription;

  AppState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _productsSubscription?.cancel();
      _userSubscription?.cancel();
      _ordersSubscription?.cancel();
      
      if (user == null) {
        _products = [];
        _clearUserData();
        notifyListeners();
      } else {
        _currentUserId = user.uid;
        _currentUserPhone = user.phoneNumber ?? '';
        
        _productsSubscription =
            _firestoreService.getProducts().listen((products) {
          // Deduplicate products by ID to prevent duplicates
          final seen = <String>{};
          _products = products.where((p) => seen.add(p.id)).toList();
          notifyListeners();
        });
        
        // Fetch orders for logged-in user
        _ordersSubscription = _firestoreService.getOrders(user.uid).listen((orders) {
          _orders = orders;
          notifyListeners();
        });
        
        // Fetch user-specific data - Direct Firestore access to avoid service issues
        _userSubscription = _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((userDoc) {
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null) {
              _updateUserDataFromFirestore(data);
            }
          }
        }, onError: (error) {
          debugPrint('Error listening to user data: $error');
        });
      }
    });
  }

  void _updateUserDataFromFirestore(Map<String, dynamic> data) {
    try {
      // Update wishlist
      if (data.containsKey('wishlist')) {
        _wishlist = Set<String>.from(data['wishlist'] ?? []);
      }
      
      // Update recently viewed
      if (data.containsKey('recentlyViewed')) {
        _recentlyViewedIds = List<String>.from(data['recentlyViewed'] ?? []);
      }
      
      // Update user name
      if (data.containsKey('name')) {
        _currentUserName = data['name'] ?? '';
      }
      
      // Update cart from Firestore
      if (data.containsKey('cart') && data['cart'] != null) {
        _cartItems.clear();
        final cartData = data['cart'] as List<dynamic>;
        for (var item in cartData) {
          final productId = item['productId'] as String;
          final quantity = item['quantity'] as int;
          final product = _products.firstWhere(
            (p) => p.id == productId,
            orElse: () => Product(
              id: '',
              name: '',
              description: '',
              category: '',
              images: [],
              price: 0,
              stock: 0,
              isNewArrival: false,
              tags: [],
              material: '',
              isAvailable: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          if (product.id.isNotEmpty) {
            _cartItems.add(CartItem(product: product, quantity: quantity));
          }
        }
      }
      
      // Update addresses from Firestore
      if (data.containsKey('addresses') && data['addresses'] != null) {
        _addresses.clear();
        final addressData = data['addresses'] as List<dynamic>;
        for (var addr in addressData) {
          _addresses.add(Address.fromMap(addr as Map<String, dynamic>));
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user data from Firestore: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _productsSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  Set<String> _wishlist = {};
  List<String> _recentlyViewedIds = [];
  final Set<String> _selectedMetals = {};
  double? _minPriceFilter;
  double? _maxPriceFilter;
  bool _trendingOnly = false;
  String _appliedCoupon = '';
  String _currentUserPhone = '';
  String _currentUserName = '';
  String _currentUserId = '';
  final List<Address> _addresses = [];
  final List<CartItem> _cartItems = [];

  // Getters
  ThemeData get theme => _theme;
  bool get isDarkTheme => _theme.brightness == Brightness.dark;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Set<String> get wishlist => _wishlist;
  List<app_order.Order> get orders => _orders;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  String get currentUserPhone => _currentUserPhone;
  String get currentUserName => _currentUserName;
  String get currentUserId => _currentUserId;
  List<Address> get addresses => _addresses;
  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).firstOrNull ??
      _addresses.firstOrNull;
  List<CartItem> get cartItems => _cartItems;
  int get cartItemCount =>
      _cartItems.fold(0, (acc, item) => acc + item.quantity);
  double get cartTotal =>
      _cartItems.fold(0, (acc, item) => acc + item.totalPrice);
  String get appliedCoupon => _appliedCoupon;

  double get couponDiscountAmount {
    final subtotal = cartTotal;
    if (_appliedCoupon.isEmpty) return 0;
    switch (_appliedCoupon.toUpperCase()) {
      case 'SHISHRA10':
        return subtotal >= 1000 ? subtotal * 0.10 : 0;
      case 'FLAT200':
        return subtotal >= 2000 ? 200 : 0;
      default:
        return 0;
    }
  }

  double get finalPayableTotal =>
      (cartTotal - couponDiscountAmount).clamp(0, double.infinity);

  bool isInWishlist(String productId) {
    return _wishlist.contains(productId);
  }

  List<Product> get products {
    List<Product> filteredProducts = _products;

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != 'All') {
      filteredProducts = filteredProducts
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_selectedMetals.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) {
        final material = p.material.toLowerCase();
        return _selectedMetals.any((m) => material.contains(m.toLowerCase()));
      }).toList();
    }

    if (_minPriceFilter != null || _maxPriceFilter != null) {
      filteredProducts = filteredProducts.where((p) {
        final price = p.price;
        final minOk = _minPriceFilter == null || price >= _minPriceFilter!;
        final maxOk = _maxPriceFilter == null || price <= _maxPriceFilter!;
        return minOk && maxOk;
      }).toList();
    }

    if (_trendingOnly) {
      filteredProducts =
          filteredProducts.where((p) => p.isBestSeller ?? false).toList();
    }

    return filteredProducts;
  }

  List<String> get categories {
    return ['All', ..._products.map((p) => p.category).toSet()];
  }

  List<Product> get recentlyViewedProducts {
    return _recentlyViewedIds
        .map((id) {
          return _products.firstWhere((p) => p.id == id,
              orElse: () => Product(
                    id: '',
                    name: '',
                    description: '',
                    category: '',
                    images: [],
                    price: 0,
                    stock: 0,
                    isNewArrival: false,
                    tags: [],
                    material: '',
                    isAvailable: false,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ));
        })
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  // Methods
  void toggleTheme() {
    _theme = isDarkTheme ? lightTheme : darkTheme;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> _updateUserField(String field, dynamic value) async {
    if (!isLoggedIn) return;
    
    try {
      await _firestore.collection('users').doc(_currentUserId).set({
        field: value,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating $field: $e');
      rethrow;
    }
  }

  Future<void> toggleWishlist(String productId) async {
    if (_wishlist.contains(productId)) {
      _wishlist.remove(productId);
    } else {
      _wishlist.add(productId);
    }
    notifyListeners();
    
    if (isLoggedIn) {
      try {
        await _updateUserField('wishlist', _wishlist.toList());
      } catch (e) {
        debugPrint('Error updating wishlist: $e');
      }
    }
  }

  Future<void> _saveCartToFirestore() async {
    if (!isLoggedIn) return;
    
    try {
      final cartData = _cartItems.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
      }).toList();
      
      await _updateUserField('cart', cartData);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  Future<void> addToCart(Product product) async {
    final existingIndex =
        _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex] = _cartItems[existingIndex]
          .copyWith(quantity: _cartItems[existingIndex].quantity + 1);
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> removeFromCart(String productId) async {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
      await _saveCartToFirestore();
    }
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _appliedCoupon = '';
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> addToRecentlyViewed(String productId) async {
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds.removeRange(10, _recentlyViewedIds.length);
    }
    
    if (isLoggedIn) {
      try {
        await _updateUserField('recentlyViewed', _recentlyViewedIds);
      } catch (e) {
        debugPrint('Error updating recently viewed: $e');
      }
    }
    notifyListeners();
  }

  // Filter setters
  void setSelectedMetals(Set<String> metals) {
    _selectedMetals
      ..clear()
      ..addAll(metals);
    notifyListeners();
  }

  void setPriceRange({double? min, double? max}) {
    _minPriceFilter = min;
    _maxPriceFilter = max;
    notifyListeners();
  }

  void setTrendingOnly(bool value) {
    _trendingOnly = value;
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedMetals.clear();
    _minPriceFilter = null;
    _maxPriceFilter = null;
    _trendingOnly = false;
    _selectedCategory = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  // Coupon handlers
  bool applyCoupon(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'SHISHRA10' || normalized == 'FLAT200') {
      _appliedCoupon = normalized;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = '';
    notifyListeners();
  }

  // Authentication methods - Simplified since auth is handled by listener
  void _clearUserData() {
    _cartItems.clear();
    _wishlist.clear();
    _orders.clear();
    _recentlyViewedIds.clear();
    _addresses.clear();
    _currentUserId = '';
    _currentUserPhone = '';
    _currentUserName = '';
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    // authStateChanges listener will handle clearing data
  }

  Future<void> updateUserName(String name) async {
    _currentUserName = name;
    notifyListeners();
    
    if (isLoggedIn) {
      try {
        await _updateUserField('name', name);
      } catch (e) {
        debugPrint('Error updating user name: $e');
      }
    }
  }

  Future<void> placeOrder(Address shippingAddress) async {
    if (!isLoggedIn) {
      throw Exception('User must be logged in to place order');
    }
    
    final order = app_order.Order(
      id: '', // Firestore will generate this
      userId: _currentUserId,
      items: _cartItems,
      total: finalPayableTotal,
      shippingAddress: shippingAddress,
      status: 'Pending',
      createdAt: DateTime.now(),
    );
    
    try {
      await _firestoreService.addOrder(order);
      await clearCart();
    } catch (e) {
      debugPrint('Error placing order: $e');
      rethrow;
    }
  }

  // Address management methods with Firestore sync
  Future<void> _saveAddressesToFirestore() async {
    if (!isLoggedIn) return;
    
    try {
      final addressData = _addresses.map((addr) => addr.toMap()).toList();
      await _updateUserField('addresses', addressData);
    } catch (e) {
      debugPrint('Error saving addresses: $e');
    }
  }

  Future<void> addAddress(Address address) async {
    _addresses.add(address);
    notifyListeners();
    await _saveAddressesToFirestore();
  }

  Future<void> updateAddress(Address updatedAddress) async {
    final index = _addresses.indexWhere((addr) => addr.id == updatedAddress.id);
    if (index >= 0) {
      _addresses[index] = updatedAddress;
      notifyListeners();
      await _saveAddressesToFirestore();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    _addresses.removeWhere((addr) => addr.id == addressId);
    notifyListeners();
    await _saveAddressesToFirestore();
  }

  Future<void> setDefaultAddress(String addressId) async {
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] =
          _addresses[i].copyWith(isDefault: _addresses[i].id == addressId);
    }
    notifyListeners();
    await _saveAddressesToFirestore();
  }
}