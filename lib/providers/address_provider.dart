import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_address.dart';
import '../models/address.dart';

class AddressProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<SavedAddress> _savedAddresses = [];
  bool _isLoading = false;
  String? _error;

  List<SavedAddress> get savedAddresses => _savedAddresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SavedAddress? get defaultAddress {
    try {
      return _savedAddresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return _savedAddresses.isNotEmpty ? _savedAddresses.first : null;
    }
  }

  Future<void> loadSavedAddresses(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simple query without ordering to avoid index requirement
      final querySnapshot = await _firestore
          .collection('saved_addresses')
          .where('customerId', isEqualTo: customerId)
          .get();

      _savedAddresses = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SavedAddress.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();

      // Sort locally by createdAt descending
      _savedAddresses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading saved addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAddress({
    required String customerId,
    required String label,
    required DetailedAddress address,
    bool isDefault = false,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // If this is set as default, update all other addresses to not be default
      if (isDefault) {
        final existingAddresses = await _firestore
            .collection('saved_addresses')
            .where('customerId', isEqualTo: customerId)
            .get();
        
        for (final doc in existingAddresses.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
      }

      // Create new address document
      final newAddressRef = _firestore.collection('saved_addresses').doc();
      final savedAddress = SavedAddress(
        id: newAddressRef.id,
        customerId: customerId,
        label: label,
        address: address,
        isDefault: isDefault,
        createdAt: DateTime.now(),
      );

      batch.set(newAddressRef, savedAddress.toMap());
      
      await batch.commit();
      
      // Reload addresses
      await loadSavedAddresses(customerId);
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving address: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateAddress(String addressId, {bool? isDefault}) async {
    try {
      final batch = _firestore.batch();
      
      if (isDefault == true) {
        // Find the address to get customerId
        final addressDoc = await _firestore
            .collection('saved_addresses')
            .doc(addressId)
            .get();
        
        if (addressDoc.exists) {
          final customerId = addressDoc.data()!['customerId'];
          
          // Update all other addresses to not be default
          final existingAddresses = await _firestore
              .collection('saved_addresses')
              .where('customerId', isEqualTo: customerId)
              .get();
          
          for (final doc in existingAddresses.docs) {
            batch.update(doc.reference, {'isDefault': false});
          }
        }
      }
      
      // Update the target address
      final updateData = <String, dynamic>{};
      if (isDefault != null) updateData['isDefault'] = isDefault;
      
      batch.update(
        _firestore.collection('saved_addresses').doc(addressId),
        updateData,
      );
      
      await batch.commit();
      
      // Update local state
      final index = _savedAddresses.indexWhere((addr) => addr.id == addressId);
      if (index != -1) {
        if (isDefault == true) {
          // Set all to false first
          for (int i = 0; i < _savedAddresses.length; i++) {
            _savedAddresses[i] = _savedAddresses[i].copyWith(isDefault: false);
          }
          // Set target to true
          _savedAddresses[index] = _savedAddresses[index].copyWith(isDefault: true);
        }
        notifyListeners();
      }
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating address: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _firestore.collection('saved_addresses').doc(addressId).delete();
      
      // Remove from local state
      _savedAddresses.removeWhere((address) => address.id == addressId);
      notifyListeners();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting address: $e');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
