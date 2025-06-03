import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../utils/theme.dart';
import '../widget/order_card.dart';
import '../provider/auth_provider.dart';
import '../services/database_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedFilter = 'today';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<Order> _filteredOrders = [];
  List<Order> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer != null) {
      _databaseService.getCustomerOrders(authProvider.customer!.id).listen((orders) {
        setState(() {
          _allOrders = orders.cast<Order>();
          _filterOrders();
        });
      });
    }
  }

  void _filterOrders() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    setState(() {
      switch (_selectedFilter) {
        case 'today':
          _filteredOrders = _allOrders.where((order) {
            final orderDate = DateTime(
              order.deliveryDate?.year ?? order.orderDate.year,
              order.deliveryDate?.month ?? order.orderDate.month,
              order.deliveryDate?.day ?? order.orderDate.day,
            );
            return orderDate.isAtSameMomentAs(today);
          }).toList();
          break;
        case 'thisMonth':
          _filteredOrders = _allOrders.where((order) {
            final orderDate = order.deliveryDate ?? order.orderDate;
            return orderDate.isAfter(thisMonthStart.subtract(const Duration(days: 1))) &&
                   orderDate.isBefore(thisMonthEnd.add(const Duration(days: 1)));
          }).toList();
          break;
        case 'all':
          _filteredOrders = List.from(_allOrders);
          break;
        case 'custom':
          if (_customStartDate != null && _customEndDate != null) {
            _filteredOrders = _allOrders.where((order) {
              final orderDate = order.deliveryDate ?? order.orderDate;
              return orderDate.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                     orderDate.isBefore(_customEndDate!.add(const Duration(days: 1)));
            }).toList();
          } else {
            _filteredOrders = List.from(_allOrders);
          }
          break;
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedFilter = 'custom';
        _filterOrders();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip('Today', 'today'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('This Month', 'thisMonth'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('All Orders', 'all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _selectCustomDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedFilter == 'custom' && _customStartDate != null && _customEndDate != null
                          ? '${DateFormat('dd/MM/yy').format(_customStartDate!)} - ${DateFormat('dd/MM/yy').format(_customEndDate!)}'
                          : 'Custom Date Range',
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedFilter == 'custom' 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : null,
                      foregroundColor: _selectedFilter == 'custom' 
                          ? AppTheme.primaryColor 
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredOrders.length} Orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_filteredOrders.isNotEmpty)
                  Text(
                    'Total: ₹${_filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Orders List
          Expanded(
            child: _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Orders Found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptyStateMessage(),
                          style: const TextStyle(
                            color: AppTheme.lightTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return OrderCard(order: _filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _filterOrders();
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'today':
        return 'No orders scheduled for today';
      case 'thisMonth':
        return 'No orders found for this month';
      case 'custom':
        return 'No orders found in the selected date range';
      default:
        return 'You haven\'t placed any orders yet';
    }
  }
}
