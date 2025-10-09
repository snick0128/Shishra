import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/services/storage_service.dart';
import 'package:shishra/product.dart';
import 'package:shishra/utils/responsive_layout.dart';
import 'dart:io';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  List<String> _allCategories = [];
  Stream<List<Product>>? _productsStream;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _productsStream = _firestore.collection('products').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList(),
        );
  }

  Future<void> _loadCategories() async {
    try {
      // Load existing categories from Firestore
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final existingCategories = categoriesSnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // Default categories if none exist
      if (existingCategories.isEmpty) {
        await _initializeDefaultCategories();
        // Give Firestore time to process the batch write
        await Future.delayed(const Duration(milliseconds: 1000));
        return _loadCategories(); // Reload after initialization
      }

      setState(() {
        _allCategories = existingCategories;
        _categories = ['All', ...existingCategories];
      });
    } catch (e) {
      print('Error loading categories: $e');
      // If Firestore fails, initialize with default categories
      if (_allCategories.isEmpty) {
        await _initializeDefaultCategories();
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _allCategories = [
            'Rings', 'Necklaces', 'Bracelets', 'Earrings', 'Pendants',
            'Bangles', 'Chains', 'Anklets', 'For Men', 'For Women'
          ];
          _categories = ['All', ..._allCategories];
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _initializeDefaultCategories() async {
    final defaultCategories = [
      // Product Types
      'Rings',
      'Necklaces',
      'Bracelets',
      'Earrings',
      'Pendants',
      'Bangles',
      'Chains',
      'Anklets',

      // Gift Guide Categories
      'For Men',
      'For Women',
      'For Mom',
      'For Sister',
      'For Friend',
      'For Husband',
      'For Wife',
      'For Couple',
      'For Kids',

      // Price Range Categories
      'Under ₹299',
      'Under ₹999',
      'Under ₹2999',
      'Under ₹4999',
      'Premium Collection',
      'Luxury Collection',

      // Occasion Categories
      'Wedding',
      'Engagement',
      'Anniversary',
      'Birthday',
      'Festival',
      'Party',
      'Daily Wear',
      'Office Wear',

      // Material Categories
      'Gold',
      'Silver',
      'Diamond',
      'Platinum',
      'Rose Gold',
      'Artificial',

      // Style Categories
      'Traditional',
      'Modern',
      'Vintage',
      'Contemporary',
      'Ethnic',
      'Western'
    ];

    try {
      final batch = _firestore.batch();
      for (final category in defaultCategories) {
        final docRef = _firestore.collection('categories').doc();
        batch.set(docRef, {
          'name': category,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }
      await batch.commit();
      print('Default categories initialized successfully');
    } catch (e) {
      print('Error initializing default categories: $e');
      // Fallback: Set categories directly in memory if Firestore fails
      if (_allCategories.isEmpty) {
        setState(() {
          _allCategories = defaultCategories;
          _categories = ['All', ...defaultCategories];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveLayout.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Products',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCategoryManagementDialog,
                icon: const Icon(Icons.category, color: Colors.white),
                label: const Text(
                  'Manage Categories',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addNewProduct,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage jewelry products and inventory',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              DropdownButton<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final products = snapshot.data ?? [];
                final filteredProducts = _selectedCategory == 'All'
                    ? products
                    : products
                        .where((p) => p.category == _selectedCategory)
                        .toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found. Add some products to get started!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        ResponsiveLayout.getResponsiveGridCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(
                      product: product,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required Product product,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl.isNotEmpty
                      ? product.imageUrl
                      : 'https://via.placeholder.com/300x300?text=No+Image'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: PopupMenuButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (value) {
                        _handleProductAction(value.toString(), product);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.stock > 5
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: product.stock > 5
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${product.stock}',
                        style: TextStyle(
                          color: product.stock > 5 ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addNewProduct() {
    _showAddEditProductDialog();
  }


  void _showAddEditProductDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(text: product?.description ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final materialController = TextEditingController(text: product?.material ?? '');

    String selectedCategory = product?.category ?? (_allCategories.isNotEmpty ? _allCategories[0] : 'Rings');
    List<File> selectedImages = [];
    bool isLoading = false;
    bool isImagePickerLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return WillPopScope(
            onWillPop: () async => !isLoading,
            child: AlertDialog(
              title: Text(
                product == null ? 'Add New Product' : 'Edit Product',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 600),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Enter product description...',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),

                      // Category Selection
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _allCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showAddCategoryDialog(setDialogState),
                            icon: const Icon(Icons.add_circle_outline),
                            tooltip: 'Add New Category',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price and Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price (₹) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              decoration: const InputDecoration(
                                labelText: 'Stock Quantity *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Material
                      TextField(
                        controller: materialController,
                        decoration: const InputDecoration(
                          labelText: 'Material (e.g., Silver, Gold)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.diamond),
                          hintText: 'Silver, Gold, Diamond, etc.',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Image Selection
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Product Images (${selectedImages.length}/5)',
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      const Text(
                                        'Optional - Add up to 5 product images',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: isImagePickerLoading ? null : () async {
                                    try {
                                      setDialogState(() {
                                        isImagePickerLoading = true;
                                      });

                                      final images = await _storageService.pickMultipleImages(maxImages: 5);

                                      if (context.mounted) {
                                        setDialogState(() {
                                          isImagePickerLoading = false;
                                          if (images.isNotEmpty) {
                                            selectedImages = images;
                                          }
                                        });

                                        if (images.isEmpty) {
                                          // Only show message if it's not a user cancellation
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('No images selected. You can add images later or continue without them.'),
                                              backgroundColor: Colors.orange,
                                              duration: Duration(seconds: 3),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('${images.length} image(s) selected successfully'),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setDialogState(() {
                                          isImagePickerLoading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error selecting images: $e'),
                                            backgroundColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: isImagePickerLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.add_photo_alternate),
                                  label: Text(isImagePickerLoading ? 'Loading...' : 'Select Images'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                        image: DecorationImage(
                                          image: FileImage(selectedImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setDialogState(() {
                                                  selectedImages.removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    // Validate required fields
                    if (nameController.text.trim().isEmpty ||
                        priceController.text.trim().isEmpty ||
                        stockController.text.trim().isEmpty ||
                        selectedCategory.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields (Name, Price, Stock, Category)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate numeric fields
                    final price = double.tryParse(priceController.text.trim());
                    final stock = int.tryParse(stockController.text.trim());

                    if (price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid price'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (stock == null || stock < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid stock quantity'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    setDialogState(() {
                      isLoading = true;
                    });

                    try {
                      // Upload images if any selected
                      List<String> imageUrls = product?.images ?? [];
                      if (selectedImages.isNotEmpty) {
                        imageUrls = await _storageService.uploadMultipleProductImages(selectedImages);

                        if (imageUrls.isEmpty) {
                          throw Exception('Failed to upload images. Please try again.');
                        }
                      }

                      // Create product object
                      final newProduct = Product(
                        id: product?.id ?? '',
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        category: selectedCategory,
                        images: imageUrls,
                        price: price,
                        stock: stock,
                        material: materialController.text.trim(),
                        isNewArrival: product?.isNewArrival ?? true,
                        tags: [selectedCategory.toLowerCase(), 'jewelry', materialController.text.toLowerCase()]
                            .where((tag) => tag.isNotEmpty).toList(),
                        isAvailable: true,
                        createdAt: product?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      if (product == null) {
                        // Add new product
                        await _firestore.collection('products').add(newProduct.toMap());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product added successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        // Update existing product
                        await _firestore.collection('products').doc(product.id).update(newProduct.toMap());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Product updated successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }

                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      setDialogState(() {
                        isLoading = false;
                      });
                    }
                  },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(product == null ? 'Add Product' : 'Update Product'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _showAddEditProductDialog(product: product);
        break;
      case 'duplicate':
        _duplicateProduct(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _duplicateProduct(Product product) async {
    try {
      final duplicatedProduct = Product(
        id: '', // Firestore will generate new ID
        name: '${product.name} (Copy)',
        description: product.description,
        category: product.category,
        images: product.images, // Reuse same images
        price: product.price,
        stock: product.stock,
        material: product.material,
        isNewArrival: true,
        tags: product.tags,
        isAvailable: product.isAvailable,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('products').add(duplicatedProduct.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product duplicated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating product: $e')),
        );
      }
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
            'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // Delete product images from storage
                for (final imageUrl in product.images) {
                  await _storageService.deleteImage(imageUrl);
                }

                // Delete product from Firestore
                await _firestore
                    .collection('products')
                    .doc(product.id)
                    .delete();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Product deleted successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting product: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(StateSetter setDialogState) {
    final categoryController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Vintage Collection',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const Text(
              'Examples: For Dad, Under ₹1999, Festive Collection, etc.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final categoryName = categoryController.text.trim();
              if (categoryName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a category name')),
                );
                return;
              }
              
              if (_allCategories.contains(categoryName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category already exists')),
                );
                return;
              }
              
              try {
                // Add to Firestore
                await _firestore.collection('categories').add({
                  'name': categoryName,
                  'createdAt': FieldValue.serverTimestamp(),
                  'isActive': true,
                });
                
                // Update local state
                setState(() {
                  _allCategories.add(categoryName);
                  _categories.add(categoryName);
                });
                
                // Update dialog state
                setDialogState(() {});
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$categoryName" added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding category: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showCategoryManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Categories'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Categories: ${_allCategories.length}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddCategoryDialog((fn) => setState(fn));
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _allCategories.length,
                  itemBuilder: (context, index) {
                    final category = _allCategories[index];
                    return Card(
                      child: ListTile(
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(category, index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String categoryName, int index) async {
    // Check if any products use this category
    final productsWithCategory = await _firestore
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .get();
    
    if (productsWithCategory.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete "$categoryName" - ${productsWithCategory.docs.length} products use this category',
            ),
          ),
        );
      }
      return;
    }
    
    try {
      // Delete from Firestore
      final categoryDocs = await _firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();
      
      for (final doc in categoryDocs.docs) {
        await doc.reference.delete();
      }
      
      // Update local state
      setState(() {
        _allCategories.removeAt(index);
        _categories.remove(categoryName);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category "$categoryName" deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }
}
