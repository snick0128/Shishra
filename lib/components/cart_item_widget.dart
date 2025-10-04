import 'package:flutter/material.dart';
import 'package:shishra/cart_item.dart';
import 'package:shishra/globals/app_state.dart';

class CartItemWidget extends StatelessWidget {
  const CartItemWidget({super.key, required this.cartItem});

  final CartItem cartItem;

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context, listen: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(cartItem.product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (cartItem.product.size != null)
                  Text(
                    'Size: ${cartItem.product.size}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${cartItem.product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (cartItem.product.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${cartItem.product.oldPrice!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Quantity Controls and Remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => appState.updateQuantity(
                        cartItem.product.id, cartItem.quantity - 1),
                  ),
                  Text('${cartItem.quantity}', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => appState.updateQuantity(
                        cartItem.product.id, cartItem.quantity + 1),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => appState.removeFromCart(cartItem.product.id),
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          )
        ],
      ),
    );
  }
}