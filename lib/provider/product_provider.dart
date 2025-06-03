import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Product> _products = [];
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  List<Product> get products => _products;
  List<Product> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  void loadProducts() {
    _isLoading = true;
    notifyListeners();

    _databaseService.getProducts().listen((products) {
      _products = products;
      _isLoading = false;
      notifyListeners();
    });
  }

  void searchProducts(String query) {
    if (query.isEmpty) {
      _searchResults.clear();
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _databaseService.searchProducts(query).listen((products) {
      _searchResults = products;
      notifyListeners();
    });
  }

  void clearSearch() {
    _searchResults.clear();
    _isSearching = false;
    notifyListeners();
  }
}
