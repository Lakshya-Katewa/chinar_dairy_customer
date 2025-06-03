import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../utils/theme.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subscription.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: subscription.isActive
                        ? AppTheme.successColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subscription.isActive ? 'Active' : 'Paused',
                    style: TextStyle(
                      color: subscription.isActive ? AppTheme.successColor : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  subscription.typeText,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.scale_outlined,
                  size: 16,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${subscription.quantity} per delivery',
                  style: const TextStyle(
                    color: AppTheme.lightTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Started: ${DateFormat('dd MMM yyyy').format(subscription.startDate)}',
                  style: const TextStyle(
                    color: AppTheme.lightTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (subscription.endDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: AppTheme.lightTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ends: ${DateFormat('dd MMM yyyy').format(subscription.endDate!)}',
                    style: const TextStyle(
                      color: AppTheme.lightTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${(subscription.pricePerUnit * subscription.quantity).toStringAsFixed(2)} per delivery',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    if (subscription.isActive && onPause != null)
                      OutlinedButton(
                        onPressed: onPause,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text(
                          'Pause',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (!subscription.isActive && onResume != null)
                      OutlinedButton(
                        onPressed: onResume,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.successColor,
                          side: const BorderSide(color: AppTheme.successColor),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text(
                          'Resume',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (onCancel != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          minimumSize: const Size(60, 32),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            // Delivery Progress
            const SizedBox(height: 12),
            _buildDeliveryProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryProgress() {
    final totalDeliveries = subscription.deliveryCount;
    final daysSinceStart = DateTime.now().difference(subscription.startDate).inDays;
    int completedDeliveries = 0;

    switch (subscription.type) {
      case SubscriptionType.monthly:
        completedDeliveries = daysSinceStart.clamp(0, 30);
        break;
      case SubscriptionType.weekly:
        completedDeliveries = daysSinceStart.clamp(0, 7);
        break;
      case SubscriptionType.alternateDay:
        completedDeliveries = (daysSinceStart / 2).floor().clamp(0, 15);
        break;
    }

    final progress = completedDeliveries / totalDeliveries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery Progress',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              '$completedDeliveries / $totalDeliveries',
              style: const TextStyle(
                color: AppTheme.lightTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ],
    );
  }
}
