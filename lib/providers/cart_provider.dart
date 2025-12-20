import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get items => _cartItems; // Added getter for compatibility
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> loadCartItems(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _firestore
          .collection('carts')
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .listen((snapshot) {
        _cartItems = snapshot.docs
            .map((doc) => CartItem.fromFirestore(doc))
            .toList();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading cart items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required String customerId,
    required Product product,
    required double quantity,
  }) async {
    try {
      // Check for existing item
      final existingItemQuery = await _firestore
          .collection('carts')
          .where('customerId', isEqualTo: customerId)
          .where('productId', isEqualTo: product.id)
          .limit(1)
          .get();

      if (existingItemQuery.docs.isNotEmpty) {
        // Update quantity
        final existingDoc = existingItemQuery.docs.first;
        final existingItem = CartItem.fromFirestore(existingDoc);
        await _firestore
            .collection('carts')
            .doc(existingDoc.id)
            .update({'quantity': existingItem.quantity + quantity});
      } else {
        // Add new item
        final cartItem = CartItem(
          id: '',
          customerId: customerId,
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          price: product.price,
          unit: product.unitText,
          imageUrl: product.imageUrl,
        );
        
        await _firestore.collection('carts').add(cartItem.toMap());
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  Future<void> updateQuantity(String cartItemId, double newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      await _firestore
          .collection('carts')
          .doc(cartItemId)
          .update({'quantity': newQuantity});
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _firestore.collection('carts').doc(cartItemId).delete();
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<void> clearCart([String? customerId]) async {
    try {
      if (customerId != null) {
        final cartItems = await _firestore
            .collection('carts')
            .where('customerId', isEqualTo: customerId)
            .get();

        final batch = _firestore.batch();
        for (final doc in cartItems.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } else {
        // Clear local cart items
        _cartItems.clear();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }
}
