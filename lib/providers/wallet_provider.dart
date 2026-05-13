import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

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
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }
}

class WalletProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Transaction> _transactions = [];
  bool _isLoading = false;
  double _walletBalance = 0.0;
  String? _currentCustomerId;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get walletBalance => _walletBalance;
  double get balance => _walletBalance;

  void updateWalletBalance(double balance) {
    _walletBalance = balance;
    notifyListeners();
  }

  Future<void> loadTransactions(String customerId) async {
    _currentCustomerId = customerId;
    _isLoading = true;
    notifyListeners();

    try {
      _firestore.collection('customers').doc(customerId).snapshots().listen((
        snapshot,
      ) {
        if (snapshot.exists) {
          _walletBalance =
              (snapshot.data()?['walletBalance'] ?? 0.0).toDouble();
          notifyListeners();
        }
      });

      _firestore
          .collection('transactions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            _transactions =
                snapshot.docs
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

  Future<void> deductFromWallet({
    required String customerId,
    required double amount,
    required String description,
  }) async {
    try {
      final batch = _firestore.batch();
      final customerRef = _firestore.collection('customers').doc(customerId);

      batch.update(customerRef, {
        'walletBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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

  Future<void> addToWallet({
    required String customerId,
    required double amount,
    required String description,
    required String transactionId,
  }) async {
    try {
      // 1. Check if this transaction has already been processed (Safety against duplicates)
      final existingTx =
          await _firestore
              .collection('transactions')
              .where('transactionId', isEqualTo: transactionId)
              .get();

      if (existingTx.docs.isNotEmpty) {
        throw Exception('This transaction has already been processed.');
      }

      final batch = _firestore.batch();
      final customerRef = _firestore.collection('customers').doc(customerId);

      // 2. Update wallet balance
      batch.update(customerRef, {
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Log the transaction with the unique Razorpay Payment ID
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'customerId': customerId,
        'amount': amount,
        'type': 'credit',
        'description': description,
        'transactionId': transactionId, // Razorpay Payment ID
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Clear any low balance notifications
      await flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Wallet Error: $e');
      throw Exception('Failed to add to wallet: $e');
    }
  }
}
