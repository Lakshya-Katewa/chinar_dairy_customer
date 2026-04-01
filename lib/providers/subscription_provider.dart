import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/address.dart';

class SubscriptionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  Future<void> loadSubscriptions(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('subscriptions')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        _subscriptions = snapshot.docs
            .map((doc) => Subscription.fromFirestore(doc))
            .toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double calculateSubscriptionAmount({
    required Product product,
    required SubscriptionType type,
    required double quantity,
  }) {
    final dailyAmount = product.price * quantity;

    // FIX FOR ISSUE #11: Added pricing for Trial pack (3 days)
    switch (type) {
      case SubscriptionType.trial:
        return dailyAmount * 3;
      case SubscriptionType.weekly:
        return dailyAmount * 7;
      case SubscriptionType.monthly:
        return dailyAmount * 30;
      case SubscriptionType.alternateDay:
        return dailyAmount * 15;
    }
  }

  DateTime calculateEndDate(SubscriptionType type, DateTime startDate) {
    // FIX FOR ISSUE #11: Added end date calculation for Trial pack
    switch (type) {
      case SubscriptionType.trial:
        // A 3-day period (inclusive) ends 2 days after the start date.
        return startDate.add(const Duration(days: 2));
      case SubscriptionType.weekly:
        // A 7-day period (inclusive) ends 6 days after the start date.
        return startDate.add(const Duration(days: 6));
      case SubscriptionType.monthly:
        // A 30-day period (inclusive) ends 29 days after the start date.
        return startDate.add(const Duration(days: 29));
      case SubscriptionType.alternateDay:
        // 15 deliveries over a period of 30 days (inclusive).
        return startDate.add(const Duration(days: 29));
    }
  }

  Future<void> createSubscription({
    required Customer customer,
    required Product product,
    required SubscriptionType type,
    required double quantity,
    required DetailedAddress deliveryAddress,
  }) async {
    final totalAmount = calculateSubscriptionAmount(
      product: product,
      type: type,
      quantity: quantity,
    );

    if (customer.walletBalance < totalAmount) {
      throw Exception('Insufficient wallet balance. Add ₹${totalAmount - customer.walletBalance} to continue.');
    }

    final now = DateTime.now();
    final todayAtMidnight = DateTime(now.year, now.month, now.day);
    final startDate = todayAtMidnight.add(const Duration(days: 1));

    final subscription = Subscription(
      id: '',
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      customerEmail: customer.email ?? '',
      productId: product.id,
      productName: product.name,
      type: type,
      startDate: startDate,
      endDate: calculateEndDate(type, startDate),
      isActive: true,
      quantity: quantity,
      pricePerUnit: product.price,
      totalAmount: totalAmount,
      areaCode: customer.areaCode,
      address: deliveryAddress.formattedAddress,
      status: SubscriptionStatus.active,
      imageUrl: product.imageUrl,
      createdAt: DateTime.now(),
    );

    try {
      final batch = _firestore.batch();
      final subscriptionRef = _firestore.collection('subscriptions').doc();
      batch.set(subscriptionRef, subscription.toMap());
      final customerRef = _firestore.collection('customers').doc(customer.id);
      batch.update(customerRef, {
        'walletBalance': customer.walletBalance - totalAmount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      final transactionRef = _firestore.collection('transactions').doc();
      batch.set(transactionRef, {
        'customerId': customer.id,
        'amount': totalAmount,
        'type': 'debit',
        'description': 'Subscription payment for ${product.name}',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  Future<void> pauseSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': SubscriptionStatus.paused.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to pause subscription: $e');
    }
  }

  Future<void> resumeSubscription(String subscriptionId) async {
    try {
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': SubscriptionStatus.active.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to resume subscription: $e');
    }
  }

  Future<double> cancelSubscription(String subscriptionId) async {
    double refundAmount = 0;
    try {
      final subDoc = await _firestore.collection('subscriptions').doc(subscriptionId).get();
      if (!subDoc.exists) throw Exception('Subscription not found');

      final subscription = Subscription.fromFirestore(subDoc);

      if ((subscription.status == SubscriptionStatus.active || subscription.status == SubscriptionStatus.paused) && subscription.endDate != null) {
        final now = DateTime.now();
        if (now.isBefore(subscription.endDate!)) {
            final totalDays = subscription.endDate!.difference(subscription.startDate).inDays + 1;
            final daysUsed = now.difference(subscription.startDate).inDays;

            if (totalDays > 0 && daysUsed < totalDays) {
              final pricePerDay = subscription.totalAmount / totalDays;
              final remainingDays = totalDays - daysUsed;
              refundAmount = pricePerDay * remainingDays;
            }
        }
      }

      final batch = _firestore.batch();
      final subRef = _firestore.collection('subscriptions').doc(subscriptionId);
      batch.update(subRef, {
        'status': SubscriptionStatus.cancelled.name,
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (refundAmount > 0) {
        final customerRef = _firestore.collection('customers').doc(subscription.customerId);
        batch.update(customerRef, {
          'walletBalance': FieldValue.increment(refundAmount),
        });
        final transactionRef = _firestore.collection('transactions').doc();
        batch.set(transactionRef, {
          'customerId': subscription.customerId,
          'amount': refundAmount,
          'type': 'credit',
          'description': 'Refund for cancelled subscription #${subscription.id.substring(0, 6)}',
          'createdAt': Timestamp.now(),
        });
        debugPrint('Refunding ₹${refundAmount.toStringAsFixed(2)} for subscription ${subscription.id}');
      }
      
      await batch.commit();

      return refundAmount;

    } catch (e) {
      debugPrint('Error during subscription cancellation: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }
}