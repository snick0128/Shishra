import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/cart_item.dart';
import 'package:shishra/address.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final Address shippingAddress;
  final String status; // e.g., 'Pending', 'Shipped', 'Delivered'
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.shippingAddress,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Order(
      id: snapshot.id,
      userId: data['userId'],
      items: (data['items'] as List)
          .map((item) => CartItem.fromMap(item))
          .toList(),
      total: data['total'],
      shippingAddress: Address.fromMap(data['shippingAddress']),
      status: data['status'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'shippingAddress': shippingAddress.toMap(),
      'status': status,
      'createdAt': createdAt,
    };
  }
}
