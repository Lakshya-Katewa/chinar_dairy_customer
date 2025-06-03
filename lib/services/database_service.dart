import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/area.dart';
import '../models/order.dart';
import '../models/subscription.dart';
import '../models/cart_item.dart';
import '../models/transaction.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Customer operations
  Future<void> createCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).set(customer.toFirestore());
  }

  Future<Customer?> getCustomer(String customerId) async {
    final doc = await _db.collection('customers').doc(customerId).get();
    if (doc.exists) {
      return Customer.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateCustomer(Customer customer) async {
    await _db.collection('customers').doc(customer.id).update(customer.toFirestore());
  }

  // Product operations
  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProduct(String productId) async {
    final doc = await _db.collection('products').doc(productId).get();
    if (doc.exists) {
      return Product.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<Product>> searchProducts(String query) {
    return _db
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Area operations
  Stream<List<Area>> getAreas() {
    return _db.collection('areas').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Area.fromFirestore(doc)).toList());
  }

  // Order operations
  Future<String> createOrder(Order order) async {
    final docRef = await _db.collection('orders').add(order.toFirestore());
    return docRef.id;
  }

  Stream<List<Order>> getCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  Stream<List<Order>> getTodayOrders(String customerId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .where('deliveryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('deliveryDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  // Subscription operations
  Future<String> createSubscription(Subscription subscription) async {
    final docRef = await _db.collection('subscriptions').add(subscription.toFirestore());
    return docRef.id;
  }

  Stream<List<Subscription>> getCustomerSubscriptions(String customerId) {
    return _db
        .collection('subscriptions')
        .where('customerId', isEqualTo: customerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Subscription.fromFirestore(doc)).toList());
  }

  Future<void> updateSubscription(String subscriptionId, Map<String, dynamic> data) async {
    await _db.collection('subscriptions').doc(subscriptionId).update(data);
  }

  // Cart operations
  Future<String> addToCart(CartItem cartItem) async {
    final docRef = await _db.collection('cart').add(cartItem.toFirestore());
    return docRef.id;
  }

  Stream<List<CartItem>> getCartItems(String customerId) {
    return _db
        .collection('cart')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList());
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _db.collection('cart').doc(cartItemId).delete();
  }

  Future<void> clearCart(String customerId) async {
    final cartItems = await _db
        .collection('cart')
        .where('customerId', isEqualTo: customerId)
        .get();

    final batch = _db.batch();
    for (final doc in cartItems.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Transaction operations
  Future<String> createTransaction(Transaction transaction) async {
    final docRef = await _db.collection('transactions').add(transaction.toFirestore());
    return docRef.id;
  }

  Stream<List<Transaction>> getCustomerTransactions(String customerId) {
    return _db
        .collection('transactions')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  }

  // Wallet operations
  Future<void> updateWalletBalance(String customerId, double amount) async {
    await _db.runTransaction((transaction) async {
      final customerRef = _db.collection('customers').doc(customerId);
      final customerDoc = await transaction.get(customerRef);
      
      if (customerDoc.exists) {
        final currentBalance = (customerDoc.data()?['walletBalance'] ?? 0).toDouble();
        final newBalance = currentBalance + amount;
        transaction.update(customerRef, {'walletBalance': newBalance});
      }
    });
  }
}
