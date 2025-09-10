import 'package:course/providers/theme_provider.dart';
import 'package:course/services/auth_service.dart'; // Import AuthService
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Helper method to show a confirmation dialog
  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Return false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error, // Make it red or distinct
              ),
              child: const Text('Log Out'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false); // Get AuthService
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: <Widget>[
          // --- Theme Mode Section ---
          _buildSectionTitle(context, 'Appearance'),
          Card(
            // ... (existing theme mode RadioListTiles) ...
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode', style: textTheme.titleMedium),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) themeProvider.setThemeMode(value);
                    },
                    secondary: const Icon(Icons.light_mode_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode', style: textTheme.titleMedium),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) themeProvider.setThemeMode(value);
                    },
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('System Default', style: textTheme.titleMedium),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (ThemeMode? value) {
                      if (value != null) themeProvider.setThemeMode(value);
                    },
                    secondary: const Icon(Icons.brightness_auto_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // --- Primary Color Section ---
          _buildSectionTitle(context, 'Primary Color'),
          Card(
            // ... (existing primary color selection Wrap) ...
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your preferred app color:',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16.0),
                  Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: appColorChoices.entries.map((entry) {
                      final colorName = entry.key;
                      final colorValue = entry.value;
                      final bool isSelected = themeProvider.primaryColorName == colorName;

                      return GestureDetector(
                        onTap: () {
                          themeProvider.setPrimaryColor(colorName);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorValue,
                            borderRadius: BorderRadius.circular(25),
                            border: isSelected
                                ? Border.all(color: colorScheme.outlineVariant, width: 3)
                                : Border.all(color: colorValue.withOpacity(0.5), width: 1),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: colorValue.withOpacity(0.5),
                                blurRadius: 6.0,
                                offset: const Offset(0, 2),
                              )
                            ]
                                : [],
                          ),
                          child: isSelected
                              ? Icon(Icons.check, color: ThemeData.estimateBrightnessForColor(colorValue) == Brightness.dark ? Colors.white : Colors.black, size: 28)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // --- Account Section ---
          _buildSectionTitle(context, 'Account'),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error), // Distinct color for logout
              title: Text(
                'Log Out',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.error, // Make text color match icon
                ),
              ),
// ... inside SettingsScreen
              onTap: () async {
                final confirmLogout = await _showLogoutConfirmationDialog(context);
                if (confirmLogout == true) {
                  try {
                    await authService.signOut();
                    // After successful sign out, pop all routes until the user is back at the AuthGate/LoginScreen.
                    // AuthGate will then rebuild due to authStateChanges and show the LoginScreen.
                    if (mounted) { // Ensure the widget is still in the tree
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Logout failed: $e")),
                      );
                    }
                  }
                }
              },
// ...

            ),
          ),
          const SizedBox(height: 24.0),


          // --- About Section ---
          _buildSectionTitle(context, 'About'),
          Card(
            // ... (existing About ListTile) ...
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('About App', style: textTheme.titleMedium),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Course App',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© ${DateTime.now().year} Your Company Name',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.school, size: 40, color: colorScheme.primary),
                  ),
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text('This is a great course application built with Flutter and Firebase.'),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    // ... (existing _buildSectionTitle method) ...
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

