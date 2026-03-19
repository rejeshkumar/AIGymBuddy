import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_dashboard_screen.dart';

void main() {
  runApp(const AiGymBuddyApp());
}

class AiGymBuddyApp extends StatelessWidget {
  const AiGymBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'AI GYM Buddy',
        theme: _buildAppTheme(Brightness.light),
        darkTheme: _buildAppTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const AuthWrapper(),
      ),
    );
  }
}

ThemeData _buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  // Apple Fitness palette
  const primaryColor = Color(0xFF30D158);   // Apple green
  const secondaryColor = Color(0xFF64D2FF);  // Apple blue
  const errorColor = Color(0xFFFF3B30);     // Apple red
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primaryColor,
    onPrimary: Colors.black,
    secondary: secondaryColor,
    onSecondary: Colors.black,
    error: errorColor,
    onError: Colors.white,
    surface: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
    onSurface: isDark ? Colors.white : Colors.black,
    surfaceContainerHighest: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
    onSurfaceVariant: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
    primaryContainer: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8F5E9),
    onPrimaryContainer: isDark ? primaryColor : const Color(0xFF1B5E20),
    errorContainer: isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFDEAEA),
    onErrorContainer: errorColor,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 17),
      bodyMedium: GoogleFonts.inter(fontSize: 15),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF),
      clipBehavior: Clip.antiAlias,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 64,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      indicatorColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 10,
          fontWeight: states.contains(MaterialState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        );
      }),
    ),
  );
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return auth.isLoggedIn ? const MainDashboardScreen() : const LoginScreen();
  }
}
