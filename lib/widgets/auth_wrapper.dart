import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_screen.dart'; // A placeholder for your main app screen

/// This widget is the new entry point for your app's UI.
/// It listens to the authentication state and decides which screen to show.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Consumer to listen to changes in the AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // --- 1. Check if the provider has finished its initial check ---
        // The `isInitialized` flag is crucial. We show a loading screen
        // until Firebase has had a chance to report the user's saved auth state.
        if (!authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --- 2. Once initialized, check if the user is authenticated ---
        if (authProvider.isAuthenticated) {
          // If the user is logged in (meaning a session was found),
          // navigate to the main screen of your app.
          return const MainScreen(); // Or your HomePage, DashboardScreen, etc.
        } else {
          // If no user session was found, show the login screen.
          return const LoginScreen();
        }
      },
    );
  }
}
