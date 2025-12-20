import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class Transaction {
  final String id;
  final String customerId;
  final double amount;
  final String type;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class WalletProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Razorpay _razorpay;
  
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  double _walletBalance = 0.0;
  String? _currentCustomerId;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get walletBalance => _walletBalance;
  double get balance => _walletBalance; // Added getter for compatibility

  WalletProvider() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> loadTransactions(String customerId) async {
    _currentCustomerId = customerId;
    _isLoading = true;
    notifyListeners();

    try {
      // Load wallet balance from customer document with real-time updates
      _firestore
          .collection('customers')
          .doc(customerId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final newBalance = (snapshot.data()!['walletBalance'] ?? 0.0).toDouble();
          if (_walletBalance != newBalance) {
            _walletBalance = newBalance;
            notifyListeners();
          }
        }
      });

      // Listen to real-time transaction updates
      _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _transactions = snapshot.docs
            .map((doc) => Transaction.fromFirestore(doc))
            .toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateWalletBalance(double balance) {
    _walletBalance = balance;
    notifyListeners();
  }

  // Added method for payment screen compatibility
  Future<void> deductFromWallet({
    required String customerId,
    required double amount,
    required String description,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update customer wallet balance
      final customerRef = _firestore.collection('customers').doc(customerId);
      batch.update(customerRef, {
        'walletBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'customerId': customerId,
        'amount': amount,
        'type': 'debit',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to deduct from wallet: $e');
    }
  }

  // Added method for payment screen compatibility
  Future<void> addToWallet({
    required String customerId,
    required double amount,
    required String description,
    required String transactionId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update customer wallet balance
      final customerRef = _firestore.collection('customers').doc(customerId);
      batch.update(customerRef, {
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'customerId': customerId,
        'amount': amount,
        'type': 'credit',
        'description': description,
        'transactionId': transactionId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to add to wallet: $e');
    }
  }

  Future<void> addMoney({
    required String customerId,
    required double amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Chinar Dairy',
      'description': 'Add money to wallet',
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
      },
      'theme': {
        'color': '#4CAF50',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay: $e');
      throw Exception('Failed to open payment gateway: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    
    if (_currentCustomerId != null) {
      try {
        // You would typically verify this payment on your backend
        // For now, we'll simulate a successful wallet top-up
        // In production, implement proper payment verification
        
        // The wallet balance will be updated via real-time listener
        // when the backend processes the payment
      } catch (e) {
        debugPrint('Error processing payment success: $e');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    // Handle payment error - you might want to show a user-friendly message
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }
}
