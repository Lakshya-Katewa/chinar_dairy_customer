import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/customer.dart';
import '../models/address.dart';

class OrderProvider with ChangeNotifier {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrders(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Loading orders for customer: $customerId');

      // Set up real-time listener
      _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .listen((snapshot) {
        debugPrint('🔄 Orders snapshot received: ${snapshot.docs.length} orders');

        _orders.clear();
        List<Order> tempOrders = [];

        for (var doc in snapshot.docs) {
          try {
            final order = Order.fromFirestore(doc);
            tempOrders.add(order);
            debugPrint('✅ Successfully parsed order: ${order.id}');
          } catch (e) {
            debugPrint('❌ Error parsing order ${doc.id}: $e');
          }
        }

        // Sort orders by creation date (newest first)
        tempOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _orders = tempOrders;

        debugPrint('📋 Final orders list: ${_orders.length} orders');
        _isLoading = false;
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ Error listening to orders: $error');
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fixed method name and implementation
  Future<String> createOrder({
    required String customerId,
    required List<CartItem> items,
    required double totalAmount,
    required DetailedAddress deliveryAddress,
    required String paymentMethod,
    required String paymentId,
    String? deliverySlot,
  }) async {
    try {
      // Get customer details
      final customerDoc = await _firestore.collection('customers').doc(customerId).get();
      
      if (!customerDoc.exists) {
        throw Exception('Customer not found');
      }
      
      final customerData = customerDoc.data() as Map<String, dynamic>;

      final orderItems = items.map((cartItem) => OrderItem(
        productId: cartItem.productId,
        productName: cartItem.productName,
        quantity: cartItem.quantity.toInt(),
        price: cartItem.price,
        unit: cartItem.unit,
        imageUrl: cartItem.imageUrl,
      )).toList();

      final order = Order(
        id: '',
        customerId: customerId,
        customerName: customerData['name'] ?? '',
        customerPhone: customerData['phone'] ?? '',
        items: orderItems,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        deliveryAddress: deliveryAddress,
        orderDate: DateTime.now(),
        deliveryDate: DateTime.now().add(const Duration(days: 1)), // Default next day
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        deliverySlot: deliverySlot,
        createdAt: DateTime.now(),
      );

      // Create order
      final orderDoc = await _firestore.collection('orders').add(order.toMap());

      // Auto-save delivery address
      await _autoSaveDeliveryAddress(customerId, deliveryAddress);

      // If payment method is wallet, deduct from wallet
      if (paymentMethod == 'wallet') {
        await _firestore.collection('customers').doc(customerId).update({
          'walletBalance': firestore.FieldValue.increment(-totalAmount),
          'updatedAt': firestore.Timestamp.fromDate(DateTime.now()),
        });

        // Create transaction record
        await _firestore.collection('transactions').add({
          'customerId': customerId,
          'amount': totalAmount,
          'type': 'debit',
          'description': 'Order payment - Order #${orderDoc.id.substring(0, 8)}',
          'orderId': orderDoc.id,
          'paymentMethod': paymentMethod,
          'paymentId': paymentId,
          'createdAt': firestore.Timestamp.fromDate(DateTime.now()),
        });
      }

      return orderDoc.id;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Auto-save delivery address like Swiggy
  Future<void> _autoSaveDeliveryAddress(String customerId, DetailedAddress address) async {
    try {
      // Check if this address already exists
      final existingAddresses = await _firestore
          .collection('saved_addresses')
          .where('customerId', isEqualTo: customerId)
          .where('address.fullAddress', isEqualTo: address.fullAddress)
          .get();

      if (existingAddresses.docs.isEmpty) {
        // Address doesn't exist, save it
        final addressCount = await _firestore
            .collection('saved_addresses')
            .where('customerId', isEqualTo: customerId)
            .get();

        final isFirstAddress = addressCount.docs.isEmpty;
        
        await _firestore.collection('saved_addresses').add({
          'customerId': customerId,
          'label': isFirstAddress ? 'Home' : 'Address ${addressCount.docs.length + 1}',
          'address': address.toMap(),
          'isDefault': isFirstAddress, // First address becomes default
          'createdAt': firestore.Timestamp.fromDate(DateTime.now()),
        });

        debugPrint('✅ Auto-saved delivery address');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to auto-save address: $e');
      // Don't throw error as this is not critical for order placement
    }
  }

  Future<String> placeOrder({
    required Customer customer,
    required List<CartItem> cartItems,
    required DetailedAddress deliveryAddress,
    required DateTime deliveryDate,
    String? notes,
  }) async {
    final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    if (customer.walletBalance < totalAmount) {
      throw Exception('Insufficient wallet balance. Add ₹${(totalAmount - customer.walletBalance).toStringAsFixed(2)} to continue.');
    }

    final orderItems = cartItems.map((cartItem) => OrderItem(
      productId: cartItem.productId,
      productName: cartItem.productName,
      quantity: cartItem.quantity.toInt(),
      price: cartItem.price,
      unit: cartItem.unit,
      imageUrl: cartItem.imageUrl,
    )).toList();

    final order = Order(
      id: '',
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      items: orderItems,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      orderDate: DateTime.now(),
      deliveryDate: deliveryDate,
      notes: notes,
      paymentMethod: 'wallet',
      paymentId: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    try {
      // Create order
      final orderDoc = await _firestore.collection('orders').add(order.toMap());

      // Auto-save delivery address
      await _autoSaveDeliveryAddress(customer.id, deliveryAddress);

      // Update wallet balance
      await _firestore.collection('customers').doc(customer.id).update({
        'walletBalance': customer.walletBalance - totalAmount,
        'updatedAt': firestore.Timestamp.fromDate(DateTime.now()),
      });

      // Create transaction record
      await _firestore.collection('transactions').add({
        'customerId': customer.id,
        'amount': totalAmount,
        'type': 'debit',
        'description': 'Order payment - Order #${orderDoc.id.substring(0, 8)}',
        'orderId': orderDoc.id,
        'paymentMethod': 'wallet',
        'createdAt': firestore.Timestamp.fromDate(DateTime.now()),
      });

      return orderDoc.id;
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
  try {
    // --- START: MODIFIED CODE ---
    final updateData = <String, dynamic>{
      'status': status.toString().split('.').last,
      'updatedAt': firestore.Timestamp.fromDate(DateTime.now()),
    };

    // If the order is being marked as delivered, also set the deliveredAt timestamp
    if (status == OrderStatus.delivered) {
      updateData['deliveredAt'] = firestore.Timestamp.fromDate(DateTime.now());
    }
    
    await _firestore.collection('orders').doc(orderId).update(updateData);
    // --- END: MODIFIED CODE ---

  } catch (e) {
    throw Exception('Failed to update order status: $e');
  }
}

  Future<void> cancelOrder(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final order = Order.fromFirestore(orderDoc);

      // Only allow cancellation if order is pending or confirmed
      if (order.status != OrderStatus.pending && order.status != OrderStatus.confirmed) {
        throw Exception('Order cannot be cancelled at this stage');
      }

      // Update order status to cancelled
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': firestore.Timestamp.fromDate(DateTime.now()),
      });

      // Refund to wallet if payment was made
      if (order.paymentMethod == 'wallet' || order.paymentMethod == 'razorpay') {
        await _firestore.collection('customers').doc(order.customerId).update({
          'walletBalance': firestore.FieldValue.increment(order.totalAmount),
          'updatedAt': firestore.Timestamp.fromDate(DateTime.now()),
        });

        // Create refund transaction record
        await _firestore.collection('transactions').add({
          'customerId': order.customerId,
          'amount': order.totalAmount,
          'type': 'credit',
          'description': 'Order cancellation refund - Order #${orderId.substring(0, 8)}',
          'orderId': orderId,
          'paymentMethod': 'refund',
          'createdAt': firestore.Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
