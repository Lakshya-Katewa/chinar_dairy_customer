import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../service/payment_service.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/order_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String paymentType; // 'order' or 'subscription' or 'wallet_topup'
  final Map<String, dynamic>? orderData;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.paymentType,
    this.orderData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String _selectedPaymentMethod = 'razorpay';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final customer = authProvider.customer!;

    try {
      if (_selectedPaymentMethod == 'razorpay') {
        await _processRazorpayPayment(customer);
      } else if (_selectedPaymentMethod == 'wallet') {
        await _processWalletPayment();
      }
    } catch (e) {
      _showErrorDialog('Payment failed: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processRazorpayPayment(customer) async {
    final orderId = PaymentService.generateOrderId();

    await _paymentService.openCheckout(
      amount: widget.totalAmount,
      orderId: orderId,
      customerName: customer.name,
      customerEmail: customer.email ?? 'customer@chinardairy.com',
      customerPhone: customer.phone,
      description: _getPaymentDescription(),
      onSuccess: (PaymentSuccessResponse response) {
        _handlePaymentSuccess(response.paymentId!, 'razorpay');
      },
      onError: (PaymentFailureResponse response) {
        _showErrorDialog('Payment failed: ${response.message}');
      },
      onExternalWallet: (ExternalWalletResponse response) {
        _showInfoDialog('Payment initiated via ${response.walletName}');
      },
    );
  }

  Future<void> _processWalletPayment() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (walletProvider.balance < widget.totalAmount) {
      _showErrorDialog('Insufficient wallet balance. Please top up your wallet.');
      return;
    }

    try {
      await walletProvider.deductFromWallet(
        customerId: authProvider.customer!.id,
        amount: widget.totalAmount,
        description: _getPaymentDescription(),
      );

      _handlePaymentSuccess('wallet_${DateTime.now().millisecondsSinceEpoch}', 'wallet');
    } catch (e) {
      _showErrorDialog('Wallet payment failed: $e');
    }
  }

  Future<void> _handlePaymentSuccess(String paymentId, String paymentMethod) async {
    try {
      if (widget.paymentType == 'order') {
        await _createOrder(paymentId, paymentMethod);
      } else if (widget.paymentType == 'subscription') {
        await _createSubscription(paymentId, paymentMethod);
      } else if (widget.paymentType == 'wallet_topup') {
        await _topUpWallet(paymentId, paymentMethod);
      }
      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Failed to process payment: $e');
    }
  }

  Future<void> _createOrder(String paymentId, String paymentMethod) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await orderProvider.createOrder(
      customerId: authProvider.customer!.id,
      items: cartProvider.items,
      totalAmount: widget.totalAmount,
      deliveryAddress: widget.orderData?['deliveryAddress'],
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      deliverySlot: widget.orderData?['deliverySlot'],
    );

    cartProvider.clearCart(authProvider.customer!.id);
  }

  Future<void> _createSubscription(String paymentId, String paymentMethod) async {
    // Implement subscription creation logic
    debugPrint('Creating subscription with payment ID: $paymentId');
  }

  Future<void> _topUpWallet(String paymentId, String paymentMethod) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await walletProvider.addToWallet(
      customerId: authProvider.customer!.id,
      amount: widget.totalAmount,
      description: 'Wallet top-up via $paymentMethod',
      transactionId: paymentId,
    );
  }

  String _getPaymentDescription() {
    switch (widget.paymentType) {
      case 'order':
        return 'Order payment - Chinar Dairy';
      case 'subscription':
        return 'Subscription payment - Chinar Dairy';
      case 'wallet_topup':
        return 'Wallet top-up - Chinar Dairy';
      default:
        return 'Payment - Chinar Dairy';
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Payment Successful!'),
        content: Text(_getSuccessMessage()),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.info, color: Colors.blue, size: 64),
        title: const Text('Payment Info'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getSuccessMessage() {
    switch (widget.paymentType) {
      case 'order':
        return 'Your order has been placed successfully!';
      case 'subscription':
        return 'Your subscription has been activated successfully!';
      case 'wallet_topup':
        return 'Your wallet has been topped up successfully!';
      default:
        return 'Payment completed successfully!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _getPaymentDescription(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Text(
                        '₹${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Payment Methods
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Razorpay Option
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RadioListTile<String>(
                value: 'razorpay',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() => _selectedPaymentMethod = value!);
                },
                title: const Text(
                  'Credit/Debit Card, UPI, Net Banking',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pay securely via Razorpay'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.payment, color: Colors.blue),
                ),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            // Wallet Option
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: RadioListTile<String>(
                value: 'wallet',
                groupValue: _selectedPaymentMethod,
                onChanged: widget.paymentType == 'wallet_topup'
                    ? null
                    : (value) {
                        setState(() => _selectedPaymentMethod = value!);
                      },
                title: Text(
                  'Wallet Balance (₹${walletProvider.balance.toStringAsFixed(2)})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  walletProvider.balance >= widget.totalAmount
                      ? 'Pay from your wallet balance'
                      : 'Insufficient balance',
                  style: TextStyle(
                    color: walletProvider.balance >= widget.totalAmount
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: walletProvider.balance >= widget.totalAmount
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: walletProvider.balance >= widget.totalAmount
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                activeColor: Theme.of(context).primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(height: 40),
            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Text(
                        'Pay ₹${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            // Security Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
