import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find answers to common questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // FAQ List
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildFAQItem(
                    question: 'What are your delivery timings?',
                    answer: 'We deliver fresh milk and dairy products every morning between 6:00 AM to 8:00 AM. For other products, delivery is available from 8:00 AM to 8:00 PM.',
                    icon: Icons.access_time,
                    color: Colors.blue,
                  ),
                  
                  _buildFAQItem(
                    question: 'How do I subscribe to regular milk delivery?',
                    answer: 'You can subscribe to regular milk delivery by selecting your preferred product, choosing the subscription type (daily, weekly, or monthly), and confirming your order. You can manage your subscription anytime from the app.',
                    icon: Icons.subscriptions,
                    color: Colors.green,
                  ),
                  
                  _buildFAQItem(
                    question: 'What payment methods do you accept?',
                    answer: 'We accept various payment methods including UPI, credit/debit cards, net banking, and wallet payments. You can also pay cash on delivery for certain orders.',
                    icon: Icons.payment,
                    color: Colors.orange,
                  ),
                  
                  _buildFAQItem(
                    question: 'How can I track my order?',
                    answer: 'You can track your order status in real-time through the "My Orders" section in the app. You\'ll receive notifications for order confirmation, preparation, and delivery updates.',
                    icon: Icons.track_changes,
                    color: Colors.purple,
                  ),
                  
                  _buildFAQItem(
                    question: 'What is your return/refund policy?',
                    answer: 'If you\'re not satisfied with the quality of our products, please contact us within 2 hours of delivery. We offer full refund or replacement for quality issues. Refunds are processed to your wallet within 24 hours.',
                    icon: Icons.assignment_return,
                    color: Colors.red,
                  ),
                  
                  _buildFAQItem(
                    question: 'Do you deliver in my area?',
                    answer: 'We currently deliver across Srinagar and nearby areas in Kashmir. You can check if we deliver to your location by entering your pincode during registration or in the app settings.',
                    icon: Icons.location_on,
                    color: Colors.teal,
                  ),
                  
                  _buildFAQItem(
                    question: 'How do I pause or cancel my subscription?',
                    answer: 'You can easily pause or cancel your subscription from the "My Subscriptions" section. Paused subscriptions can be resumed anytime, and cancelled subscriptions will refund the remaining amount to your wallet.',
                    icon: Icons.pause_circle,
                    color: Colors.indigo,
                  ),
                  
                  _buildFAQItem(
                    question: 'Are your products organic and fresh?',
                    answer: 'Yes, all our dairy products are sourced from local farms and are 100% fresh and natural. We maintain strict quality standards and our products are free from harmful chemicals and preservatives.',
                    icon: Icons.eco,
                    color: Colors.green.shade600,
                  ),
                  
                  _buildFAQItem(
                    question: 'How do I add money to my wallet?',
                    answer: 'You can add money to your wallet through the "My Wallet" section using UPI, cards, or net banking. Wallet money can be used for faster checkout and you\'ll receive refunds directly to your wallet.',
                    icon: Icons.account_balance_wallet,
                    color: Colors.amber,
                  ),
                  
                  _buildFAQItem(
                    question: 'What if I miss my delivery?',
                    answer: 'If you miss your delivery, our delivery person will try to contact you. You can also reschedule the delivery for later in the day or the next day through the app or by calling our support team.',
                    icon: Icons.delivery_dining,
                    color: Colors.brown,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              question,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
