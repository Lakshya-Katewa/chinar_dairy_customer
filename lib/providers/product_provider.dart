// product_provider.dart (Updated)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All'; // NEW: To track selected category

  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory; // NEW: Getter

  // NEW: Get a unique list of categories for the filter chips
  List<String> get categories {
    final allCategories = _products.map((p) => p.category).toSet().toList();
    allCategories.sort();
    return ['All', ...allCategories];
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('products').get();

      _products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      _products.sort((a, b) => a.name.compareTo(b.name));
      
      _applyFilters(); // UPDATED: Use a central filter method
      
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Central method to apply all filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || product.name.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }
  
  // NEW: Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsByCategory(String category) {
    return _products
        .where((product) => product.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}