import 'package:chinar_dairy/models/transaction.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import '../widget/custom_buttom.dart';
import '../provider/auth_provider.dart';
import '../provider/cart_provider.dart';
import '../services/database_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime? _selectedOrderDate;
  bool _isLoading = false;

  Future<void> _selectOrderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedOrderDate = picked;
      });
    }
  }

  Future<void> _placeOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.customer == null || cartProvider.cartItems.isEmpty) {
      return;
    }

    if (_selectedOrderDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an order date'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final customer = authProvider.customer!;
    final totalAmount = cartProvider.totalAmount;

    if (customer.walletBalance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient wallet balance'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => OrderConfirmationDialog(
        totalAmount: totalAmount,
        walletBalance: customer.walletBalance,
        orderDate: _selectedOrderDate!,
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create orders for each cart item
      for (final cartItem in cartProvider.cartItems) {
        final order = Order(
          id: '',
          customerId: customer.id,
          customerName: customer.name,
          customerPhone: customer.phone,
          productId: cartItem.productId,
          productName: cartItem.productName,
          quantity: cartItem.quantity,
          totalAmount: cartItem.totalPrice,
          areaCode: customer.areaCode,
          address: customer.address,
          status: OrderStatus.pending,
          orderDate: DateTime.now(),
          deliveryDate: _selectedOrderDate,
        );

        await _databaseService.createOrder(order);
      }

      // Update wallet balance
      await _databaseService.updateWalletBalance(customer.id, -totalAmount);

      // Create transaction record
      await _databaseService.createTransaction(
        Transaction(
          id: '',
          customerId: customer.id,
          amount: totalAmount,
          type: TransactionType.debit,
          description: 'Order payment',
          createdAt: DateTime.now(),
        ),
      );

      // Clear cart
      await cartProvider.clearCart(customer.id);

      // Update customer data
      final updatedCustomer = customer.copyWith(
        walletBalance: customer.walletBalance - totalAmount,
      );
      await authProvider.updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cartItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style: TextStyle(
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartProvider.cartItems[index];
                    return CartItemCard(
                      cartItem: cartItem,
                      onRemove: () {
                        cartProvider.removeFromCart(cartItem.id);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Order Date Selection
                    InkWell(
                      onTap: _selectOrderDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedOrderDate != null
                                  ? 'Order Date: ${DateFormat('dd/MM/yyyy').format(_selectedOrderDate!)}'
                                  : 'Select Order Date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedOrderDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${cartProvider.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Place Order',
                      onPressed: _placeOrder,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemCard extends StatelessWidget {
  final CartItem cartItem;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_drink,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartItem.quantity} ${cartItem.unit}',
                    style: const TextStyle(
                      color: AppTheme.lightTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${cartItem.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (cartItem.orderDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Order Date: ${DateFormat('dd/MM/yyyy').format(cartItem.orderDate!)}',
                      style: const TextStyle(
                        color: AppTheme.lightTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderConfirmationDialog extends StatelessWidget {
  final double totalAmount;
  final double walletBalance;
  final DateTime orderDate;

  const OrderConfirmationDialog({
    super.key,
    required this.totalAmount,
    required this.walletBalance,
    required this.orderDate,
  });

  @override
  Widget build(BuildContext context) {
    final remainingBalance = walletBalance - totalAmount;

    return AlertDialog(
      title: const Text('Confirm Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Date: ${DateFormat('dd/MM/yyyy').format(orderDate)}'),
          const SizedBox(height: 8),
          Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Current Wallet Balance: ₹${walletBalance.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text(
            'Remaining Balance: ₹${remainingBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: remainingBalance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: remainingBalance >= 0
              ? () {
                  Navigator.pop(context, true);
                }
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
