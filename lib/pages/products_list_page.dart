import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shishra/globals/app_state.dart';
import 'package:shishra/components/product_card.dart';

class ProductsListPage extends StatelessWidget {
  final String title;
  final String? category;
  final String? gender; // 'Men' | 'Women'

  const ProductsListPage({super.key, required this.title, this.category, this.gender});

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
        title: Text(title, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          var list = appState.products;

          if (category != null && category != 'All') {
            list = list.where((p) => p.category == category).toList();
          }

          if (gender != null) {
            list = list.where((p) => p.subCategory == gender).toList();
          }

          if (list.isEmpty) {
            return Center(
                child: Text('No products found',
                    style: TextStyle(color: Colors.grey.shade600)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) => ProductCard(product: list[index]),
          );
        },
      ),
    );
  }
}