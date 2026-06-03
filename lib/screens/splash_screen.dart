import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeScaleController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for the Logo and Text popping in
    _fadeScaleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Animation for the Progress Bar filling up
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeScaleController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeScaleController, curve: Curves.elasticOut),
    );

    _fadeScaleController.forward();
    _progressController.forward();

    _navigate();
  }

  @override
  void dispose() {
    _fadeScaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for the exact duration of the progress bar animation
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;

      int attempts = 0;
      const maxAttempts = 20;
      while (!authProvider.isInitialized && attempts < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      debugPrint('Error in splash screen: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the dark green used for text and the progress bar fill
    const Color darkGreen = Color(0xFF1B4332);

    return Scaffold(
      body: Container(
        width: double.infinity,
        // The green gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6AC578), // Lighter green at top
              Color(0xFF48A658), // Darker green at bottom
            ],
          ),
        ),
        child: Stack(
          children: [
            // Optional: If you have a background pattern image with the faint leaves,
            // you can uncomment this block and add the asset.
            /*
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/leaf_pattern.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            */
            Center(
              child: AnimatedBuilder(
                animation: _fadeScaleController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // Circular Logo Badge
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/chinar_agro_logo.png', // Ensure you crop just the circle logo
                              width: 180,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 180,
                                  height: 180,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    size: 80,
                                    color: darkGreen,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Title
                          const Text(
                            'CHINAR AGRO',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: darkGreen,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            'Pure. Fresh. Delivered.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: darkGreen,
                            ),
                          ),

                          const Spacer(flex: 2),

                          // Custom Progress Bar
                          SizedBox(
                            width: 200,
                            height: 14,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return LinearProgressIndicator(
                                    value: _progressController.value,
                                    backgroundColor: Colors.white,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          darkGreen,
                                        ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Loading Text
                          const Text(
                            'LOADING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 2.0,
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
