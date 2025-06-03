import 'package:chinar_dairy/widget/custom_buttom.dart';
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'profile_screen.dart';
import 'home_Screen.dart';
import 'order_screen.dart';
import 'subscription_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final double _walletBalance = 250.0;
  int _currentIndex = 2;

 
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
   void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to respective screens
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      ).then((_) {
        setState(() {
          _currentIndex = 2;
        });
      });
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionScreen(),
        ),
      ).then((_) {
        setState(() {
          _currentIndex = 2;
        });
      });
    } else if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(zone: "Delhi - North",),
        ),
      ).then((_) {
        setState(() {
          _currentIndex = 2;
        });
      });
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrdersScreen(),
        ),
      ).then((_) {
        setState(() {
          _currentIndex = 2;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         automaticallyImplyLeading: false, 
        title: const Text('My Wallet'),
      ),
      body: Column(
        children: [
          // Wallet Balance Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Wallet Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Add Money',
                  onPressed: () {
                    // Show add money dialog
                    showDialog(
                      context: context,
                      builder: (context) => const AddMoneyDialog(),
                    );
                  },
                  backgroundColor: Colors.white,
                  textColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.lightTextColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Rewards'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Transactions Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TransactionItem(
                      title: 'Added Money',
                      date: DateTime.now().subtract(const Duration(days: 2)),
                      amount: 100.0,
                      isCredit: true,
                    ),
                    TransactionItem(
                      title: 'Order #12345',
                      date: DateTime.now().subtract(const Duration(days: 3)),
                      amount: 60.0,
                      isCredit: false,
                    ),
                    TransactionItem(
                      title: 'Referral Bonus',
                      date: DateTime.now().subtract(const Duration(days: 5)),
                      amount: 50.0,
                      isCredit: true,
                    ),
                    TransactionItem(
                      title: 'Order #12340',
                      date: DateTime.now().subtract(const Duration(days: 7)),
                      amount: 120.0,
                      isCredit: false,
                    ),
                    TransactionItem(
                      title: 'Added Money',
                      date: DateTime.now().subtract(const Duration(days: 10)),
                      amount: 200.0,
                      isCredit: true,
                    ),
                  ],
                ),

                // Rewards Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    RewardItem(
                      title: 'Refer a friend',
                      description: 'Get ₹100 for each friend who joins',
                      amount: 100.0,
                      isAvailable: true,
                      onClaim: () {
                        // Share referral code
                      },
                    ),
                    RewardItem(
                      title: 'First Subscription',
                      description: 'Get ₹50 on your first subscription',
                      amount: 50.0,
                      isAvailable: true,
                      onClaim: () {
                        // Navigate to products
                      },
                    ),
                    RewardItem(
                      title: 'Weekly Order',
                      description: 'Order for a week continuously',
                      amount: 30.0,
                      isAvailable: false,
                      onClaim: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
       bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.lightTextColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Subscriptions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            activeIcon: Icon(Icons.shopping_bag),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final double amount;
  final bool isCredit;

  const TransactionItem({
    super.key,
    required this.title,
    required this.date,
    required this.amount,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} ₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isCredit ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

class RewardItem extends StatelessWidget {
  final String title;
  final String description;
  final double amount;
  final bool isAvailable;
  final VoidCallback onClaim;

  const RewardItem({
    super.key,
    required this.title,
    required this.description,
    required this.amount,
    required this.isAvailable,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAvailable ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? AppTheme.primaryColor : Colors.grey[300],
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey[500],
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(isAvailable ? 'Claim Now' : 'Not Available'),
            ),
          ),
        ],
      ),
    );
  }
}

class AddMoneyDialog extends StatefulWidget {
  const AddMoneyDialog({super.key});

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  final TextEditingController _amountController = TextEditingController();
  final List<double> _quickAmounts = [100, 200, 500, 1000];
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addMoney() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate payment process
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Money added successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Money to Wallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quick Add'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _quickAmounts.map((amount) {
              return ElevatedButton(
                onPressed: () {
                  setState(() {
                    _amountController.text = amount.toString();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: Text('₹${amount.toInt()}'),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addMoney,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
