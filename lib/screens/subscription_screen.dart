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
  SubscriptionType selectedType = SubscriptionType.monthly;
  double quantity = 1.0;
  DetailedAddress? selectedAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    product = ModalRoute.of(context)?.settings.arguments as Product?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );
      if (authProvider.customer != null) {
        addressProvider.loadSavedAddresses(authProvider.customer!.id);
      }
    });
  }

  double get calculatedAmount {
    if (product == null) return 0.0;
    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    return subscriptionProvider.calculateSubscriptionAmount(
      product: product!,
      type: selectedType,
      quantity: quantity,
    );
  }

  String get subscriptionDescription {
    switch (selectedType) {
      case SubscriptionType.trial:
        return 'Daily delivery for 3 days (Trial)';
      case SubscriptionType.weekly:
        return 'Daily delivery for 7 days';
      case SubscriptionType.monthly:
        return 'Daily delivery for 30 days';
      case SubscriptionType.alternateDay:
        return 'Alternate day delivery for 30 days';
    }
  }

  void _selectAddress() async {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    if (addressProvider.savedAddresses.isEmpty) {
      final result = await Navigator.pushNamed(context, '/address-selection');
      if (result != null && result is DetailedAddress)
        setState(() => selectedAddress = result);
    } else {
      _showAddressSelectionDialog();
    }
  }

  void _showAddressSelectionDialog() {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Delivery Address'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...addressProvider.savedAddresses
                        .map(
                          (savedAddress) => ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(savedAddress.label),
                            subtitle: Text(
                              savedAddress.address.fullAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing:
                                savedAddress.isDefault
                                    ? const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    )
                                    : null,
                            onTap: () {
                              setState(
                                () => selectedAddress = savedAddress.address,
                              );
                              Navigator.pop(context);
                            },
                          ),
                        )
                        .toList(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_location),
                      title: const Text('Add New Address'),
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await Navigator.pushNamed(
                          context,
                          '/address-selection',
                        );
                        if (result != null && result is DetailedAddress)
                          setState(() => selectedAddress = result);
                      },
                    ),
                  ],
                ),
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

    final subscriptionProvider = Provider.of<SubscriptionProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshCustomerData();
    if (authProvider.customer!.walletBalance < calculatedAmount) {
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
            content: Text('Subscription created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (product == null)
      return const Scaffold(body: Center(child: Text('Product not found')));

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
              // Product Info
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
                        child:
                            product!.imageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Icon(
                                  Icons.local_drink,
                                  color: Colors.grey,
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
                                fontSize: 16,
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(
                    selectedAddress != null
                        ? 'Address Selected'
                        : 'Select delivery address',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    selectedAddress?.fullAddress ?? 'Tap to select address',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _selectAddress,
                ),
              ),
              const SizedBox(height: 24),

              // Plan
              const Text(
                'Select Subscription Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    RadioListTile(
                      title: const Text('3-Day Trial Pack'),
                      subtitle: const Text('Daily for 3 days'),
                      value: SubscriptionType.trial,
                      groupValue: selectedType,
                      onChanged:
                          (v) => setState(
                            () => selectedType = v as SubscriptionType,
                          ),
                    ),
                    const Divider(height: 1),
                    RadioListTile(
                      title: const Text('Weekly'),
                      subtitle: const Text('Daily for 7 days'),
                      value: SubscriptionType.weekly,
                      groupValue: selectedType,
                      onChanged:
                          (v) => setState(
                            () => selectedType = v as SubscriptionType,
                          ),
                    ),
                    const Divider(height: 1),
                    RadioListTile(
                      title: const Text('Monthly'),
                      subtitle: const Text('Daily for 30 days'),
                      value: SubscriptionType.monthly,
                      groupValue: selectedType,
                      onChanged:
                          (v) => setState(
                            () => selectedType = v as SubscriptionType,
                          ),
                    ),
                    const Divider(height: 1),
                    RadioListTile(
                      title: const Text('Alternate Day'),
                      subtitle: const Text('15 deliveries over 30 days'),
                      value: SubscriptionType.alternateDay,
                      groupValue: selectedType,
                      onChanged:
                          (v) => setState(
                            () => selectedType = v as SubscriptionType,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- FIXED: Stacked Quantity vertically so it NEVER overflows ---
              const Text(
                'Quantity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Quantity:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed:
                                  quantity > 0.5
                                      ? () => setState(() => quantity -= 0.5)
                                      : null,
                              icon: const Icon(Icons.remove),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                quantity % 1 == 0
                                    ? '${quantity.toInt()} ${product!.unitText}'
                                    : '${quantity.toStringAsFixed(1)} ${product!.unitText}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => quantity += 0.5),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- FIXED: Payment Summary safely wrapped ---
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
                          const Text('Daily Amount:'),
                          Text(
                            '₹${(product!.price * quantity).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plan:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subscriptionDescription,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
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
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '₹${calculatedAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
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
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: Consumer<SubscriptionProvider>(
                  builder: (context, subscriptionProvider, child) {
                    return ElevatedButton(
                      onPressed:
                          subscriptionProvider.isLoading
                              ? null
                              : _createSubscription,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          subscriptionProvider.isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
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
