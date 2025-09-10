import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define a map of color choices accessible by a key (e.g., string name)
// This makes it easier to save and load the preference.
Map<String, Color> _appColors = {
  'Amber': Colors.amber,
  'Blue': Colors.blue,
  'Green': Colors.green,
  'Red': Colors.red,
  'Purple': Colors.purple,
  'Teal': Colors.teal,
  'Orange': Colors.orange,
  'Indigo': Colors.indigo,
};

// Expose the color choices for the UI
Map<String, Color> get appColorChoices => _appColors;


class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _primaryColorKey = 'primaryColorName'; // Key for saving color name

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = _appColors['Amber']!; // Default to Amber
  String _primaryColorName = 'Amber'; // Default name

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  String get primaryColorName => _primaryColorName;

  ThemeData get currentLightTheme => _generateTheme(_primaryColor, Brightness.light);
  ThemeData get currentDarkTheme => _generateTheme(_primaryColor, Brightness.dark);


  ThemeProvider() {
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load ThemeMode
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load Primary Color
    final savedColorName = prefs.getString(_primaryColorKey);
    if (savedColorName != null && _appColors.containsKey(savedColorName)) {
      _primaryColorName = savedColorName;
      _primaryColor = _appColors[savedColorName]!;
    } else {
      _primaryColorName = 'Amber'; // Default if nothing is saved or key is invalid
      _primaryColor = _appColors['Amber']!;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setPrimaryColor(String colorName) async {
    if (_appColors.containsKey(colorName)) {
      _primaryColorName = colorName;
      _primaryColor = _appColors[colorName]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryColorKey, colorName);
      notifyListeners(); // This will trigger UI rebuild with new themes
    }
  }

  // Helper method to generate themes based on the selected primary color
  ThemeData _generateTheme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    Color cardBackgroundColor;

    if (brightness == Brightness.dark) {
      // For dark mode, let's try a slightly lighter surface for cards
      // to ensure content within them has better contrast.
      // Default M3 for cards is surfaceContainerLow.
      // Options from darkest to lightest relevant for cards:
      // surfaceContainerLow -> surfaceContainer -> surfaceContainerHigh -> surfaceContainerHighest
      cardBackgroundColor = colorScheme.surfaceContainer; // A bit lighter than surfaceContainerLow
      // Experiment with surfaceContainerHigh if more contrast is needed
    } else {
      // For light mode, use the M3 default for cards
      cardBackgroundColor = colorScheme.surfaceContainerLow;
    }

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: cardBackgroundColor, // Use the adjusted card background color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias, // Ensures content like images respect the rounded corners
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant, // General icon color for ListTiles
        // tileColor: cardBackgroundColor, // If you want ListTiles outside cards to match card color
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          )
      ),
      // If the lesson number in the CircleAvatar is still not clear in dark mode,
      // you will likely need to adjust its Text and CircleAvatar colors directly
      // in the CourseDetailScreen widget using Theme.of(context).brightness
      // as shown in "Option 2" in the previous response.
      // Example:
      // textTheme: TextTheme(
      //   bodyLarge: TextStyle(color: colorScheme.onSurface),
      //   // ... other text styles
      // ),
    );
  }
}
