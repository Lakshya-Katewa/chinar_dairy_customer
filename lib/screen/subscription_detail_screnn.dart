import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../widget/custom_buttom.dart';
import '../provider/auth_provider.dart';
import '../services/database_service.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Product product;

  const SubscriptionDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  SubscriptionType _subscriptionType = SubscriptionType.monthly;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  double _quantity = 1;
  bool _isLoading = false;

  void _incrementQuantity() {
    setState(() {
      _quantity += 0.5;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 0.5) {
      setState(() {
        _quantity -= 0.5;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _subscribe() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer == null) return;

    final customer = authProvider.customer!;
    final totalAmount = widget.product.price * _quantity;

    // Check wallet balance
    if (customer.walletBalance < totalAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet balance'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => SubscriptionConfirmationDialog(
        product: widget.product,
        subscriptionType: _subscriptionType,
        quantity: _quantity,
        startDate: _startDate,
        totalAmount: totalAmount,
        walletBalance: customer.walletBalance,
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate end date based on subscription type
      DateTime? endDate;
      switch (_subscriptionType) {
        case SubscriptionType.monthly:
          endDate = _startDate.add(const Duration(days: 30));
          break;
        case SubscriptionType.weekly:
          endDate = _startDate.add(const Duration(days: 7));
          break;
        case SubscriptionType.alternateDay:
          endDate = _startDate.add(const Duration(days: 30)); // 15 deliveries over 30 days
          break;
      }

      // Create subscription
      final subscription = Subscription(
        id: '',
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        customerEmail: customer.email,
        productId: widget.product.id,
        productName: widget.product.name,
        type: _subscriptionType,
        startDate: _startDate,
        endDate: endDate,
        isActive: true,
        quantity: _quantity,
        pricePerUnit: widget.product.price,
        areaCode: customer.areaCode,
        address: customer.address,
      );

      await _databaseService.createSubscription(subscription);

      // Update wallet balance
      await _databaseService.updateWalletBalance(customer.id, -totalAmount);

      // Create transaction record
      await _databaseService.createTransaction(
        Transaction(
          id: '',
          customerId: customer.id,
          amount: totalAmount,
          type: TransactionType.debit,
          description: 'Subscription payment - ${widget.product.name}',
          createdAt: DateTime.now(),
        ),
      );

      // Update customer data
      final updatedCustomer = customer.copyWith(
        walletBalance: customer.walletBalance - totalAmount,
      );
      await authProvider.updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription added successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating subscription: $e'),
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

  String _getSubscriptionTypeText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Monthly Subscription';
      case SubscriptionType.weekly:
        return 'Weekly Subscription';
      case SubscriptionType.alternateDay:
        return 'Alternate Day Subscription';
    }
  }

  String _getSubscriptionDescription(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Daily delivery for 30 days';
      case SubscriptionType.weekly:
        return 'Daily delivery for 7 days';
      case SubscriptionType.alternateDay:
        return '15 deliveries on alternate days';
    }
  }

  int _getDeliveryCount(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.weekly:
        return 7;
      case SubscriptionType.alternateDay:
        return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.local_drink,
                                    color: AppTheme.primaryColor,
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
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
                          widget.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.product.price.toStringAsFixed(2)} per ${widget.product.unitText}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.description,
                          style: const TextStyle(
                            color: AppTheme.lightTextColor,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subscription Type
              const Text(
                'Select Subscription Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<SubscriptionType>(
                      title: const Text('Monthly'),
                      subtitle: Text(_getSubscriptionDescription(SubscriptionType.monthly)),
                      value: SubscriptionType.monthly,
                      groupValue: _subscriptionType,
                      onChanged: (value) {
                        setState(() {
                          _subscriptionType = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Divider(height: 1),
                    RadioListTile<SubscriptionType>(
                      title: const Text('Weekly'),
                      subtitle: Text(_getSubscriptionDescription(SubscriptionType.weekly)),
                      value: SubscriptionType.weekly,
                      groupValue: _subscriptionType,
                      onChanged: (value) {
                        setState(() {
                          _subscriptionType = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const Divider(height: 1),
                    RadioListTile<SubscriptionType>(
                      title: const Text('Alternate Day'),
                      subtitle: Text(_getSubscriptionDescription(SubscriptionType.alternateDay)),
                      value: SubscriptionType.alternateDay,
                      groupValue: _subscriptionType,
                      onChanged: (value) {
                        setState(() {
                          _subscriptionType = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start Date
              const Text(
                'Select Start Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
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
                        DateFormat('dd/MM/yyyy').format(_startDate),
                        style: const TextStyle(
                          fontSize: 16,
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
              const SizedBox(height: 24),

              // Quantity
              const Text(
                'Quantity per delivery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _decrementQuantity,
                          icon: const Icon(Icons.remove),
                          color: AppTheme.primaryColor,
                        ),
                        Text(
                          _quantity.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: _incrementQuantity,
                          icon: const Icon(Icons.add),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.product.unitText,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Subscription Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Product', widget.product.name),
                    _buildSummaryRow('Subscription Type', _getSubscriptionTypeText(_subscriptionType)),
                    _buildSummaryRow('Start Date', DateFormat('dd/MM/yyyy').format(_startDate)),
                    _buildSummaryRow('Quantity per delivery', '$_quantity ${widget.product.unitText}'),
                    _buildSummaryRow('Total deliveries', '${_getDeliveryCount(_subscriptionType)} times'),
                    _buildSummaryRow('Price per delivery', '₹${(widget.product.price * _quantity).toStringAsFixed(2)}'),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Amount',
                      '₹${(widget.product.price * _quantity * _getDeliveryCount(_subscriptionType)).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subscribe Button
              CustomButton(
                text: 'Subscribe Now',
                onPressed: _subscribe,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryColor : Colors.black,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionConfirmationDialog extends StatelessWidget {
  final Product product;
  final SubscriptionType subscriptionType;
  final double quantity;
  final DateTime startDate;
  final double totalAmount;
  final double walletBalance;

  const SubscriptionConfirmationDialog({
    super.key,
    required this.product,
    required this.subscriptionType,
    required this.quantity,
    required this.startDate,
    required this.totalAmount,
    required this.walletBalance,
  });

  int _getDeliveryCount(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 30;
      case SubscriptionType.weekly:
        return 7;
      case SubscriptionType.alternateDay:
        return 15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSubscriptionAmount = totalAmount * _getDeliveryCount(subscriptionType);
    final remainingBalance = walletBalance - totalSubscriptionAmount;

    return AlertDialog(
      title: const Text('Confirm Subscription'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product: ${product.name}'),
          const SizedBox(height: 4),
          Text('Type: ${subscriptionType.name}'),
          const SizedBox(height: 4),
          Text('Start Date: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
          const SizedBox(height: 4),
          Text('Deliveries: ${_getDeliveryCount(subscriptionType)} times'),
          const SizedBox(height: 4),
          Text('Per delivery: ₹${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text('Total Amount: ₹${totalSubscriptionAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          Text('Current Wallet Balance: ₹${walletBalance.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
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
