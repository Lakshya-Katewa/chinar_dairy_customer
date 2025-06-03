import 'package:flutter/material.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How can I place an order?',
      'answer': 'You can browse our products on the home screen, select the ones you want, and add them to your cart. Once you\'re ready, you can proceed to checkout and place your order.',
      'isExpanded': false,
    },
    {
      'question': 'What are the delivery timings?',
      'answer': 'We deliver milk and dairy products between 6:00 AM and 7:00 AM every morning. For other products, delivery time may vary depending on your location and availability.',
      'isExpanded': false,
    },
    {
      'question': 'How do I cancel my subscription?',
      'answer': 'You can cancel your subscription by going to the Subscriptions tab, selecting the subscription you want to cancel, and tapping on the "Cancel Subscription" button.',
      'isExpanded': false,
    },
    {
      'question': 'Can I change my delivery address?',
      'answer': 'Yes, you can change your delivery address by going to your Profile, selecting "Manage Addresses", and adding or editing your address.',
      'isExpanded': false,
    },
    {
      'question': 'How do I track my order?',
      'answer': 'You can track your order by going to the Orders tab. There you\'ll see the status of your current orders and delivery estimates.',
      'isExpanded': false,
    },
    {
      'question': 'What payment methods do you accept?',
      'answer': 'We accept all major credit/debit cards, UPI payments, and wallet payments. You can also pay using CHINAR Wallet credits.',
      'isExpanded': false,
    },
    {
      'question': 'How do I add money to my wallet?',
      'answer': 'You can add money to your wallet by going to the Wallet tab and tapping on the "Add Money" button. You can add money using various payment methods.',
      'isExpanded': false,
    },
    {
      'question': 'What is the referral program?',
      'answer': 'You can earn ₹100 for each friend who joins CHINAR Dairy using your referral code. Your friend will also receive ₹100 in their wallet upon sign-up.',
      'isExpanded': false,
    },
  ];

  void _toggleExpand(int index) {
    setState(() {
      _faqs[index]['isExpanded'] = !_faqs[index]['isExpanded'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              initiallyExpanded: _faqs[index]['isExpanded'],
              onExpansionChanged: (expanded) {
                _toggleExpand(index);
              },
              title: Text(
                _faqs[index]['question'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    _faqs[index]['answer'],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
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
}
