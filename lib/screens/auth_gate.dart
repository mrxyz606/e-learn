import 'package:course/screens/home_screen.dart';
import 'package:course/screens/login_screen.dart'; // Or your initial auth screen
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// No need to Provider.of<AuthService>(context) here if just using FirebaseAuth.instance stream

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Crucial: This stream fires on login/logout
      builder: (context, snapshot) {
        // Optional: Add more debug prints to see snapshot states
        // debugPrint("AuthGate Snapshot: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, error=${snapshot.error}");


        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("AuthGate: Waiting for auth connection...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint("AuthGate: Auth stream error: ${snapshot.error}");
          return const Scaffold(
              body: Center(child: Text("Authentication error. Please restart."))
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in
          debugPrint("AuthGate: User is logged in - ${snapshot.data!.uid}. Showing HomeScreen.");
          return const HomeScreen();
        } else {
          // User is not logged in (or logged out)
          debugPrint("AuthGate: User is not logged in. Showing LoginScreen.");
          // IMPORTANT: Pop all routes until the first one (AuthGate/LoginScreen)
          // This ensures that screens like SettingsScreen are removed.
          // Do this in a post-frame callback to avoid issues during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) { // Check if there's anything to pop
              // Check if we are not already on the root (which might be LoginScreen itself after a rebuild)
              // This logic can be tricky if LoginScreen is the initial route and AuthGate rebuilds to it.
              // A simpler approach for logout specifically is handled in SettingsScreen.
              // For now, let's rely on SettingsScreen handling its own pop after logout.
              // Or, if LoginScreen is always the destination, and it's what AuthGate returns,
              // the navigator stack will adjust. The main issue is if HomeScreen or other
              // authenticated routes are still present above LoginScreen.
            }
          });
          return const LoginScreen();
        }
      },
    );
  }
}
