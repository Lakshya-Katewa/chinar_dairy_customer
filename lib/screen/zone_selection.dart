import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_Screen.dart';
import 'customer_details_screen.dart';
import '../utils/theme.dart';
import '../widget/custom_buttom.dart';
import '../provider/auth_provider.dart';
import '../services/database_service.dart';
import '../models/area.dart';
class ZoneSelectionScreen extends StatefulWidget {
  const ZoneSelectionScreen({super.key});

  @override
  State<ZoneSelectionScreen> createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _referralController = TextEditingController();
  String? _selectedAreaCode;
  String? _selectedAreaName;
  bool _isLoading = false;
  List<Area> _areas = [];

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
  }

  void _loadAreas() {
    _databaseService.getAreas().listen((areas) {
      setState(() {
        _areas = areas;
      });
    });
  }

  Future<void> _continueToNext() async {
    if (_selectedAreaCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your zone'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.customer == null) {
        // New user, go to customer details screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(
                areaCode: _selectedAreaCode!,
                referralCode: _referralController.text.trim(),
              ),
            ),
          );
        }
      } else {
        // Existing user, update area and go to home
        final updatedCustomer = authProvider.customer!.copyWith(
          areaCode: _selectedAreaCode!,
        );
        await authProvider.updateCustomer(updatedCustomer);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSelectedZone', true);
        await prefs.setString('selectedAreaCode', _selectedAreaCode!);
        await prefs.setString('selectedAreaName', _selectedAreaName!);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                userId: authProvider.user!.uid,
                areaCode: _selectedAreaCode!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Zone'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Zone',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your delivery zone to see available products',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select your zone'),
                    value: _selectedAreaCode,
                    items: _areas.map((Area area) {
                      return DropdownMenuItem<String>(
                        value: area.areaCode,
                        child: Text(area.name),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedAreaCode = newValue;
                        _selectedAreaName = _areas
                            .firstWhere((area) => area.areaCode == newValue)
                            .name;
                      });
                    },
                  ),
                ),
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Have a referral code?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _referralController,
                decoration: const InputDecoration(
                  labelText: 'Referral Code (Optional)',
                  hintText: 'Enter referral code',
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Continue',
                onPressed: _continueToNext,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
