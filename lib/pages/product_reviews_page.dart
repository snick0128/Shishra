import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shishra/models/review_model.dart';
import 'package:shishra/product.dart';

class ProductReviewsPage extends StatefulWidget {
  final Product product;

  const ProductReviewsPage({super.key, required this.product});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', '5 Stars', '4 Stars', '3 Stars', '2 Stars', '1 Star'];

  Stream<List<Review>> _getReviews() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('reviews')
        .where('productId', isEqualTo: widget.product.id)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      var reviews = snapshot.docs.map((doc) => Review.fromSnapshot(doc)).toList();

      // Apply rating filter
      if (_selectedFilter != 'All') {
        final rating = int.parse(_selectedFilter.split(' ')[0]);
        reviews = reviews.where((review) => review.rating.toInt() == rating).toList();
      }

      return reviews;
    });
  }

  Future<Map<String, dynamic>> _getReviewStats() async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('productId', isEqualTo: widget.product.id)
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }

    final reviews = reviewsSnapshot.docs.map((doc) => Review.fromSnapshot(doc)).toList();
    final totalReviews = reviews.length;
    final averageRating = reviews.fold<double>(0, (sum, review) => sum + review.rating) / totalReviews;

    final ratingDistribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      ratingDistribution[review.rating.toInt()] = (ratingDistribution[review.rating.toInt()] ?? 0) + 1;
    }

    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reviews & Ratings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Review Stats
          FutureBuilder<Map<String, dynamic>>(
            future: _getReviewStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }

              final stats = snapshot.data!;
              final totalReviews = stats['totalReviews'] as int;
              final averageRating = stats['averageRating'] as double;
              final ratingDistribution = stats['ratingDistribution'] as Map<int, int>;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < averageRating.floor()
                                        ? Icons.star
                                        : (index < averageRating ? Icons.star_half : Icons.star_border),
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: List.generate(5, (index) {
                              final rating = 5 - index;
                              final count = ratingDistribution[rating] ?? 0;
                              final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text('$rating', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.star, size: 12, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: percentage,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Filter Options
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _selectedFilter == option;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = option);
                    },
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Reviews List
          Expanded(
            child: StreamBuilder<List<Review>>(
              stream: _getReviews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to review this product',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(reviews[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        backgroundColor: Colors.black,
        icon: const Icon(Icons.rate_review, color: Colors.white),
        label: const Text('Write Review', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'Verified Purchase',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(review.images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _markHelpful(review.id),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${review.helpfulCount})'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review')),
      );
      return;
    }

    double rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() => rating = (index + 1).toDouble());
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Your Review', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience with this product...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review')),
                  );
                  return;
                }

                try {
                  // Get user name from Firestore
                  final userDoc = await _firestore.collection('users').doc(user.uid).get();
                  final userName = userDoc.data()?['name'] ?? 'Anonymous';

                  // Check if user has purchased this product
                  final ordersSnapshot = await _firestore
                      .collection('orders')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'Delivered')
                      .get();

                  bool isVerifiedPurchase = false;
                  for (var orderDoc in ordersSnapshot.docs) {
                    final items = orderDoc.data()['items'] as List<dynamic>;
                    if (items.any((item) => item['productId'] == widget.product.id)) {
                      isVerifiedPurchase = true;
                      break;
                    }
                  }

                  final review = Review(
                    id: '',
                    productId: widget.product.id,
                    userId: user.uid,
                    userName: userName,
                    rating: rating,
                    comment: commentController.text.trim(),
                    images: [],
                    createdAt: DateTime.now(),
                    isVerifiedPurchase: isVerifiedPurchase,
                  );

                  await _firestore.collection('reviews').add(review.toMap());

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markHelpful(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
