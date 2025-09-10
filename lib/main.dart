import 'package:course/providers/theme_provider.dart';
import 'package:course/screens/auth_gate.dart';
import 'package:course/services/auth_service.dart'; // Make sure this is imported
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; // Assuming you have this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider( // Use MultiProvider to provide multiple services/notifiers
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<AuthService>(create: (_) => AuthService()), // <<< ENSURE THIS LINE IS HERE
        // You might have other providers here (e.g., for FirestoreService if needed globally)
      ],
      child: const CourseAppRoot(), // A new root widget for clarity
    ),
  );
}

class CourseAppRoot extends StatelessWidget {
  const CourseAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider here if needed for MaterialApp, or it can be accessed lower down
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Course App',
      themeMode: themeProvider.themeMode,
      theme: themeProvider.currentLightTheme,
      darkTheme: themeProvider.currentDarkTheme,
      home: const AuthGate(), // AuthGate will decide to show HomeScreen or LoginScreen
      // SettingsScreen is typically navigated to from HomeScreen
    );
  }
}
