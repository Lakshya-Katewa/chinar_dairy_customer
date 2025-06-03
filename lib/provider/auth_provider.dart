import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/customer.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  User? _user;
  Customer? _customer;
  bool _isLoading = false;
  String? _verificationId;

  User? get user => _user;
  Customer? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get verificationId => _verificationId;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadCustomer(user.uid);
      } else {
        _customer = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadCustomer(String userId) async {
    try {
      _customer = await _databaseService.getCustomer(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading customer: $e');
    }
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _authService.signInWithPhoneCredential(credential);
          _isLoading = false;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          notifyListeners();
          throw Exception(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _authService.signInWithPhoneCredential(credential);
      if (userCredential?.user != null) {
        await _authService.saveLoginState(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Invalid OTP');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential?.user != null) {
        await _authService.saveLoginState(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Google sign in failed');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithEmail(email, password);
      if (userCredential?.user != null) {
        await _authService.saveLoginState(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.signUpWithEmail(email, password);
      if (userCredential?.user != null) {
        await _authService.saveLoginState(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> createCustomer({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String areaCode,
  }) async {
    if (_user == null) return;

    final customer = Customer(
      id: _user!.uid,
      name: name,
      phone: phone,
      email: email,
      address: address,
      areaCode: areaCode,
      walletBalance: 0.0,
      createdAt: DateTime.now(),
    );

    await _databaseService.createCustomer(customer);
    _customer = customer;
    notifyListeners();
  }

  Future<void> updateCustomer(Customer customer) async {
    await _databaseService.updateCustomer(customer);
    _customer = customer;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _customer = null;
    notifyListeners();
  }
}
