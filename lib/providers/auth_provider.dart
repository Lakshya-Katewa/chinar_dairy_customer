import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/customer.dart';
import '../models/address.dart';
import 'referal_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReferralProvider _referralProvider = ReferralProvider();
  
  Customer? _customer;
  bool _isLoading = false;
  String? _verificationId;
  bool _isInitialized = false;
  int? _resendToken;
  bool _canResendOTP = true;
  int _resendCooldown = 0;
  Timer? _resendTimer;
  String? _lastPhoneNumber;

  Customer? get customer => _customer;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _customer != null && _isInitialized;
  bool get isInitialized => _isInitialized;
  bool get canResendOTP => _canResendOTP;
  int get resendCooldown => _resendCooldown;

  // Initialize auth state when app starts
  AuthProvider() {
    _initializeAuth();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    // Listen to auth state changes to automatically handle login/logout state.
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // If user is already logged in and we haven't loaded their data yet.
        if (_customer == null || !_isInitialized) {
          await _loadCustomerData();
        }
      } else {
        // User logged out.
        _customer = null;
      }
      // Mark initialization as complete after the first check.
      if (!_isInitialized) {
        _isInitialized = true;
        notifyListeners();
      }
    });

    // Initial check for a currently signed-in user.
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _loadCustomerData();
    } else {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _canResendOTP = false;
    _resendCooldown = 60; // 60 seconds cooldown
    notifyListeners();
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        _resendCooldown--;
      } else {
        _canResendOTP = true;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> sendOTP(String phoneNumber) async {
    if (_isLoading) return;
    _isLoading = true;
    _lastPhoneNumber = phoneNumber;
    notifyListeners();

    try {
      final completer = Completer<void>();
       
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            debugPrint('Auto verification completed');
            await _auth.signInWithCredential(credential);
            await _loadCustomerData();
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            debugPrint('Auto verification failed: $e');
            if (!completer.isCompleted) completer.completeError(e);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Verification failed: ${e.code} - ${e.message}');
          
          String errorMessage = 'Failed to send OTP. Please try again.';
          switch (e.code) {
            case 'too-many-requests':
              errorMessage = 'Too many requests. Please try again later.';
              break;
            case 'invalid-phone-number':
              errorMessage = 'The phone number provided is not valid.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded for this project. Please try again later.';
              break;
            case 'captcha-check-failed':
              errorMessage = 'reCAPTCHA check failed. Please ensure you have a stable network connection.';
              break;
            default:
              if (e.message?.contains('unusual activity') == true) {
                errorMessage = 'Unusual activity detected from this device. Please try again later.';
              } else {
                errorMessage = e.message ?? 'An unknown error occurred.';
              }
          }
          
          if (!completer.isCompleted) {
            completer.completeError(Exception(errorMessage));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Code sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _startResendCooldown();
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Code auto retrieval timeout');
          _verificationId = verificationId;
          
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        forceResendingToken: _resendToken,
      );

      await completer.future;
      
    } catch (e) {
      debugPrint('Send OTP error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendOTP() async {
    if (!_canResendOTP) {
      throw Exception('Please wait $_resendCooldown seconds before resending OTP');
    }
    
    if (_lastPhoneNumber == null) {
      throw Exception('Phone number not found. Please go back and try again.');
    }
    
    debugPrint('Resending OTP to: $_lastPhoneNumber');
    await sendOTP(_lastPhoneNumber!);
  }

  Future<bool> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw Exception('Verification ID not found. Please request OTP again.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential,);
      if (userCredential.user != null) {
        await _loadCustomerData();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      
      String errorMessage = 'Invalid OTP';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = 'Invalid OTP. Please check and try again.';
            break;
          case 'session-expired':
            errorMessage = 'OTP expired. Please request a new one.';
            _verificationId = null; // Clear expired verification ID
            break;
          case 'invalid-verification-id':
            errorMessage = 'Invalid verification session. Please request OTP again.';
            _verificationId = null;
            break;
          default:
            errorMessage = e.message ?? 'Invalid OTP';
        }
      }
      throw Exception(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alternative login method for development/testing
  Future<void> signInWithTestAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create a test customer for development
      final testCustomer = Customer(
        id: 'test_customer_id',
        name: 'Test User',
        phone: '9999999999',
        email: 'test@example.com',
        address: DetailedAddress(
          houseNumber: '123',
          street: 'Test Street',
         
          city: 'Test City',
          
          pinCode: '123456',
          landmark: 'Test Landmark',
          latitude: 0.0,
          longitude: 0.0,
          fullAddress: '123, Test Street, Test Area, Test City, Test State - 123456',
        ),
        areaCode: 'TEST001',
        walletBalance: 100.0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        referralCode: 'TEST123',
        referredBy: null,
        hasUsedReferral: false,
        referralRewardClaimed: false,
        successfulReferrals: 0,
      );

      _customer = testCustomer;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Test sign in error: $e');
      throw Exception('Test sign in failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCustomerData() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      // Extract phone number without country code
      String phoneNumber = user.phoneNumber ?? '';
      if (phoneNumber.startsWith('+91')) {
        phoneNumber = phoneNumber.substring(3);
      }

      final querySnapshot = await _firestore
          .collection('customers')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _customer = Customer.fromFirestore(querySnapshot.docs.first);
      } else {
        // Customer doesn't exist, will need to create profile
        _customer = null;
      }
    } catch (e) {
      debugPrint('Error loading customer data: $e');
      _customer = null;
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
      }
      notifyListeners();
    }
  }

  Future<void> refreshCustomerData() async {
    if (_customer == null) return;

    try {
      final doc = await _firestore
          .collection('customers')
          .doc(_customer!.id)
          .get();

      if (doc.exists) {
        _customer = Customer.fromFirestore(doc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing customer data: $e');
    }
  }

  Future<void> createCustomer({
    required String name,
    required String email,
    required DetailedAddress address,
    required String areaCode,
    String? referralCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    _isLoading = true;
    notifyListeners();

    try {
      String phoneNumber = user.phoneNumber ?? '';
      if (phoneNumber.startsWith('+91')) {
        phoneNumber = phoneNumber.substring(3);
      }

      final existingCustomer = await _firestore
          .collection('customers')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (existingCustomer.docs.isNotEmpty) {
        _customer = Customer.fromFirestore(existingCustomer.docs.first);
        notifyListeners();
        return;
      }

      if (referralCode != null && referralCode.isNotEmpty) {
        final isValidReferral = await _referralProvider.validateReferralCode(referralCode);
        if (!isValidReferral) {
          throw Exception('Invalid referral code');
        }
      }

      final userReferralCode = _referralProvider.generateReferralCode(name, user.uid);

      final newCustomer = Customer(
        id: '', // Firestore will generate this
        name: name,
        phone: phoneNumber,
        email: email,
        address: address,
        areaCode: areaCode,
        walletBalance: 0.0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        referralCode: userReferralCode,
        referredBy: referralCode?.toUpperCase(),
        hasUsedReferral: referralCode != null && referralCode.isNotEmpty,
        referralRewardClaimed: false,
        successfulReferrals: 0,
      );

      final docRef = await _firestore.collection('customers').add(newCustomer.toMap());
      _customer = newCustomer.copyWith(id: docRef.id);
      notifyListeners();

    } catch (e) {
      debugPrint('Failed to create customer: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _customer = null;
    _verificationId = null;
    _resendToken = null;
    _canResendOTP = true;
    _resendCooldown = 0;
    _lastPhoneNumber = null;
    _resendTimer?.cancel();
    notifyListeners();
  }

  bool get needsRegistration {
    final user = _auth.currentUser;
    return user != null && _customer == null && _isInitialized;
  }

  void resetVerificationState() {
    _verificationId = null;
    _resendToken = null;
    _canResendOTP = true;
    _resendCooldown = 0;
    _lastPhoneNumber = null;
    _resendTimer?.cancel();
    notifyListeners();
  }
}

extension on Customer {
  Customer copyWith({String? id}) {
    return Customer(
      id: id ?? this.id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      areaCode: areaCode,
      walletBalance: walletBalance,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      referralCode: referralCode,
      referredBy: referredBy,
      hasUsedReferral: hasUsedReferral,
      referralRewardClaimed: referralRewardClaimed,
      successfulReferrals: successfulReferrals,
    );
  }
}