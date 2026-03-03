import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ensure these paths match your project structure exactly
import 'login_page/splash_screen.dart';
import 'home_page/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Check SharedPreferences for the 'remember_me' flag
  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('remember_me') ?? false;

  // 2. Check if a Firebase user session already exists
  final User? user = FirebaseAuth.instance.currentUser;

  // 3. Decide which screen to show first
  Widget initialScreen;

  if (rememberMe && user != null) {
    // If they checked "Remember Me" and are logged in, go straight to Dashboard
    initialScreen = const DashboardPage();
  } else {
    // Otherwise, show the Splash Screen (or Login)
    initialScreen = const SplashScreen();
  }

  // 4. Pass that screen into your App
  runApp(PlanovaApp(startScreen: initialScreen));
}

class PlanovaApp extends StatelessWidget {
  final Widget startScreen;

  const PlanovaApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Recommended for modern Flutter looks
      ),
      // Use the screen we decided on in the main function
      home: startScreen,
    );
  }
}