import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/referal_provider.dart';
import '../models/address.dart';

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

class ZoneSelectionScreen extends StatefulWidget {
  const ZoneSelectionScreen({super.key});

  @override
  State<ZoneSelectionScreen> createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Area> _areas = [];
  Area? _selectedArea;
  bool _isLoading = true;
  bool _isValidatingReferral = false;
  bool? _isReferralValid;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    try {
      // FIX 10: Removed .where('isActive') to prevent errors if the field is missing
      final snapshot =
          await FirebaseFirestore.instance.collection('areas').get();

      setState(() {
        _areas =
            snapshot.docs
                .map((doc) => Area.fromFirestore(doc))
                .where((area) => area.isActive) // Filter locally instead
                .toList();

        _areas.sort((a, b) => a.name.compareTo(b.name));
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

  Future<void> _validateReferralCode(String code) async {
    if (code.isEmpty) {
      setState(() {
        _isReferralValid = null;
      });
      return;
    }

    setState(() {
      _isValidatingReferral = true;
    });

    final referralProvider = Provider.of<ReferralProvider>(
      context,
      listen: false,
    );
    final isValid = await referralProvider.validateReferralCode(code);

    setState(() {
      _isValidatingReferral = false;
      _isReferralValid = isValid;
    });
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate() || _selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select an area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_referralCodeController.text.isNotEmpty && _isReferralValid != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid referral code or leave it empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // FIX 8: Create a placeholder address since we no longer ask for GPS during registration
    final dummyAddress = DetailedAddress(
      houseNumber: '',
      street: '',
      city: '',
      pinCode: '',
      landmark: '',
      latitude: 0.0,
      longitude: 0.0,
      fullAddress: 'Address will be added during first order',
    );

    try {
      await authProvider.createCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: dummyAddress,
        areaCode: _selectedArea!.areaCode,
        referralCode:
            _referralCodeController.text.trim().isNotEmpty
                ? _referralCodeController.text.trim()
                : null,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Registration'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _referralCodeController,
                          decoration: InputDecoration(
                            labelText: 'Referral Code (Optional)',
                            hintText: 'Enter friend\'s referral code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.card_giftcard),
                            suffixIcon:
                                _isValidatingReferral
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                    : _isReferralValid != null
                                    ? Icon(
                                      _isReferralValid!
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color:
                                          _isReferralValid!
                                              ? Colors.green
                                              : Colors.red,
                                    )
                                    : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.length >= 4) {
                              _validateReferralCode(value);
                            } else {
                              setState(() {
                                _isReferralValid = null;
                              });
                            }
                          },
                        ),

                        if (_referralCodeController.text.isNotEmpty &&
                            _isReferralValid == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.celebration,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Great! You\'ll get ₹50 bonus after your first order',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),

                        Text(
                          'Select Delivery Area',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_areas.isEmpty)
                          const Center(
                            child: Text('No delivery areas available'),
                          )
                        else
                          ..._areas.map(
                            (area) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: RadioListTile<Area>(
                                title: Text(
                                  area.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (area.description != null)
                                      Text(
                                        area.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      'Delivery Charge: ₹${area.deliveryCharge}',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                value: area,
                                groupValue: _selectedArea,
                                onChanged: (Area? value) {
                                  setState(() {
                                    _selectedArea = value;
                                  });
                                },
                                activeColor: Colors.green.shade700,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return ElevatedButton(
                              onPressed:
                                  authProvider.isLoading
                                      ? null
                                      : _completeRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  authProvider.isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Complete Registration',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
