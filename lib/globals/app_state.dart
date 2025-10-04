
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
  List<Product> _products = [];
  List<app_order.Order> _orders = [];
  StreamSubscription<List<Product>>? _productsSubscription;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _productsSubscription?.cancel();
      if (user == null) {
        _products = [];
        notifyListeners();
      } else {
        _productsSubscription = _firestoreService.getProducts().listen((products) {
          _products = products;
          notifyListeners();
        });
        // Fetch orders for logged-in user
        _firestoreService.getOrders(user.uid).listen((orders) {
          _orders = orders;
          notifyListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _wishlist = {};
  final List<String> _recentlyViewedIds = [];
  final Set<String> _selectedMetals = {};
  double? _minPriceFilter;
  double? _maxPriceFilter;
  bool _trendingOnly = false;
  String _appliedCoupon = '';
  bool _isLoggedIn = false;
  String _currentUserPhone = '';
  String _currentUserName = '';
  String _currentUserId = '';
  final List<Address> _addresses = []; // Should be fetched from Firestore for production
  final List<CartItem> _cartItems = [];

  // Getters
  ThemeData get theme => _theme;
  bool get isDarkTheme => _theme.brightness == Brightness.dark;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  Set<String> get wishlist => _wishlist;
  List<app_order.Order> get orders => _orders;
  bool get isLoggedIn => _isLoggedIn;
  String get currentUserPhone => _currentUserPhone;
  String get currentUserName => _currentUserName;
  List<Address> get addresses => _addresses;
  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).firstOrNull ??
      _addresses.firstOrNull;
  List<CartItem> get cartItems => _cartItems;
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
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

  double get finalPayableTotal => (cartTotal - couponDiscountAmount).clamp(0, double.infinity);

  bool isInWishlist(String productId) {
    return _wishlist.contains(productId);
  }

  List<Product> get products {
    List<Product> filteredProducts = _products;

    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != 'All') {
      filteredProducts =
          filteredProducts.where((p) => p.category == _selectedCategory).toList();
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
      filteredProducts = filteredProducts.where((p) => p.isBestSeller ?? false).toList();
    }

    return filteredProducts;
  }

  List<String> get categories {
    return ['All', ..._products.map((p) => p.category).toSet()];
  }

  List<Product> get recentlyViewedProducts {
    return _recentlyViewedIds.map((id) {
      return _products.firstWhere((p) => p.id == id, orElse: () => Product(
        id: '', name: '', description: '', category: '', images: [], price: 0, stock: 0, isNewArrival: false, tags: [], material: '', isAvailable: false, createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
    }).where((p) => p.id.isNotEmpty).toList();
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

  void toggleWishlist(String productId) {
    if (_wishlist.contains(productId)) {
      _wishlist.remove(productId);
    } else {
      _wishlist.add(productId);
    }
    notifyListeners();
  }

  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _cartItems[existingIndex] =
          _cartItems[existingIndex].copyWith(quantity: _cartItems[existingIndex].quantity + 1);
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _appliedCoupon = '';
    notifyListeners();
  }

  void addToRecentlyViewed(String productId) {
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > 10) {
      _recentlyViewedIds.removeRange(10, _recentlyViewedIds.length);
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

  // Authentication methods
  Future<void> login(String userId, String phoneNumber, String name) async {
    _isLoggedIn = true;
    _currentUserId = userId;
    _currentUserPhone = phoneNumber;
    _currentUserName = name;
    // Orders are fetched in the constructor's authStateChanges listener
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUserId = '';
    _currentUserPhone = '';
    _currentUserName = '';
    // Clear user-specific data
    _cartItems.clear();
    _wishlist.clear();
    _orders.clear();
    notifyListeners();
  }

  void updateUserName(String name) {
    _currentUserName = name;
    notifyListeners();
  }

  Future<void> placeOrder(Address shippingAddress) async {
    final order = app_order.Order(
      id: '', // Firestore will generate this
      userId: _currentUserId,
      items: _cartItems,
      total: finalPayableTotal,
      shippingAddress: shippingAddress,
      status: 'Pending',
      createdAt: DateTime.now(),
    );
    await _firestoreService.addOrder(order);
    clearCart();
  }

  // Address management methods
  void addAddress(Address address) {
    _addresses.add(address);
    notifyListeners();
  }

  void updateAddress(Address updatedAddress) {
    final index = _addresses.indexWhere((addr) => addr.id == updatedAddress.id);
    if (index >= 0) {
      _addresses[index] = updatedAddress;
      notifyListeners();
    }
  }

  void deleteAddress(String addressId) {
    _addresses.removeWhere((addr) => addr.id == addressId);
    notifyListeners();
  }

  void setDefaultAddress(String addressId) {
    for (int i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == addressId);
    }
    notifyListeners();
  }
}
