import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/product.dart';
import 'package:shishra/components/product_card.dart';

class AdvancedSearchPage extends StatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  State<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 50000);
  double _minRating = 0;
  List<String> _selectedMaterials = [];
  bool _inStockOnly = false;
  bool _isSearching = false;

  final List<String> _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Popular'
  ];

  final List<String> _materials = ['Gold', 'Silver', 'Diamond', 'Platinum', 'Rose Gold'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Product>> _getFilteredProducts() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('products');

    // Category filter
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Stock filter
    if (_inStockOnly) {
      query = query.where('stock', isGreaterThan: 0);
    }

    // Sorting
    switch (_selectedSortBy) {
      case 'Newest':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'Price: Low to High':
        query = query.orderBy('price', descending: false);
        break;
      case 'Price: High to Low':
        query = query.orderBy('price', descending: true);
        break;
      default:
        query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots().map((snapshot) {
      var products = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();

      // Apply client-side filters
      products = products.where((product) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          if (!product.name.toLowerCase().contains(searchLower) &&
              !product.description.toLowerCase().contains(searchLower) &&
              !product.category.toLowerCase().contains(searchLower)) {
            return false;
          }
        }

        // Price range filter
        if (product.price < _priceRange.start || product.price > _priceRange.end) {
          return false;
        }

        // Material filter
        if (_selectedMaterials.isNotEmpty) {
          if (!_selectedMaterials.any((material) =>
              product.material.toLowerCase().contains(material.toLowerCase()))) {
            return false;
          }
        }

        return true;
      }).toList();

      return products;
    });
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
          'Advanced Search',
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: _showFilters,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Active Filters Chips
          if (_selectedCategory != 'All' ||
              _selectedMaterials.isNotEmpty ||
              _inStockOnly ||
              _priceRange.start > 0 ||
              _priceRange.end < 50000)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedCategory != 'All')
                    _buildFilterChip(_selectedCategory, () {
                      setState(() => _selectedCategory = 'All');
                    }),
                  ..._selectedMaterials.map((material) =>
                      _buildFilterChip(material, () {
                        setState(() => _selectedMaterials.remove(material));
                      })),
                  if (_inStockOnly)
                    _buildFilterChip('In Stock', () {
                      setState(() => _inStockOnly = false);
                    }),
                  if (_priceRange.start > 0 || _priceRange.end < 50000)
                    _buildFilterChip(
                        '₹${_priceRange.start.toInt()}-₹${_priceRange.end.toInt()}',
                        () {
                      setState(() => _priceRange = const RangeValues(0, 50000));
                    }),
                  TextButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ),

          // Sort Options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _sortOptions.map((option) {
                        final isSelected = _selectedSortBy == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedSortBy = option);
                            },
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Products Grid
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _getFilteredProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
        backgroundColor: Colors.black,
        labelStyle: const TextStyle(color: Colors.white),
        deleteIconColor: Colors.white,
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() => _clearAllFilters());
                        setState(() {});
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Filter
                const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final categories = ['All', ...snapshot.data!.docs.map((doc) => doc['name'] as String)];
                    return Wrap(
                      spacing: 8,
                      children: categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() => _selectedCategory = category);
                            setState(() {});
                          },
                          selectedColor: Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Price Range
                const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 50000,
                  divisions: 100,
                  labels: RangeLabels(
                    '₹${_priceRange.start.toInt()}',
                    '₹${_priceRange.end.toInt()}',
                  ),
                  onChanged: (values) {
                    setModalState(() => _priceRange = values);
                    setState(() {});
                  },
                ),
                Text(
                  '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 24),

                // Material Filter
                const Text('Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _materials.map((material) {
                    final isSelected = _selectedMaterials.contains(material);
                    return FilterChip(
                      label: Text(material),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            _selectedMaterials.add(material);
                          } else {
                            _selectedMaterials.remove(material);
                          }
                        });
                        setState(() {});
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Stock Filter
                SwitchListTile(
                  title: const Text('In Stock Only'),
                  value: _inStockOnly,
                  onChanged: (value) {
                    setModalState(() => _inStockOnly = value);
                    setState(() {});
                  },
                  activeColor: Colors.black,
                ),

                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearAllFilters() {
    _selectedCategory = 'All';
    _selectedMaterials.clear();
    _inStockOnly = false;
    _priceRange = const RangeValues(0, 50000);
    _minRating = 0;
  }
}
