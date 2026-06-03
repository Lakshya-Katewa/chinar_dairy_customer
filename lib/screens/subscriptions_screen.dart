import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../models/subscription.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.customer != null) {
        subscriptionProvider.loadSubscriptions(authProvider.customer!.id);
      }
    });
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.paused:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.expired:
        return Colors.grey;
    }
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  String _getTypeText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.trial:
        return '3-Day Trial';
      case SubscriptionType.monthly:
        return 'Monthly';
      case SubscriptionType.weekly:
        return 'Weekly';
      case SubscriptionType.alternateDay:
        return 'Alternate Day';
    }
  }

  Widget _buildDaysInfo(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionActions(Subscription subscription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Added: Allows the sheet to expand beyond half screen
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        int totalDays = 0;
        int daysUsed = 0;

        if (subscription.endDate != null) {
          totalDays =
              subscription.endDate!.difference(subscription.startDate).inDays +
              1;

          if (today.isAfter(subscription.startDate) ||
              today.isAtSameMomentAs(subscription.startDate)) {
            daysUsed = today.difference(subscription.startDate).inDays + 1;
          }

          daysUsed = daysUsed.clamp(0, totalDays);
        }

        final int daysRemaining = totalDays - daysUsed;

        // Added: SingleChildScrollView wraps the content to prevent bottom overflow
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        subscription.productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            subscription.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(subscription.status),
                          ),
                        ),
                        child: Text(
                          'Status: ${_getStatusText(subscription.status)}',
                          style: TextStyle(
                            color: _getStatusColor(subscription.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Plan: ${_getTypeText(subscription.type)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDaysInfo(
                      'Days Used',
                      daysUsed,
                      Colors.orange.shade700,
                    ),
                    _buildDaysInfo(
                      'Days Remaining',
                      daysRemaining,
                      Colors.green.shade700,
                    ),
                    _buildDaysInfo(
                      'Total Days',
                      totalDays,
                      Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (subscription.status == SubscriptionStatus.active) ...[
                  _buildActionButton(
                    icon: Icons.pause,
                    label: 'Pause Subscription',
                    color: Colors.orange,
                    onTap: () => _pauseSubscription(subscription.id),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: 'Cancel Subscription',
                    color: Colors.red,
                    onTap: () => _cancelSubscription(subscription.id),
                  ),
                ] else if (subscription.status ==
                    SubscriptionStatus.paused) ...[
                  _buildActionButton(
                    icon: Icons.play_arrow,
                    label: 'Resume Subscription',
                    color: Colors.green,
                    onTap: () => _resumeSubscription(subscription.id),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: Icons.cancel,
                    label: 'Cancel Subscription',
                    color: Colors.red,
                    onTap: () => _cancelSubscription(subscription.id),
                  ),
                ],
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Close',
                  color: Colors.grey,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pauseSubscription(String subscriptionId) async {
    Navigator.pop(context);
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subscriptionProvider.pauseSubscription(subscriptionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription paused successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeSubscription(String subscriptionId) async {
    Navigator.pop(context);
    try {
      final subscriptionProvider = Provider.of<SubscriptionProvider>(
        context,
        listen: false,
      );
      await subscriptionProvider.resumeSubscription(subscriptionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription resumed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelSubscription(String subscriptionId) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Cancel Subscription'),
            content: const Text(
              'Are you sure you want to cancel? Any remaining balance will be refunded to your wallet.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final subscriptionProvider = Provider.of<SubscriptionProvider>(
          context,
          listen: false,
        );
        final double refundedAmount = await subscriptionProvider
            .cancelSubscription(subscriptionId);

        if (mounted) {
          if (refundedAmount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Subscription cancelled. ₹${refundedAmount.toStringAsFixed(2)} refunded.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription cancelled successfully.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            if (subscriptionProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (subscriptionProvider.subscriptions.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subscriptionProvider.subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptionProvider.subscriptions[index];
                return SubscriptionCard(
                  subscription: subscription,
                  onTap: () => _showSubscriptionActions(subscription),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.subscriptions_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Subscriptions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Subscribe to products for hassle-free,\nregular deliveries to your doorstep!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onTap,
  });

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.paused:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.expired:
        return Colors.grey;
    }
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = 1;
    int daysUsed = 0;
    if (subscription.endDate != null) {
      totalDays =
          subscription.endDate!.difference(subscription.startDate).inDays + 1;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      if (today.isAfter(subscription.startDate) ||
          today.isAtSameMomentAs(subscription.startDate)) {
        daysUsed = today.difference(subscription.startDate).inDays + 1;
      }
      daysUsed = daysUsed.clamp(0, totalDays);
    }
    final double progress = totalDays > 0 ? daysUsed / totalDays : 0.0;

    final statusColor = _getStatusColor(subscription.status);

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        subscription.imageUrl != null
                            ? Image.network(
                              subscription.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(Icons.local_drink, size: 30),
                            )
                            : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.local_drink,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.productName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${subscription.quantity.toInt()} units • ₹${subscription.totalAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(subscription.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (subscription.status == SubscriptionStatus.active ||
                  subscription.status == SubscriptionStatus.paused) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$daysUsed of $totalDays days used',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subscription.endDate != null)
                          Text(
                            'Ends: ${subscription.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
