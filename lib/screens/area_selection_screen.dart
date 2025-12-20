import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Area {
  final String id;
  final String name;
  final String areaCode;
  final bool isActive;
  final double deliveryCharge;
  final String? description;

  Area({
    required this.id,
    required this.name,
    required this.areaCode,
    required this.isActive,
    required this.deliveryCharge,
    this.description,
  });

  factory Area.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Area(
      id: doc.id,
      name: data['name'] ?? '',
      areaCode: data['areaCode'] ?? '',
      isActive: data['isActive'] ?? true,
      deliveryCharge: (data['deliveryCharge'] ?? 0.0).toDouble(),
      description: data['description'],
    );
  }
}

class AreaSelectorScreen extends StatefulWidget {
  const AreaSelectorScreen({super.key});

  @override
  State<AreaSelectorScreen> createState() => _AreaSelectorScreenState();
}

class _AreaSelectorScreenState extends State<AreaSelectorScreen> {
  List<Area> _areas = [];
  Area? _selectedArea;
  bool _isLoading = true;
  String? _currentAreaCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentArea();
    _loadAreas();
  }

  void _loadCurrentArea() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentAreaCode = authProvider.customer?.areaCode;
  }

  Future<void> _loadAreas() async {
    try {
      // Simplified query without orderBy to avoid index requirement
      final snapshot = await FirebaseFirestore.instance
          .collection('areas')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _areas = snapshot.docs.map((doc) => Area.fromFirestore(doc)).toList();
        
        // Sort areas alphabetically in memory instead of in query
        _areas.sort((a, b) => a.name.compareTo(b.name));
        
        // Set current area as selected
        if (_currentAreaCode != null) {
          try {
            _selectedArea = _areas.firstWhere(
              (area) => area.areaCode == _currentAreaCode,
            );
          } catch (e) {
            // If current area not found, don't set any selection
            _selectedArea = null;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading areas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDeliveryArea() async {
    if (_selectedArea == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer == null) return;

    try {
      // Update customer's area code in Firestore
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(authProvider.customer!.id)
          .update({
        'areaCode': _selectedArea!.areaCode,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update the customer object in the provider
      await authProvider.refreshCustomerData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery area updated to ${_selectedArea!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating area: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Select Delivery Area'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedArea != null && _selectedArea!.areaCode != _currentAreaCode)
            TextButton(
              onPressed: _updateDeliveryArea,
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Current Area Info
                  if (_currentAreaCode != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Current Delivery Area',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentAreaCode!,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Areas List
                  Expanded(
                    child: _areas.isEmpty
                        ? const Center(
                            child: Text('No delivery areas available'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _areas.length,
                            itemBuilder: (context, index) {
                              final area = _areas[index];
                              final isSelected = _selectedArea?.id == area.id;
                              final isCurrent = area.areaCode == _currentAreaCode;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isSelected ? 4 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected 
                                        ? Colors.green.shade700 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected 
                                        ? Colors.green.shade700 
                                        : Colors.grey.shade200,
                                    child: Icon(
                                      Icons.location_on,
                                      color: isSelected 
                                          ? Colors.white 
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          area.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isSelected 
                                                ? Colors.green.shade700 
                                                : Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isCurrent)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Current',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      if (area.description != null)
                                        Text(
                                          area.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Delivery Charge: ₹${area.deliveryCharge.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Radio<Area>(
                                    value: area,
                                    groupValue: _selectedArea,
                                    onChanged: (Area? value) {
                                      setState(() {
                                        _selectedArea = value;
                                      });
                                    },
                                    activeColor: Colors.green.shade700,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedArea = area;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),

                  // Update Button
                  if (_selectedArea != null && _selectedArea!.areaCode != _currentAreaCode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _updateDeliveryArea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Update to ${_selectedArea!.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
