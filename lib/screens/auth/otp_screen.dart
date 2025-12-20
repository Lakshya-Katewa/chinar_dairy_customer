import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../main.dart'; // <-- 1. ADD THIS IMPORT

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  String? phoneNumber;
  bool _isVerifying = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    phoneNumber = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // =======================================================================
  // === 2. THIS IS THE UPDATED FUNCTION WITH THE FCM TOKEN LOGIC ===
  // =======================================================================
  Future<void> _verifyOTP(String otpCode) async {
    if (otpCode.length != 6) {
      _showSnackBar('Please enter complete OTP', Colors.red);
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyOTP(otpCode);
      
      if (success && mounted) {
        _showSnackBar('OTP verified successfully!', Colors.green);

        // --- Start of FCM Token Logic ---
        // After successful login, get the customer data.
        final customer = authProvider.customer;
        if (customer != null) {
          // Now, call the function from main.dart to save the FCM token.
          // This ensures the user can receive notifications on this device.
          debugPrint('Saving FCM token for customer: ${customer.id}');
          await initializeNotificationsAndSaveToken(customer.id);
        } else {
          debugPrint('Warning: Customer data not found after login. FCM token cannot be saved.');
        }
        // --- End of FCM Token Logic ---

        // A small delay before navigating for a smoother feel.
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          if (authProvider.needsRegistration) {
            Navigator.pushReplacementNamed(context, '/zone-selection');
          } else {
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), Colors.red);
        _pinController.clear();
        _pinFocusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _resendOTP() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resendOTP();
      if (mounted) {
        _showSnackBar('OTP sent successfully', Colors.green);
        _pinController.clear();
        _pinFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), Colors.red);
      }
    }
  }

  void _goBack() {
    Provider.of<AuthProvider>(context, listen: false).resetVerificationState();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value * 50),
              child: Opacity(
                opacity: 1 - _slideAnimation.value,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sms,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Verify Your Phone',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enter the 6-digit code sent to\n+91 ${phoneNumber ?? ''}',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Pinput(
                        length: 6,
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        autofocus: true,
                        onCompleted: (pin) => _verifyOTP(pin),
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                          ),
                        ),
                        errorPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return ElevatedButton(
                              onPressed: (authProvider.isLoading || _isVerifying) 
                                ? null 
                                : () => _verifyOTP(_pinController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: (authProvider.isLoading || _isVerifying)
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Verify OTP',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive the code? "),
                              TextButton(
                                onPressed: authProvider.canResendOTP && !authProvider.isLoading
                                    ? _resendOTP
                                    : null,
                                child: Text(
                                  authProvider.canResendOTP
                                      ? 'Resend OTP'
                                      : 'Resend in ${authProvider.resendCooldown}s',
                                  style: TextStyle(
                                    color: authProvider.canResendOTP
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}