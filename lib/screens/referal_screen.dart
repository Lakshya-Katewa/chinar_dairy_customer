import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/referal_provider.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  List<Map<String, dynamic>> _referralHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReferralHistory();
  }

  Future<void> _loadReferralHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final referralProvider = Provider.of<ReferralProvider>(
      context,
      listen: false,
    );

    if (authProvider.customer != null) {
      final history = await referralProvider.getReferralHistory(
        authProvider.customer!.referralCode,
      );
      setState(() {
        _referralHistory = history;
        _isLoading = false;
      });
    }
  }

  void _shareReferralCode() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer != null) {
      final referralCode = authProvider.customer!.referralCode;
      final message = '''
🥛 Join Chinar Dairy and get fresh milk delivered to your doorstep!

Use my referral code: $referralCode

🎁 Get ₹50 bonus in your wallet after your first order!

Download the app and start enjoying fresh dairy products daily.
      ''';

      Share.share(message);
    }
  }

  void _copyReferralCode() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer != null) {
      Clipboard.setData(
        ClipboardData(text: authProvider.customer!.referralCode),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.customer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final customer = authProvider.customer!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Referral Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Refer Friends & Earn ₹50',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your friend gets ₹50 too when they place their first order!',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Referral Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customer.referralCode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _copyReferralCode,
                              icon: const Icon(Icons.copy, size: 18),
                              // --- FIXED: Wrapped in FittedBox to prevent 2 lines ---
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Copy Code', maxLines: 1),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade700,
                                // --- FIXED: Reduced horizontal padding ---
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareReferralCode,
                              icon: const Icon(Icons.share, size: 18),
                              // --- FIXED: Wrapped in FittedBox to prevent 2 lines ---
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Share', maxLines: 1),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green.shade700,
                                // --- FIXED: Reduced horizontal padding ---
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${customer.successfulReferrals}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const Text(
                                'Friends Referred',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '₹${(customer.successfulReferrals * 50).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const Text(
                                'Total Earned',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // How it works
                const Text(
                  'How it works',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildHowItWorksStep(
                  1,
                  'Share your referral code',
                  'Send your unique code to friends via WhatsApp, SMS, or social media',
                  Icons.share,
                ),

                _buildHowItWorksStep(
                  2,
                  'Friend signs up',
                  'Your friend downloads the app and enters your referral code during registration',
                  Icons.person_add,
                ),

                _buildHowItWorksStep(
                  3,
                  'Both get rewarded',
                  'You both get ₹50 in your wallet after their first order is delivered',
                  Icons.celebration,
                ),

                const SizedBox(height: 24),

                // Referral History
                if (_referralHistory.isNotEmpty) ...[
                  const Text(
                    'Referral History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Column(
                      children:
                          _referralHistory.map((referral) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              title: Text(referral['name']),
                              subtitle: Text(
                                'Joined on ${referral['joinDate'].day}/${referral['joinDate'].month}/${referral['joinDate'].year}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      referral['rewardClaimed']
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  referral['rewardClaimed']
                                      ? '₹50 Earned'
                                      : 'Pending',
                                  style: TextStyle(
                                    color:
                                        referral['rewardClaimed']
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Terms
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTermsPoint(
                          '• Referral reward is credited after friend\'s first order is delivered',
                        ),
                        _buildTermsPoint(
                          '• Maximum 10 successful referrals per user',
                        ),
                        _buildTermsPoint(
                          '• Referral code cannot be used by the same user',
                        ),
                        _buildTermsPoint(
                          '• Rewards are non-transferable and non-refundable',
                        ),
                        _buildTermsPoint(
                          '• Chinar Dairy reserves the right to modify terms',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHowItWorksStep(
    int step,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }
}
