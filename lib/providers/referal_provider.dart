import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class ReferralProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String generateReferralCode(String name, String uid) {
    final namePrefix = name.length >= 4 
        ? name.substring(0, 4).toUpperCase() 
        : name.toUpperCase().padRight(4, 'X');
    final uidSuffix = uid.length >= 4 
        ? uid.substring(0, 4).toUpperCase() 
        : uid.toUpperCase().padRight(4, '0');
    return '$namePrefix$uidSuffix';
  }

  Future<bool> validateReferralCode(String code) async {
    if (code.isEmpty) return true; // Optional field
    
    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('referralCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating referral code: $e');
      return false;
    }
  }

  Future<void> applyReferralRewards(String userId) async {
    try {
      final userDoc = await _firestore.collection('customers').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final referredBy = userData['referredBy'] as String?;
      final referralRewardClaimed = userData['referralRewardClaimed'] ?? false;

      if (referredBy != null && !referralRewardClaimed) {
        // Find the referrer
        final referrerSnapshot = await _firestore
            .collection('customers')
            .where('referralCode', isEqualTo: referredBy)
            .limit(1)
            .get();

        if (referrerSnapshot.docs.isNotEmpty) {
          final referrerDoc = referrerSnapshot.docs.first;
          final referrerData = referrerDoc.data();
          final currentReferrals = referrerData['successfulReferrals'] ?? 0;

          // Check if referrer hasn't exceeded max referrals (e.g., 10)
          if (currentReferrals < 10) {
            final batch = _firestore.batch();

            // Update referrer's wallet and referral count
            batch.update(referrerDoc.reference, {
              'walletBalance': FieldValue.increment(50),
              'successfulReferrals': FieldValue.increment(1),
            });

            // Update referee's wallet and mark reward as claimed
            batch.update(userDoc.reference, {
              'walletBalance': FieldValue.increment(50),
              'referralRewardClaimed': true,
            });

            // Create transaction records
            batch.set(_firestore.collection('transactions').doc(), {
              'customerId': referrerDoc.id,
              'amount': 50.0,
              'type': 'credit',
              'description': 'Referral reward - Friend joined',
              'createdAt': Timestamp.fromDate(DateTime.now()),
            });

            batch.set(_firestore.collection('transactions').doc(), {
              'customerId': userId,
              'amount': 50.0,
              'type': 'credit',
              'description': 'Welcome bonus - Referral reward',
              'createdAt': Timestamp.fromDate(DateTime.now()),
            });

            await batch.commit();
            debugPrint('Referral rewards applied successfully');
          }
        }
      }
    } catch (e) {
      debugPrint('Error applying referral rewards: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReferralHistory(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('customers')
          .where('referredBy', isEqualTo: customerId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name'] ?? 'Unknown',
          'joinDate': (data['createdAt'] as Timestamp).toDate(),
          'rewardClaimed': data['referralRewardClaimed'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting referral history: $e');
      return [];
    }
  }
}
