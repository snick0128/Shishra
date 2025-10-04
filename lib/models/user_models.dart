import 'package:shishra/product.dart';

enum JewelrySize {
  s,
  m,
  l,
  xl,
  oneSize,
  custom,
}

class UserAddress {
  const UserAddress({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phoneNumber,
    this.addressLine2 = '',
    this.isDefault = false,
    this.type = 'Home',
  });

  final String id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String phoneNumber;
  final bool isDefault;
  final String type; // Home, Office, Other

  UserAddress copyWith({
    String? id,
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    String? phoneNumber,
    bool? isDefault,
    String? type,
  }) {
    return UserAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      type: type ?? this.type,
    );
  }

  String get fullAddress {
    String address = addressLine1;
    if (addressLine2.isNotEmpty) {
      address += ', $addressLine2';
    }
    address += ', $city, $state - $pincode';
    return address;
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber = '',
    this.profileImageUrl = '',
    this.addresses = const [],
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String profileImageUrl;
  final List<UserAddress> addresses;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    List<UserAddress>? addresses,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      addresses: addresses ?? this.addresses,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  UserAddress? get defaultAddress {
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  refunded,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  cod, // Cash on Delivery
  upi,
  card,
  netBanking,
  wallet,
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.priceAtTime,
    this.selectedSize,
    this.discountAtTime = 0.0,
  });

  final String id;
  final Product product;
  final int quantity;
  final double priceAtTime; // Price when ordered
  final JewelrySize? selectedSize;
  final double discountAtTime; // Discount when ordered

  double get totalPrice => priceAtTime * quantity;
  double get discountedPriceAtTime => priceAtTime * (1 - discountAtTime / 100);
  double get totalDiscountedPrice => discountedPriceAtTime * quantity;

  OrderItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? priceAtTime,
    JewelrySize? selectedSize,
    double? discountAtTime,
  }) {
    return OrderItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtTime: priceAtTime ?? this.priceAtTime,
      selectedSize: selectedSize ?? this.selectedSize,
      discountAtTime: discountAtTime ?? this.discountAtTime,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.orderDate,
    required this.shippingAddress,
    this.estimatedDelivery,
    this.actualDelivery,
    this.trackingNumber = '',
    this.notes = '',
    this.discountAmount = 0.0,
    this.shippingCharges = 0.0,
    this.taxes = 0.0,
  });

  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus orderStatus;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final DateTime orderDate;
  final UserAddress shippingAddress;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final String trackingNumber;
  final String notes;
  final double discountAmount;
  final double shippingCharges;
  final double taxes;

  double get itemsTotal => items.fold(0, (sum, item) => sum + item.totalDiscountedPrice);
  double get finalAmount => itemsTotal - discountAmount + shippingCharges + taxes;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  String get orderStatusDisplay {
    switch (orderStatus) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Payment Pending';
      case PaymentStatus.completed:
        return 'Payment Completed';
      case PaymentStatus.failed:
        return 'Payment Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? orderStatus,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    DateTime? orderDate,
    UserAddress? shippingAddress,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    String? trackingNumber,
    String? notes,
    double? discountAmount,
    double? shippingCharges,
    double? taxes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderDate: orderDate ?? this.orderDate,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      notes: notes ?? this.notes,
      discountAmount: discountAmount ?? this.discountAmount,
      shippingCharges: shippingCharges ?? this.shippingCharges,
      taxes: taxes ?? this.taxes,
    );
  }
}
