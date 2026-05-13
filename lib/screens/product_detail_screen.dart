// product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
// Note: You might need to import your CartItem model if it's in a separate file
// import '../models/cart_item.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  double quantity = 1.0;
  bool _isAdding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (product == null) {
      product = ModalRoute.of(context)?.settings.arguments as Product?;
    }
  }

  Future<void> _addToCart() async {
    if (product == null || _isAdding) return;

    setState(() {
      _isAdding = true;
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.customer == null) {
      if (mounted) {
        setState(() => _isAdding = false);
      }
      return;
    }

    try {
      await cartProvider.addToCart(
        customerId: authProvider.customer!.id,
        product: product!,
        quantity: quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product!.name} added to cart'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  void _showSubscriptionOptions() {
    Navigator.pushNamed(context, '/subscription', arguments: product);
  }

  // --- UPDATED: WIDGET FOR THE PERSISTENT CART BUTTON ---
  // --- Logic is now specific to the current product ---
  Widget _buildPersistentCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        if (product == null) {
          return const SizedBox.shrink(); // Don't show if product isn't loaded
        }

        // Find if the current product is in the cart
        final indexInCart = cartProvider.items.indexWhere(
          (item) => item.productId == product!.id,
        );
        final bool isVisible = indexInCart != -1;

        // Get the quantity of this specific item in the cart
        final quantityInCart =
            isVisible ? cartProvider.items[indexInCart].quantity : 0;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          bottom: isVisible ? 16 : -80, // Slide in from bottom
          left: 16,
          right: 16,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_checkout),
            // UPDATED LABEL: Shows quantity of the current item
            label: Text('View in Cart (${quantityInCart.toInt()} added)'),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Text(product!.name),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child:
                      product!.imageUrl != null
                          ? Image.network(
                            product!.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.local_drink,
                                size: 100,
                                color: Colors.grey.shade400,
                              );
                            },
                          )
                          : Icon(
                            Icons.local_drink,
                            size: 100,
                            color: Colors.grey.shade400,
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product!.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${product!.price.toStringAsFixed(2)} per ${product!.unitText}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Quantity',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                                quantity > 0.5
                                    ? () => setState(() => quantity -= 0.5)
                                    : null,
                            icon: const Icon(Icons.remove),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            quantity % 1 == 0
                                ? '${quantity.toInt()} ${product!.unitText}'
                                : '${quantity.toStringAsFixed(1)} ${product!.unitText}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => setState(() => quantity += 0.5),
                            icon: const Icon(Icons.add),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (product!.isOneTimeOnly)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isAdding ? null : _addToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isAdding
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : Text(
                                      'Buy Once - ₹${(product!.price * quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            if (product!.canSubscribe)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _showSubscriptionOptions,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                    side: BorderSide(
                                      color: Colors.green.shade700,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Subscribe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (product!.canSubscribe)
                              const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isAdding ? null : _addToCart,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child:
                                    _isAdding
                                        ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                        : const Text(
                                          'Buy Once',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildPersistentCartButton(),
        ],
      ),
    );
  }
}
