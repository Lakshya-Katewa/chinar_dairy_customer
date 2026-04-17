import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'address_management.dart';
import 'referal_screen.dart';
import 'area_selection_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserData());
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.customer != null) {
      _nameController.text = authProvider.customer!.name;
      _emailController.text = authProvider.customer!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(authProvider.customer!.id)
          .update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      await authProvider.refreshCustomerData();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted)
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _loadUserData();
              });
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final customer = authProvider.customer;

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_isEditing) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Name cannot be empty'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : const Text('Save Changes'),
                              ),
                            ),
                          ] else ...[
                            _buildInfoRow(
                              icon: Icons.person,
                              label: 'Name',
                              value: customer?.name ?? 'Not available',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.email,
                              label: 'Email',
                              value: customer?.email ?? 'Not available',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.phone,
                              label: 'Phone',
                              value:
                                  customer?.phone != null
                                      ? '+91 ${customer!.phone}'
                                      : 'Not available',
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.location_on,
                              label: 'Address',
                              value:
                                  customer?.address.formattedAddress ??
                                  'Not available',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.account_balance_wallet,
                              label: 'Wallet',
                              value:
                                  '₹${(customer?.walletBalance ?? 0).toStringAsFixed(2)}',
                              valueColor: Colors.green.shade700,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!_isEditing) ...[
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Manage Addresses'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const AddressManagementScreen(),
                                  ),
                                ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.card_giftcard),
                            title: const Text('Refer & Earn'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReferralScreen(),
                                  ),
                                ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.location_city),
                            title: const Text('Delivery Area'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AreaSelectorScreen(),
                                  ),
                                ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HelpSupportScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- FIXED: Expanded prevents long texts from causing overflow ---
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
