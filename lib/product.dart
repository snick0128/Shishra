
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? subCategory;
  final List<String> images;
  final double price;
  final double? oldPrice;
  final int stock;
  final bool isNewArrival;
  final bool? isBestSeller;
  final List<String> tags;
  final String material;
  final String? size;
  final double? weight;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.subCategory,
    required this.images,
    required this.price,
    this.oldPrice,
    required this.stock,
    required this.isNewArrival,
    this.isBestSeller,
    required this.tags,
    required this.material,
    this.size,
    this.weight,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  String get imageUrl => images.isNotEmpty ? images.first : '';

  factory Product.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Product(
      id: snapshot.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'],
      images: List<String>.from(data['images'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      oldPrice: (data['oldPrice'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      isNewArrival: data['isNewArrival'] ?? false,
      isBestSeller: data['isBestSeller'],
      tags: List<String>.from(data['tags'] ?? []),
      material: data['material'] ?? '',
      size: data['size'],
      weight: (data['weight'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'],
      images: List<String>.from(data['images'] ?? []),
      price: (data['price'] ?? 0).toDouble(),
      oldPrice: data['oldPrice']?.toDouble(),
      stock: data['stock'] ?? 0,
      isNewArrival: data['isNewArrival'] ?? false,
      isBestSeller: data['isBestSeller'],
      tags: List<String>.from(data['tags'] ?? []),
      material: data['material'] ?? '',
      size: data['size'],
      weight: data['weight']?.toDouble(),
      isAvailable: data['isAvailable'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'subCategory': subCategory,
      'images': images,
      'price': price,
      'oldPrice': oldPrice,
      'stock': stock,
      'isNewArrival': isNewArrival,
      'isBestSeller': isBestSeller,
      'tags': tags,
      'material': material,
      'size': size,
      'weight': weight,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
