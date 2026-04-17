import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const CartItemCard({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  cartItem.imageUrl != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          cartItem.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.local_drink,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                      : Icon(Icons.local_drink, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 12),

            // Product Details - WRAPPED IN EXPANDED TO PREVENT OVERFLOW
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2, // Forces wrap
                    overflow: TextOverflow.ellipsis, // Adds ... if too long
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${cartItem.price.toStringAsFixed(2)} per ${cartItem.unit}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total: ₹${cartItem.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Quantity Controls - COMPACT CUSTOM DESIGN
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          final cp = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          cp.updateQuantity(cartItem.id, cartItem.quantity - 1);
                        },
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${cartItem.quantity.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          final cp = Provider.of<CartProvider>(
                            context,
                            listen: false,
                          );
                          cp.updateQuantity(cartItem.id, cartItem.quantity + 1);
                        },
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final cp = Provider.of<CartProvider>(
                      context,
                      listen: false,
                    );
                    cp.removeFromCart(cartItem.id);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Remove',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
