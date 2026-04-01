import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/subscription.dart';
import '../models/address.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Product? product;
  SubscriptionType selectedType = SubscriptionType.monthly; // Defaulting to Monthly, but Trial is now an option
  double quantity = 1.0;
  DetailedAddress? selectedAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Product?;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);
      
      if (authProvider.customer != null) {
        addressProvider.loadSavedAddresses(authProvider.customer!.id);
      }
    });
  }

  double get calculatedAmount {
    if (product == null) return 0.0;
    
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    return subscriptionProvider.calculateSubscriptionAmount(
      product: product!,
      type: selectedType,
      quantity: quantity,
    );
  }

  String get subscriptionDescription {
    switch (selectedType) {
      case SubscriptionType.trial: // FIX FOR ISSUE #11
        return 'Daily delivery for 3 days (Trial)';
      case SubscriptionType.weekly:
        return 'Daily delivery for 7 days';
      case SubscriptionType.monthly:
        return 'Daily delivery for 30 days';
      case SubscriptionType.alternateDay:
        return 'Alternate day delivery for 30 days (15 deliveries)';
    }
  }

  void _selectAddress() async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    if (addressProvider.savedAddresses.isEmpty) {
      final result = await Navigator.pushNamed(context, '/address-selection');
      if (result != null && result is DetailedAddress) {
        setState(() {
          selectedAddress = result;
        });
      }
    } else {
      _showAddressSelectionDialog();
    }
  }

  void _showAddressSelectionDialog() {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Delivery Address'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...addressProvider.savedAddresses.map((savedAddress) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(savedAddress.label),
                  subtitle: Text(savedAddress.address.fullAddress),
                  trailing: savedAddress.isDefault 
                      ? const Icon(Icons.star, color: Colors.amber)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedAddress = savedAddress.address;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.add_location),
                title: const Text('Add New Address'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.pushNamed(context, '/address-selection');
                  if (result != null && result is DetailedAddress) {
                    setState(() {
                      selectedAddress = result;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createSubscription() async {
    if (product == null) return;
    
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.customer == null) return;

    final totalAmount = calculatedAmount;
    if (authProvider.customer!.walletBalance < totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient wallet balance'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Add Money',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/wallet'),
          ),
        ),
      );
      return;
    }

    try {
      await subscriptionProvider.createSubscription(
        customer: authProvider.customer!,
        product: product!,
        type: selectedType,
        quantity: quantity,
        deliveryAddress: selectedAddress!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Create Subscription'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product!.imageUrl != null
                              ? Image.network(
                                  product!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.local_drink,
                                      color: Colors.grey.shade400,
                                      size: 40,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.local_drink,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${product!.price.toStringAsFixed(2)} per ${product!.unitText}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Delivery Address Selection
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(selectedAddress?.fullAddress ?? 'Select delivery address'),
                  subtitle: selectedAddress != null 
                      ? Text('${selectedAddress!.city}, ${selectedAddress!.pinCode}')
                      : const Text('Tap to select address'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectAddress,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Subscription Type Selection
              const Text(
                'Select Subscription Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Column(
                  children: [
                    // FIX FOR ISSUE #11: Insert Trial Pack option at the top of the list
                    RadioListTile<SubscriptionType>(
                      title: const Text('3-Day Trial Pack', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Daily delivery for 3 days to test our service'),
                      value: SubscriptionType.trial,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                      activeColor: Colors.green.shade700,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const Divider(height: 1),
                    RadioListTile<SubscriptionType>(
                      title: const Text('Weekly Subscription'),
                      subtitle: const Text('Daily delivery for 7 days'),
                      value: SubscriptionType.weekly,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                      activeColor: Colors.green.shade700,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const Divider(height: 1),
                    RadioListTile<SubscriptionType>(
                      title: const Text('Monthly Subscription'),
                      subtitle: const Text('Daily delivery for 30 days'),
                      value: SubscriptionType.monthly,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                      activeColor: Colors.green.shade700,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const Divider(height: 1),
                    RadioListTile<SubscriptionType>(
                      title: const Text('Alternate Day Subscription'),
                      subtitle: const Text('Alternate day delivery for 30 days'),
                      value: SubscriptionType.alternateDay,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                      activeColor: Colors.green.shade700,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quantity Selection
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily Quantity:',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: quantity > 1
                            ? () => setState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${quantity.toInt()} ${product!.unitText}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() => quantity++),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          minimumSize: const Size(40, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Daily Amount:'),
                          ),
                          Text('₹${(product!.price * quantity).toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text('Plan:'),
                          ),
                          Expanded(
                            child: Text(
                              subscriptionDescription,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Amount:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '₹${calculatedAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Wallet Balance
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final walletBalance = authProvider.customer?.walletBalance ?? 0.0;
                  final isInsufficientBalance = walletBalance < calculatedAmount;
                  
                  return Card(
                    color: isInsufficientBalance ? Colors.red.shade50 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: isInsufficientBalance ? Colors.red : Colors.green.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Wallet Balance',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${walletBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isInsufficientBalance ? Colors.red : Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isInsufficientBalance)
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/wallet'),
                              child: const Text('Add Money'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Create Subscription Button
              SizedBox(
                width: double.infinity,
                child: Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, child) {
                    return ElevatedButton(
                      onPressed: subscriptionProvider.isLoading ? null : _createSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: subscriptionProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create Subscription',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}