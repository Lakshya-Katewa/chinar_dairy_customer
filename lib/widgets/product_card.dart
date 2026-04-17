import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_isAdding) return;

    setState(() {
      _isAdding = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.customer == null) {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
      return;
    }

    try {
      await cartProvider.addToCart(
        customerId: authProvider.customer!.id,
        product: widget.product,
        quantity: 1.0,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} added to cart'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
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

  void _showProductDetails() {
    Navigator.pushNamed(context, '/product-detail', arguments: widget.product);
  }

  void _showSubscriptionOptions() {
    if (!widget.product.canSubscribe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is not available for subscription'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushNamed(context, '/subscription', arguments: widget.product);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: _showProductDetails,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child:
                                widget.product.imageUrl != null
                                    ? Image.network(
                                      widget.product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.local_drink,
                                            size: 60,
                                            color: Colors.grey.shade400,
                                          ),
                                    )
                                    : Icon(
                                      Icons.local_drink,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                          ),
                        ),
                        // Product Type Badge
                        if (widget.product.isOneTimeOnly)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'One-time',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Product Details
                  Expanded(
                    flex: 3, // Increased flex to give buttons more room
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.product.price.toStringAsFixed(0)} / ${widget.product.unitText}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),

                          // --- FIXED: STACKED BUTTONS VERTICALLY ---
                          Column(
                            children: [
                              if (widget.product.canSubscribe)
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: OutlinedButton(
                                    onPressed: _showSubscriptionOptions,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).primaryColor,
                                      side: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text(
                                      'Subscribe',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.product.canSubscribe)
                                const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: ElevatedButton(
                                  onPressed: _isAdding ? null : _addToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                  ),
                                  child:
                                      _isAdding
                                          ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                          : const Text(
                                            'Buy Once',
                                            style: TextStyle(
                                              fontSize: 12,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
