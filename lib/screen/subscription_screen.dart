import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../utils/theme.dart';
import '../widget/subscription_card.dart';
import '../provider/auth_provider.dart';
import '../services/database_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  void _loadSubscriptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer != null) {
      _databaseService.getCustomerSubscriptions(authProvider.customer!.id).listen((subscriptions) {
        setState(() {
          _subscriptions = subscriptions;
          _isLoading = false;
        });
      });
    }
  }

  Future<void> _pauseSubscription(Subscription subscription) async {
    try {
      await _databaseService.updateSubscription(
        subscription.id,
        {'isActive': false},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription paused successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing subscription: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resumeSubscription(Subscription subscription) async {
    try {
      await _databaseService.updateSubscription(
        subscription.id,
        {'isActive': true},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming subscription: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription(Subscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: Text('Are you sure you want to cancel your subscription for ${subscription.productName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.updateSubscription(
          subscription.id,
          {
            'isActive': false,
            'endDate': DateTime.now(),
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription cancelled successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling subscription: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subscriptions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Subscriptions Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Subscribe to your favorite products',
                        style: TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Subscriptions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_subscriptions.where((s) => s.isActive).length} active subscriptions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Next delivery: ${_getNextDeliveryDate()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subscriptions List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = _subscriptions[index];
                          return SubscriptionCard(
                            subscription: subscription,
                            onPause: () => _pauseSubscription(subscription),
                            onResume: () => _resumeSubscription(subscription),
                            onCancel: () => _cancelSubscription(subscription),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  String _getNextDeliveryDate() {
    final activeSubscriptions = _subscriptions.where((s) => s.isActive && s.shouldDeliverToday()).toList();
    
    if (activeSubscriptions.isEmpty) {
      // Find the next delivery date from all active subscriptions
      DateTime? nextDate;
      for (final subscription in _subscriptions.where((s) => s.isActive)) {
        final today = DateTime.now();
        final daysSinceStart = today.difference(subscription.startDate).inDays;
        
        DateTime? nextDelivery;
        switch (subscription.type) {
          case SubscriptionType.monthly:
            if (daysSinceStart < 30) {
              nextDelivery = today.add(const Duration(days: 1));
            }
            break;
          case SubscriptionType.weekly:
            if (daysSinceStart < 7) {
              nextDelivery = today.add(const Duration(days: 1));
            }
            break;
          case SubscriptionType.alternateDay:
            if (daysSinceStart < 30) {
              final nextAlternateDay = daysSinceStart % 2 == 0 ? 2 : 1;
              nextDelivery = today.add(Duration(days: nextAlternateDay));
            }
            break;
        }
        
        if (nextDelivery != null && (nextDate == null || nextDelivery.isBefore(nextDate))) {
          nextDate = nextDelivery;
        }
      }
      
      return nextDate != null ? DateFormat('dd MMM yyyy').format(nextDate) : 'No upcoming deliveries';
    }
    
    return 'Today';
  }
}
