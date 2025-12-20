import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;
  
  // Callback functions
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
    // Store callbacks
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    var options = {
      'key': 'rzp_test_0UJcJkVMPrEqog', // Replace with your actual Razorpay key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Chinar Dairy',
      'order_id': orderId,
      'description': description,
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {
        'color': '#4CAF50'
      },
      'modal': {
        'ondismiss': () {
          debugPrint('Payment cancelled by user');
        }
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      _onError?.call(PaymentFailureResponse(
        1, // code
        'Failed to open payment gateway', // message  
        'PAYMENT_GATEWAY_ERROR' as Map?, // error
      ));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  static String generateOrderId() {
    return 'order_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _razorpay.clear();
  }
}
