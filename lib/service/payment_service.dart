import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> openCheckout({
    required double amount,
    required String orderId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) async {
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    // Ensure amount is at least 100 paise (₹1.00)
    int amountInPaise = (amount * 100).toInt();
    if (amountInPaise < 100) amountInPaise = 100;

    var options = {
      'key': 'rzp_test_SeVEtAoJ3Trffh', // Correct confirmed key
      'amount': amountInPaise,
      'name': 'Chinar Dairy',
      'description': description,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'external': {
        'wallets': ['paytm'],
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("RAZORPAY SUCCESS: ${response.paymentId}");
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Failed: ${response.code} - ${response.message}');
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onExternalWallet?.call(response);
  }

  static String generateOrderId() {
    return 'test_order_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _razorpay.clear();
  }
}
