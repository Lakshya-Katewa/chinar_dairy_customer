import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  int get itemCount => _cartItems.length;
  double get totalAmount => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  void loadCartItems(String customerId) {
    _databaseService.getCartItems(customerId).listen((items) {
      _cartItems = items;
      notifyListeners();
    });
  }

  Future<void> addToCart({
    required String customerId,
    required Product product,
    required double quantity,
    DateTime? orderDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cartItem = CartItem(
        id: '',
        customerId: customerId,
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: quantity,
        unit: product.unitText,
        orderDate: orderDate,
        createdAt: DateTime.now(),
      );

      await _databaseService.addToCart(cartItem);
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.removeFromCart(cartItemId);
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.clearCart(customerId);
      _cartItems.clear();
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
