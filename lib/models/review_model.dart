import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final List<String> images;
  final DateTime createdAt;
  final bool isVerifiedPurchase;
  final int helpfulCount;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.isVerifiedPurchase,
    this.helpfulCount = 0,
  });

  factory Review.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerifiedPurchase': isVerifiedPurchase,
      'helpfulCount': helpfulCount,
    };
  }
}
